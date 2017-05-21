//
//  Authentication.swift
//  Iris Manager
//
//  Created by Keith Tan on 5/18/17.
//  Copyright © 2017 Axis. All rights reserved.
//

import Moya

protocol AuthenticationDelegate: class {
    func onAuthentication()
    func onForbidden()
    func onGeneralFailure()
}

extension AuthenticationDelegate {
    func onForbidden() {
        //If forbidden is not implemented, call general failure's implementation
        onGeneralFailure()
    }

    func onGeneralFailure() {
        //The implementation of general failure is optional.
    }
}

class Authentication {

    static fileprivate var delegates: [AuthenticationDelegate] = []

    static func add(delegate: AuthenticationDelegate) {
        if self.delegates.contains(where: { $0 === delegate }) {
            //If instance already in array, do not append22
            return
        }

        self.delegates.append(delegate)
    }

    static fileprivate func callDelegatesSuccess() {
        delegates.forEach { delegate in
            delegate.onAuthentication()
        }
    }

    static fileprivate func callDelegatesForbidden() {
        delegates.forEach { delegate in
            delegate.onForbidden()
        }
    }

    static fileprivate func callDelegatesFailure() {
        delegates.forEach { delegate in
            delegate.onGeneralFailure()
        }
    }
    
    static fileprivate func isValidResponse(response: [String: Any]) -> Bool {
        return response["username"] != nil
    }

    static fileprivate func onSuccess(response: Response) {
        do {
            let responseDict = try JSONSerialization.jsonObject(with: response.data, options: []) as! [String: Any]

            if self.isValidResponse(response: responseDict) {
                log.info("Username successfully authentication")
                self.callDelegatesSuccess()
                return
            }

            if response.statusCode == 403 {
                log.error("Server returned forbidden")
                self.callDelegatesForbidden()
            } else {
                log.error("Unkown error occurred")
                log.error("Status code: \(response.statusCode)")
                self.callDelegatesFailure()
            }

            let response = String(data: response.data, encoding: .utf8) ?? "No response"
            log.error("Response: \(response)")
        } catch {
            log.error("An error occurred deserializing JSON")
            log.error(error.localizedDescription)
            let response = String(data: response.data, encoding: .utf8) ?? "No response"
            log.error("Response: \(response)")
        }
    }

    static fileprivate func onFailure() {
        self.callDelegatesFailure()
        IrisProvider.removeCredentials()
    }

    static func signIn(username: String, password: String) {
        IrisProvider.setCredentials(username: username, password: password)
        let requestCreator = IrisProvider.RequestCreator(onSuccess: Authentication.onSuccess, onGeneralFailure: Authentication.onFailure)
        
        requestCreator.request(for: .isSignedIn)
    }

}
