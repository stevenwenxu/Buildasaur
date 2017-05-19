//
//  EditorState.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 10/5/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation

enum EditorState: Int {
    
    case Initial
    
    case NoServer
    case EditingServer
    
    case NoProject
    case EditingProject
    
    case NoBuildTemplate
    case EditingBuildTemplate
    
    case Syncer
    
    case Final
    
    func next() -> EditorState? {
        return self + 1
    }
    
    func previous() -> EditorState? {
        return self + (-1)
    }
}

extension EditorState: Comparable { }

func <(lhs: EditorState, rhs: EditorState) -> Bool {
    return lhs.rawValue < rhs.rawValue
}

func +(lhs: EditorState, rhs: Int) -> EditorState? {
    return EditorState(rawValue: lhs.rawValue + rhs)
}

