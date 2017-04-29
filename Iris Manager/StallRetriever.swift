//
//  StallRetriever.swift
//  Iris Manager
//
//  Created by Keith Tan on 4/29/17.
//  Copyright © 2017 Axis. All rights reserved.
//

import Moya

enum StallRetriever {
    case getStalls
    case getStallUpdates
    case getStall(id: Int)

    case createStall(stall: Stall)
    case modifyStall(stall: Stall)
    case deleteStall(id: Int)
}

extension StallRetriever: TargetType {
    var baseURL: URL {
        return URL(string: BaseURL.shared.url)!
    }

    var path: String {
        switch self {

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
        }
    }

    var method: Moya.Method {
        switch self {
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
        }
    }

    var parameters: [String : Any]? {
        switch self {
            case .createStall(let stall),
                 .modifyStall(let stall):
                return [ "name" : stall.name ]

            case .getStalls,
                 .getStallUpdates,
                 .getStall,
                 .deleteStall:
                return nil
        }
    }

    var parameterEncoding: ParameterEncoding {
        switch self {
            case .createStall(_),
                 .modifyStall(_):
                return JSONEncoding.default

            case .getStalls,
                 .getStallUpdates,
                 .getStall,
                 .deleteStall:
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
