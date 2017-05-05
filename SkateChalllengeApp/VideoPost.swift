//
//  VideoPost.swift
//  SkateChalllengeApp
//
//  Created by Max Jala on 03/05/2017.
//  Copyright © 2017 Max Jala. All rights reserved.
//

import Foundation

class VideoPost {
    
    var videoPostID: Int = 0
    var userID : String = ""
    var userScreenName : String = ""
    var userProfileImageURL : String = ""
    var videoURL : String = ""
    var trickType : String = ""
    var timestamp : String = ""
    var thumbnailURL : String = ""
    
    init(anID: Int, aUserID: String, aUserScreenName: String, aUserProfileImageURL: String, aTrickType: String, aVideoURL: String, aThumbnailURL: String, aTimeStamp: String) {
        videoPostID = anID
        userID = aUserID
        userScreenName = aUserScreenName
        userProfileImageURL = aUserProfileImageURL
        videoURL = aVideoURL
        thumbnailURL = aThumbnailURL
        trickType = aTrickType
        timestamp = aTimeStamp
    }
}

//    let post : [String : Any] = ["userID": self.currentUserID, "screenName": self.profileScreenName,"profileImageURL": self.profileImageURL, "postedVideoURL" : self.videoURL, "timestamp": timeCreated]
