//
//  BaseURL.swift
//  Iris Manager
//
//  Created by Keith Tan on 4/28/17.
//  Copyright © 2017 Axis. All rights reserved.
//

class BaseURL {
    let url = "https://8ec74063.ngrok.io/api"
    public static var shared = BaseURL()
    private init() {}
}
