//
//  SummaryCreator.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 10/15/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import XcodeServerSDK
import BuildaUtils
import BuildaGitServer

class SummaryBuilder {
    
    var statusCreator: BuildStatusCreator!
    var lines: [String] = []
    var linkBuilder: (Integration) -> String? = { _ in nil }
    var retestURLBuilder: (() -> String?) = { nil }
    
    //MARK: high level
    
    func buildPassing(integration: Integration) -> StatusAndComment {
        
        let linkToIntegration = self.linkBuilder(integration)
        let status = self.createStatus(.Success, description: "Build passed for Integration #\(integration.number)!", targetUrl: linkToIntegration)
        let buildResultSummary = integration.buildResultSummary!

        switch integration.result {
        case .Succeeded?:
            self.appendTestsPassed(integration, buildResultSummary: buildResultSummary)
        case .Warnings?, .AnalyzerWarnings?:
            
            switch (buildResultSummary.warningCount, buildResultSummary.analyzerWarningCount) {
            case (_, 0):
                self.appendWarnings(integration, buildResultSummary: buildResultSummary)
            case (0, _):
                self.appendAnalyzerWarnings(integration, buildResultSummary: buildResultSummary)
            default:
                self.appendWarningsAndAnalyzerWarnings(integration, buildResultSummary: buildResultSummary)
            }
            
        default: break
        }
        
        //and code coverage
        self.appendCodeCoverage(buildResultSummary)
        
        return self.build(with: status, summary: buildResultSummary)
    }
    
    func buildFailingTests(integration: Integration) -> StatusAndComment {
        
        let linkToIntegration = self.linkBuilder(integration)
        let status = self.createStatus(.Failure, description: "Build failed tests for Integration #\(integration.number)!", targetUrl: linkToIntegration)
        let buildResultSummary = integration.buildResultSummary!

        self.appendTestFailure(integration, buildResultSummary: buildResultSummary)
        appendRebuildLink()
        return build(with: status, summary: buildResultSummary)
    }
    
    func buildErrorredIntegration(integration: Integration) -> StatusAndComment {
        
        let linkToIntegration = self.linkBuilder(integration)
        let status = self.createStatus(.Error, description: "Build error for Integration #\(integration.number)!", targetUrl: linkToIntegration)
        let buildResultSummary = integration.buildResultSummary!

        self.appendErrors(integration, buildResultSummary: buildResultSummary)
        appendRebuildLink()
        return build(with: status, summary: buildResultSummary)
    }
    
    func buildCanceledIntegration(integration: Integration) -> StatusAndComment {
        
        let linkToIntegration = self.linkBuilder(integration)
        let status = self.createStatus(.Error, description: "Build canceled for Integration #\(integration.number)!", targetUrl: linkToIntegration)
        
        self.appendCancel()
        appendRebuildLink()
        return build(with: status, summary: integration.buildResultSummary)
    }
    
    func buildEmptyIntegration() -> StatusAndComment {
        
        let status = self.createStatus(.NoState, description: nil, targetUrl: nil)
        return build(with: status, summary: nil)
    }
    
    //MARK: utils
    
    private func createStatus(state: BuildState, description: String?, targetUrl: String?) -> StatusType {
        
        let status = self.statusCreator.createStatusFromState(state, description: description, targetUrl: targetUrl)
        return status
    }

    func getIntegrationText(integration: Integration) -> String {
        var integrationText = "Integration \(integration.number)"
        if let link = self.linkBuilder(integration) {
            //linkify
            integrationText = "[\(integrationText)](\(link))"
        }
        return "# \(integrationText)"
    }

    func appendDuration(integration: Integration) {
        if let duration = self.formattedDurationOfIntegration(integration) {
            self.lines.append("| Duration  | \(duration) |")
        }
    }

    func appendTestsPassed(integration: Integration, buildResultSummary: BuildResultSummary) {
        self.lines.append(getIntegrationText(integration) + ": 👍")
        appendTableHead()
        appendDuration(integration)
        let testsCount = buildResultSummary.testsCount
        let testSection = testsCount >= 0 ? "All \(testsCount) " + "test".pluralizeStringIfNecessary(testsCount) + " passed!" : ""
        self.lines.append("| Result | \(testSection) |")
    }
    
