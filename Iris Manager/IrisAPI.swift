//
//  IrisAPI.swift
//  Iris Manager
//
//  Created by Keith Tan on 4/29/17.
//  Copyright © 2017 Axis. All rights reserved.
//

import Moya

enum IrisAPI {
    case isSignedIn

    case getStalls
    case getStallUpdates
    case getStall(id: Int)

    case createStall(stall: Stall)
    case modifyStall(stall: Stall)
    case deleteStall(id: Int)

    case getProducts
    case getProductUpdates
    case getProduct(productID: Int)

    case createProduct(product: Product, stallID: Int)
    case modifyProduct(product: Product, stallID: Int)
    case deleteProduct(id: Int)
}

extension IrisAPI: TargetType {
    var baseURL: URL {
        return URL(string: BaseURL.shared.completeAddress)!
    }

    var path: String {
        switch self {
            case .isSignedIn:
                return "/logincheck/"

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
            case .isSignedIn:
                return .get

            case .getStalls,
                 .getStallUpdates,
                 .getStall:
                return .get
            case .createStall:
                return .post
            case .modifyStall:
                return .patch
            case .deleteStall:
                return .delete

            case .getProducts,
                 .getProductUpdates,
                 .getProduct:
                return .get

            case .createProduct:
                return .post

            case .modifyProduct:
                return .patch

            case .deleteProduct:
                return .delete
        }
    }

    var parameters: [String : Any]? {
        switch self {
            case .isSignedIn:
                return nil

            case .createStall(let stall),
                 .modifyStall(let stall):
                return [ "name" : stall.name ]

            case .getStalls,
                 .getStallUpdates,
                 .getStall,
                 .deleteStall:
                return nil

            case .createProduct(let product, let stallID),
                 .modifyProduct(let product, let stallID):
                return [
                        "name" : product.name,
                        "price" : product.price,
                        "description" : product.productDescription,
                        "quantity" : product.quantity,
                        "tags" : product.tags,
                        "stall" : stallID
                ]

            case .getProducts,
                 .getProductUpdates,
                 .getProduct,
                 .deleteProduct:
                return nil
        }
    }

    var parameterEncoding: ParameterEncoding {
        switch self {
            case .isSignedIn:
                return URLEncoding.default

            case .createStall(_),
                 .modifyStall(_):
                return JSONEncoding.default

            case .getStalls,
                 .getStallUpdates,
                 .getStall,
                 .deleteStall:
                return URLEncoding.default

            case .createProduct,
                 .modifyProduct:
                return JSONEncoding.default

            case .getProducts,
                 .getProductUpdates,
                 .getProduct,
                 .deleteProduct:
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
