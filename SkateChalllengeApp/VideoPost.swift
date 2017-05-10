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
    
    var rating : Double = 0.0
    
    init(anID: Int, aUserID: String, aUserScreenName: String, aUserProfileImageURL: String, aTrickType: String, aVideoURL: String, aThumbnailURL: String /*, aTimeStamp: String*/) {
        videoPostID = anID
        userID = aUserID
        userScreenName = aUserScreenName
        userProfileImageURL = aUserProfileImageURL
        videoURL = aVideoURL
        thumbnailURL = aThumbnailURL
        trickType = aTrickType
        //timestamp = aTimeStamp
    }

    func createDateDifference(timeStamp: Int) {
        let dateRangeStart = Date(timeIntervalSince1970: Double(timeStamp))
        let dateRangeEnd = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day, .weekOfYear, .month, .year], from: dateRangeStart, to: dateRangeEnd)
        
        guard let minute = components.minute! as? Int else {return}
        guard let hour = components.hour! as? Int else {return}
        guard let day = components.day! as? Int else {return}
        guard let week = components.weekOfYear! as? Int else {return}
        guard let month = components.month! as? Int else {return}
        guard let year = components.year! as? Int else {return}
        
        print(dateRangeStart)
        print(dateRangeEnd)
        print("difference is \(components.hour ?? 0) hours and \(components.day ?? 0) days")
        
        if year >= 1 {
            timestamp = "\(year) year\(checkifPlural(dateComponent: year)) ago"
        } else if month >= 1 {
            timestamp = "\(month) month\(checkifPlural(dateComponent: month)) ago"
        } else if week >= 1 {
            timestamp = "\(week) week\(checkifPlural(dateComponent: week)) ago"
        } else if day >= 1 {
            timestamp = "\(day) day\(checkifPlural(dateComponent: day)) ago"
        } else if hour >= 1 {
            timestamp = "\(hour) hour\(checkifPlural(dateComponent: hour)) ago"
        } else if minute > 1 {
            timestamp = "\(minute) minute\(checkifPlural(dateComponent: minute)) ago"
        } else {
            timestamp = "Just now"
        }
        
    }
    
    func checkifPlural(dateComponent: Int) -> String {
        if dateComponent > 1 {
            return "s"
        } else {
            return ""
        }
    }


}




