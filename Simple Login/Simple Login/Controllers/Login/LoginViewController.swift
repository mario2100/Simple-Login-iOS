//
//  LoginViewController.swift
//  Simple Login
//
//  Created by Thanh-Nhon Nguyen on 03/02/2020.
//  Copyright © 2020 SimpleLogin. All rights reserved.
//

import UIKit
import SkyFloatingLabelTextField
import MaterialComponents.MaterialRipple
import MBProgressHUD
import Toaster
import OAuth2

final class LoginViewController: UIViewController, Storyboarded {
    @IBOutlet private weak var emailTextField: SkyFloatingLabelTextField!
    @IBOutlet private weak var passwordTextField: SkyFloatingLabelTextField!
    @IBOutlet private weak var loginButton: UIButton!
    
    @IBOutlet private weak var githubView: RippleView!
    @IBOutlet private weak var googleView: RippleView!
    @IBOutlet private weak var facebookView: RippleView!
    @IBOutlet private var socialLoginViews: [RippleView]!
    
    private var isValidEmailAddress: Bool = true {
        didSet {
            loginButton.isEnabled = isValidEmailAddress
        }
    }
    
    private(set) var oauthGithub: OAuth2CodeGrant?
    private(set) var oauthGoogle: OAuth2CodeGrant?

    deinit {
        print("LoginViewController is deallocated")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        
        githubView.didTap = { [unowned self] in
            self.oauthWithGithub()
        }
        
        googleView.didTap = { [unowned self] in
            self.oauthWithGoogle()
        }
        
        facebookView.didTap = { [unowned self] in
            print("facebook")
        }
        
        (UIApplication.shared.delegate as! AppDelegate).loginViewController = self
    }
    
    private func setUpUI() {
        socialLoginViews.forEach({$0.layer.cornerRadius = 4})
        
        loginButton.setTitleColor(SLColor.tintColor, for: .normal)
        loginButton.setTitleColor(SLColor.tintColor.withAlphaComponent(0.3), for: .disabled)
    }
    
    @IBAction private func login() {
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        
        guard isValidEmailAddress else {
            Toast.displayShortly(message: "Invalid email address")
            return
        }
        
        guard let email = emailTextField.text, let password = passwordTextField.text else { return }
        
        MBProgressHUD.showAdded(to: view, animated: true)
        
        SLApiService.login(email: email, password: password) { [weak self] (userLogin, error) in
            guard let self = self else { return }
            
            MBProgressHUD.hide(for: self.view, animated: true)
            
            if let userLogin = userLogin {
                print(userLogin.apiKey)
            } else if let error = error {
                Toast.displayShortly(message: error.description)
            }
        }
    }
    
    private func verifyEmailAddress() {
        if emailTextField.text?.isValidEmail() ?? false {
            emailTextField.errorMessage = nil
            isValidEmailAddress = true
        } else {
            emailTextField.errorMessage = "Invalid email address"
            isValidEmailAddress = false
        }
    }

    @IBAction private func emailTextFieldEditingChanged() {
        guard let email = emailTextField.text, email.contains("@") else {
            emailTextField.errorMessage = nil
            return
        }
        verifyEmailAddress()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
}

// MARK: - OAuth
extension LoginViewController {
    private func socialLogin(social: SLOAuthService, accessToken: String) {
        Toast.displayShortly(message: "\(social.rawValue): \(accessToken)")
    }
    
    private func oauthWithGithub() {
        oauthGithub = OAuth2CodeGrant(settings: [
            "client_id": SLOAuth.Github.clientId,
            "client_secret": SLOAuth.Github.clientSecret,
            "authorize_uri": "https://github.com/login/oauth/authorize",
            "token_uri": "https://github.com/login/oauth/access_token",
            "scope": "user:email",
            "redirect_uris": ["simplelogin://github/callback"],
            "secret_in_body": true,
        ])
        
        oauthGithub?.forgetTokens()
        
        oauthGithub?.authorize() { [weak self] authParameters, error in
            guard let self = self else { return }
            
            if let _ = authParameters {
                if let accessToken = self.oauthGithub?.accessToken {
                    self.socialLogin(social: .github, accessToken: accessToken)
                }
                
            } else if let error = error {
                Toast.displayShortly(message: "Error occured: \(error.description)")
            }
        }
    }
    
    private func oauthWithGoogle() {
        oauthGoogle = OAuth2CodeGrant(settings: [
            "client_id": "\(SLOAuth.Google.clientId).apps.googleusercontent.com",
            "authorize_uri": "https://accounts.google.com/o/oauth2/auth",
            "token_uri": "https://www.googleapis.com/oauth2/v4/token",
            "response_type": "code",
            "scope": "email",
            "redirect_uris": ["com.googleusercontent.apps.\(SLOAuth.Google.clientId):/oauth"]
        ])
        
        oauthGoogle?.forgetTokens()
        
        oauthGoogle?.authorize() { [weak self] authParameters, error in
            guard let self = self else { return }
            
            if let _ = authParameters {
                if let accessToken = self.oauthGoogle?.accessToken {
                    self.socialLogin(social: .google, accessToken: accessToken)
                }
                
            } else if let error = error {
                Toast.displayShortly(message: "Error occured: \(error.description)")
            }
        }
    }
}

// MARK: - UITextFieldDelegate
extension LoginViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == emailTextField {
            verifyEmailAddress()
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
            verifyEmailAddress()
        } else if textField == passwordTextField {
            login()
        }
        
        return true
    }
}