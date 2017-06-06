//
//  WebSocketAPI.swift
//  Iris Manager
//
//  Created by Keith Tan on 5/28/17.
//  Copyright © 2017 Axis. All rights reserved.
//

import Foundation

enum WebSocketAPI {
    case stallCreation(stall: [String: Any])
    case stallUpdate(stall: [String: Any])
    case stallDeletion(id: Int)
}
