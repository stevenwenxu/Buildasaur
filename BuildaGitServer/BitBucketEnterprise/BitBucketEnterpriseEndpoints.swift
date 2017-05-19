//
//  BitBucketEnterpriseEndpoints.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 1/27/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils
import ReactiveCocoa

class BitBucketEnterpriseEndpoints {
    
    enum Endpoint {
        case Repos
        case PullRequests
        case PullRequestComments
        case CommitStatuses
    }
    
    private let baseURL: String
    internal let auth = MutableProperty<ProjectAuthenticator?>(nil)
    
    init(baseURL: String, auth: ProjectAuthenticator?) {
        self.baseURL = baseURL
        self.auth.value = auth
    }
    
    private func endpointURL(endpoint: Endpoint, params: [String: String]? = nil) -> String {
        
        switch endpoint {
            
        case .Repos:
            if let repo = params?["repo"] {
                // https://{host}/rest/api/1.0/projects/{project_name}/repos/{repo_name}
                return "/rest/api/1.0/projects/\(self.repoEndPointName(repo))"
            } else {
                return ""
            }
            
        case .PullRequests:
            
            assert(params?["repo"] != nil, "A repo must be specified")
            if let repo = params?["repo"] {
                return "/rest/api/1.0/projects/\(self.repoEndPointName(repo))/pull-requests"
            } else {
                return ""
            }
        
        case .PullRequestComments:
            
            assert(params?["repo"] != nil, "A repo must be specified")
            assert(params?["pr"] != nil, "A PR must be specified")
            let pr = self.endpointURL(.PullRequests, params: params)
            
            if params?["method"] == "POST" {
                let repo = params!["repo"]!
                let pr = params!["pr"]!
                return "/1.0/repositories/\(self.repoEndPointName(repo))/pull-requests/\(pr)/comments"
            } else {
                return "\(pr)/comments"
            }
            
        case .CommitStatuses:
            assert(params?["sha"] != nil, "A commit sha must be specified")
            let sha = params!["sha"]!
            let build = "/rest/build-status/1.0/commits/\(sha)"
            return build
            
        }
        
    }
    
    func setBasicAuthorizationOnRequest(request: NSMutableURLRequest) {
        
        guard let auth = self.auth.value else { return }
            
        switch auth.type {
        case .Basic:
            let credential = "\(auth.username):\(auth.secret)".base64String()
            request.setValue("Basic \(credential)", forHTTPHeaderField:"Authorization")
        default:
            fatalError("This kind of authentication is not supported for BitBucket Enterprise")
        }
    }
    
    func createRequest(method: HTTP.Method, endpoint: Endpoint, params: [String : String]? = nil, query: [String : String]? = nil, body: NSDictionary? = nil) throws -> NSMutableURLRequest {
        
        let endpointURL = self.endpointURL(endpoint, params: params)
        let queryString = HTTP.stringForQuery(query)
        let wholePath = "\(self.baseURL)\(endpointURL)\(queryString)"
        
        let url = NSURL(string: wholePath)!
        
        let request = NSMutableURLRequest(URL: url)
        
        request.HTTPMethod = method.rawValue
        self.setBasicAuthorizationOnRequest(request)
        
        if let body = body {
            try self.setJSONBody(request, body: body)
        }
        
        return request
    }
    
    func setStringBody(request: NSMutableURLRequest, body: String) {
        let data = body.dataUsingEncoding(NSUTF8StringEncoding)
        request.HTTPBody = data
        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
    }

    func setJSONBody(request: NSMutableURLRequest, body: NSDictionary) throws {
        let data = try NSJSONSerialization.dataWithJSONObject(body, options: NSJSONWritingOptions())
        request.HTTPBody = data
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    }
    
    // Converts "{project_name}/{repo_name}" to "{project_name}/repos/{repo_name}".
    private func repoEndPointName(repo: String) -> String {
        let repoComponents = repo.componentsSeparatedByString("/")
        let repoName = "\(repoComponents[0])/repos/\(repoComponents[1])"
        return repoName
    }
}