//
//  File.swift
//  SkateChalllengeApp
//
//  Created by Max Jala on 02/05/2017.
//  Copyright © 2017 Max Jala. All rights reserved.
//

import Foundation
import UIKit
//import MobileCoreServices
import AVKit
import AVFoundation

extension UIImageView {
    
    func loadImageUsingCacheWithUrlString(urlString: String) {
        
        self.image = nil
        let imageCache = NSCache<AnyObject, AnyObject>()
        
        // Check cache for image first
        if let cachedImage = imageCache.object(forKey: urlString as NSString) {
            self.image = cachedImage as? UIImage
            return
        }
        
        // Otherwise fire off a new download
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
            
            // Dowload hit an error so let's return out
            if error != nil {
                print(error!)
                
                return
            }
            DispatchQueue.main.async(execute: {
                
                if let downloadedImage = UIImage(data: data!) {
                    imageCache.setObject(downloadedImage, forKey: urlString as NSString)
                    self.image = downloadedImage
                    
                }
            })
        }).resume()
    }
    
    
    
}

extension UIViewController {
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
}

import UIKit
import AVFoundation
import AVKit

//class UploadVC: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate  {
//    
//    @IBOutlet weak var recordButton: UIButton! {
//        didSet{
//            recordButton.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
//        }
//    }
//    
//    let dataOutput = AVCaptureVideoDataOutput()
//    var didStartRecording = false
//    let fileName = "mysavefile.mp4"
//    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//    
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupCameraSession()
//    }
//    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        
//        view.layer.addSublayer(previewLayer)
//        self.view.bringSubview(toFront: recordButton)
//        
//        cameraSession.startRunning()
//    }
//    
//    lazy var cameraSession: AVCaptureSession = {
//        let s = AVCaptureSession()
//        s.sessionPreset = AVCaptureSessionPresetMedium
//        return s
//    }()
//    
//    lazy var previewLayer: AVCaptureVideoPreviewLayer = {
//        let preview =  AVCaptureVideoPreviewLayer(session: self.cameraSession)
//        preview?.bounds = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
//        preview?.position = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)
//        preview?.videoGravity = AVLayerVideoGravityResize
//        return preview!
//    }()
//    
//    func setupCameraSession() {
//        let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) as AVCaptureDevice
//        
//        do {
//            let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
//            
//            cameraSession.beginConfiguration()
//            
//            if (cameraSession.canAddInput(deviceInput) == true) {
//                cameraSession.addInput(deviceInput)
//            }
//            
//            dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange as UInt32)]
//            dataOutput.alwaysDiscardsLateVideoFrames = true
//            
//            if (cameraSession.canAddOutput(dataOutput) == true) {
//                cameraSession.addOutput(dataOutput)
//            }
//            
//            cameraSession.commitConfiguration()
//            
//            let queue = DispatchQueue(label: "com.invasivecode.videoQueue")
//            dataOutput.setSampleBufferDelegate(self, queue: queue)
//            
//        }
//        catch let error as NSError {
//            NSLog("\(error), \(error.localizedDescription)")
//        }
//    }
//    
//    func recordButtonTapped() {
//        
//        if let videoConnection = dataOutput.connection(withMediaType: AVMediaTypeVideo) {
//            
//            let videoOutput = AVCaptureMovieFileOutput()
//            let filePath = documentsURL.appendingPathComponent(fileName)
//            
//            //            let paths = NSSearchPathForDirectoriesInDomains(
//            //                FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
//            //            let documentsDirectory: URL = URL(fileURLWithPath: paths[0])
//            //            let dataPath = documentsDirectory.appendingPathComponent(fileName)
//            //            try! videoOutput.write(to: dataPath, options: [])
//            //            print("Saved to " + dataPath.absoluteString)
//            
//            if didStartRecording == true {
//                videoOutput.stopRecording()
//            } else {
//                
//                cameraSession.addOutput(videoOutput)
//                didStartRecording = true
//                
//                let recordingDelegate:AVCaptureFileOutputRecordingDelegate? = self
//                videoOutput.startRecording(toOutputFileURL: filePath, recordingDelegate: recordingDelegate)
//            }
//        }
//    }
//    
//    
//    
//    
//    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
//        // Here you collect each frame and process it
//    }
//    
//    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
//        print("Camera finished recording")
//    }
//    
//    func captureOutput(_ captureOutput: AVCaptureOutput!, didDrop sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
//        // Here you can count how many frames are dopped
//    }
//    
//}










