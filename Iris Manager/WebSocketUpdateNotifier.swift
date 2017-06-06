//
//  WebSocketUpdateNotifier.swift
//  Iris Manager
//
//  Created by Keith Tan on 5/28/17.
//  Copyright © 2017 Axis. All rights reserved.
//

enum WebSocketUpdate {
    case creation(dict: [String : Any])
    case modification(dict: [String : Any])
    case deletion(id: Int)
}

protocol WebSocketReceiver {
    static func handle(update: WebSocketUpdate)
}

class WebSocketUpdateNotifier {

    fileprivate static var delegates : [ ModelType : WebSocketReceiver.Type ] = [
        ModelType.stalls : StallUpdateManager.self
    ]

    static func notify(model: ModelType, of update: WebSocketUpdate) {

        log.info("Received WebSocket notification for \(model.stringName), of \(update)")

        guard let delegate = self.delegates[model] else {
            log.error("Error: Received update for \(model.stringName) but no delegate was found")
            return
        }

        delegate.handle(update: update)
    }

}
