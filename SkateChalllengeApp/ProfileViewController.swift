//
//  ProfileViewController.swift
//  SkateChalllengeApp
//
//  Created by Max Jala on 08/05/2017.
//  Copyright © 2017 Max Jala. All rights reserved.
//

import UIKit
import Firebase
import Cosmos
import AVKit
import AVFoundation

enum ProfileType {
    case myProfile
    case otherProfile
}

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var userPostTableView: UITableView! {
        didSet{
            userPostTableView.delegate = self
            userPostTableView.dataSource = self
            userPostTableView.register(ProfileOverviewViewCell.cellNib, forCellReuseIdentifier: ProfileOverviewViewCell.cellIdentifier)
            userPostTableView.register(VideoPostViewCell.cellNib, forCellReuseIdentifier: VideoPostViewCell.cellIdentifier)
            
            userPostTableView.estimatedRowHeight = 510
            userPostTableView.rowHeight = UITableViewAutomaticDimension
        }
    }
    
    
    var ref: FIRDatabaseReference!
    var currentUser : FIRUser? = FIRAuth.auth()?.currentUser
    var currentUserID : String = ""
    var loggedInID : String = ""
    
    var profileType : ProfileType = .myProfile
    var selectedProfile : User?
    
    var profileImageURL : String? = ""
    var profileScreenName : String? = ""
    var profileDesc : String? = ""
    
    var profileFollowers : [String] = []
    var profileFollowing : [String] = []
    //var profilePosts : [String]? = []
    var numberOfPosts : Int = 0
    
    //var otherUserPosts: [VideoPost] = []
    var chosenProfile : [User] = []
    var videoPosts : [VideoPost] = []
    var profileContent : [[Any]] = []
    var lastPostID = 0
    
