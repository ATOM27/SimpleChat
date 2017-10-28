//
//  UserDetailViewController.swift
//  SimpleChat
//
//  Created by Eugene Mekhedov on 28.10.2017.
//  Copyright © 2017 Eugene Mekhedov. All rights reserved.
//

import UIKit

import FacebookCore
class UserDetailViewController: UIViewController {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var birthdayLabel: UILabel!
    
    var message : Message? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let message = self.message{
            self.avatarImageView.image = getImage()
            self.nameLabel.text = message.senderDisplayName
            self.cityLabel.text = message.city
            self.birthdayLabel.text = message.birthday
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func getImage() -> UIImage{
        let data : Data!
        let image : UIImage
        
        let req = GraphRequestConnection()
        let ImageWidth = Int(self.avatarImageView.frame.width)
        req.add(GraphRequest(graphPath: (message?.facebookID)!, parameters: ["fields": String(format: "%@%d%@%d%@", "picture.type(large).width(", ImageWidth, ").height(", ImageWidth, ")")], accessToken: AccessToken.current, httpMethod: .GET, apiVersion: GraphAPIVersion.defaultVersion)){httpResponce, result in
            switch result {
            case .success(let response):
                let dic = response.dictionaryValue! as! [String : Any]
                let imageURL = URL(string:((dic["picture"] as! [String : Any])["data"] as! [String : Any])["url"] as! String)
                let data : Data
                do {
                    data = try Data(contentsOf: imageURL! )
                    DispatchQueue.main.async {
                        self.avatarImageView.image = UIImage(data: data)
                    }
                } catch{
                    print(error.localizedDescription)
                }
            case .failed(let error):
                print("Graph Request Failed: \(error)")
            }
        }
        req.start()

        
        if let imageURL = message?.largeImageURL{
            guard imageURL.absoluteString != "https://scontent.xx.fbcdn.net/v/t1.0-1/s200x200/10354686_10150004552801856_220367501106153455_n.jpg?oh=3291ae59a2a792a7def447cffa85792b&oe=5A761150" else{
                return UIImage(named: "user")!
            }
            do {
                data = try Data(contentsOf: imageURL )
                image = UIImage(data: data as Data)!
            } catch{
                print(error.localizedDescription)
                image = UIImage(named: "user")!
            }
        }else{
            image = UIImage(named: "user")!
        }
        return image
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
