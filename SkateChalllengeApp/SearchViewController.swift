//
//  SearchViewController.swift
//  SkateChalllengeApp
//
//  Created by Max Jala on 08/05/2017.
//  Copyright © 2017 Max Jala. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import AVKit
import AVFoundation
import Cosmos

class SearchViewController: UIViewController, UISearchBarDelegate {
    
    @IBOutlet weak var searchTableView: UITableView! {
        didSet {
            searchTableView.delegate = self
            searchTableView.dataSource = self
            searchTableView.register(VideoPostViewCell.cellNib, forCellReuseIdentifier: VideoPostViewCell.cellIdentifier)
            searchTableView.register(UserTableViewCell.cellNib, forCellReuseIdentifier: UserTableViewCell.cellIdentifier)
            searchTableView.register(TrickTableViewCell.cellNib, forCellReuseIdentifier: TrickTableViewCell.cellIdentifier)
            
            searchTableView.estimatedRowHeight = 510.0
            searchTableView.rowHeight = UITableViewAutomaticDimension
        }
    }
    
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    @IBOutlet weak var searchBar: UISearchBar! {
        didSet{
            searchBar.delegate = self
        }
    }
    
    var videoPosts : [VideoPost] = []
    var users : [User] = []
    var filteredUsers : [User] = []
    var filterVideo : [VideoPost] = []
    var activeArray : [Any] = []
    
    var searchActive: Bool = false
    
    var player : AVPlayer!
    var ref: FIRDatabaseReference!
    var currentUser : FIRUser? = FIRAuth.auth()?.currentUser
    