    func appendWarnings(integration: Integration, buildResultSummary: BuildResultSummary) {
        self.lines.append(getIntegrationText(integration) + ": ⚠️")
        appendTableHead()
        appendDuration(integration)
        let warningCount = buildResultSummary.warningCount
        let testsCount = buildResultSummary.testsCount
        self.lines.append("| Result | All \(testsCount) tests passed, but please **fix \(warningCount) " + "warning".pluralizeStringIfNecessary(warningCount) + "**. |")
        if warningCount > maxWarningsAllowed {
            self.lines.append("| Message | Reduce the number of warnings to \(maxWarningsAllowed) and I'll approve this! |")
        }
    }
    
    func appendAnalyzerWarnings(integration: Integration, buildResultSummary: BuildResultSummary) {
        self.lines.append(getIntegrationText(integration) + ": ⚠️")
        appendTableHead()
        appendDuration(integration)
        let analyzerWarningCount = buildResultSummary.analyzerWarningCount
        let testsCount = buildResultSummary.testsCount
        self.lines.append("| Result | All \(testsCount) tests passed, but please **fix \(analyzerWarningCount) " + "analyzer warning".pluralizeStringIfNecessary(analyzerWarningCount) + "**. |")
        if analyzerWarningCount > maxWarningsAllowed {
            self.lines.append("| Message | Reduce the number of warnings to \(maxWarningsAllowed) and I'll approve this! |")
        }
    }

    func appendWarningsAndAnalyzerWarnings(integration: Integration, buildResultSummary: BuildResultSummary) {
        self.lines.append(getIntegrationText(integration) + ": ⚠️")
        appendTableHead()
        appendDuration(integration)
        let warningCount = buildResultSummary.warningCount
        let analyzerWarningCount = buildResultSummary.analyzerWarningCount
        let testsCount = buildResultSummary.testsCount
        self.lines.append("| Result | All \(testsCount) tests passed, but please **fix \(warningCount) " + "warning".pluralizeStringIfNecessary(warningCount) + "** and **\(analyzerWarningCount) " + "analyzer warning".pluralizeStringIfNecessary(analyzerWarningCount) + "**. |")
        if warningCount + analyzerWarningCount > maxWarningsAllowed {
            self.lines.append("| Message | Reduce the number of warnings to \(maxWarningsAllowed) and I'll approve this! |")
        }
    }

    func appendCodeCoverage(buildResultSummary: BuildResultSummary) {
        
        let codeCoveragePercentage = buildResultSummary.codeCoveragePercentage
        if codeCoveragePercentage > 0 {
            self.lines.append("| Test Coverage | \(codeCoveragePercentage)% |")
        }
    }
    
    func appendTestFailure(integration: Integration, buildResultSummary: BuildResultSummary) {
        self.lines.append(getIntegrationText(integration) + ": ❌")
        appendTableHead()
        appendDuration(integration)
        let testFailureCount = buildResultSummary.testFailureCount
        let testsCount = buildResultSummary.testsCount
        self.lines.append("| Result | \(testFailureCount) " + "test".pluralizeStringIfNecessary(testFailureCount) + " out of \(testsCount) failed. |")
    }
    
    func appendErrors(integration: Integration, buildResultSummary: BuildResultSummary) {
        self.lines.append(getIntegrationText(integration) + ": ❌")
        appendTableHead()
        appendDuration(integration)
        let errorCount: Int = integration.buildResultSummary?.errorCount ?? -1
        self.lines.append("| Result | Build failed. \(errorCount) " + "error".pluralizeStringIfNecessary(errorCount) + ", failing state: \(integration.result!.rawValue). |")
    }
    
    func appendCancel() {
        appendTableHead()
        //TODO: find out who canceled it and add it to the comment?
        self.lines.append("| Result | Build was manually canceled. |")
    }

    func appendRebuildLink() {
        if let url = retestURLBuilder() {
            self.lines.append("Make a new commit or [click here](\(url)) to test again")
        } else {
            self.lines.append("Make a new commit to test again")
        }
    }

    func appendTableHead() {
        self.lines.append("| | |")
        self.lines.append("|---|---|")
    }

    func build(with status: StatusType, summary: BuildResultSummary?) -> StatusAndComment {
        
        let comment: String?
        if lines.count == 0 {
            comment = nil
        } else {
            comment = lines.joinWithSeparator("\n")
        }
        return StatusAndComment(status: status, comment: comment, buildResultSummary: summary)
    }
}

extension SummaryBuilder {
    
    func formattedDurationOfIntegration(integration: Integration) -> String? {
        
        if let seconds = integration.duration {
            
            let result = TimeUtils.secondsToNaturalTime(Int(seconds))
            return result
            
        } else {
            Log.error("No duration provided in integration \(integration)")
            return "[NOT PROVIDED]"
        }
    }
}
