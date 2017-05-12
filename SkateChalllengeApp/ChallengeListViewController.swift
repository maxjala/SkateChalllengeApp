//
//  ChallengeListViewController.swift
//  SkateChalllengeApp
//
//  Created by Max Jala on 03/05/2017.
//  Copyright © 2017 Max Jala. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class ChallengeListViewController: UIViewController {
    
    @IBOutlet weak var clearButton: UIButton! {
        didSet{
            clearButton.addTarget(self, action: #selector(clearChallengeLabel), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var continueButton: UIButton! {
        didSet{
            continueButton.addTarget(self, action: #selector(continueToUpload), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var challengeLabel: UILabel! {
        didSet{
            challengeLabel.text = ""
        }
    }
    
    @IBOutlet weak var categorySegControl: UISegmentedControl!
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var trickListTableView: UITableView! {
        didSet{
            trickListTableView.delegate = self
            trickListTableView.dataSource = self
            
        }
    }
    
    var ref: FIRDatabaseReference!
    var currentUser : FIRUser? = FIRAuth.auth()?.currentUser
    var currentUserID : String = ""
    var currentUserEmail : String = ""
    
    var allTricks : [[String]] = []
    let flips : [String] = ["kickflip", "heelflip", "popshuvit", "fs-popshuvit", "ollie", "nollie"]
    let grinds: [String] = ["tailslide", "noseslide", "50-50", "5-0", "bluntslide"]
    let grabs : [String] = ["melon", "indie", "boneless"]
    let manuals : [String] = ["manual", "nosemanual"]
    let typeTitles : [String] = ["Flips", "Grinds", "Grabs", "Manuals"]
    

    override func viewDidLoad() {
        super.viewDidLoad()
        setCurrentUser()
        createTrickList()
        
    }
    
    func setCurrentUser() {
        ref = FIRDatabase.database().reference()
        // Do any additional setup after loading the view, typically from a nib.
        
        if let id = currentUser?.uid,
            let email = currentUser?.email {
            print(id)
            currentUserID = id
            currentUserEmail = email
        }
    }
    
    func createTrickList() {
        allTricks.append(flips)
        allTricks.append(grinds)
        allTricks.append(grabs)
        allTricks.append(manuals)
        trickListTableView.reloadData()
    }
    
    func clearChallengeLabel() {
        challengeLabel.text = ""
    }
    
    func continueToUpload() {
        let word = challengeLabel.text?.lowercased()
        let firebaseKey = word?.replacingOccurrences(of: "#", with: "")
        let currentDate = Date()
        let currentTimeStamp = Int(currentDate.timeIntervalSince1970)
        let twoHrsInSecs = 7200
        
        //test timeInt 1493793537
        if challengeLabel.text != "" {
        
            ref.child("users").child(currentUserID).child("posts").child(firebaseKey!).observeSingleEvent(of: .value, with: { (snapshot) in
                guard let posts = snapshot.value as? NSDictionary else {self.presentUploadVC(); return}
                guard let challengePosts = posts.allKeys as? [String] else {return}
                
                let lastPost = challengePosts.last
                let lastPostTime = Int(lastPost!)
                
                if currentTimeStamp - twoHrsInSecs > lastPostTime! {
                    self.presentUploadVC()
                } else {
                    return
                }
            })
        }
    }
    
    func presentUploadVC() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "UploadVC") as? UploadVC
        vc?.chosenChallenge = self.challengeLabel.text!
        self.navigationController?.present(vc!, animated: true, completion: nil)
    }


}

extension ChallengeListViewController : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return allTricks.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return typeTitles[section]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allTricks[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "trickCell")
        
        let trickType = allTricks[indexPath.section]
        let specificTrick = trickType[indexPath.row]
        
        cell?.textLabel?.text = specificTrick
        
        return cell!
    }
    
}

extension ChallengeListViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let trickType = allTricks[indexPath.section]
        let specificTrick = trickType[indexPath.row]
        let labelString = "#\(specificTrick)"
        challengeLabel.text = challengeLabel.text! + labelString
    }
}


