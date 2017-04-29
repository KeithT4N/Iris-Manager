//
//  SignInVC.swift
//  Iris Manager
//
//  Created by Keith Tan on 4/23/17.
//  Copyright © 2017 Axis. All rights reserved.
//

import UIKit
import Moya

class SignInVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    
    override func viewDidLoad() {
        errorLabel.isHidden = true
        usernameField.delegate = self
        passwordField.delegate = self
    }
    
    @IBAction func signInButtonPress(_ sender: Any) {
        errorLabel.isHidden = false
        let username = usernameField.text ?? ""
        let password = passwordField.text ?? ""
        
        
        let provider = MoyaProvider<Authentication>()
        provider.request(.signIn(username: username, password: password)) { result in
            
//            print(String(data: response.data, encoding: String.Encoding.utf8) as String!)

            switch result {
            case let .success(response):
                break
            case let .failure(error):
                print(error)
            }
        }
    }
}

