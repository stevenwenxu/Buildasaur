//
//  BitBucketEnterprisePullRequestBranch.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 1/27/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import Foundation

class BitBucketEnterprisePullRequestBranch : BitBucketEnterpriseEntity {
    
    let branch: String
    let commit: String
    let repo: BitBucketEnterpriseRepo
    
    required init(json: NSDictionary) {
        let name = json.stringForKey("id").stringByReplacingOccurrencesOfString("refs/heads/", withString: "")
        self.branch = name
        self.commit = json.stringForKey("latestCommit")
        self.repo = BitBucketEnterpriseRepo(json: json.dictionaryForKey("repository"))
        
        super.init(json: json)
    }
}