//
//  HomeViewController.swift
//  SkateChalllengeApp
//
//  Created by Max Jala on 02/05/2017.
//  Copyright © 2017 Max Jala. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
//import MobileCoreServices
import FBSDKLoginKit
import AVKit
import AVFoundation
import Cosmos

enum DisplayType {
    case homeDisplay
    case exploreDisplay
}

class ExploreViewController: UIViewController {
    
    @IBOutlet weak var videoTableView: UITableView! {
        didSet{
            videoTableView.delegate = self
            videoTableView.dataSource = self
            videoTableView.register(VideoPostViewCell.cellNib, forCellReuseIdentifier: VideoPostViewCell.cellIdentifier)
            videoTableView.estimatedRowHeight = 510.0
            videoTableView.rowHeight = UITableViewAutomaticDimension
        }
    }
    
    var profileType : DisplayType = .homeDisplay
    

    //var filteredPictureFeed: [PicturePost] = []
    var ref: FIRDatabaseReference!
    var currentUser : FIRUser? = FIRAuth.auth()?.currentUser
    var currentUserID : String = ""
    var lastPostID : Int = 0
    var followingArray : [String] = []
    var videoFeed : [VideoPost] = []
    var player : AVPlayer!

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = FIRDatabase.database().reference()
        // Do any additional setup after loading the view, typically from a nib.
        
        if let id = currentUser?.uid {
            print(id)
            currentUserID = id
        }
        
        //listenToFirebase()
        fetchFollowingUsers()
    
    }
    
    @IBAction func tempLogout(_ sender: Any) {
        let firebaseAuth = FIRAuth.auth()
        
        do {
            try firebaseAuth?.signOut()
            let logInVC = storyboard?.instantiateViewController(withIdentifier: "AuthNavController")
            present(logInVC!, animated: true, completion: nil)
            
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        
    }
    
    func fetchFollowingUsers() {
        
        ref.child("users").child(currentUserID).child("following").observe(.value, with: { (snapshot) in
            print("Value : " , snapshot)
            
            self.videoFeed.removeAll()
            
            guard let checkedID = snapshot.value as? NSDictionary
                else {
                    print("observing child value for \(self.currentUserID) following no value")
                    self.videoTableView.reloadData()
                    return
            }
            self.followingArray = (checkedID.allKeys as? [String])!
            self.followingArray.append(self.currentUserID)
            
            self.fetchPosts()
            
        })
        
    }
    
    func fetchPosts() {
        
        ref.child("posts").observe(.childAdded, with: { (snapshot) in
            print("Value : " , snapshot)
            
            // 3. convert snapshot to dictionary
            guard let info = snapshot.value as? NSDictionary else {return}
            // 4. add users to array of following users
            let newPost = self.createVideoPost(id: snapshot.key, postInfo: info)
            
//            if let tempPost = newPost {
                self.addToMyFeed(newPost!)
            //}
            
            // sort
            self.videoFeed.sort(by: { (picture1, picture2) -> Bool in
                return picture1.videoPostID > picture2.videoPostID
                
            })
            
            self.videoTableView.reloadData()
            
            
        })
        
        //self.videoTableView.reloadData()
        
    }

    
    func createVideoPost(id: Any, postInfo: NSDictionary) -> VideoPost? {
        if let userID = postInfo["userID"] as? String,
            let trickType = postInfo["trickType"] as? String,
            let userProfilePicture = postInfo["profileImageURL"] as? String,
            //let timeStamp = postInfo["timestamp"] as? String,
            let postID = id as? String,
            let currentPostId = Int(postID),
            let screenName = postInfo["screenName"] as? String,
            let videoURL = postInfo["postedVideoURL"] as? String,
            let thumbnailURL = postInfo["thumbnailURL"] as? String {
           //let postTime = PostTime(snapshot.key)
            //let dateSince = postTime.dateSince
            let videoPost = VideoPost(anID: currentPostId, aUserID: userID, aUserScreenName: screenName, aUserProfileImageURL: userProfilePicture, aTrickType: trickType, aVideoURL: videoURL, aThumbnailURL: thumbnailURL)
            
            videoPost.createDateDifference(timeStamp: currentPostId)
            
            //self.videoFeed.append(videoPost)
            
            return videoPost
        }
        return nil
    }
    
    func addToMyFeed(_ post : VideoPost) {
        
        for each in self.followingArray {
            if each == post.userID {
                
                self.videoFeed.append(post)
                
            }
        }
        //self.videoTableView.reloadData()
    }


}

