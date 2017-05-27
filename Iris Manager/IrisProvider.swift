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

    static func authenticateFromKeychain() {
        let token = AuthenticationPersistence.token

        self.provider = MoyaProvider<IrisAPI>(endpointClosure: { (target: IrisAPI) -> Endpoint<IrisAPI> in
            let defaultEndpoint = MoyaProvider.defaultEndpointMapping(for: target)
            return defaultEndpoint.adding(newHTTPHeaderFields: [ "Authorization" : "Token \(token)" ])
        })

    }

    static func removeCredentials() {
        self.provider = MoyaProvider<IrisAPI>() //Remove EndPoint Closure
        AuthenticationPersistence.removeToken()
    }

    class RequestCreator {

        //Executes on 200-299 success
        fileprivate var onSuccess:            (Response) -> Void

        //Executes on any other failure
        fileprivate var onGeneralFailure:     (() -> Void)?

        //Executes on 403 Forbidden
        fileprivate var onUnauthorized:       (() -> Void)?

        //Executes when request could not be sent
        fileprivate var onInternetDisconnect: (() -> Void)?

        //Executes on 404 not found
        fileprivate var onNotFound:           (() -> Void)?

        //Executes after every condition
        fileprivate var finally:              (() -> Void)?

        init(onSuccess: @escaping (Response) -> Void,
             onUnauthorized:  (() -> Void)? = nil,
             onInternetDisconnect:  (() -> Void)? = nil,
             onNotFound:  (() -> Void)? = nil,
             onGeneralFailure:  (() -> Void)? = nil) {

            self.onSuccess = onSuccess
            self.onGeneralFailure = onGeneralFailure
            self.onInternetDisconnect = onInternetDisconnect
            self.onUnauthorized = onUnauthorized
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
                        self.handleResponse(response: response, from: action)

                    case let .failure(error):
                        self.handleFailure(error: error, from: action)
                }

            }
        }

        fileprivate func handleFailure(error: MoyaError, from action: IrisAPI) {
            log.error("Error performing request for action: \(action)")
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
                executeOrGeneralFailure(self.onInternetDisconnect)
            } else {
                self.onGeneralFailure?()
            }
        }

        fileprivate func handleResponse(response: Response, from action: IrisAPI) {
            switch response.statusCode {
                case 200...299:
                    onSuccess(response)

                case 401:
                    log.error("Unable to do action \(action) - 401 Unauthorized")
                    log.error("Response: \(String(data: response.data, encoding: .utf8) ?? "")")
                    executeOrGeneralFailure(self.onUnauthorized)
                    Authentication.showSignInSheet()

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
}
