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
import AVKit
import AVFoundation
import SwiftyStarRatingView

class HomeViewController: UIViewController {
    
    @IBOutlet weak var videoTableView: UITableView! {
        didSet{
            videoTableView.delegate = self
            videoTableView.dataSource = self
            videoTableView.register(VideoPostViewCell.cellNib, forCellReuseIdentifier: VideoPostViewCell.cellIdentifier)
        }
    }
    

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
        
        listenToFirebase()
        
        
        
           
    }
    
    func listenToFirebase(){
        ref.child("posts").observe(.value, with: {(snapshot) in
            print("Value: " , snapshot)
            
        })
        
        ref.child("posts").observe(.childAdded, with:{ (snapshot) in
            
            print("Value: ", snapshot)
            
            guard let info = snapshot.value as? NSDictionary else {return}
            
            self.addToVideoFeed(id:snapshot.key, postInfo:info)
            
            self.videoFeed.sort(by:{(vid1, vid2) -> Bool in
                return vid1.videoPostID > vid2.videoPostID
            })
            
            if let lastPost = self.videoFeed.last {
                self.lastPostID = lastPost.videoPostID
            }
            
            self.videoTableView.reloadData()
            
        })
    }
    
    func addToVideoFeed(id: Any, postInfo: NSDictionary) {
        if let userID = postInfo["userID"] as? String,
            let trickType = postInfo["trickType"] as? String,
            let userProfilePicture = postInfo["profileImageURL"] as? String,
            let timeStamp = postInfo["timestamp"] as? String,
            let postID = id as? String,
            let currentPostId = Int(postID),
            let screenName = postInfo["screenName"] as? String,
            let videoURL = postInfo["postedVideoURL"] as? String,
            let thumbnailURL = postInfo["thumbnailURL"] as? String {
           
            let videoPost = VideoPost(anID: currentPostId, aUserID: userID, aUserScreenName: screenName, aUserProfileImageURL: userProfilePicture, aTrickType: trickType, aVideoURL: videoURL, aThumbnailURL: thumbnailURL, aTimeStamp: timeStamp)

            self.videoFeed.append(videoPost)
            
            
        }
    }

}

extension HomeViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videoFeed.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 510
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: VideoPostViewCell.cellIdentifier) as? VideoPostViewCell else { return UITableViewCell() }
        let currentVideo = videoFeed[indexPath.row]
        //let videoURL = currentVideo.videoURL
        //let videoURL = URL(string: videoURLString)
        let profilePic = currentVideo.userProfileImageURL
        let trickType = currentVideo.trickType
        let screenName = currentVideo.userScreenName
        let thumbnailURL = currentVideo.thumbnailURL
        
        cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: profilePic)
        //cell.previewImageView.image = thumbnailForVideoFileURL(fileURL: videoURL!)
        cell.previewImageView.loadImageUsingCacheWithUrlString(urlString: thumbnailURL)
        cell.hashtagLabel.text = trickType
        cell.userNameLabel.text = screenName
        
        cell.delegate = self
        cell.videoPost = currentVideo
        //cell.videoView = cell.
        
        
        return cell
        
    }
    
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
    
    func sendToFireBase(_videoPost: VideoPost, _starView: SwiftyStarRatingView) {
        
        let rate = [currentUserID: _starView.value]
        
        
        ref.child("posts").child("\(_videoPost.videoPostID)").child("ratings").updateChildValues(rate)
    }
    
}

extension HomeViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
}

extension HomeViewController : VideoPostDelegate {
    func loadVideo(_ post: VideoPost, _ videoView: UIView) {
        handlePlay(_videoURL: post.videoURL, _videoView: videoView)
    }
    
    func sendStarRating(_ post: VideoPost, _ starView: SwiftyStarRatingView) {
        sendToFireBase(_videoPost: post, _starView: starView)
    }
}