//    var postReferences : [String] = []
//    var onlyMyPosts : [VideoPost] = []
    var player : AVPlayer!

    override func viewDidLoad() {
        super.viewDidLoad()
        ref = FIRDatabase.database().reference()
        configuringProfileType(profileType)
        setupProfile()
        //self.videoPosts.removeAll()
        listenToFirebase()

        // Do any additional setup after loading the view.
    }

    func configuringProfileType (_ type : ProfileType) {
        switch type {
        case .myProfile :
            
            configureMyProfile()
        case .otherProfile:
            
            //configureOtherProfile()
            break
            
        }
    }
    
    func configureMyProfile () {
        
        if let id = currentUser?.uid {
            print(id)
            currentUserID = id
        }
        
    }
    
    func configureOtherProfile () {
        
//        editButton.setTitle("Follow", for: .normal)
//        checkFollowing(sender: editButton)
//        editButton.addTarget(self, action: #selector(followButtonTapped), for: .touchUpInside)
        
    }
    
    func setupProfile () {
        
        
//        ref.child("users").child(currentUserID).observeSingleEvent(of: .value, with: { (snapshot) in
//            guard let userDict = snapshot.value as? [String : Any] else {return}
        
//            self.profileScreenName = userDict["screenName"] as? String
//            self.profileImageURL = userDict["imageURL"] as? String
//            self.profileDesc = userDict["desc"] as? String
//            
//            //            self.chosenProfile.removeAll()
//            //
//            //            if self.profileContent.count > 1 {
//            //                self.profileContent.remove(at: 0)
//            //            }
//            
//            self.addUser(id: snapshot.key, userInfo: userDict)
//            //self.profileContent.append(self.chosenProfile)
//            self.profileContent.insert(self.chosenProfile, at: 0)
//            self.userPostTableView.reloadData()
//        })
        ref.child("users").child(currentUserID).observe(.value, with: { (snapshot) in
            guard let userDict = snapshot.value as? [String : Any] else {return}
            
            self.profileScreenName = userDict["screenName"] as? String
            self.profileImageURL = userDict["imageURL"] as? String
            self.profileDesc = userDict["desc"] as? String
            
            if self.currentUserID == self.currentUser?.uid {
                self.navigationItem.title = self.profileScreenName
            }
            
            self.chosenProfile.removeAll()
            
            if self.profileContent.count > 1 {
                self.profileContent.remove(at: 0)
            }
            
            self.addUser(id: snapshot.key, userInfo: userDict)
            self.profileContent.insert(self.chosenProfile, at: 0)
            self.userPostTableView.reloadData()
            
        })
    
        ref.child("users").child(currentUserID).child("followers").observe(.value, with: { (snapshot) in
            if (snapshot.value == nil) { return }
            else {
                
                let noOfFollowers = snapshot.value as? NSDictionary
                guard let followers = noOfFollowers?.allKeys as? [String]
                    else { return }
                
                self.profileFollowers = followers
                //self.numberOfFollowers.text = String (describing: followers.count)
            }
        })
        
        ref.child("users").child(currentUserID).child("following").observe(.value, with: { (snapshot) in
            if (snapshot.value == nil) { return }
            else {
                
                let noOfFollowing = snapshot.value as? NSDictionary
                guard let following = noOfFollowing?.allKeys as? [String]
                    else { return }
                
                self.profileFollowing = following
                //self.numberOfFollowers.text = String (describing: followers.count)
            }
        })
        
        ref.child("users").child(currentUserID).child("posts").observe(.childAdded, with: { (snapshot) in
            if (snapshot.value == nil) { return }
            else {
                
                self.numberOfPosts = Int(snapshot.childrenCount)
                
        
            }
        })
    }
    
    func listenToFirebase(){
        ref.child("posts").observe(.value, with: {(snapshot) in
            print("Value: " , snapshot)
            
            DispatchQueue.main.async {
                self.profileContent.append(self.videoPosts)
                self.userPostTableView.reloadData()
            }
            
        })
        
        ref.child("posts").observe(.childAdded, with:{ (snapshot) in
            
            print("Value: ", snapshot)
            
            guard let info = snapshot.value as? [String: Any] else {return}
            
            
            guard let userID = info["userID"] as? String else {return}
            
            if userID == self.currentUserID {
            
                self.addToVideoFeed(id:snapshot.key, postInfo:info)
                
                self.numberOfPosts += 1
                
            }
            
            self.videoPosts.sort(by:{(vid1, vid2) -> Bool in
                return vid1.videoPostID > vid2.videoPostID
            })
            
            if let lastPost = self.videoPosts.last {
                self.lastPostID = lastPost.videoPostID
            }
            
            //self.videoTableView.reloadData()
            //self.profileContent.append(self.videoPosts)
            
            
        })
        
    }
    
    func addUser(id: Any , userInfo: [String: Any]){
        if
            let screenName = userInfo["screenName"] as? String,
            let userImage = userInfo["imageURL"] as? String,
            let userId = id as? String,
            let userEmail = userInfo["email"] as? String,
            let userDescription = userInfo["desc"] as? String,
            let userStance = userInfo["stance"] as? String {
            
            let newUser = User(anId: userId, anEmail: userEmail, aScreenName: screenName, aDesc: userDescription, anImageURL: userImage, aStance: userStance)
            
            self.chosenProfile.append(newUser)
            //self.profileContent.append(chosenProfile)
            
        }
    }
    
    func addToVideoFeed(id: Any, postInfo: [String: Any]) {
        if let userID = postInfo["userID"] as? String,
            let trickType = postInfo["trickType"] as? String,
            let userProfilePicture = postInfo["profileImageURL"] as? String,
            let timeStamp = postInfo["timestamp"] as? String,
            let postID = id as? String,
            let currentPostId = Int(postID),
            let screenName = postInfo["screenName"] as? String,
            let videoURL = postInfo["postedVideoURL"] as? String,
            let thumbnailURL = postInfo["thumbnailURL"] as? String {
            
            let videoPost = VideoPost(anID: currentPostId, aUserID: userID, aUserScreenName: screenName, aUserProfileImageURL: userProfilePicture, aTrickType: trickType, aVideoURL: videoURL, aThumbnailURL: thumbnailURL)
            
            
            self.videoPosts.append(videoPost)
            
            self.userPostTableView.reloadData()
            
            
        }
    }
    
    
}

