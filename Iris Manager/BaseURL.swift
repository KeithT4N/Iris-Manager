//
//  BaseURL.swift
//  Iris Manager
//
//  Created by Keith Tan on 4/28/17.
//  Copyright © 2017 Axis. All rights reserved.
//

class BaseURL {
    let domain = "bbd163b0.ngrok.io"
    var completeAddress: String {
        return "https://" + domain + "/api"
    }
    
    public static var shared = BaseURL()
    private init() {}
}
