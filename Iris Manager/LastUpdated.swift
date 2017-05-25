//
// Created by Keith Tan on 5/25/17.
// Copyright (c) 2017 Axis. All rights reserved.
//

import Foundation

fileprivate protocol LastUpdated {
    var lastUpdated: Date? { get }
    var key: String { get }
}

extension ModelType: LastUpdated {

    fileprivate var key: String {
        switch self {
            case .products:
                return "productsLastUpdated"
            case .stalls:
                return "stallsLastUpdated"
        }
    }

    var lastUpdated: Date? {
        get {
            let defaults = UserDefaults.standard

            switch self {
                case .products:
                    return defaults.object(forKey: self.key) as? Date
                case .stalls:
                    return defaults.object(forKey: self.key) as? Date
            }
        }
    }

    func setLastUpdated(_ newValue: Date) {
        let defaults = UserDefaults.standard

        switch self {
            case .products:
                defaults.set(newValue, forKey: self.key)
            case .stalls:
                defaults.set(newValue, forKey: self.key)
        }
    }

   
}
