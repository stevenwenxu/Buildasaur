//
//  BitBucketEnterpriseIssue.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 1/27/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import Foundation

class BitBucketEnterpriseIssue: BitBucketEnterpriseEntity, IssueType {
    
    let number: Int
    
    required init(json: NSDictionary) {
        
        self.number = json.intForKey("id")
        
        super.init(json: json)
    }
}