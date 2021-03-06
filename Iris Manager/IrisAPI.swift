//
//  IrisAPI.swift
//  Iris Manager
//
//  Created by Keith Tan on 4/29/17.
//  Copyright © 2017 Axis. All rights reserved.
//

import Moya

enum IrisAPI {
    case getAuthToken(username: String, password: String)

    case getStalls
    case getStallUpdates(lastUpdate: Date)
    case getStall(id: Int)

    case createStall(stallName: String)
    case modifyStall(stall: Stall)
    case deleteStall(id: Int)

    case getProducts
    case getProductUpdates(lastUpdate: Date)
    case getProduct(productID: Int)

    case createProduct(product: Product, stallID: Int)
    case modifyProduct(product: Product, stallID: Int)
    case deleteProduct(id: Int)
}

extension IrisAPI: TargetType {
    var baseURL: URL {
        return URL(string: BaseURL.completeAddress)!
    }

    var path: String {
        switch self {
            case .getAuthToken(_, _):
                return "/get_auth_token/"

            case .getStalls:
                return "/stalls/"
            case .getStallUpdates:
                return "/stalls/update/"
            case .getStall(let id):
                return "/stalls/\(id)/"
            case .createStall(_):
                return "/stalls/"
            case .modifyStall(let stall):
                return "/stalls/\(stall.id)/"
            case .deleteStall(let id):
                return "/stalls/\(id)/"


            case .getProducts:
                return "/products/"
            case .getProductUpdates:
                return "/products/update/"
            case .getProduct(let id):
                return "/products/\(id)/"
            case .createProduct:
                return "/products/"
            case .modifyProduct(let product, _):
                return "/products/\(product.id)/"
            case .deleteProduct(let id):
                return "/products/\(id)/"
        }
    }

    var method: Moya.Method {
        switch self {
            case .getAuthToken:
                return .post

            case .getStalls, .getStallUpdates, .getStall:
                return .get
            case .createStall:
                return .post
            case .modifyStall:
                return .put
            case .deleteStall:
                return .delete

            case .getProducts, .getProductUpdates, .getProduct:
                return .get

            case .createProduct:
                return .post

            case .modifyProduct:
                return .put

            case .deleteProduct:
                return .delete
        }
    }

    var parameters: [String : Any]? {
        switch self {
            case .getAuthToken(let username, let password):
                return ["username": username, "password": password]

            case .createStall(let stallName):
                return [ "name" : stallName ]

            case .modifyStall(let stall):
                return [ "name" : stall.name ]

            case .getStalls, .getStall, .deleteStall:
                return nil

            case .createProduct(let product, let stallID),
                 .modifyProduct(let product, let stallID):

                return [ "name" : product.name,
                         "price" : product.price,
                         "description" : product.productDescription,
                         "quantity" : product.quantity,
                         "tags" : product.tags,
                         "stall" : stallID ]

            case .getProducts, .getProduct, .deleteProduct:
                return nil

            case
            .getStallUpdates(let lastUpdate),
            .getProductUpdates(let lastUpdate):
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
                return ["last_updated": formatter.string(from: lastUpdate)]
        }
    }

    var parameterEncoding: ParameterEncoding {
        switch self {
            case .getAuthToken(_, _):
                return JSONEncoding.default

            case .createStall(_), .modifyStall(_):
                return JSONEncoding.default

            case .getStalls, .getStallUpdates, .getStall, .deleteStall:
                return URLEncoding.default

            case .createProduct, .modifyProduct:
                return JSONEncoding.default

            case .getProducts, .getProductUpdates, .getProduct, .deleteProduct:
                return URLEncoding.default
        }
    }

    var sampleData: Data {
        return Data()
    }

    var task: Task {
        return .request
    }

}
