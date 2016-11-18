//
//  BitBucketEnterpriseServer.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 1/27/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils
import ReactiveCocoa
import Result

class BitBucketEnterpriseServer : GitServer<BitBucketEnterpriseService> {
    
    let endpoints: BitBucketEnterpriseEndpoints
    let cache = InMemoryURLCache()
    
    init(endpoints: BitBucketEnterpriseEndpoints, service: BitBucketEnterpriseService, http: HTTP? = nil) {
        
        self.endpoints = endpoints
        super.init(service: service, http: http)
    }
    
    override func authChangedSignal() -> Signal<ProjectAuthenticator?, NoError> {
        var res: Signal<ProjectAuthenticator?, NoError>?
        self.endpoints.auth.producer.startWithSignal { res = $0.0 }
        return res!.observeOn(UIScheduler())
    }
}

extension BitBucketEnterpriseServer: SourceServerType {
    
    func createStatusFromState(state: BuildState, description: String?, targetUrl: String?) -> StatusType {
        
        let bbState = BitBucketEnterpriseStatus.BitBucketEnterpriseState.fromBuildState(state)
        let key = "Buildasaur"
        let url = targetUrl ?? "https://github.com/czechboy0/Buildasaur"
        return BitBucketEnterpriseStatus(state: bbState, key: key, name: key, description: description, url: url)
    }
    
    func getBranchesOfRepo(repo: String, completion: (branches: [BranchType]?, error: ErrorType?) -> ()) {
        
        //TODO: start returning branches
        completion(branches: [], error: nil)
    }
    
    func getOpenPullRequests(repo: String, completion: (prs: [PullRequestType]?, error: ErrorType?) -> ()) {
        
        let params = [
            "repo": repo
        ]
        self._sendRequestWithMethod(.GET, endpoint: .PullRequests, params: params, query: nil, body: nil) { (response, body, error) -> () in
            
            if error != nil {
                completion(prs: nil, error: error)
                return
            }
            
            if let body = body as? [NSDictionary] {
                let prs: [BitBucketEnterprisePullRequest] = BitBucketEnterpriseArray(body)
                completion(prs: prs.map { $0 as PullRequestType }, error: nil)
            } else {
                completion(prs: nil, error: Error.withInfo("Wrong body \(body)"))
            }
        }
    }
    
    func getPullRequest(pullRequestNumber: Int, repo: String, completion: (pr: PullRequestType?, error: ErrorType?) -> ()) {
        
        let params = [
            "repo": repo,
            "pr": pullRequestNumber.description
        ]
        
        self._sendRequestWithMethod(.GET, endpoint: .PullRequests, params: params, query: nil, body: nil) { (response, body, error) -> () in
            
            if error != nil {
                completion(pr: nil, error: error)
                return
            }
            
            if let body = body as? NSDictionary {
                let pr = BitBucketEnterprisePullRequest(json: body)
                completion(pr: pr, error: nil)
            } else {
                completion(pr: nil, error: Error.withInfo("Wrong body \(body)"))
            }
        }
    }
    
    func getRepo(repo: String, completion: (repo: RepoType?, error: ErrorType?) -> ()) {
        let repo = service.repoName()
        let params = [
            "repo": repo
        ]
        
        self._sendRequestWithMethod(.GET, endpoint: .Repos, params: params, query: nil, body: nil) {
            (response, body, error) -> () in
            
            if error != nil {
                completion(repo: nil, error: error)
                return
            }
            
            if let body = body as? NSDictionary {
                let repository = BitBucketEnterpriseRepo(json: body)
                completion(repo: repository, error: nil)
            } else {
                completion(repo: nil, error: Error.withInfo("Wrong body \(body)"))
            }
        }
    }
    
    func getStatusOfCommit(commit: String, repo: String, completion: (status: StatusType?, error: ErrorType?) -> ()) {
        
        let params = [
            "repo": repo,
            "sha": commit,
            ]
        
        self._sendRequestWithMethod(.GET, endpoint: .CommitStatuses, params: params, query: nil, body: nil) { (response, body, error) -> () in
            
            if response?.statusCode == 404 {
                //no status yet, just pass nil but OK
                completion(status: nil, error: nil)
                return
            }
            
            if error != nil {
                completion(status: nil, error: error)
                return
            }
            
            if let body = body as? NSArray {
                if body.count > 0 {
                    if let body = body[0] as? NSDictionary {
                        let status = BitBucketEnterpriseStatus(json: body)
                        completion(status: status, error: nil)
                        return
                    }
                }
                // No Status
                completion(status: nil, error: nil)
                return
            }
            completion(status: nil, error: Error.withInfo("Wrong body \(body)"))
            
        }
    }
    