extension ProfileViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
       return profileContent.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let profileElement = profileContent[section]
        
        return profileElement.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let profileObjectType = profileContent[indexPath.section]
        let currentProfileObject = profileObjectType[indexPath.row]
        
        if let profileObject = currentProfileObject as? User {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ProfileOverviewViewCell.cellIdentifier) as? ProfileOverviewViewCell else {return UITableViewCell() }
            cell.nameLabel.text = profileObject.screenName
            cell.bioTextView.text = profileObject.desc
            cell.noOfPostsLabel.text = "\(self.numberOfPosts)"
            cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: profileObject.imageURL)
            cell.stanceLabel.text = profileObject.stance
            
            cell.noOfFollowingLabel.text = "\(self.profileFollowing.count)"
            cell.noOfFollowersLabel.text = "\(self.profileFollowers.count)"
            handleEditOrFollowButton(button: cell.editProfileButton)
            return cell
        }
        
            guard let cell = tableView.dequeueReusableCell(withIdentifier: VideoPostViewCell.cellIdentifier) as? VideoPostViewCell else { return UITableViewCell() }
        
            let currentVideo = currentProfileObject as! VideoPost
            
            //let currentVideo = videoPosts[indexPath.row]
            let profilePic = currentVideo.userProfileImageURL
            let trickType = currentVideo.trickType
            let screenName = currentVideo.userScreenName
            let thumbnailURL = currentVideo.thumbnailURL
            
            cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: profilePic)
            cell.previewImageView.loadImageUsingCacheWithUrlString(urlString: thumbnailURL)
            cell.hashtagLabel.text = trickType
            cell.userNameLabel.text = screenName
            
            //Assign Star Ratings
            observeUserRating(_id: currentVideo.videoPostID, _starRating: cell.userRatingView)
            observeAllRatings(_id: currentVideo.videoPostID, _starRatings: cell.publicRatingView)
            
            cell.delegate = self
            cell.videoPost = currentVideo
        
        
        return cell
        
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
    
    func observeAllRatings(_id: Int, _starRatings: CosmosView) {
        ref.child("posts").child("\(_id)").child("ratings").observe(.value, with: {(snapshot) in
            print("Value: " , snapshot)
            
            //guard let existingRating = snapshot.value as? String else {return}
            var averageRating = 0.0
            
            guard let ratingDict = snapshot.value as? NSDictionary else {return}
            let ratingCount = snapshot.childrenCount
            
            guard let ratingValues = ratingDict.allValues as? [String] else {return}
            
            for each in ratingValues {
                averageRating += Double(each)!
            }
            
            _starRatings.rating = averageRating/Double(ratingCount)
        })
    }
    
    func handleEditOrFollowButton(button: UIButton) {
        //let loggedInID = curre
        
        if currentUser?.uid == currentUserID {
            button.setTitle("Edit Profile", for: .normal)
            button.addTarget(self, action: #selector(editProfileBtnTapped), for: .touchUpInside)
        } else {
            handleFollowButtonFunction(button: button)
        }
    }
    
    func editProfileBtnTapped() {
        //Segue to new EditProfileVC
    }
    
    func handleFollowButtonFunction(button: UIButton) {
        ref.child("users").child((currentUser?.uid)!).child("following").observe(.childAdded, with: { (snapshot) in
            
            //For observing Value
//            if let following = snapshot.value as? NSDictionary {
//                guard let fllwing = following.allKeys as? [String] else {return}
//                
//                for any in fllwing {
//                    if any == self.currentUserID {
//                        button.setTitle("Following", for: .normal)
//                        button.addTarget(self, action: #selector(self.unfollow), for: .touchUpInside)
//                        return
//                    }
//                }
//                
//                button.setTitle("Follow", for: .normal)
//                button.addTarget(self, action: #selector(self.follow), for: .touchUpInside)
//                return
//            }
            
         //For observing childAdded
            if let following = snapshot.key as? String {

                    if following == self.currentUserID {
                        button.setTitle("Following", for: .normal)
                        button.addTarget(self, action: #selector(self.unfollow), for: .touchUpInside)
                        return
                    }

                button.setTitle("Follow", for: .normal)
                button.addTarget(self, action: #selector(self.follow), for: .touchUpInside)
                return
            }
            
            
        })
        button.setTitle("Follow", for: .normal)
        button.addTarget(self, action: #selector(follow), for: .touchUpInside)
    }

    
    func follow(sender: UIButton) {
        let following = [self.currentUserID: "following"]
        self.ref.child("users").child((currentUser?.uid)!).child("following").updateChildValues(following)
        
        let follower = [(currentUser?.uid)!: "follower"]
        self.ref.child("users").child(currentUserID).child("followers").updateChildValues(follower)

        sender.setTitle("Unfollow", for: .normal)
        
    }
    
    func unfollow(sender: UIButton) {
        //let following = [self.currentUserID: "following"]
        self.ref.child("users").child((currentUser?.uid)!).child("following").child(currentUserID).removeValue()
        
        //let follower = [currentUserID: "follower"]
        self.ref.child("users").child(currentUserID).child("followers").child((currentUser?.uid)!).removeValue()
        
        sender.setTitle("Follow", for: .normal)
        //self.profileFollowers.removeLast()
    }
    
    
    
}

extension ProfileViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        player = nil
        
    }
    
    
}

extension ProfileViewController : VideoPostDelegate {
    func loadVideo(_ post: VideoPost, _ videoView: UIView) {
        handlePlay(_videoURL: post.videoURL, _videoView: videoView)
    }
    
    func sendRatingToFirebase(_ post: VideoPost, _ rating: Double) {
        let rate = [self.currentUserID: "\(rating)"]
        self.ref.child("posts").child("\(post.videoPostID)").child("ratings").updateChildValues(rate)
    }
    
    func passTrickTag(_ post: VideoPost) {
        
    }
    
    func challengeTrickIfAvailable(_ post: VideoPost) {
        
    }

    
}



