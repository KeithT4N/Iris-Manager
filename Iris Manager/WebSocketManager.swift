//
// Created by Keith Tan on 5/28/17.
// Copyright (c) 2017 Axis. All rights reserved.
//

import Starscream

protocol WebSocketConnectionDelegate {
    static func websocketDidConnect()
    static func websocketDidDisconnect()
}

class WebSocketManager: WebSocketDelegate, AuthenticationDelegate {

    fileprivate static var delegates: [WebSocketConnectionDelegate.Type] = [
        StallUpdateManager.self
    ]

    static var shared = WebSocketManager()

    //Will automatically connect on authentication
    fileprivate var socket: WebSocket!

    static func addDelegate(_ delegate: WebSocketConnectionDelegate.Type) {
        self.delegates.append(delegate)
    }

    fileprivate static func callDelegatesConnection() {
        self.delegates.forEach { delegate in delegate.websocketDidConnect() }
    }

    fileprivate static func callDelegatesDisconnection() {
        self.delegates.forEach { delegate in delegate.websocketDidDisconnect() }
    }

    //Must be singleton because delegate is required to be an instance
    @discardableResult
    fileprivate init() {
        let url = BaseURL.websocketURL + "?token=" + AuthenticationPersistence.token
        self.socket = WebSocket(url: URL(string: url)!)
        self.socket.delegate = self
    }
   
    static func connectSocket() {
        log.verbose("Attempting to connect socket...")
        self.shared.socket.connect()
    }
    
    fileprivate static func reinitializeSocket() {
        WebSocketManager.init()
    }

    fileprivate func toDictionary(str: String) -> [String : Any]? {
        guard let data = str.data(using: .utf8) else {
            log.error("Unable to create data from string: \(str)")
            return nil
        }

        do {
            return try JSONSerialization.jsonObject(with: data) as? [String : Any]
        } catch {
            log.error("Unable to deserialize to JSON.")
            log.error(error.localizedDescription)
            log.error("String: \(str)")

            return nil
        }
    }

    func notifyDelegates(of dict: [String : Any]) {
        guard let model = dict["model"] as? String,
              let type = dict["type"] as? String else {
            log.error("Failed to retrieve model and type from dictionary \(dict)")
            return
        }

        guard let modelType = ModelType.getModelType(for: model) else {
            log.error("Could not get model type for \(model)")
            log.error("Source dictionary: \(dict)")
            return
        }

        switch type {
            case "deletion":
                guard let id = dict["id"] as? Int else {
                    log.error("Failed to retrieve id from dictionary \(dict)")
                    return
                }

                WebSocketUpdateNotifier.notify(model: modelType, of: .deletion(id: id))

            case "creation":
                guard let instanceJSON = dict["instance"] as? [String: Any] else {
                    log.error("Could not retrieve instance from dictionary \(dict)")
                    return
                }

                WebSocketUpdateNotifier.notify(model: modelType, of: .creation(dict: instanceJSON))

            case "modification":
                guard let instanceJSON = dict["instance"] as? [String: Any] else {
                    log.error("Could not retrieve instance from dictionary \(dict)")
                    return
                }

                WebSocketUpdateNotifier.notify(model: modelType, of: .modification(dict: instanceJSON))

            default:
                log.error("Unable to find update type for \(type)")
                log.error("Source dictionary: \(dict)")
        }
    }

    //MARK: - WebSocketDelegate
    func websocketDidReceiveData(socket: WebSocket, data: Data) {
        //Unexpected
    }

    func websocketDidConnect(socket: WebSocket) {
        log.verbose("Websocket is connected")
        WebSocketManager.callDelegatesConnection()
    }

    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        log.error("WebSocket is disconnected: \(error?.localizedDescription ?? "No description provided")")
        WebSocketManager.callDelegatesDisconnection()

        if InternetReachabilityManager.isConnected && AuthenticationPersistence.isSignedIn {
            //Why is websockets disconnected? Retry connection.
            log.verbose("WebSocket is disconnected while connection is available. Retrying connection")
            self.socket.connect()
        }
    }

    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        guard let dictString = self.toDictionary(str: text) else {
            log.error("Failed to convert to dictionary: \(text)")
            return
        }

        log.verbose("Received WebSocket Message")
        self.notifyDelegates(of: dictString)
    }

    //MARK: AuthenticationDelegate
    static func onAuthenticationSuccess() {
        self.reinitializeSocket()
    }
}
