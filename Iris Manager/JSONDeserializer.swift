//
// Created by Keith Tan on 5/25/17.
// Copyright (c) 2017 Axis. All rights reserved.
//

import Foundation

class JSONDeserializer {
    static func toDictionary(json: Data) -> [String: Any]? {
        do {
            let responseDict = try JSONSerialization.jsonObject(with: json) as! [String : Any]
            return responseDict
        } catch {
            log.error("An error occurred deserializing JSON")
            log.error(error.localizedDescription)
        }
        
        return nil
    }
}
