//
//  Authentication.swift
//  Iris Manager
//
//  Created by Keith Tan on 4/25/17.
//  Copyright © 2017 Axis. All rights reserved.
//

import Moya

enum Authentication {
    case signIn(username: String, password: String)
    case isSignedIn
    case signOut
}

extension Authentication: TargetType {
    var baseURL: URL {
        return URL(string: BaseURL.shared.url)!
    }

    var path: String {
        switch self {
            case .signIn(_, _):
                return "/signin/"
            case .isSignedIn:
                return "/logincheck/"
            case .signOut:
                return "/signout/"
        }
    }

    var method: Moya.Method {
        switch self {
            case .signIn:
                return .post
            case .isSignedIn, .signOut:
                return .get
        }
    }

    var parameters: [String : Any]? {
        switch self {
            case .signIn(let username, let password):
                return [ "username" : username, "password" : password ]
            case .isSignedIn, .signOut:
                return nil
        }
    }

    var parameterEncoding: ParameterEncoding {
        switch self {
            case .signIn:
                return JSONEncoding.default
            case .isSignedIn,
                 .signOut:
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
