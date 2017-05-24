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
    let resultString: String
    var linkBuilder: (Integration) -> String? = { _ in nil }
    
    init() {
        self.resultString = "*Result*: "
    }
    
    //MARK: high level
    
    func buildPassing(integration: Integration) -> StatusAndComment {
        
        let linkToIntegration = self.linkBuilder(integration)
        self.addBaseCommentFromIntegration(integration)
        
        let status = self.createStatus(.Success, description: "Build passed for Integration #\(integration.number)!", targetUrl: linkToIntegration)
        
        let buildResultSummary = integration.buildResultSummary!
        switch integration.result {
        case .Succeeded?:
            self.appendTestsPassed(buildResultSummary)
        case .Warnings?, .AnalyzerWarnings?:
            
            switch (buildResultSummary.warningCount, buildResultSummary.analyzerWarningCount) {
            case (_, 0):
                self.appendWarnings(buildResultSummary)
            case (0, _):
                self.appendAnalyzerWarnings(buildResultSummary)
            default:
                self.appendWarningsAndAnalyzerWarnings(buildResultSummary)
            }
            
        default: break
        }
        
        //and code coverage
        self.appendCodeCoverage(buildResultSummary)
        
        return self.buildWithStatus(status)
    }
    
    func buildFailingTests(integration: Integration) -> StatusAndComment {
        
        let linkToIntegration = self.linkBuilder(integration)
        
        self.addBaseCommentFromIntegration(integration)
        
        let status = self.createStatus(.Failure, description: "Build failed tests for Integration #\(integration.number)!", targetUrl: linkToIntegration)
        let buildResultSummary = integration.buildResultSummary!
        self.appendTestFailure(buildResultSummary)
        appendRebuildLink()
        return self.buildWithStatus(status)
    }
    
    func buildErrorredIntegration(integration: Integration) -> StatusAndComment {
        
        let linkToIntegration = self.linkBuilder(integration)
        self.addBaseCommentFromIntegration(integration)
        
        let status = self.createStatus(.Error, description: "Build error for Integration #\(integration.number)!", targetUrl: linkToIntegration)
        
        self.appendErrors(integration)
        appendRebuildLink()
        return self.buildWithStatus(status)
    }
    
    func buildCanceledIntegration(integration: Integration) -> StatusAndComment {
        
        let linkToIntegration = self.linkBuilder(integration)
        
        self.addBaseCommentFromIntegration(integration)
        
        let status = self.createStatus(.Error, description: "Build canceled for Integration #\(integration.number)!", targetUrl: linkToIntegration)
        
        self.appendCancel()
        appendRebuildLink()
        return self.buildWithStatus(status)
    }
    
    func buildEmptyIntegration() -> StatusAndComment {
        
        let status = self.createStatus(.NoState, description: nil, targetUrl: nil)
        return self.buildWithStatus(status)
    }
    
    //MARK: utils
    
    private func createStatus(state: BuildState, description: String?, targetUrl: String?) -> StatusType {
        
        let status = self.statusCreator.createStatusFromState(state, description: description, targetUrl: targetUrl)
        return status
    }
    
    func addBaseCommentFromIntegration(integration: Integration) {
        
        var integrationText = "Integration \(integration.number)"
        if let link = self.linkBuilder(integration) {
            //linkify
            integrationText = "[\(integrationText)](\(link))"
        }
        
        self.lines.append("Result of \(integrationText)")
        self.lines.append("---")
        
        if let duration = self.formattedDurationOfIntegration(integration) {
            self.lines.append("*Duration*: " + duration)
        }
    }
    
    func appendTestsPassed(buildResultSummary: BuildResultSummary) {
        
        let testsCount = buildResultSummary.testsCount
        let testSection = testsCount > 0 ? "All \(testsCount) " + "test".pluralizeStringIfNecessary(testsCount) + " passed. " : ""
        self.lines.append(self.resultString + "**Perfect build!** \(testSection)👍")
    }
    
    func appendWarnings(buildResultSummary: BuildResultSummary) {
        
        let warningCount = buildResultSummary.warningCount
        let testsCount = buildResultSummary.testsCount
        self.lines.append(self.resultString + "All \(testsCount) tests passed, but please **fix \(warningCount) " + "warning".pluralizeStringIfNecessary(warningCount) + "**.")
    }
    
    func appendAnalyzerWarnings(buildResultSummary: BuildResultSummary) {
        
        let analyzerWarningCount = buildResultSummary.analyzerWarningCount
        let testsCount = buildResultSummary.testsCount
        self.lines.append(self.resultString + "All \(testsCount) tests passed, but please **fix \(analyzerWarningCount) " + "analyzer warning".pluralizeStringIfNecessary(analyzerWarningCount) + "**.")
    }
    
    func appendWarningsAndAnalyzerWarnings(buildResultSummary: BuildResultSummary) {
        
        let warningCount = buildResultSummary.warningCount
        let analyzerWarningCount = buildResultSummary.analyzerWarningCount
        let testsCount = buildResultSummary.testsCount
        self.lines.append(self.resultString + "All \(testsCount) tests passed, but please **fix \(warningCount) " + "warning".pluralizeStringIfNecessary(warningCount) + "** and **\(analyzerWarningCount) " + "analyzer warning".pluralizeStringIfNecessary(analyzerWarningCount) + "**.")
    }
    
    func appendCodeCoverage(buildResultSummary: BuildResultSummary) {
        
        let codeCoveragePercentage = buildResultSummary.codeCoveragePercentage
        if codeCoveragePercentage > 0 {
            self.lines.append("*Test Coverage*: \(codeCoveragePercentage)%")
        }
    }
    
    func appendTestFailure(buildResultSummary: BuildResultSummary) {
        
        let testFailureCount = buildResultSummary.testFailureCount
        let testsCount = buildResultSummary.testsCount
        self.lines.append(self.resultString + "**Build failed \(testFailureCount) " + "test".pluralizeStringIfNecessary(testFailureCount) + "** out of \(testsCount)")
    }
    
    func appendErrors(integration: Integration) {
        
        let errorCount: Int = integration.buildResultSummary?.errorCount ?? -1
        self.lines.append(self.resultString + "**\(errorCount) " + "error".pluralizeStringIfNecessary(errorCount) + ", failing state: \(integration.result!.rawValue)**")
    }
    
    func appendCancel() {
        
        //TODO: find out who canceled it and add it to the comment?
        self.lines.append("Build was **manually canceled**.")
    }

    func appendRebuildLink() {
        self.lines.append("Make a new commit or [click here](http://wxu-laptop.local:5000) to test again")
    }
    
    func buildWithStatus(status: StatusType) -> StatusAndComment {
        
        let comment: String?
        if lines.count == 0 {
            comment = nil
        } else {
            comment = lines.joinWithSeparator("\n")
        }
        return StatusAndComment(status: status, comment: comment)
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
