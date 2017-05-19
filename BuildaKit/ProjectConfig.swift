//
//  ProjectConfig.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 10/3/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils
import BuildaGitServer

public struct ProjectConfig {

    public let id: RefType
    public var url: String
    public var privateSSHKeyPath: String
    public var publicSSHKeyPath: String
    
    // Loaded from keychain
    public var sshPassphrase: String?
    public var serverAuthentication: ProjectAuthenticator?
    public var username: String? // Used for basic authentication
    public var password: String? // Used for basic authentication
    
    public let serviceType: GitServiceType
    
    //creates a new default ProjectConfig
    public init() {
        self.id = Ref.new()
        self.url = ""
        self.serverAuthentication = nil
        self.privateSSHKeyPath = ""
        self.publicSSHKeyPath = ""
        self.sshPassphrase = nil
        self.username = nil
        self.password = nil
        self.serviceType = .GitHub
    }
    
    public func validate() throws {
        //TODO: throw of required keys are not valid
    }
}

private struct Keys {
    
    static let URL = "url"
    static let PrivateSSHKeyPath = "ssh_private_key_url"
    static let PublicSSHKeyPath = "ssh_public_key_url"
    static let Id = "id"
    static let ServiceType = "service_type"
}

extension ProjectConfig: JSONSerializable {
    
    public func jsonify() -> NSDictionary {
        
        let json = NSMutableDictionary()
        
        json[Keys.URL] = self.url
        json[Keys.PrivateSSHKeyPath] = self.privateSSHKeyPath
        json[Keys.PublicSSHKeyPath] = self.publicSSHKeyPath
        json[Keys.Id] = self.id
        json[Keys.ServiceType] = self.serviceType.rawValue
        return json
    }
    
    public init(json: NSDictionary) throws {
        
        self.url = try json.get(Keys.URL)
        self.privateSSHKeyPath = try json.get(Keys.PrivateSSHKeyPath)
        self.publicSSHKeyPath = try json.get(Keys.PublicSSHKeyPath)
        self.id = try json.get(Keys.Id)
        self.serviceType = try GitServiceType(rawValue:json.get(Keys.ServiceType))!
    }
}

