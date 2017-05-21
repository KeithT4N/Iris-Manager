//
//  Stall.swift
//  Iris Manager
//
//  Created by Keith Tan on 4/28/17.
//  Copyright © 2017 Axis. All rights reserved.
//

import ObjectMapper
import RealmSwift

class Stall: Object, Mappable, Updatable {
    dynamic var id:          Int    = 0
    dynamic var name:        String = ""
    dynamic var lastUpdated: Date   = Date()

    let products = List<Product>()
    
    
    override static func primaryKey() -> String? {
        return "id"
    }

    required convenience init? (map: Map) {
        self.init()
    }

    func mapping(map: Map) {
        id <- map["id"]
        name <- map["name"]
        lastUpdated = try! map.value("last_updated", using: CustomDateFormatTransform(formatString: "yyyy-MM-dd'T'HH:mm:ss.SSSSZ"))
    }

}
