//
//  BitBucketEnterprisePullRequest.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 1/27/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import Foundation

class BitBucketEnterprisePullRequest: BitBucketEnterpriseIssue, PullRequestType {
    
    let title: String
    let source: BitBucketEnterprisePullRequestBranch
    let destination: BitBucketEnterprisePullRequestBranch
    
    required init(json: NSDictionary) {
        
        self.title = json.stringForKey("title")
        
        self.source = BitBucketEnterprisePullRequestBranch(json: json.dictionaryForKey("fromRef"))
        self.destination = BitBucketEnterprisePullRequestBranch(json: json.dictionaryForKey("toRef"))
        
        super.init(json: json)
    }
    
    var headName: String {
        return self.source.branch
    }
    
    var headCommitSHA: String {
        return self.source.commit
    }
    
    var headRepo: RepoType {
        return self.source.repo
    }
    
    var baseName: String {
        return self.destination.branch
    }
}
