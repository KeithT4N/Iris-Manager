//
//  Authentication.swift
//  Iris Manager
//
//  Created by Keith Tan on 5/10/17.
//  Copyright © 2017 Axis. All rights reserved.
//

import SwiftKeychainWrapper

class AuthenticationPersistence {

    static var token: String {
        get {
            return KeychainWrapper.standard.string(forKey: "token") ?? ""
        }

        set {
            KeychainWrapper.standard.set(newValue, forKey: "token")
        }
    }

    static var isSignedIn: Bool {
        return KeychainWrapper.standard.string(forKey: "username") != nil
    }
    
    static func removeToken() {
        KeychainWrapper.standard.removeObject(forKey: "token")
    }

}
