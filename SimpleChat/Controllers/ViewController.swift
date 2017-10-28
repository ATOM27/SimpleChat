//
//  ViewController.swift
//  SimpleChat
//
//  Created by Eugene Mekhedov on 27.10.2017.
//  Copyright © 2017 Eugene Mekhedov. All rights reserved.
//

import UIKit
import Firebase
import FacebookCore
import FacebookLogin

class ViewController: UIViewController {
    var currentMyUser : EMUser? = nil
    
    var indicator : UIActivityIndicatorView? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    //MARK: Firebase
    
    private func firebaseLoginSetup(){
        
        let credential = FacebookAuthProvider.credential(withAccessToken: (AccessToken.current?.authenticationToken)!)
        Auth.auth().signIn(with: credential) {[weak self] (user, error) in
//            indicator.removeFromSuperview()
            if let error = error {
                print(error.localizedDescription)
                return
            }else{
                self?.currentMyUser = EMUser(imageURL: (user?.providerData[0].photoURL)!, fullName: (user?.displayName)!, senderID: (user?.uid)!)
                let req = GraphRequestConnection()
                req.add(GraphRequest(graphPath: "/me", parameters: ["fields": "birthday, location, picture.type(large)"], accessToken: AccessToken.current, httpMethod: .GET, apiVersion: GraphAPIVersion.defaultVersion)){httpResponce, result in
                    switch result {
                    case .success(let response):
                        print("Graph Request Succeeded: \(response)")
                        let dic = response.dictionaryValue! as! [String : Any]
                        print("aa")
                        let location : [String : String]? = dic["location"] as? [String : String]
                        self?.currentMyUser?.facebookID = dic["id"] as? String
                        self?.currentMyUser?.currentCity = location?["name"]
                        self?.currentMyUser?.birthday = dic["birthday"] as? String
                        self?.currentMyUser?.largeImageURL = ((dic["picture"] as! [String : Any])["data"] as! [String : Any])["url"] as! String
                    case .failed(let error):
                        print("Graph Request Failed: \(error)")
                    }
                    self?.indicator?.removeFromSuperview()
                }
                req.start()
                self?.performSegue(withIdentifier: "LoginToChat", sender: nil)
            }
        }
    }
    
    //MARK: Actions
    @IBAction func loginButtonClicked(_ sender: UIButton) {
        indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        indicator?.startAnimating()
        indicator?.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(indicator!)
        
        //        let centerX = indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        //        let centerY = indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        
        let con = NSLayoutConstraint(item: indicator, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
        con.isActive = true
        let con2 = NSLayoutConstraint(item: indicator, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0)
        con2.isActive = true
        
        //        NSLayoutConstraint.activate([centerX, centerY])
        view.layoutIfNeeded()
        
        let loginManager = LoginManager()
        loginManager.logIn(readPermissions: [.publicProfile, .userBirthday, .userLocation], viewController: self) {[weak self] (loginResult) in
            switch loginResult {
            case .failed(let error):
                print(error)
            case .cancelled:
                print("User cancelled login.")
            case .success(let grantedPermissions, let declinedPermissions, let accessToken):
                self?.firebaseLoginSetup()
            }
        }
    }
    //MARK: Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "LoginToChat"{
            let vc = segue.destination as! UINavigationController
            (vc.viewControllers.first as! ChatRoomViewController).currentMyUser = self.currentMyUser
            
        }
    }
}

