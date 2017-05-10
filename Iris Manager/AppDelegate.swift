//
//  AppDelegate.swift
//  Iris Manager
//
//  Created by Keith Tan on 4/23/17.
//  Copyright © 2017 Axis. All rights reserved.
//

import UIKit
import Moya
import Alamofire
import SwiftMessages
import SwiftKeychainWrapper
import IQKeyboardManagerSwift


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window:              UIWindow?
    var reachabilityManager: NetworkReachabilityManager?

    func setUpReachabilityManager() {

        guard let manager = self.reachabilityManager else {

            //ReachabilityManager REQUIRES that https:// is NOT included in the URL.
            reachabilityManager = NetworkReachabilityManager(host: BaseURL.shared.domain)

            reachabilityManager!.listener = { status in
                switch status {
                    case .notReachable, .unknown:
                        print("Server not reachable")
                        self.onInternetDisconnect()

                    case .reachable:
                        print("Internet connection found")
                        self.onInternetConnect()
                }
            }

            reachabilityManager!.startListening()
            return
        }

        //On app launch, status may not have changed.
        if !manager.isReachable {
            self.onInternetDisconnect()
        }

    }

    func onInternetConnect() {
        SwiftMessages.hide()
        //let internetFoundMessageView
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
        permanentMessageView.configureContent(body: "No internet connection")

        var permanentMessageConfig = SwiftMessages.Config()
        permanentMessageConfig.presentationStyle = .top
        permanentMessageConfig.presentationContext = .window(windowLevel: UIWindowLevelAlert)
        permanentMessageConfig.duration = .forever
        permanentMessageConfig.dimMode = .none


        initialMessageConfig.eventListeners.append() { event in
            if case .didHide = event {
                SwiftMessages.show(config: permanentMessageConfig,
                                   view: permanentMessageView)
            }
        }

        SwiftMessages.hide()

        SwiftMessages.show(config: initialMessageConfig,
                           view: initialMessageView)
    }


    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]?) -> Bool {
        // Override point for customization after application launch.
        setUpReachabilityManager()
        IQKeyboardManager.sharedManager().enable = true
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        if Authentication.shared.isSignedIn() {
            print("Is signed in")
            StallEntityRetriever.shared.updateLocalDatabase()
            ProductEntityRetriever.shared.updateLocalDatabase()
        } else {
            print("Not signed in")
            Authentication.shared.showSignInSheet()
        }


    }


    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

