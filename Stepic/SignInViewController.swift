//
//  SignInViewController.swift
//  Stepic
//
//  Created by Alexander Karpov on 25.12.16.
//  Copyright © 2016 Alex Karpov. All rights reserved.
//

import UIKit
import SVProgressHUD
import TextFieldEffects

class SignInViewController: UIViewController {

    @IBOutlet weak var emailTextField: HoshiTextField!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var passwordTextField: HoshiTextField!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    @IBOutlet weak var socialLabel: UILabel!
    
    func setupLocalizations() {
        emailTextField.placeholder = NSLocalizedString("Email", comment: "")
        passwordTextField.placeholder = NSLocalizedString("Password", comment: "")
        signInButton.setTitle(NSLocalizedString("SignIn", comment: ""), for: UIControlState())
        socialLabel.text = NSLocalizedString("SocialSignIn", comment: "")
        forgotPasswordButton.setTitle(NSLocalizedString("ForgotPassword", comment: ""), for: UIControlState())
    }
    
    var success : ((Void)->Void)? {
        return (navigationController as? AuthNavigationViewController)?.success
    }
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLocalizations()
        passwordTextField.isSecureTextEntry = true
        
        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no
        
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.default
        
        signInButton.setRoundedCorners(cornerRadius: 8, borderWidth: 0, borderColor: UIColor.stepicGreenColor())
        
        NotificationCenter.default.addObserver(self, selector: #selector(SignInViewController.didGetAuthentificationCode(_:)), name: NSNotification.Name(rawValue: "ReceivedAuthorizationCodeNotification"), object: nil)
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    func didGetAuthentificationCode(_ notification: Foundation.Notification) {
        print("entered didGetAuthentificationCode")
        
        //TODO: Implement WebControllerManager
        
        WebControllerManager.sharedManager.dismissWebControllerWithKey("social auth", animated: true, completion: {
            self.authentificateWithCode((notification as NSNotification).userInfo?["code"] as? String ?? "")
        }, error: {
            errorMessage in
            print(errorMessage)
        })        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func authentificateWithCode(_ code: String) {
        SVProgressHUD.show(withStatus: "", maskType: SVProgressHUDMaskType.clear)
        AuthManager.sharedManager.logInWithCode(code, 
                                                success: {
                                                    t in
                                                    AuthInfo.shared.token = t
                                                    NotificationRegistrator.sharedInstance.registerForRemoteNotifications(UIApplication.shared)
                                                    ApiDataDownloader.sharedDownloader.getCurrentUser({
                                                        user in
                                                        AuthInfo.shared.user = user
                                                        User.removeAllExcept(user)
                                                        SVProgressHUD.showSuccess(withStatus: NSLocalizedString("SignedIn", comment: ""))
                                                        UIThread.performUI { 
                                                            self.navigationController?.dismiss(animated: true, completion: {
                                                                [weak self] in
                                                                self?.success?()
                                                            })
                                                        }
                                                        AnalyticsHelper.sharedHelper.changeSignIn()
                                                        AnalyticsHelper.sharedHelper.sendSignedIn()
                                                    }, failure: {
                                                        e in
                                                        print("successfully signed in, but could not get user")
                                                        SVProgressHUD.showSuccess(withStatus: NSLocalizedString("SignedIn", comment: ""))
                                                        UIThread.performUI { 
                                                            self.navigationController?.dismiss(animated: true, completion: {
                                                                [weak self] in
                                                                self?.success?()
                                                            })
                                                        }
                                                    })
        }, failure: {
            e in
            SVProgressHUD.showError(withStatus: NSLocalizedString("FailedToSignIn", comment: ""))
        })
    }
    
    @IBAction func signInPressed(_ sender: UIButton) {
        
        AnalyticsReporter.reportEvent(AnalyticsEvents.SignIn.onSignInScreen, parameters: nil)
        
        SVProgressHUD.show(withStatus: "", maskType: SVProgressHUDMaskType.clear)
        AuthManager.sharedManager.logInWithUsername(emailTextField.text!, password: passwordTextField.text!, 
                                                    success: {
                                                        t in
                                                        AuthInfo.shared.token = t
                                                        NotificationRegistrator.sharedInstance.registerForRemoteNotifications(UIApplication.shared)
                                                        ApiDataDownloader.sharedDownloader.getCurrentUser({
                                                            user in
                                                            AuthInfo.shared.user = user
                                                            User.removeAllExcept(user)
                                                            SVProgressHUD.showSuccess(withStatus: NSLocalizedString("SignedIn", comment: ""))
                                                            UIThread.performUI { 
                                                                self.navigationController?.dismiss(animated: true, completion: {
                                                                    [weak self] in
                                                                    self?.success?()
                                                                })
                                                            }
                                                            AnalyticsHelper.sharedHelper.changeSignIn()
                                                            AnalyticsHelper.sharedHelper.sendSignedIn()
                                                        }, failure: {
                                                            e in
                                                            print("successfully signed in, but could not get user")
                                                            SVProgressHUD.showSuccess(withStatus: NSLocalizedString("SignedIn", comment: ""))
                                                            UIThread.performUI{ 
                                                                self.navigationController?.dismiss(animated: true, completion: {
                                                                    [weak self] in
                                                                    self?.success?()
                                                                })
                                                            }
                                                        })
        }, failure: {
            e in
            SVProgressHUD.showError(withStatus: NSLocalizedString("FailedToSignIn", comment: ""))
        })
    }
    
    @IBAction func forgotPasswordPressed(_ sender: UIButton) {
        WebControllerManager.sharedManager.presentWebControllerWithURLString("\(StepicApplicationsInfo.stepicURL)/accounts/password/reset/", inController: self, 
                                                                             withKey: "reset password", allowsSafari: true, backButtonStyle: BackButtonStyle.done)        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "ReceivedAuthorizationCodeNotification"), object: nil)
        if segue.identifier == "socialNetworksEmbedSegue" {
            let dvc = segue.destination as? SocialNetworksViewController
            dvc?.dismissBlock = {
                self.navigationController?.dismiss(animated: true, completion: {
                    [weak self] in
                    self?.success?()
                })
                
            }
        }
    }
    
    
}
