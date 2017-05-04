//
//  ViewController.swift
//  SkateChalllengeApp
//
//  Created by Max Jala on 02/05/2017.
//  Copyright © 2017 Max Jala. All rights reserved.
//

import UIKit
import MobileCoreServices
import AVKit
import AVFoundation
import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth

class UploadViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var thumbnailImageView: UIImageView!
    
    @IBOutlet weak var videoPlayerView: UIView!
    
    @IBOutlet weak var playButton: UIButton! {
        didSet {
            playButton.isHidden = true
            playButton.setImage((UIImage(named: "play")), for: .normal)
            playButton.addTarget(self, action: #selector(handlePlay), for: .touchUpInside)
            
        }
    }
    
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var challengeLabel: UILabel!
    
    var ref: FIRDatabaseReference!
    var currentUser : FIRUser? = FIRAuth.auth()?.currentUser
    var currentUserID : String = ""
    var currentUserEmail : String = ""
    var profileScreenName : String = ""
    var profileImageURL : String = ""
    
    var videoURL : String?
    var thumbnailURL : String?
    var chosenChallenge : String?
    var player : AVPlayer!
    
    
    let imagePicker: UIImagePickerController! = UIImagePickerController()
    let saveFileName = "/test.mp4"
    
    // MARK: ViewController methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setCurrentUser()
        
        challengeLabel.text = chosenChallenge
        
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
        
        self.ref.child("users").child(currentUserID).observe(.value, with: { (userSS) in
            print("Value : " , userSS)
            
            let dictionary = userSS.value as? [String: Any]
            
            self.profileScreenName = (dictionary?["screenName"])! as! String
            self.profileImageURL = (dictionary?["imageURL"])! as! String
            
        })
        
    }
    
    // MARK: Button handlers
    // Record a video
    @IBAction func recordVideo(_ sender: AnyObject) {
        if (UIImagePickerController.isSourceTypeAvailable(.camera)) {
            if UIImagePickerController.availableCaptureModes(for: .rear) != nil {
                postPrivatelyFirst()
                
                imagePicker.sourceType = .camera
                imagePicker.mediaTypes = [kUTTypeMovie as String]
                //imagePicker.showsCameraControls = false
                //imagePicker.cameraOverlayView =

                imagePicker.videoMaximumDuration = 30
                imagePicker.allowsEditing = false
                imagePicker.delegate = self
                
                present(imagePicker, animated: true, completion: {})
            } else {
                postAlert("Rear camera doesn't exist", message: "Application cannot access the camera.")
            }
        } else {
            postAlert("Camera inaccessable", message: "Application cannot access the camera.")
        }
    }
    
    func postPrivatelyFirst() {
        let currentDate = NSDate()
        let dateFormatter:DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd HH:mm"
        let uniqueTimeID = Int(currentDate.timeIntervalSince1970)
        let timeCreated = dateFormatter.string(from: currentDate as Date)
        let trickTag = challengeLabel.text?.lowercased()
        let firebaseKey = trickTag?.replacingOccurrences(of: "#", with: "")
        
            let post : [String : Any] = ["userID": self.currentUserID, "screenName": self.profileScreenName,  "profileImageURL": self.profileImageURL, "timestamp": timeCreated]
            
            let personalReference : [String : Any] = ["userID" : currentUserID]

            self.ref.child("users").child(currentUserID).child("posts").child(firebaseKey!).child("\(uniqueTimeID)").updateChildValues(personalReference)
            
    }
    
    // Play the video recorded for the app
    @IBAction func playVideo(_ sender: AnyObject) {
        print("Play a video")
        
        // Find the video in the app's document directory
        let paths = NSSearchPathForDirectoriesInDomains(
            FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentsDirectory: URL = URL(fileURLWithPath: paths[0])
        let dataPath = documentsDirectory.appendingPathComponent(saveFileName)
        print(dataPath.absoluteString)
        let videoAsset = (AVAsset(url: dataPath))
        let playerItem = AVPlayerItem(asset: videoAsset)
        
        // Play the video
        let player = AVPlayer(playerItem: playerItem)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        
        self.present(playerViewController, animated: true) {
            playerViewController.player!.play()
        }
    }
    
    
    @IBAction func backButtonTapped(_ sender: Any) {
        
        if self.videoURL != nil {
            let alertController = UIAlertController(title: "Are you sure?", message: "You can only try this challenge again in 2 hours time.", preferredStyle: .alert)
            let goBackAction = UIAlertAction(title: "Flight", style: .destructive, handler: { (alert:UIAlertAction) in
                self.dismiss(animated: true, completion: nil)
            })
            alertController.addAction(goBackAction)
            let cancelAction = UIAlertAction(title: "Fight", style: .destructive, handler: nil)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
        } else {
            dismiss(animated: true, completion: nil)
        }
        
    }
    
    @IBAction func postChallengeBtn(_ sender: Any) {
        
        let currentDate = NSDate()
        let dateFormatter:DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd HH:mm"
        let uniqueTimeID = Int(currentDate.timeIntervalSince1970)
        let timeCreated = dateFormatter.string(from: currentDate as Date)
        let trickTag = challengeLabel.text?.lowercased()
        let firebaseKey = trickTag?.replacingOccurrences(of: "#", with: "")
        
        
        if self.videoURL != nil {
            // write to firebase
            let post : [String : Any] = ["userID": self.currentUserID, "screenName": self.profileScreenName,"profileImageURL": self.profileImageURL,"trickType": chosenChallenge, "postedVideoURL" : self.videoURL, "thumbnailURL": self.thumbnailURL, "timestamp": timeCreated]
            
            let personalReference : [String : Any] = ["userID" : currentUserID, "postID" : uniqueTimeID]
            
            //self.ref.child("posts").child(firebaseKey!).child("\(uniqueTimeID)").updateChildValues(post)
            self.ref.child("posts").child("\(uniqueTimeID)").updateChildValues(post)
            
            self.ref.child("users").child(currentUserID).child("posts").child(firebaseKey!).removeValue()
            
            self.ref.child("users").child(currentUserID).child("posts").child(firebaseKey!).child("\(uniqueTimeID)").updateChildValues(personalReference)
            
            let controller = storyboard?.instantiateViewController(withIdentifier: "TabBarController")
            present(controller!, animated: true, completion: nil)
        }
    }
    
    
    // MARK: UIImagePickerControllerDelegate delegate methods
    // Finished recording a video
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        print("Got a video")
        
        if let pickedVideo = info[UIImagePickerControllerMediaURL] as? URL {
            
            // Create Thumbnail Image for Video and Upload to Firebase
            if let thumbnail = thumbnailForVideoFileURL(fileURL: pickedVideo) {
                thumbnailImageView.image = thumbnail
                uploadImage(thumbnail)
            }
            
            // Save video to the main photo album
            let selectorToCall = #selector(UploadViewController.videoWasSavedSuccessfully(_:didFinishSavingWithError:context:))
            UISaveVideoAtPathToSavedPhotosAlbum(pickedVideo.relativePath, self, selectorToCall, nil)
            
            // Save the video to the app directory so we can play it later
            let videoData = try? Data(contentsOf: pickedVideo)
            let paths = NSSearchPathForDirectoriesInDomains(
                FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
            let documentsDirectory: URL = URL(fileURLWithPath: paths[0])
            let dataPath = documentsDirectory.appendingPathComponent(saveFileName)
            try! videoData?.write(to: dataPath, options: [])
            print("Saved to " + dataPath.absoluteString)
            
            // Upload to Firebase Storage
            let currentDate = NSDate()
            let uniqueTimeID = Int(currentDate.timeIntervalSince1970)
            let fileName = "\(uniqueTimeID).mov"
            let storageRef = FIRStorage.storage().reference()
            
            let uploadTask = storageRef.child(fileName).putFile(pickedVideo, metadata: nil, completion: { (metadata, error) in
                
                if error != nil {
                    print("Error when uploading to FIRStorage : \(error?.localizedDescription)")
                    return
                }
                
                self.videoURL = metadata?.downloadURL()?.absoluteString
                
                print("Video URL : " , self.videoURL)
                
            })
            
            uploadTask.observe(.progress, handler: { (snapshot) in
                print("Progress : " , snapshot.progress?.fractionCompleted)
                let percentage = Int((snapshot.progress?.fractionCompleted)! * 100)
                self.progressLabel.text = "\(percentage)%"
                
                if self.progressLabel.text == "100%" {
                    self.progressLabel.text = "Upload Completed!"
                    
                    self.playButton.isHidden = false
                    
                    
                }
                
                
            })
            
        }
        
        
        
        imagePicker.dismiss(animated: true, completion: {
            // Anything you want to happen when the user saves an video
        })
    }
    
    func uploadImage(_ image: UIImage) {
        
        let ref = FIRStorage.storage().reference()
        guard let imageData = UIImageJPEGRepresentation(image, 0.1) else {return}
        let metaData = FIRStorageMetadata()
        metaData.contentType = "image/jpeg"
        ref.child("\(currentUser?.email)-\(Date()).jpeg").put(imageData, metadata: metaData) { (meta, error) in
            
            if let downloadPath = meta?.downloadURL()?.absoluteString {
                

                self.thumbnailURL = downloadPath
                
            }
            
        }
        
        
    }
    
    func thumbnailForVideoFileURL(fileURL: URL) -> UIImage? {
        let asset = AVAsset(url: fileURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        do {
            let thumbnailImage = try imageGenerator.copyCGImage(at: CMTimeMake(1, 60), actualTime: nil)
            return UIImage(cgImage: thumbnailImage)
            
        } catch let err {
            print(err)
        }
        
        return nil
        
    }
    
    // Called when the user selects cancel
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("User canceled image")
        dismiss(animated: true, completion: {
            // Anything you want to happen when the user selects cancel
        })
    }
    
    // Any tasks you want to perform after recording a video
    func videoWasSavedSuccessfully(_ video: String, didFinishSavingWithError error: NSError!, context: UnsafeMutableRawPointer){
        if let theError = error {
            print("An error happened while saving the video = \(theError)")
        } else {
            
            DispatchQueue.main.async(execute: { () -> Void in
                // What you want to happen
            })
        }
    }
    
    func handlePlay() {
        if let url = URL(string: self.videoURL!) {
            if player == nil {
                player = AVPlayer(url: url)
                playButton.setImage((UIImage(named: "play")), for: .normal)
            }
        
            if playButton.titleLabel?.text == "Play" {
                //Play Function
                let playerLayer = AVPlayerLayer(player: player)
                playerLayer.frame = videoPlayerView.bounds
//                playerLayer.frame = CGRect(x: view.frame.width/2, y: view.frame.height/2, width: view.frame.width/2, height: <#T##CGFloat#>)
                videoPlayerView.layer.addSublayer(playerLayer)
                player.play()
                print("Attempting to play Video")
                
                //playButton.isHidden = true
                playButton.setTitle(" ", for: .normal)
                playButton.imageView?.image = nil
            } else {
                //Pause Function
                player.pause()
                playButton.setTitle("Play", for: .normal)
            playButton.setImage((UIImage(named: "play")), for: .normal)
                
            }
            
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
            NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying(note:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
            
        }
        
        
        
        
    }
    
    func playerDidFinishPlaying(note: NSNotification) {
        print("Video Finished")
        player = nil
        playButton.setTitle("Play", for: .normal)
        playButton.setImage((UIImage(named: "play")), for: .normal)
    }
    
    
    // MARK: Utility methods for app
    // Utility method to display an alert to the user.
    func postAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message,
                                      preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

