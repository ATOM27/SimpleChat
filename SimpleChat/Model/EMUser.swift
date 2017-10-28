//
//  User.swift
//  SimpleChat
//
//  Created by Eugene Mekhedov on 27.10.2017.
//  Copyright © 2017 Eugene Mekhedov. All rights reserved.
//

import Foundation

class EMUser{
    
    var fullName : String
    var imageURL : URL
    var currentCity : String?
    var birthday : String?
    var senderID : String!
    var largeImageURL : String?
    var facebookID : String?
    
    init(imageURL: URL, fullName: String, senderID: String) {
        self.imageURL = imageURL
        self.fullName = fullName
        self.senderID = senderID
    }
    
    var propertyListRepresentation : [String: Any]{
        return ["fullName" : fullName,
                "imageURL" : imageURL.absoluteString,
                "currentCity" : currentCity ?? "",
                "birthday" : birthday ?? "",
                "senderID" : senderID,
                "largeImageURL": largeImageURL ?? "",
                "facebookID" : facebookID ?? ""]
    }
}
