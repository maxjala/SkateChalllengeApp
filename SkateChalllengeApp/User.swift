//
//  User.swift
//  SkateChalllengeApp
//
//  Created by Max Jala on 08/05/2017.
//  Copyright © 2017 Max Jala. All rights reserved.
//

import Foundation

class User {
    var id: String
    var email : String
    var screenName : String
    var desc : String
    var imageURL : String
    var stance : String
    
    init( ) {
        id = ""
        email = ""
        screenName = ""
        desc = ""
        imageURL = ""
        stance = ""
    }
    
    init(anId : String, anEmail : String, aScreenName : String, aDesc : String, anImageURL : String, aStance: String) {
        id = anId
        email = anEmail
        screenName = aScreenName
        desc = aDesc
        imageURL = anImageURL
        stance = aStance
    }
}
