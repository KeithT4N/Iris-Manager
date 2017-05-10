//
//  IrisProvider.swift
//  Iris Manager
//
//  Created by Keith Tan on 5/9/17.
//  Copyright © 2017 Axis. All rights reserved.
//

import Moya

class IrisProvider {

    //Public Read Only Provider
    var api: MoyaProvider<IrisAPI> {
        return provider
    }

    //Private Read/Write Provider
    fileprivate var provider: MoyaProvider<IrisAPI>!

    //Singleton Instance
    public static let shared = IrisProvider()

    init() {
        self.provider = MoyaProvider<IrisAPI>()
    }

    static func setCredentials(username: String, password: String) {

        Authentication.shared.setKeychainCredentials(username: username, password: password)

        guard let base64 = Authentication.shared.getBase64() else {
            print("Unable to base64 credentials")
            return
        }

        IrisProvider.shared.provider = MoyaProvider<IrisAPI>(endpointClosure: { (target: IrisAPI) -> Endpoint<IrisAPI> in
            let defaultEndpoint = MoyaProvider.defaultEndpointMapping(for: target)
            return defaultEndpoint.adding(newHTTPHeaderFields: [ "Authorization" : "Basic \(base64)" ])
        })
    }

    static func removeCredentials() {
        IrisProvider.shared.provider = MoyaProvider<IrisAPI>()
        Authentication.shared.removeKeychainCredentials()
    }


}
