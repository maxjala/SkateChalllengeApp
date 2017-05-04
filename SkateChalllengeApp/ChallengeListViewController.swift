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
            continueButton.addTarget(self, action: #selector(checkUserUploads), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var challengeLabel: UILabel!
    
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
        if challengeLabel.text != "" {
            let vc = storyboard?.instantiateViewController(withIdentifier: "UploadViewController") as? UploadViewController
            //let vc = navController?.viewControllers.first as? UploadViewController
            vc?.chosenChallenge = challengeLabel.text
            
            //navigationController?.presen(controller!, animated: true)
            //present(navController!, animated: true, completion: nil)
            //navController?.pushViewController(vc!, animated: true)
            navigationController?.present(vc!, animated: true, completion: nil)
        }
        return
    }
    
    func checkUserUploads() {
        let word = challengeLabel.text?.lowercased()
        let firebaseKey = word?.replacingOccurrences(of: "#", with: "")
        let currentDate = Date()
        let currentTimeStamp = Int(currentDate.timeIntervalSince1970)
        let twoHrsInSecs = 7200
        
        //test timeInt 1493793537
        
        ref.child("users").child(currentUserID).child("posts").child(firebaseKey!).observe(.value, with: { (snapshot) in
            print("Value : " , snapshot)
            
            guard let posts = snapshot.value as? NSDictionary else {self.continueToUpload(); return}
            guard let challengePosts = posts.allKeys as? [String] else {return}
            
            let lastPost = challengePosts.last
            let lastPostTime = Int(lastPost!)
            
            if currentTimeStamp - twoHrsInSecs > lastPostTime! {
                self.continueToUpload()
            } else {
                return
            }
            
            
            //guard let post = snapshot.
            
            
        })
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


