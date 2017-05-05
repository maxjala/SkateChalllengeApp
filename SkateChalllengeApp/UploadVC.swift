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
            recordButton.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var previewImageView: UIImageView!
    
    @IBOutlet weak var playButton: UIButton! {
        didSet{
            playButton.addTarget(self, action: #selector(playVideo), for: .touchUpInside)
            playButton.isHidden = true
        }
    }
    
    var ref: FIRDatabaseReference!
    var currentUser : FIRUser? = FIRAuth.auth()?.currentUser
    var currentUserID : String = ""
    var currentUserEmail : String = ""
    var profileScreenName : String = ""
    var profileImageURL : String = ""
    
    var videoCaptureDevice : AVCaptureDevice? // check capture device availability
    var audioCaptureDevice : AVCaptureDevice?
    let captureSession = AVCaptureSession() // to create capture session
    
    var previewLayer : AVCaptureVideoPreviewLayer? // to add video inside container
    var playerLayer : AVPlayerLayer?
    
    let videoFileOutput = AVCaptureMovieFileOutput()
    let audioFileOutput = AVCaptureAudioDataOutput()
    var filePath : URL?
    var fileName : String?
    
    var thumbnailURL : String?
    
    //trying out AssetWriter
    var assetWriter : AVAssetWriter?

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setCurrentUser()
        captureSession.sessionPreset = AVCaptureSessionPresetMedium
        fileName = createFileName()
        filePath = savePath()
        setUpCamera()
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
        if let videoDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .back),
            let audioDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInMicrophone, mediaType: AVMediaTypeAudio, position: .unspecified) {
            beginSession(_audioCaptureDevice: audioDevice, _videoCaptureDevice: videoDevice)
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
            print("error: \(err?.localizedDescription)")
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.frame = view.bounds
        //previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.portrait
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        view.layer.addSublayer(previewLayer!)
        
        view.bringSubview(toFront: recordButton)
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
    
//    func setUpAssetWriter() {
//    
//    let fileManager = FileManager.default
//    let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
//    guard let documentDirectory: NSURL = urls.first as NSURL? else {
//    print("Video Controller: getAssetWriter: documentDir Error")
//    return
//    }
//    
//    //let local_video_name = NSUUID().uuidString + ".mp4"
//    self.filePath = documentDirectory.appendingPathComponent(fileName!)
//    
//    guard let url = self.filePath else {
//    return
//    }
//    
//    
//    self.assetWriter = try! AVAssetWriter(outputURL: url, fileType: AVFileTypeMPEG4)
//    
//    guard let writer = self.assetWriter else {
//    return
//    }
//    
//    //TODO: Set your desired video size here!
//    let videoSettings: [String : AnyObject] = [
//        AVVideoCodecKey  : AVVideoCodecH264 as AnyObject,
//        AVVideoWidthKey  : previewImageView.frame.width as AnyObject,//may not be correct
//        AVVideoHeightKey : previewImageView.frame.height as AnyObject,
//        AVVideoCompressionPropertiesKey : [
//            AVVideoAverageBitRateKey : 200000,
//            AVVideoProfileLevelKey : AVVideoProfileLevelH264Baseline41,
//            AVVideoMaxKeyFrameIntervalKey : 90,
//        ],
//        ]
//    
//    assetWriterInputCamera = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoSettings)
//    assetWriterInputCamera?.expectsMediaDataInRealTime = true
//    writer.addInput(assetWriterInputCamera!)
//    
//    let audioSettings : [String : AnyObject] = [
//        AVFormatIDKey : NSInteger(kAudioFormatMPEG4AAC) as AnyObject,
//        AVNumberOfChannelsKey : 2 as AnyObject,
//        AVSampleRateKey : NSNumber(value: 44100.0)
//    ]
//    
//    assetWriterInputAudio = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: audioSettings)
//    assetWriterInputAudio?.expectsMediaDataInRealTime = true
//    writer.addInput(assetWriterInputAudio!)
//    
//        
//    }

    func recordButtonTapped() {
        
        if !videoFileOutput.isRecording {
        
            captureSession.addOutput(videoFileOutput)
            //captureSession.addOutput(audioFileOutput)
            let recordingDelegate:AVCaptureFileOutputRecordingDelegate? = self
            videoFileOutput.recordsVideoOrientationAndMirroringChangesAsMetadataTrack(for: previewLayer?.connection)
            videoFileOutput.startRecording(toOutputFileURL: filePath, recordingDelegate: recordingDelegate)
            //audio
//            videoFileOutput.setRecordsVideoOrientationAndMirroringChanges(true, asMetadataTrackFor: previewLayer?.connection)
            
//            let orientation: UIDeviceOrientation = UIDevice.current.orientation
//            print(orientation)
//            
//            switch (orientation) {
//            case .portrait:
//                previewLayer?.connection.videoOrientation = .portrait
//                previewLayer?.frame = view.bounds
//            case .landscapeRight:
//                previewLayer?.connection.videoOrientation = .landscapeLeft
//                previewLayer?.frame = view.bounds
//            case .landscapeLeft:
//                previewLayer?.connection.videoOrientation = .landscapeRight
//                previewLayer?.frame = view.bounds
//            default:
//                previewLayer?.connection.videoOrientation = .portrait
//                previewLayer?.frame = view.bounds
//            }

        } else {
            
            videoFileOutput.stopRecording()
            captureSession.removeOutput(videoFileOutput)
            captureSession.stopRunning()

        }
    }
    
    func presentAVPlayerLayer(){
        previewLayer?.removeFromSuperlayer()
        playButton.isHidden = false
        recordButton.removeFromSuperview()
        
        // Create Thumbnail Image for Video and Upload to Firebase
        if let thumbnail = thumbnailForVideoFileURL(fileURL: filePath!) {
            previewImageView.image = thumbnail
            uploadImage(thumbnail)
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
    
    func uploadImage(_ image: UIImage) {
        
        let ref = FIRStorage.storage().reference()
        guard let imageData = UIImageJPEGRepresentation(image, 0.5) else {return}
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
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds( 30, 30) )
        
        instruction.layerInstructions = [transformer]
        videoComposition.instructions = [instruction]
        
        // Export
        //let croppedOutputFileUrl = URL(fileURLWithPath: <#T##String#>)
        let paths = NSSearchPathForDirectoriesInDomains(
            FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
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
        let outputPath = "\(documentPath)/\(name))"
        return outputPath
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        
    }
    
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        print("Recording has finished.")
//        cropVideo(URL(string: outputFileURL.relativePath)!) { (url) in
//            //UISaveVideoAtPathToSavedPhotosAlbum("\(url)\(self.createFileName())", nil, nil, nil)
//            print("\(outputFileURL.relativePath) -> Crop URL : \(url)")
//
//            self.filePath = url
//            
//
//        }
        //UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.relativePath, nil, nil, nil)
        //UIVideoAtPathIsCompatibleWithSavedPhotosAlbum("\(outputFileURL)")
        // store to gallery
        UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.relativePath, nil, nil, nil)
        self.presentAVPlayerLayer()
           }

}

