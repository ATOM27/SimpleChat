//
//  LogoutViewController.swift
//  SimpleChat
//
//  Created by Eugene Mekhedov on 27.10.2017.
//  Copyright © 2017 Eugene Mekhedov. All rights reserved.
//

import UIKit
import FacebookLogin

class LogoutViewController: UIViewController {

    var prevVC : ChatRoomViewController!
    var navBar : UINavigationBar = UINavigationBar()
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func logoutButtonClicked(_ sender: UIButton) {
        let loginManger = LoginManager()
        loginManger.logOut()
        self.dismiss(animated: true) {
            self.prevVC.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func cancelButtomClicked(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
