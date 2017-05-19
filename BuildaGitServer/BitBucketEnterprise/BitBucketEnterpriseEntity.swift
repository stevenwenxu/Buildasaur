//
//  BitBucketEnterpriseEntity.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 1/27/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import Foundation

protocol BitBucketEnterpriseType {
    init(json: NSDictionary)
}

class BitBucketEnterpriseEntity : BitBucketEnterpriseType {
    
    required init(json: NSDictionary) {
        
        //add any common keys to be parsed here
    }
    
    init() {
        
        //
    }
    
    func dictionarify() -> NSDictionary {
        assertionFailure("Must be overriden by subclasses that wish to dictionarify their data")
        return NSDictionary()
    }
    
    class func optional<T: BitBucketEnterpriseEntity>(json: NSDictionary?) -> T? {
        if let json = json {
            return T(json: json)
        }
        return nil
    }
    
}

//parse an array of dictionaries into an array of parsed entities
func BitBucketEnterpriseArray<T where T: BitBucketEnterpriseType>(jsonArray: [NSDictionary]) -> [T] {
    
    let parsed = jsonArray.map {
        (json: NSDictionary) -> (T) in
        return T(json: json)
    }
    return parsed
}
