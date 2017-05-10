//
//  SignInVC.swift
//  Iris Manager
//
//  Created by Keith Tan on 4/23/17.
//  Copyright © 2017 Axis. All rights reserved.
//

import UIKit
import Moya
import SwiftMessages
import SwiftKeychainWrapper

class SignInVC: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var errorLabel:    UILabel!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var signInButton:  UIButton!

    override func viewDidLoad() {
        errorLabel.isHidden = true
        usernameField.delegate = self
        passwordField.delegate = self
    }

    @IBAction func signInButtonPress(_ sender: Any) {
        errorLabel.isHidden = false
        let username = usernameField.text ?? ""
        let password = passwordField.text ?? ""

        signIn(username: username, password: password)
    }

    fileprivate func signIn(username: String, password: String) {


        IrisProvider.setCredentials(username: username, password: password)

        IrisProvider.shared.api.request(.isSignedIn) { result in
            switch result {
                case let .success(response):
                    do {
                        let responseDict = try JSONSerialization.jsonObject(with: response.data,
                                                                            options: []) as! [String : Any]
                        if responseDict["username"] != nil {
                            print("User successfully authenticated")
                            self.dismiss(animated: true, completion: nil)
//                            StallEntityRetriever().updateLocalDatabase()
                            return
                        } else {
                            print("User is not signed in.")
                            print(responseDict)
                        }
                    } catch {
                        print("An error occurred deserializing JSON")
                        print(error.localizedDescription)
                    }
                case let .failure(error):
                    print(error)
                    print("A network error occurred")
            }

            //Only reaches on unsuccessful authentication
            IrisProvider.removeCredentials()
        }
    }

    internal func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        defer {
            textField.resignFirstResponder()
        }

        if textField == usernameField {
            passwordField.becomeFirstResponder()
        } else {

            guard let username = usernameField.text,
                  let password = passwordField.text else {
                return true
            }

            signIn(username: username, password: password)
        }

        return true
    }


}

