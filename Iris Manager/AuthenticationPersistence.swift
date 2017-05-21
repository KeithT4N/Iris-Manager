//
//  Authentication.swift
//  Iris Manager
//
//  Created by Keith Tan on 5/10/17.
//  Copyright © 2017 Axis. All rights reserved.
//

import SwiftKeychainWrapper

class AuthenticationPersistence: SignInVCDelegate {
    
    static let shared = AuthenticationPersistence()
    
    
    //Callables on authentication succcess
    fileprivate var doOnAuthentication = [() -> Void]()
    
    fileprivate init() {}
    
    func addCallableOnAuthentication(callable: @escaping () -> Void) {
        doOnAuthentication.append(callable)
    }

    func setKeychainCredentials(username: String, password: String) {
        KeychainWrapper.standard.set(username, forKey: "username")
        KeychainWrapper.standard.set(password, forKey: "password")
    }
    
    func removeKeychainCredentials() {
        KeychainWrapper.standard.removeObject(forKey: "username")
        KeychainWrapper.standard.removeObject(forKey: "password")
    }

    func showSignInSheet() {
        let appDelegate = UIKit.UIApplication.shared.delegate!

        if let tabBarController = appDelegate.window??.rootViewController as? UITabBarController {
            let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
            let signInVC   = storyboard.instantiateViewController(withIdentifier: "SignInVC") as! SignInVC

            guard !signInVC.isBeingPresented else {
                log.info("Attempt to present sign in sheet when it is already showing")
                return
            }

            signInVC.modalPresentationStyle = UIModalPresentationStyle.formSheet
            signInVC.delegate = self
            
            tabBarController.present(signInVC, animated: true, completion: nil)
        }
    }

    func getBase64() -> String? {
        guard let username = KeychainWrapper.standard.string(forKey: "username"),
              let password = KeychainWrapper.standard.string(forKey: "password") else {
            return nil
        }
        
        let rawCredentials = "\(username):\(password)"
        let credentialsData = rawCredentials.data(using: .utf8)
        return credentialsData?.base64EncodedString()
    }
    
    func onAuthentication() {
        for callable in doOnAuthentication {
            callable()
        }
    }

    func isSignedIn() -> Bool {
        return KeychainWrapper.standard.string(forKey: "username") != nil
    }
}
