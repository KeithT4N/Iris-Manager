//
//  Authentication.swift
//  Iris Manager
//
//  Created by Keith Tan on 5/18/17.
//  Copyright © 2017 Axis. All rights reserved.
//

import Moya

//Protocol must be class for instance to be compared on Authentication.add(delegate:)
protocol AuthenticationDelegate: class {
    func onAuthenticationSuccess()

    func onAuthenticationFailure()
}

extension AuthenticationDelegate {
    func onAuthenticationFailure() {
        //Optional function
    }
}

class Authentication {

    static fileprivate var delegates: [AuthenticationDelegate] = []

    static func showSignInSheet() {
        let appDelegate = UIKit.UIApplication.shared.delegate!

        if let tabBarController = appDelegate.window??.rootViewController as? UITabBarController {
            let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
            let signInVC   = storyboard.instantiateViewController(withIdentifier: "SignInVC") as! SignInVC

            guard !signInVC.isBeingPresented else {
                log.warning("Attempt to present sign in sheet when it is already showing")
                return
            }

            signInVC.modalPresentationStyle = UIModalPresentationStyle.formSheet

            tabBarController.present(signInVC, animated: true, completion: nil)
        }
    }

    static func add(delegate: AuthenticationDelegate) {
        if self.delegates.contains(where: { $0 === delegate }) {
            //If instance already in array, do not append22
            return
        }

        self.delegates.append(delegate)
    }

    static fileprivate func callDelegatesSuccess() {
        delegates.forEach { delegate in
            delegate.onAuthenticationSuccess()
        }
    }

    static fileprivate func callDelegatesFailure() {
        delegates.forEach { delegate in
            delegate.onAuthenticationFailure()
        }
    }

    static fileprivate func onResponse(response: Response) {
        guard let responseDict = JSONDeserializer.toDictionary(json: response.data),
              let token = responseDict["token"] as? String else {

            let response = String(data: response.data, encoding: .utf8) ?? "No response"
            log.error("Response: \(response)")

            IrisProvider.removeCredentials()
            self.callDelegatesFailure()
            return
        }

        AuthenticationPersistence.token = token
        IrisProvider.authenticateFromKeychain()
        log.info("User successfully authenticated.")
        self.callDelegatesSuccess()
    }

    static fileprivate func onFailure() {
        IrisProvider.removeCredentials()
        self.callDelegatesFailure()
    }

    static func signIn(username: String, password: String) {
        let requestCreator = IrisProvider.RequestCreator(onSuccess: Authentication.onResponse,
                                                         onGeneralFailure: self.onFailure)

        requestCreator.request(for: .getAuthToken(username: username, password: password))
    }

}