    var currentUserID : String = ""
    var worstRating : Double = 0.0
    var receivedSearch : String?
    
    
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        configureSearch()
    }
    
    func configureSearch() {
        if let tag = UserDefaults.getTag() {
            DispatchQueue.main.async {
                self.segmentedControl.selectedSegmentIndex = 1
                self.activeArray = self.videoPosts
                self.searchBar.text = tag
                self.searchActive = true
                self.searchTag(self.searchBar.text)
                self.searchTableView.reloadData()
            }
        }
    }
    
    func useCorrectArray() {
        DispatchQueue.main.async {
            if self.segmentedControl.selectedSegmentIndex == 0 {
                self.activeArray = self.users
            } else {
                self.activeArray = self.videoPosts
                if self.searchActive {
                    self.searchTag(self.searchBar.text)
                }
            }
            self.searchTableView.reloadData()
        }
    }
    
    
    
    func listenToFirebase(){
        ref.child("users").observe(.childAdded, with: { (snapshot) in
            print("Value : " , snapshot)
            
            guard let info = snapshot.value as? [String : Any] else {return}
            self.addUser(id: snapshot.key, userInfo: info)
            
            self.users.sort(by: { (user1, user2) -> Bool in
                return user1.screenName  < user2.screenName
            })

            self.useCorrectArray()
            
        })
        
        ref.child("posts").observe(.childAdded, with:{ (snapshot) in
            
            print("Value: ", snapshot)
            
            guard let info = snapshot.value as? NSDictionary else {return}
            
            self.addToVideoFeed(id:snapshot.key, postInfo:info)
            
            
            DispatchQueue.main.async {
                self.videoPosts.sort(by:{(vid1, vid2) -> Bool in
                    print("\(vid1.rating) > \(vid2.rating)")
                    return vid1.rating > vid2.rating
                })
            }
            
            
            if let lastPost = self.videoPosts.last {
                self.worstRating = lastPost.rating
            }
            self.useCorrectArray()
            
        })
    }
    
    func addUser(id: Any , userInfo: [String: Any]){
        if let screenName = userInfo["screenName"] as? String,
            let userImage = userInfo["imageURL"] as? String,
            let userId = id as? String,
            let userEmail = userInfo["email"] as? String,
            let userDescription = userInfo["desc"] as? String,
            let userStance = userInfo["stance"] as? String {
            
            let newUser = User(anId: userId, anEmail: userEmail, aScreenName: screenName, aDesc: userDescription, anImageURL: userImage, aStance: userStance)
            
            self.users.append(newUser)
            
        }
    }

    
    func addToVideoFeed(id: Any, postInfo: NSDictionary) {
        if let userID = postInfo["userID"] as? String,
            let trickType = postInfo["trickType"] as? String,
            let userProfilePicture = postInfo["profileImageURL"] as? String,
            let postID = id as? String,
            let currentPostId = Int(postID),
            let screenName = postInfo["screenName"] as? String,
            let videoURL = postInfo["postedVideoURL"] as? String,
            let thumbnailURL = postInfo["thumbnailURL"] as? String {
            
            let videoPost = VideoPost(anID: currentPostId, aUserID: userID, aUserScreenName: screenName, aUserProfileImageURL: userProfilePicture, aTrickType: trickType, aVideoURL: videoURL, aThumbnailURL: thumbnailURL)
            
            observeVideoRatings(postID: postID, videoPost: videoPost)
            
            self.videoPosts.append(videoPost)
            
            
        }
    }
    
    func observeVideoRatings(postID: String, videoPost: VideoPost) {
        ref.child("posts").child(postID).child("ratings").observe(.value, with: {(snapshot) in
            print("Value: " , snapshot)
            
            var rating = 0.0
            
            guard let ratingDict = snapshot.value as? NSDictionary else {return}
            let ratingCount = snapshot.childrenCount
            
            guard let ratingValues = ratingDict.allValues as? [String] else {return}
            
            for each in ratingValues {
                rating += Double(each)!
            }

            videoPost.rating = rating/Double(ratingCount)
        })
    }
    
    @IBAction func segmentIndexChanged(_ sender: UISegmentedControl) {
        
        switch sender.selectedSegmentIndex {
        case 0:
            activeArray = users
            self.searchTableView.reloadData()
            break
            
        case 1:
            activeArray = videoPosts
            self.searchTableView.reloadData()
            break
        default:
            break
        }
    }
    
    //MARK search Bar
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true;
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if segmentedControl.selectedSegmentIndex == 0 {
        
            if searchText.characters.count == 0 {
                
                activeArray = users
                self.searchTableView.reloadData()
                return
            }
            
            activeArray = users.filter({ (user) -> Bool in
                let nameString: NSString = user.screenName as NSString
                let range = nameString.range(of: searchText, options: .caseInsensitive)
                return range.location != NSNotFound
            })
            
        } else {
            searchTag(searchText)
        }
        self.searchTableView.reloadData()
    }

    func searchTag(_ str : String?) {
        guard let tag = str
            else  { return }
        
        if tag.characters.count == 0 {
            
            activeArray = videoPosts
            self.searchTableView.reloadData()
            return
        }
        
        self.videoPosts.sort(by:{(vid1, vid2) -> Bool in
            print("\(vid1.rating) > \(vid2.rating)")
            return vid1.rating > vid2.rating
        })
        
        activeArray = videoPosts.filter({ (post) -> Bool in
            let nameString: NSString = post.trickType as NSString
            let range = nameString.range(of: tag, options: .caseInsensitive)
            return range.location != NSNotFound
        })

    }
}



extension SearchViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activeArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let currentProfileObject = activeArray[indexPath.row]
        
        if let profileObject = currentProfileObject as? User {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: UserTableViewCell.cellIdentifier) as? UserTableViewCell else {return UITableViewCell()}
            cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: profileObject.imageURL)
            cell.userNameLabel.text = profileObject.screenName
            
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
        //cell.publicRatingView.rating = currentVideo.rating
        
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
    

    
    
}

extension SearchViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if segmentedControl.selectedSegmentIndex == 0 {
        
            if let chosenUser = users[indexPath.row] as? User {
               let controller = storyboard?.instantiateViewController(withIdentifier: "ProfileViewController") as? ProfileViewController
                controller?.currentUserID = chosenUser.id
                controller?.selectedProfile = chosenUser
                controller?.profileType = .otherProfile
                
                navigationController?.pushViewController(controller!, animated: true)
            }
        }
//        } else {
//            //tableView.deleteRows(at: [indexPath], with: .fade)
//            guard let cell = tableView.dequeueReusableCell(withIdentifier: "TrickTableViewCell", for: indexPath) as? TrickTableViewCell else {return}
//            cell.nameLabel.text = videoPosts[indexPath.row].userScreenName
//            tableView.deleteRows(at: [indexPath], with: .fade)
//            tableView.insertRows(at: [indexPath], with: .fade)
//            tableView.reloadData()
//        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        player = nil
        
    }
}

extension SearchViewController : VideoPostDelegate {
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