extension ExploreViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videoFeed.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: VideoPostViewCell.cellIdentifier) as? VideoPostViewCell else { return UITableViewCell() }
        
        let currentVideo = videoFeed[indexPath.row]
        let profilePic = currentVideo.userProfileImageURL
        let trickType = currentVideo.trickType
        let screenName = currentVideo.userScreenName
        let thumbnailURL = currentVideo.thumbnailURL
        
        cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: profilePic)
        cell.previewImageView.loadImageUsingCacheWithUrlString(urlString: thumbnailURL)
        cell.hashtagLabel.text = trickType
        cell.userNameLabel.text = screenName
        cell.timeLabel.text = currentVideo.timestamp
        //cell.exploreButton.addTarget(self, action: #selector(exploreButtonTapped), for: .touchUpInside)
        
        //Assign Star Ratings
        observeUserRating(_id: currentVideo.videoPostID, _starRating: cell.userRatingView)
        observeAllRatings(_id: currentVideo.videoPostID, _starRatings: cell.publicRatingView, _labelRatings: cell.ratingLabel)
        
        cell.delegate = self
        cell.videoPost = currentVideo
        
        return cell
        
    }
    
    //MARK : VIDEOPOSTCELL FUNCTIONS
    
    func exploreButtonTapped(_ trickTag: String) {
        UserDefaults.saveTag(trickTag)
        tabBarController?.selectedIndex = 2
    }
    
    func challengeButtonTapped(_ tricktag: String) {
        let word = tricktag.lowercased()
        let firebaseKey = word.replacingOccurrences(of: "#", with: "")
        let currentDate = Date()
        let currentTimeStamp = Int(currentDate.timeIntervalSince1970)
        let twoHrsInSecs = 7200
        
        ref.child("users").child(currentUserID).child("posts").child(firebaseKey).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let posts = snapshot.value as? NSDictionary else {self.presentUploadVC(tricktag); return}
            guard let challengePosts = posts.allKeys as? [String] else {return}
            
            let lastPost = challengePosts.last
            let lastPostTime = Int(lastPost!)
            
            if currentTimeStamp - twoHrsInSecs > lastPostTime! {
                self.presentUploadVC(tricktag)
            } else {
                return
            }
        })
    }
    
    func presentUploadVC(_ trickTag: String) {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "UploadVC") as? UploadVC
            else {return}
        vc.chosenChallenge = trickTag
        navigationController?.present(vc, animated: true, completion: nil)
    }
    
    
    //Video Streaming Functions For Cell
    func handlePlay(_videoURL: String, _videoView: UIView) {
        if let url = URL(string: _videoURL) {
            if player == nil {
                player = AVPlayer(url: url)
            }

                //Play Function
                let playerLayer = AVPlayerLayer(player: player)
                playerLayer.frame = _videoView.bounds
                _videoView.layer.addSublayer(playerLayer)
                player.play()
                print("Attempting to play Video")

            
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
            NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying(note:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
            
        }
        
    }
    
    func playerDidFinishPlaying(note: NSNotification) {
        print("Video Finished")
        player = nil
    }
    
    //Firebase Observations for Cell Display Elements
    func observeUserRating(_id: Int, _starRating: CosmosView) {
        ref.child("posts").child("\(_id)").child("ratings").child(currentUserID).observe(.value, with: {(snapshot) in
            print("Value: " , snapshot)
            
            guard let existingRating = snapshot.value as? String else {return}
            let doubleValue = Double(existingRating)
            
            _starRating.rating = doubleValue!
        })
    }
    
    func observeAllRatings(_id: Int, _starRatings: CosmosView, _labelRatings: UILabel) {
        ref.child("posts").child("\(_id)").child("ratings").observe(.value, with: {(snapshot) in
            print("Value: " , snapshot)

            var totalRating = 0.0
            
            guard let ratingDict = snapshot.value as? NSDictionary else {return}
            let ratingCount = snapshot.childrenCount
            
            guard let ratingValues = ratingDict.allValues as? [String] else {return}
            
            for each in ratingValues {
                totalRating += Double(each)!
            }
            
            let averageRating = totalRating/Double(ratingCount)
            
            _starRatings.rating = averageRating
            if ratingCount > 1 {
                _labelRatings.text = "\(ratingCount) people rated this \(averageRating)"
                return
            }
            _labelRatings.text = "\(ratingCount) person rated this \(averageRating)"
        })
    }

}



extension ExploreViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        player = nil

    }
    
    
}

extension ExploreViewController : VideoPostDelegate {
    func loadVideo(_ post: VideoPost, _ videoView: UIView) {
        handlePlay(_videoURL: post.videoURL, _videoView: videoView)
    }

    func sendRatingToFirebase(_ post: VideoPost, _ rating: Double) {
        let rate = [self.currentUserID: "\(rating)"]
        self.ref.child("posts").child("\(post.videoPostID)").child("ratings").updateChildValues(rate)
    }
    
    func passTrickTag(_ post: VideoPost) {
        exploreButtonTapped(post.trickType)
    }
    
    func challengeTrickIfAvailable(_ post: VideoPost) {
        challengeButtonTapped(post.trickType)
    }
    
}





