//
//  updatable.swift
//  Iris Manager
//
//  Created by Keith Tan on 4/28/17.
//  Copyright © 2017 Axis. All rights reserved.
//

import Foundation

protocol Updatable {

    associatedtype SkeletonType

    var lastUpdated: Date { get set }
    func isUpdated(latest: Date) -> Bool
    func toSkeleton() -> SkeletonType
}

extension Updatable {
    func isUpdated(latest: Date) -> Bool {
        return self.lastUpdated < latest
    }
}
