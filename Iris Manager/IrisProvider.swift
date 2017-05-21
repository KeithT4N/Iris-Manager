//
//  IrisProvider.swift
//  Iris Manager
//
//  Created by Keith Tan on 5/9/17.
//  Copyright © 2017 Axis. All rights reserved.
//

import Moya

class IrisProvider {

    //Public Read Only Provider
    fileprivate static var provider = MoyaProvider<IrisAPI>()

    static func setCredentials(username: String, password: String) {
        AuthenticationPersistence.shared.setKeychainCredentials(username: username, password: password)
        authenticateFromKeychain()
    }


    static func authenticateFromKeychain() {
        guard let base64 = AuthenticationPersistence.shared.getBase64() else {
            log.error("Unable to base64 credentials")
            return
        }

        self.provider = MoyaProvider<IrisAPI>(endpointClosure: { (target: IrisAPI) -> Endpoint<IrisAPI> in
            let defaultEndpoint = MoyaProvider.defaultEndpointMapping(for: target)
            return defaultEndpoint.adding(newHTTPHeaderFields: [ "Authorization" : "Basic \(base64)" ])
        })

    }

    static func removeCredentials() {
        self.provider = MoyaProvider<IrisAPI>()
        AuthenticationPersistence.shared.removeKeychainCredentials()
    }

    class RequestCreator {

        //Executes on 200-299 success
        fileprivate var onSuccess:            (Response) -> Void

        //Executes on any other failure
        fileprivate var onGeneralFailure:     (() -> Void)?

        //Executes on 403 Forbidden
        fileprivate var onForbidden:          (() -> Void)?

        //Executes when request could not be sent
        fileprivate var onInternetDisconnect: (() -> Void)?

        //Executes on 404 not found
        fileprivate var onNotFound:           (() -> Void)?

        //Executes after every condition
        fileprivate var finally:              (() -> Void)?

        init(onSuccess: @escaping (Response) -> Void,
             onForbidden:  (() -> Void)? = nil,
             onInternetDisconnect:  (() -> Void)? = nil,
             onNotFound:  (() -> Void)? = nil,
             onGeneralFailure:  (() -> Void)? = nil) {

            self.onSuccess = onSuccess
            self.onGeneralFailure = onGeneralFailure
            self.onInternetDisconnect = onInternetDisconnect
            self.onForbidden = onForbidden
            self.onNotFound = onNotFound
        }

        //If function is not defined, attempt on general failure instead
        fileprivate func executeOrGeneralFailure(_ executable: (() -> Void)?) {
            if let executeCallback = executable {
                executeCallback()
            } else {
                self.onGeneralFailure?()
            }
        }

        func request(for action: IrisAPI) {
            IrisProvider.provider.request(action) { result in

                defer {
                    self.finally?()
                }

                switch result {
                    case let .success(response):
                        self.handleSuccess(response: response, from: action)

                    case let .failure(error):
                        log.error("Error performing request for action: \(action)")
                        self.handleFailure(error: error, from: action)
                }

            }
        }

        fileprivate func handleFailure(error: MoyaError, from action: IrisAPI) {
            
            log.error("Unable to do action \(action)")
            log.error(error.localizedDescription)

            if let reason = error.failureReason {
                log.error("Failure reason: \(reason)")
            }

            guard let description = error.errorDescription else {
                log.error("No error description")
                self.onGeneralFailure?()
                return
            }

            //Upon internet disconnection, retry on reconnection
            if description == "The Internet connection appears to be offline." {
                log.verbose("Internet connection error found. Retrying request upon reconnection...")
                executeOrGeneralFailure(self.onInternetDisconnect)
                return
            } else {
                self.onGeneralFailure?()
            }

        }

        fileprivate func handleSuccess(response: Response, from action: IrisAPI) {
            switch response.statusCode {
                case 200...299:
                    onSuccess(response)

                case 403:
                    log.error("Unable to do action \(action) - 403 Forbidden")
                    executeOrGeneralFailure(self.onForbidden)
                    AuthenticationPersistence.shared.showSignInSheet()

                case 404:
                    log.error("Unable to do action \(action) - 404 not found")
                    executeOrGeneralFailure(self.onNotFound)

                default:
                    log.error("Unable to do action \(action) - Status code: \(response.statusCode)")
                    log.error("Response: \(String(data: response.data, encoding: .utf8) ?? "")")

                    self.onGeneralFailure?()
            }

            return
        }

    }

//
//    static func request(for action: IrisAPI, onSuccess: @escaping(Response) -> Void, onFailure: (() -> Void)? = nil) {
//        guard InternetReachabilityManager.isConnected else {
//            InternetReachabilityManager.showDisconnectionAlert {
//                //On retry, recurse
//                request(for: action, onSuccess: onSuccess)
//            }
//            return
//        }
//
//
//        self.api.request(action) { result in
//
//            switch result {
//
//                case let .success(response):
//                    switch response.statusCode {
//                        case 200...299:
//                            //Success
//                            onSuccess(response)
//                            return
//
//                        case 403:
//                            //Unauthorized
//                            log.error("User is not authenticated")
//                            log.error("Response: \(String(data: response.data, encoding: .utf8) ?? "")")
//
//                            AuthenticationPersistence.shared.removeKeychainCredentials()
//                            AuthenticationPersistence.shared.showSignInSheet()
//
//                            //On authentication, re-execute non-destructive action
//                            if action.method == .get {
//                                AuthenticationPersistence.shared.addCallableOnAuthentication {
//                                    request(for: action, onSuccess: onSuccess)
//                                    log.info("Re-executing \(action)")
//                                }
//                            }
//
//                            break
//
//                        default:
//                            log.error("Error performing request for action: \(action)")

//                            break
//                    }
//                    break
//
//                case let .failure(error):
//                    log.error("Error performing request for action: \(action)")
//
//                    if let description = error.errorDescription {
//                        log.error("Description: \(description)")
//
//                        //Upon internet disconnection, retry on reconnection
//                        if description == "The Internet connection appears to be offline." {
//                            log.verbose("Internet connection error found. Retrying request upon reconnection...")
//                            request(for: action, onSuccess: onSuccess, onFailure: onFailure)
//                        }
//                    }
//
//                    if let reason = error.failureReason {
//                        log.error("Failure reason: \(reason)")
//                    }
//
//                    break
//            }
//
//            onFailure?()
//        }
//
//    }
//
//    static func request(for action: IrisAPI, onSuccess: @escaping (Response) -> Void) {
//        request(for: action, onSuccess: onSuccess, onFailure: nil)
//    }
}