    func postStatusOfCommit(commit: String, status: StatusType, repo: String, completion: (status: StatusType?, error: ErrorType?) -> ()) {
        
        let params = [
            "repo": repo,
            "sha": commit
        ]
        
        let body = (status as! BitBucketEnterpriseStatus).dictionarify()
        self._sendRequestWithMethod(.POST, endpoint: .CommitStatuses, params: params, query: nil, body: body) { (response, body, error) -> () in
            
            if error != nil {
                completion(status: nil, error: error)
                return
            }
            
            if let body = body as? NSDictionary {
                let status = BitBucketEnterpriseStatus(json: body)
                completion(status: status, error: nil)
            } else {
                completion(status: nil, error: Error.withInfo("Wrong body \(body)"))
            }
        }
    }
    
    func postCommentOnIssue(comment: String, issueNumber: Int, repo: String, completion: (comment: CommentType?, error: ErrorType?) -> ()) {
        
        let params = [
            "repo": repo,
            "pr": issueNumber.description
        ]
        
        let body = [
            "content": comment
        ]
        
        self._sendRequestWithMethod(.POST, endpoint: .PullRequestComments, params: params, query: nil, body: body) { (response, body, error) -> () in
            
            if error != nil {
                completion(comment: nil, error: error)
                return
            }
            
            if let body = body as? NSDictionary {
                let comment = BitBucketEnterpriseComment(json: body)
                completion(comment: comment, error: nil)
            } else {
                completion(comment: nil, error: Error.withInfo("Wrong body \(body)"))
            }
        }
    }
    
    func getCommentsOfIssue(issueNumber: Int, repo: String, completion: (comments: [CommentType]?, error: ErrorType?) -> ()) {
        
        let params = [
            "repo": repo,
            "pr": issueNumber.description
        ]
        
        self._sendRequestWithMethod(.GET, endpoint: .PullRequestComments, params: params, query: nil, body: nil) { (response, body, error) -> () in
            
            if error != nil {
                completion(comments: nil, error: error)
                return
            }
            
            if let body = body as? [NSDictionary] {
                let comments: [BitBucketEnterpriseComment] = BitBucketEnterpriseArray(body)
                completion(comments: comments.map { $0 as CommentType }, error: nil)
            } else {
                completion(comments: nil, error: Error.withInfo("Wrong body \(body)"))
            }
        }
    }
}

extension BitBucketEnterpriseServer {
    
    private func _sendRequest(request: NSMutableURLRequest, isRetry: Bool = false, completion: HTTP.Completion) {
        
        self.http.sendRequest(request) { (response, body, error) -> () in
            
            if let error = error {
                completion(response: response, body: body, error: error)
                return
            }
            
            //error out on special HTTP status codes
            let statusCode = response!.statusCode
            switch statusCode {
            case 400, 401, 402 ... 500:
                
                let message = (((body as? NSDictionary)?["errors"] as? NSArray)?[0] as? NSDictionary)?["message"] as? String ?? (body as? String ?? "Unknown error")
                let resultString = "\(statusCode): \(message)"
                completion(response: response, body: body, error: Error.withInfo(resultString, internalError: error))
                return
            default:
                break
            }
            
            completion(response: response, body: body, error: error)
        }
    }
    
    private func _sendRequestWithMethod(method: HTTP.Method, endpoint: BitBucketEnterpriseEndpoints.Endpoint, params: [String: String]?, query: [String: String]?, body: NSDictionary?, completion: HTTP.Completion) {
        
        var allParams = [
            "method": method.rawValue
        ]
        
        //merge the two params
        if let params = params {
            for (key, value) in params {
                allParams[key] = value
            }
        }
        
        do {
            let request = try self.endpoints.createRequest(method, endpoint: endpoint, params: allParams, query: query, body: body)
            self._sendRequestWithPossiblePagination(request, accumulatedResponseBody: NSArray(), completion: completion)
        } catch {
            completion(response: nil, body: nil, error: Error.withInfo("Couldn't create Request, error \(error)"))
        }
    }
    
    private func _sendRequestWithPossiblePagination(request: NSMutableURLRequest, accumulatedResponseBody: NSArray, completion: HTTP.Completion) {
        
        self._sendRequest(request) {
            (response, body, error) -> () in
            
            if error != nil {
                completion(response: response, body: body, error: error)
                return
            }
            
            guard let dictBody = body as? NSDictionary else {
                completion(response: response, body: body, error: error)
                return
            }
            
            //pull out the values
            guard let arrayBody = dictBody["values"] as? [AnyObject] else {
                completion(response: response, body: dictBody, error: error)
                return
            }
            
            //we do have more, let's fetch it
            let newBody = accumulatedResponseBody.arrayByAddingObjectsFromArray(arrayBody)
            
            guard let nextLink = dictBody.optionalStringForKey("next") else {
                
                //is array, but we don't have any more data
                completion(response: response, body: newBody, error: error)
                return
            }
            
            let newRequest = request.mutableCopy() as! NSMutableURLRequest
            newRequest.URL = NSURL(string: nextLink)!
            self._sendRequestWithPossiblePagination(newRequest, accumulatedResponseBody: newBody, completion: completion)
            return
        }
    }
    
}
