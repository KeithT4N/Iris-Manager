//
//  Product.swift
//  Iris Manager
//
//  Created by Keith Tan on 4/28/17.
//  Copyright © 2017 Axis. All rights reserved.
//

import Foundation
import ObjectMapper

struct Product: Mappable, Updatable {
    var id: Int!
    var name: String!
    var price: Double!
    var description: String!
    var quantity: Int!
    var tags: [String]!
    var lastUpdated: Date!
    
    init? (map: Map) {}
    
    mutating func mapping(map: Map) {
        id <- map["id"]
        name <- map["name"]
        price <- map["price"]
        description <- map["description"]
        quantity <- map["quantity"]
        tags <- map["tags"]
        lastUpdated <- map["last_updated"]
    }
}
