//
//  UserDefault.swift
//  SkateChalllengeApp
//
//  Created by Max Jala on 11/05/2017.
//  Copyright © 2017 Max Jala. All rights reserved.
//

import Foundation


extension UserDefaults {
    
    static func saveTag(_ tag : String) {
        UserDefaults.standard.set(tag, forKey: "savedTag")
    }
    
    static func getTag() -> String? {
        
        let savedTag = UserDefaults.standard.value(forKey: "savedTag") as? String
        UserDefaults.standard.removeObject(forKey: "savedTag")
        return savedTag
    }
    
    
}
