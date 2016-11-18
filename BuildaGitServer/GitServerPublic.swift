//
//  GitSourcePublic.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 12/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils
import Keys
import ReactiveCocoa
import Result

typealias BuildasaurKeys = BuildasaurxcodeprojKeys

public enum GitServiceType: String {
    case GitHub = "github"
    case BitBucket = "bitbucket"
    case BitBucketEnterprise = "bitbucketenterprise"
}

public protocol GitService {
    func serviceType() -> GitServiceType
    func prettyName() -> String
    func logoName() -> String
    func hostname() -> String
    func baseURL() -> NSURL
    func authorizeUrl() -> String
    func accessTokenUrl() -> String
    func serviceKey() -> String
    func serviceSecret() -> String
}

public class GitServer<T: GitService> : HTTPServer {
    
    let service: T
    
    public func authChangedSignal() -> Signal<ProjectAuthenticator?, NoError> {
        return Signal.never
    }
    
    init(service: T, http: HTTP? = nil) {
        self.service = service
        super.init(http: http)
    }
}

