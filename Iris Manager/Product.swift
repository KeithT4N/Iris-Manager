//
//  Product.swift
//  Iris Manager
//
//  Created by Keith Tan on 4/28/17.
//  Copyright © 2017 Axis. All rights reserved.
//

import Foundation
import ObjectMapper
import RealmSwift

class Product: Object, Mappable, Updatable {
    dynamic var id:                 Int    = 0
    dynamic var name:               String = ""
    dynamic var price:              Double = 0.0
    // NSObject has property named description.
    dynamic var productDescription: String = ""
    dynamic var quantity:           Int    = 0
    dynamic var lastUpdated:        Date   = Date()


    /*
     This hack is required because Realm does not
     support [String].
     
     */
    var tags: [String] {
        get {
            return _backingTags.map {
                $0.stringValue
            }
        }

        set {
            _backingTags.removeAll()
            newValue.forEach { item in
                _backingTags.append(RealmString(value: item))
            }
        }

    }
    let _backingTags = List<RealmString>()

    override static func ignoredProperties() -> [String] {
        return [ "tags" ]
    }


    typealias SkeletonType = ProductUpdateSkeleton

    override static func primaryKey() -> String? {
        return "id"
    }

    required convenience init? (map: Map) {
        self.init()
    }

    func mapping(map: Map) {
        id <- map["id"]
        name <- map["name"]
        price <- map["price"]
        productDescription <- map["description"]
        quantity <- map["quantity"]
        tags <- map["friends"]
        lastUpdated = try! map.value("last_updated", using: CustomDateFormatTransform(formatString: "yyyy-MM-dd'T'HH:mm:ss.SSSSZ"))
    }

    func toSkeleton() -> ProductUpdateSkeleton {
        return ProductUpdateSkeleton(id: self.id, lastUpdated: self.lastUpdated)
    }
}

class RealmString: Object {
    dynamic var stringValue = ""
}
