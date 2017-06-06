//
// Created by Keith Tan on 5/25/17.
// Copyright (c) 2017 Axis. All rights reserved.
//

import Foundation

enum ModelType {
    case products
    case stalls
}

extension ModelType {
    var stringName: String {
        switch self {
            case .stalls:
                return "Stall"
            case .products:
                return "Product"
        }
    }

    static func getModelType(for str: String) -> ModelType? {
        switch str {
            case "Stall":
                return ModelType.stalls
            case "Product":
                return ModelType.products
            default:
                return nil
        }
    }

}
