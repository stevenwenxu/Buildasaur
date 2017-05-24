//
//  File.swift
//  Buildasaur
//
//  Created by Steven Xu on 5/23/17.
//  Copyright © 2017 Honza Dvorsky. All rights reserved.
//

import Foundation

private struct AssociateKeys {
    static var ItemsToRetestKey = "ItemsToRetestKey"
}

public class RetestItem {
    var repoName: String
    var prNumber: Int

    public init(repo name: String, pr number: Int) {
        repoName = name
        prNumber = number
    }
}

extension StandardSyncer {

    public var itemsToRetest: [RetestItem] {
        get {
            return objc_getAssociatedObject(self, &AssociateKeys.ItemsToRetestKey) as! [RetestItem]
        }
        set {
            objc_setAssociatedObject(self, &AssociateKeys.ItemsToRetestKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }


}
