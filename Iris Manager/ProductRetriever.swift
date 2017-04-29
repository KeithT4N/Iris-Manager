//
//  ProductRetriever.swift
//  Iris Manager
//
//  Created by Keith Tan on 4/28/17.
//  Copyright © 2017 Axis. All rights reserved.
//

import Moya

enum ProductRetriever {
    case getProducts
    case getProductUpdates
    case getProduct(productID: Int)

    case createProduct(product: Product, stallID: Int)
    case modifyProduct(product: Product, stallID: Int)
    case deleteProduct(id: Int)
}

extension ProductRetriever: TargetType {
    var baseURL: URL {
        return URL(string: BaseURL.shared.url)!
    }

    var path: String {
        switch self {
            case .getProducts:
                return "/products/"
            case .getProductUpdates:
                return "/products/update"
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
            case .createProduct(let product, let stallID),
                 .modifyProduct(let product, let stallID):
                return [
                        "name" : product.name,
                        "price" : product.price,
                        "description" : product.description,
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
