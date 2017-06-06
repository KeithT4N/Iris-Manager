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

class SignInVC: UIViewController, UITextFieldDelegate, AuthenticationDelegate {

    @IBOutlet weak var errorLabel:        UILabel!
    @IBOutlet weak var usernameField:     UITextField!
    @IBOutlet weak var passwordField:     UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var signInButton:      UIButton!
    
    fileprivate static var onSuccess: (() -> Void)? = nil
    fileprivate static var onFailure: (() -> Void)? = nil

    override func viewDidLoad() {
        usernameField.delegate = self
        passwordField.delegate = self
        
        Authentication.add(delegate: SignInVC.self)
        
        SignInVC.onSuccess = {
            self.dismiss(animated: true)
        }
        
        SignInVC.onFailure = {
            self.activityIndicator.isHidden = true
            self.errorLabel.text = "Unknown error occurred"
        }

        errorLabel.isHidden = true
        activityIndicator.isHidden = true
    }

    @IBAction func signInButtonPress(_ sender: Any) {
        let username = usernameField.text ?? ""
        let password = passwordField.text ?? ""

        self.signIn(username: username, password: password)
    }

    func signIn(username: String, password: String) {
        guard InternetReachabilityManager.isConnected else {
            InternetReachabilityManager.showDisconnectionAlert {
                //Recurse on retry
                self.signIn(username: username, password: password)
            }
            return
        }

        activityIndicator.isHidden = false
        errorLabel.isHidden = false
        errorLabel.text = "Signing in..."

        Authentication.signIn(username: username, password: password)
    }

    //MARK: - AuthenticationDelegate
    static func onAuthenticationSuccess() {
        self.onSuccess?()
    }

    static func onAuthenticationFailure() {
        self.onFailure?()
    }


    //MARK: - UITextFieldDelegate
    internal func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        defer {
            textField.resignFirstResponder()
        }

        if textField == usernameField {
            passwordField.becomeFirstResponder()
        } else {

            guard let username = usernameField.text, let password = passwordField.text else {
                return true
            }

            signIn(username: username, password: password)
        }

        return true
    }


}

