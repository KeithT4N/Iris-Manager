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
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var signInButton:  UIButton!

    override func viewDidLoad() {
        usernameField.delegate = self
        passwordField.delegate = self
        
        errorLabel.isHidden = true
        activityIndicator.isHidden = true
    }

    @IBAction func signInButtonPress(_ sender: Any) {
        errorLabel.isHidden = false
        let username = usernameField.text ?? ""
        let password = passwordField.text ?? ""

        signIn(username: username, password: password)
    }

    fileprivate func signIn(username: String, password: String) {
        activityIndicator.isHidden = false
        errorLabel.isHidden = false
        errorLabel.text = "Signing in..."
        
        IrisProvider.setCredentials(username: username, password: password)

        IrisProvider.shared.api.request(.isSignedIn) { result in
            
            self.activityIndicator.isHidden = true
            
            switch result {
                case let .success(response):
                    do {
                        let responseDict = try JSONSerialization.jsonObject(with: response.data,
                                                                            options: []) as! [String : Any]
                        
                        if responseDict["username"] != nil {
                            print("User successfully authenticated")
                            self.dismiss(animated: true, completion: nil)
                            return
                        } else if response.statusCode == 403 {
                            print("Invalid credentials")
                            self.errorLabel.text = "Invalid credentials"
                        } else {
                            print("Unkown error occurred")
                            print("Status code: \(response.statusCode)")
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

