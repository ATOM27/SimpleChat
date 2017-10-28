//
//  Message.swift
//  SimpleChat
//
//  Created by Eugene Mekhedov on 28.10.2017.
//  Copyright © 2017 Eugene Mekhedov. All rights reserved.
//

import Foundation
import JSQMessagesViewController

class Message : JSQMessage {
    var imageURL : URL?
    var city : String?
    var birthday : String?
    var largeImageURL: URL?
    var facebookID : String?
    
    init!(senderId: String!, displayName: String!, text: String!, imageURL : URL?, city : String?, birthday: String?, largeImageURL: URL?, facebookID : String?) {
        super.init(senderId: senderId, senderDisplayName: displayName, date: Date(), text: text)
        self.imageURL = imageURL
        self.city = city
        self.birthday = birthday
        self.largeImageURL = largeImageURL
        self.facebookID = facebookID
    }
    
     init!(with message: JSQMessage, imageURL : URL?, city : String?, birthday: String?, largeImageURL: URL?, facebookID : String?) {
        super.init(senderId: message.senderId, senderDisplayName: message.senderDisplayName, date: Date(), media: message.media)
        self.imageURL = imageURL
        self.city = city
        self.birthday = birthday
        self.largeImageURL = largeImageURL
        self.facebookID = facebookID

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
