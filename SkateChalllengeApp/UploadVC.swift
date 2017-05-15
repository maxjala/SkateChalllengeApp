//
//  UploadVC.swift
//  SkateChalllengeApp
//
//  Created by Max Jala on 04/05/2017.
//  Copyright © 2017 Max Jala. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth

class UploadVC: UIViewController, AVCaptureFileOutputRecordingDelegate  {
    
    @IBOutlet weak var recordButton: UIButton! {
        didSet{
            recordButton.isHidden = true
            recordButton.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var cameraFrameView1: UIView!
    
    @IBOutlet weak var cameraFrameView2: UIView!
    
    @IBOutlet weak var previewImageView: UIImageView!
    
    @IBOutlet weak var toggleCameraButton: UIButton! {
        didSet{
            toggleCameraButton.addTarget(self, action: #selector(toggleCamButtonTapped), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var timerLabel: UILabel! {
        didSet{
            timerLabel.isHidden = true
        }
    }
    
    
    
    @IBOutlet weak var playButton: UIButton! {
        didSet{
            playButton.addTarget(self, action: #selector(playVideo), for: .touchUpInside)
            playButton.isHidden = true
        }
    }
    
    @IBOutlet weak var challengeLabel: UILabel! {
        didSet{
            challengeLabel.text = chosenChallenge
        }
    }
    
    @IBOutlet weak var backButton: UIButton! {
        didSet{
            backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var postButton: UIButton! {
        didSet{
            postButton.addTarget(self, action: #selector(postButtonTapped), for: .touchUpInside)
            //postButton.isEnabled = false
        }
    }

    
    var ref: FIRDatabaseReference!
    var currentUser : FIRUser? = FIRAuth.auth()?.currentUser
    var currentUserID : String = ""
    var currentUserEmail : String = ""
    var profileScreenName : String = ""
    var profileImageURL : String = ""
    var chosenChallenge : String = ""
    
    var videoCaptureDevice : AVCaptureDevice? // check capture device availability
    var audioCaptureDevice : AVCaptureDevice?
    let captureSession = AVCaptureSession() // to create capture session
    
    var timer = Timer()
    var seconds = 30 // timer for recorded videos
    
    var previewLayer : AVCaptureVideoPreviewLayer? // to add video inside container
    var playerLayer : AVPlayerLayer?
    
    let videoFileOutput = AVCaptureMovieFileOutput()
    let audioFileOutput = AVCaptureAudioDataOutput()
    var filePath : URL?
    var fileName : String?
    
    var thumbnailURL : String = ""
    var videoURL : String = ""
    
    //trying out AssetWriter
    var assetWriter : AVAssetWriter?

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setCurrentUser()
    }
    
    override func viewWillLayoutSubviews() {
        let orientation: UIDeviceOrientation = UIDevice.current.orientation
        print(orientation)
        
        switch (orientation) {
        case .portrait:
            previewLayer?.connection.videoOrientation = .portrait
            previewLayer?.frame = view.bounds
        case .landscapeRight:
            previewLayer?.connection.videoOrientation = .landscapeLeft
            previewLayer?.frame = view.bounds
        case .landscapeLeft:
            previewLayer?.connection.videoOrientation = .landscapeRight
            previewLayer?.frame = view.bounds
        default:
            previewLayer?.connection.videoOrientation = .portrait
            previewLayer?.frame = view.bounds
        }
        
    }
    
    func setCurrentUser() {
        ref = FIRDatabase.database().reference()
        
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
    
    func toggleCamButtonTapped() {
        captureSession.sessionPreset = AVCaptureSessionPresetMedium
        fileName = createFileName()
        filePath = savePath()
        setUpCamera()
        recordButton.isHidden = false
        cameraFrameView1.isHidden = false
        cameraFrameView2.isHidden = false
        timerLabel.isHidden = false
        view.bringSubview(toFront: cameraFrameView1)
        view.bringSubview(toFront: cameraFrameView2)
        view.bringSubview(toFront: backButton)
        view.bringSubview(toFront: timerLabel)
        view.bringSubview(toFront: recordButton)
        toggleCameraButton.isEnabled = false
    }
    
    func createFileName() -> String {
        let currentDate = NSDate()
        let uniqueTimeID = Int(currentDate.timeIntervalSince1970)
        return "\(uniqueTimeID).mp4"
    }
    
    func savePath() -> URL? {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent(fileName!)
    }
    
    func setUpCamera() {
        if let videoCaptureDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .back),
            let audioCaptureDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInMicrophone, mediaType: AVMediaTypeAudio, position: .unspecified) {
            beginSession(_audioCaptureDevice: audioCaptureDevice, _videoCaptureDevice: videoCaptureDevice)
        }
    }
    
    func beginSession(_audioCaptureDevice: AVCaptureDevice, _videoCaptureDevice: AVCaptureDevice) {
        configureDevice()
        let err : NSError? = nil
        do{
            try captureSession.addInput(AVCaptureDeviceInput(device: _videoCaptureDevice))
            try captureSession.addInput(AVCaptureDeviceInput(device: _audioCaptureDevice))
        }catch{
            print("error")
        }
        if err != nil {
            print("error: \(String(describing: err?.localizedDescription))")
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.frame = view.bounds
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        view.layer.addSublayer(previewLayer!)
        videoFileOutput.maxRecordedDuration = CMTimeMakeWithSeconds(30, 30)
        captureSession.startRunning()
    }
    
    func configureDevice() {
        if let videoDevice = videoCaptureDevice,
            let audioDevice = audioCaptureDevice {
            do{
                try videoDevice.lockForConfiguration()
                try audioDevice.lockForConfiguration()
            }catch{
                print("error")
            }
        }
    }
    
    func recordButtonTapped() {
        
        if !videoFileOutput.isRecording {
        
            captureSession.addOutput(videoFileOutput)
            
            let recordingDelegate:AVCaptureFileOutputRecordingDelegate? = self
            videoFileOutput.recordsVideoOrientationAndMirroringChangesAsMetadataTrack(for: previewLayer?.connection)
            videoFileOutput.startRecording(toOutputFileURL: filePath, recordingDelegate: recordingDelegate)

            backButton.isHidden = true
            postPrivatelyFirst()
            
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(counter), userInfo: nil, repeats: true)

        } else {
            
            videoFileOutput.stopRecording()
            captureSession.removeOutput(videoFileOutput)
            captureSession.stopRunning()

        }
    }
    
    func counter() {
        seconds -= 1
        timerLabel.text = "\(seconds)"
    }
    
    func postPrivatelyFirst() {
        let currentDate = NSDate()
        let dateFormatter:DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd HH:mm"
        let uniqueTimeID = Int(currentDate.timeIntervalSince1970)
        let trickTag = challengeLabel.text?.lowercased()
        let firebaseKey = trickTag?.replacingOccurrences(of: "#", with: "")
        
        let personalReference : [String : Any] = ["userID" : currentUserID]
        
        self.ref.child("users").child(currentUserID).child("posts").child(firebaseKey!).child("\(uniqueTimeID)").updateChildValues(personalReference)
        
    }
    
    func cropVideo( _ outputFileUrl: URL, callback: @escaping ( _ newUrl: URL ) -> () ) {
        // Get input clip
        let videoAsset: AVAsset = AVAsset( url: outputFileUrl )
        let clipVideoTrack = videoAsset.tracks( withMediaType: AVMediaTypeVideo ).first! as AVAssetTrack
        
        // Make video to square
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize( width: clipVideoTrack.naturalSize.height, height: clipVideoTrack.naturalSize.height )
        videoComposition.frameDuration = CMTimeMake( 1, 30)
        
        // Rotate to portrait
        let transformer = AVMutableVideoCompositionLayerInstruction( assetTrack: clipVideoTrack )
        let transform1 = CGAffineTransform( translationX: clipVideoTrack.naturalSize.height, y: -( clipVideoTrack.naturalSize.width - clipVideoTrack.naturalSize.height ) / 2 )
        let transform2 = transform1.rotated(by: CGFloat( M_PI_2 ) )
        transformer.setTransform( transform2, at: kCMTimeZero)
        
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds( 60, 30) )
        
        instruction.layerInstructions = [transformer]
        videoComposition.instructions = [instruction]
        
        let croppedOutputFileURL: URL = URL(fileURLWithPath: getOutputPath(createFileName()))
        
        let exporter = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPresetHighestQuality)!
        exporter.videoComposition = videoComposition
        exporter.outputURL = croppedOutputFileURL
        exporter.outputFileType = AVFileTypeQuickTimeMovie
        
        exporter.exportAsynchronously( completionHandler: { () -> Void in
            DispatchQueue.main.async(execute: {
                callback( croppedOutputFileURL )
            })
        })
    }
    
    func getOutputPath( _ name: String ) -> String {
        let documentPath = NSSearchPathForDirectoriesInDomains(      .documentDirectory, .userDomainMask, true )[ 0 ] as NSString
        let outputPath = "\(documentPath)/\(name)"
        return outputPath
    }
    
    func presentAVPlayerLayer(){
        previewLayer?.removeFromSuperlayer()
        playButton.isHidden = false
        recordButton.isHidden = true
        timerLabel.isHidden = true
        toggleCameraButton.isHidden = true
        backButton.isHidden = false
        view.bringSubview(toFront: challengeLabel)
        view.bringSubview(toFront: backButton)
        view.bringSubview(toFront: postButton)
        view.bringSubview(toFront: backButton)
        previewLayer = nil
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
    
    func uploadImageAndUseThumbnail(_ image: UIImage) {
        
        previewImageView.image = image
        
        let ref = FIRStorage.storage().reference()
        guard let imageData = UIImageJPEGRepresentation(image, 1) else {return}
        let metaData = FIRStorageMetadata()
        
        metaData.contentType = "image/jpeg"
        ref.child("\(currentUser?.email)-\(Date()).jpeg").put(imageData, metadata: metaData) { (meta, error) in
            
            if let downloadPath = meta?.downloadURL()?.absoluteString {
                self.thumbnailURL = downloadPath
            }
        }
    }
    
    
    
    
    func playVideo() {
        print("Play a video")
        
        // Find the video in the app's document directory
        let paths = NSSearchPathForDirectoriesInDomains(
            FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        //let documentsDirectory: URL = URL(fileURLWithPath: "\(filePath)")
        let documentsDirectory: URL = URL(fileURLWithPath: paths[0])
        let dataPath = documentsDirectory.appendingPathComponent(fileName!)
        print(dataPath.absoluteString)
        let videoAsset = (AVAsset(url: filePath!))
        let playerItem = AVPlayerItem(asset: videoAsset)
        
        // Play the video
        let player = AVPlayer(playerItem: playerItem)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        
        self.present(playerViewController, animated: true) {
            playerViewController.player!.play()
        }
    }
    
    
    func postButtonTapped() {
        let currentDate = NSDate()
        let dateFormatter:DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd HH:mm"
        let uniqueTimeID = Int(currentDate.timeIntervalSince1970)
        let timeCreated = dateFormatter.string(from: currentDate as Date)
        let trickTag = challengeLabel.text?.lowercased()
        let firebaseKey = trickTag?.replacingOccurrences(of: "#", with: "")
        
        
        if self.videoURL != "" {
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
    
    func backButtonTapped() {
        if previewLayer != nil {
            previewLayer?.removeFromSuperlayer()
            previewLayer = nil
            timerLabel.isHidden = true
            recordButton.isHidden = true
            postButton.isHidden = false
            view.bringSubview(toFront: challengeLabel)
            view.bringSubview(toFront: postButton)
            view.bringSubview(toFront: toggleCameraButton)
            toggleCameraButton.isEnabled = true
            
            //remove
            let inputs = captureSession.inputs as! [AVCaptureInput]
            for oldInput:AVCaptureInput in inputs {
                captureSession.removeInput(oldInput)
            }
        } else if self.thumbnailURL != "" {
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
    
    func uploadVideoToStorage(url: URL) {
        let storageRef = FIRStorage.storage().reference()
        let uploadTask = storageRef.child(fileName!).putFile(url, metadata: nil, completion: { (metadata, error) in
            
            if error != nil {
                print("Error when uploading to FIRStorage : \(error?.localizedDescription)")
                return
            }
            
            self.videoURL = (metadata?.downloadURL()?.absoluteString)!
            
            print("Video URL : " , self.videoURL)
            
        })
        
        uploadTask.observe(.progress, handler: { (snapshot) in
            print("Progress : " , snapshot.progress?.fractionCompleted)
            var percentage = Int((snapshot.progress?.fractionCompleted)! * 100)
            //self.progressLabel.text = "\(percentage)%"
            
            if percentage == 100 {
  
            }
        })
        
    }
    


    
    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        //print("Recording time is: \(videoFileOutput.recordedDuration)")
    }
    
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        print("Recording has finished.")
        cropVideo(outputFileURL) { (url) in
            UISaveVideoAtPathToSavedPhotosAlbum(url.relativePath, nil, nil, nil)
            print("\(outputFileURL.relativePath) -> Crop URL : \(url.relativePath)")

            self.filePath = url
            self.uploadImageAndUseThumbnail(self.thumbnailForVideoFileURL(fileURL: url)!)
            self.uploadVideoToStorage(url: url)
            

        }
        timer.invalidate()
        self.presentAVPlayerLayer()
   }

}

