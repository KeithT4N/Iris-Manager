//
//  APIRequest.swift
//  Iris Manager
//
//  Created by Keith Tan on 5/10/17.
//  Copyright © 2017 Axis. All rights reserved.
//

import Moya

func request(for action: IrisAPI, onSuccess: @escaping (Response) -> Void) {
    IrisProvider.shared.api.request(action) { result in
        switch result {
            case let .success(response):
                switch response.statusCode {
                    case 200:
                        //Success
                        onSuccess(response)
                        break

                    case 403:
                        //Unauthorized
                        print("User is not authenticated")
                        Authentication.shared.removeKeychainCredentials()
                        break

                    case 404:
                        //Not Found
                        break
                    
                default:
                    break
                }
                break
            case let .failure(error):
                print("Error performing request for action: \(action)")

                guard let description = error.errorDescription,
                      let reason = error.failureReason else {
                    break
                }

                print(description)
                print(reason)
                break
        }
    }
}
