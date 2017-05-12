//
//  LoginViewController.swift
//  SkateChalllengeApp
//
//  Created by Max Jala on 02/05/2017.
//  Copyright © 2017 Max Jala. All rights reserved.
//

import UIKit
import Firebase
//import FBSDKCoreKit
import FBSDKLoginKit
//import GoogleSignIn

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    
    @IBOutlet weak var logInButton: UIButton! {
        didSet{
            logInButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var registerButton: UIButton! {
        didSet{
            registerButton.addTarget(self, action: #selector(registerButtonTapped), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var fbLoginButton: FBSDKLoginButton! {
        didSet{
            fbLoginButton.delegate = self
            fbLoginButton.readPermissions = ["email", "public_profile"]
        }
    }
    
    
    var databaseRef : FIRDatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (FIRAuth.auth()?.currentUser) != nil {
            print("User already logged in")
            // go to main page
            directToViewController()
            //navigationBarHidden()
            
        }
        
        self.hideKeyboardWhenTappedAround()
    }
    
//    func navigationBarHidden(){
//        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
//        self.navigationController?.navigationBar.shadowImage = UIImage()
//        self.navigationController?.navigationBar.isTranslucent = true
//        self.navigationController?.view.backgroundColor = UIColor.clear
//    }
    
    
    // MARK - Email Login
    func loginButtonTapped () {
        guard let email = emailTextField.text,
            let password = passwordTextField.text
            else { return }
        
        if email == "" || password == "" {
            print ("input error : email / password cannot be empty")
            return
        }
        
        //paste from Sign in existing users in Authentication
        FIRAuth.auth()?.signIn(withEmail: email, password: password) { (user, error) in
            // ...
            if let err = error {
                print("SignIn Error : \(err.localizedDescription)")
                return
            }
            
            guard let user = user
                else {
                    print("User Error")
                    return
            }
            
            print("User Logged In")
            print("email : \(String(describing: user.email))")
            print("uid : \(user.uid)")
            
            self.directToViewController()
        }
    }
    
    func facebookLogin() {
        
        if (FBSDKAccessToken.current() == nil) {
            print(123)
        } else {
            print("Logged in to Facebook")
            
        }
    }
    
    func registerButtonTapped() {
        if let controller = storyboard?.instantiateViewController(withIdentifier: "SignUpViewController") {
            navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    func directToViewController () {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "TabBarController")
        present(controller, animated: true, completion: nil)
    }
    
    //End of LoginViewController
}

extension LoginViewController : FBSDKLoginButtonDelegate {
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        
        if error != nil {
            print(error)
            return
        }
        
        showEmailAddress()
        
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("User logged out")
    }
    
    func showEmailAddress() {
        let accessToken = FBSDKAccessToken.current()
        
        guard let accessTokenString = accessToken?.tokenString else {return}
        
        let credential = FIRFacebookAuthProvider.credential(withAccessToken: accessTokenString)
        
        FIRAuth.auth()?.signIn(with: credential, completion: { (user, error) in
            if error != nil {
                print("Something wrong with error user ", error!)
                return
            }
            
            FBSDKGraphRequest(graphPath: "/me", parameters: ["fields" : "id, name, email"]).start { (completion, result, err) in
                if err != nil {
                    print("Failed to graph request", err!)
                    return
                }
                
                if let dictionary = result as? [String : Any] {
                    guard let fBUserName = user?.displayName as? String else {return}
                    let fbUserPic = "\((user!.photoURL)!)"
                    guard let fBEmail = dictionary["email"] as? String else {return}
                    guard let FBvalues : [String : Any] = ["screenName" : fBUserName, "imageURL" : fbUserPic, "email" : fBEmail, "stance" : "unknown", "desc" : ""] else {return}
                    FIRDatabase.database().reference().child("users").child((user?.uid)!).updateChildValues(FBvalues)
                    
                    
                    
                    
                }
                
                self.directToViewController()
            }
            
            
            
            
            print("Successfully logged in ", user!)
        })
        
        
        
    }
    
}

