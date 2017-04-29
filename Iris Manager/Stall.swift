//
//  Stall.swift
//  Iris Manager
//
//  Created by Keith Tan on 4/28/17.
//  Copyright © 2017 Axis. All rights reserved.
//

import Foundation
import ObjectMapper

struct Stall: Mappable, Updatable {
    var id: Int!
    var name: String!
    var products: [Product]!
    var lastUpdated: Date!
    
    init? (map: Map) {}
    
    mutating func mapping(map: Map) {
        id <- map["id"]
        name <- map["name"]
        lastUpdated <- map["last_updated"]
    }
}
