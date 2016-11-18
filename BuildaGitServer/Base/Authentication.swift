//
//  Authentication.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 1/26/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils

public struct ProjectAuthenticator {
    
    public enum AuthType: String {
        case PersonalToken
        case OAuthToken
        case Basic
    }
    
    public let service: GitService
    public let username: String
    public let type: AuthType
    public let secret: String
    
    public init(service: GitService, username: String, type: AuthType, secret: String) {
        self.service = service
        self.username = username
        self.type = type
        self.secret = secret
    }
}

public protocol KeychainStringSerializable {
    static func fromString(value: String) throws -> Self
    func toString() -> String
}

extension ProjectAuthenticator: KeychainStringSerializable {
    
    public static func fromString(value: String) throws -> ProjectAuthenticator {
        
        let comps = value.componentsSeparatedByString(":")
        guard comps.count >= 5 else { throw Error.withInfo("Corrupted keychain string") }
        guard let serviceType = GitServiceType(rawValue: comps[0]) else {
            throw Error.withInfo("Unsupported service: \(comps[0])")
        }
        guard let type = AuthType(rawValue: comps[2]) else {
            throw Error.withInfo("Unsupported auth type: \(comps[2])")
        }
        //join the rest back in case we have ":" in the token
        let remaining = comps.dropFirst(3).joinWithSeparator(":")
    
        let service: GitService!
        switch serviceType {
        case .GitHub:
            service = GitHubService()
        case .BitBucket:
            service = BitBucketService()
        case .BitBucketEnterprise:
            let baseURL = comps[4].stringByRemovingPercentEncoding!
            service = BitBucketEnterpriseService(baseURL:baseURL)
        }
        let auth = ProjectAuthenticator(service: service, username: comps[1], type: type, secret: remaining)
        return auth
    }
    
    public func toString() -> String {
        var hostname = ""
        switch self.service.serviceType() {
        case .GitHub, .BitBucket:
            hostname = self.service.hostname()
        case .BitBucketEnterprise:
            hostname = self.service.baseURL().absoluteString
        }
        return [
            self.service.serviceType().rawValue,
            self.username,
            self.type.rawValue,
            self.secret,
            hostname.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())!
            ].joinWithSeparator(":")
    }
}
