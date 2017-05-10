//
//  StallUpdateSkeleton.swift
//  Iris Manager
//
//  Created by Keith Tan on 4/29/17.
//  Copyright © 2017 Axis. All rights reserved.
//

import ObjectMapper

struct StallUpdateSkeleton: Mappable {
    var id:          Int = 0
    var lastUpdated: Date = Date()

    init? (map: Map) {}

    init(id: Int, lastUpdated: Date) {
        self.id = id
        self.lastUpdated = lastUpdated
    }

    mutating func mapping(map: Map) {
        id <- map["id"]
        lastUpdated = try! map.value("last_updated", using: CustomDateFormatTransform(formatString: "yyyy-MM-dd'T'HH:mm:ss.SSSSZ"))
    }
}
