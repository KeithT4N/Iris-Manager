//
//  InternetReachabilityManager.swift
//  Iris Manager
//
//  Created by Keith Tan on 5/12/17.
//  Copyright © 2017 Axis. All rights reserved.
//

import Alamofire
import SwiftMessages
import LKAlertController

protocol InternetReachabilityManagerDelegate {
    func onInternetDisconnect()
    func onInternetConnect()
}

//This class has to be a singleton to remain in memory.
class InternetReachabilityManager {

    static var shared: InternetReachabilityManager {
        return self.singleton
    }

    static var isConnected: Bool {
        return self.shared.reachabilityManager.isReachable
    }

    fileprivate static var singleton = InternetReachabilityManager()
    fileprivate var reachabilityManager: NetworkReachabilityManager
    
    fileprivate var delegates: [InternetReachabilityManagerDelegate] = []

    fileprivate init() {

        //ReachabilityManager REQUIRES that https:// is NOT included in the URL.
        reachabilityManager = NetworkReachabilityManager(host: BaseURL.shared.domain)!

        reachabilityManager.listener = { status in
            switch status {
                case .notReachable, .unknown:
                    log.error("Could not reach the internet")
                    self.onInternetDisconnect()

                case .reachable:
                    log.verbose("Internet connection found")
                    self.onInternetConnect()
            }
        }

        reachabilityManager.startListening()
    }
    
    func add(delegate: InternetReachabilityManagerDelegate) {
        self.delegates.append(delegate)
    }

    func onInternetConnect() {
        SwiftMessages.hide()

        let connectionMessageView = MessageView.viewFromNib(layout: .StatusLine)
        connectionMessageView.configureTheme(.success)
        connectionMessageView.configureContent(body: "Connected")

        var connectionMessageConfig = SwiftMessages.Config()
        connectionMessageConfig.presentationStyle = .top
        connectionMessageConfig.presentationContext = .automatic
        connectionMessageConfig.duration = .seconds(seconds: 1)
        connectionMessageConfig.preferredStatusBarStyle = .lightContent
        connectionMessageConfig.dimMode = .none

        SwiftMessages.hide()
        SwiftMessages.show(config: connectionMessageConfig,
                           view: connectionMessageView)
    }

    func onInternetDisconnect() {
        let initialMessageView = MessageView.viewFromNib(layout: .CardView)
        initialMessageView.configureTheme(.error)
        initialMessageView.configureContent(title: "Connection Error", body: "No internet connection found")
        initialMessageView.configureDropShadow()

        var initialMessageConfig = SwiftMessages.Config()
        initialMessageConfig.presentationStyle = .top
        initialMessageConfig.presentationContext = .window(windowLevel: UIWindowLevelNormal)
        initialMessageConfig.duration = .seconds(seconds: 5)
        initialMessageConfig.dimMode = .none
        initialMessageConfig.interactiveHide = false

        let permanentMessageView = MessageView.viewFromNib(layout: .StatusLine)
        permanentMessageView.configureTheme(.error)
        permanentMessageView.configureContent(body: "No Internet Connection")

        var permanentMessageConfig = SwiftMessages.Config()
        permanentMessageConfig.presentationStyle = .top
        permanentMessageConfig.presentationContext = .automatic
        permanentMessageConfig.duration = .forever
        permanentMessageConfig.preferredStatusBarStyle = .lightContent
        permanentMessageConfig.dimMode = .none


        initialMessageConfig.eventListeners.append() { event in
            if case .didHide = event {
                SwiftMessages.show(config: permanentMessageConfig, view: permanentMessageView)
            }
        }

        SwiftMessages.hide()

        SwiftMessages.show(config: initialMessageConfig, view: initialMessageView)
    }
    
    static fileprivate var actionsOnRetry: [() -> Void] = []
    
    static fileprivate func executeQueuedActions() {
        for action in actionsOnRetry {
            action()
        }
    }
    
    static func showDisconnectionAlert(onRetry: @escaping () -> Void) {
        
        defer {
            actionsOnRetry.append(onRetry)
        }
        
        let topWindow = UIWindow(frame: UIScreen.main.bounds)
        
        if let top = topWindow.rootViewController, top.presentedViewController is UIAlertController {
            return
        }
        
        Alert(title: "Could not connect to the server.")
            .addAction("Cancel", style: .cancel)
            .addAction("Retry", style: .default) { _ in
                executeQueuedActions()
            }
            .show()
        
    }


}
