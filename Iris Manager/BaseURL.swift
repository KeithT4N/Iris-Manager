//
//  BaseURL.swift
//  Iris Manager
//
//  Created by Keith Tan on 4/28/17.
//  Copyright © 2017 Axis. All rights reserved.
//

import Foundation

class BaseURL {
    static let websocketURL = "wss://\(domain)/"
    static let domain = "7427b746.ngrok.io"
    static var completeAddress: String {
        return "https://" + domain + "/api"
    }
}
