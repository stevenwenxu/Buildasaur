//
//  BitBucketEnterpriseRepo.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 1/27/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import Foundation

class BitBucketEnterpriseRepo: BitBucketEnterpriseEntity, RepoType {
    
    //kind of pointless here
    let permissions = RepoPermissions(read: true, write: true)
    let latestRateLimitInfo: RateLimitType? = BitBucketEnterpriseRateLimit()
    let originUrlSSH: String
    
    required init(json: NSDictionary) {
        
        //split with forward slash, the last two comps are the repo
        //create a proper ssh url for bitbucket enterprise here
        let clone = json
            .dictionaryForKey("links")
            .arrayForKey("clone")
        let ssh:[String:String] = clone[0] as! [String : String]
        let sshURL = NSURL(string: ssh["href"]!)!
        
        self.originUrlSSH = sshURL.absoluteString //sshURL.host! + sshURL.path!
        
        super.init(json: json)
    }
}
