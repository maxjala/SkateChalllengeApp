//
//  VideoPostViewCell.swift
//  SkateChalllengeApp
//
//  Created by Max Jala on 02/05/2017.
//  Copyright © 2017 Max Jala. All rights reserved.
//

import UIKit
import Cosmos


protocol VideoPostDelegate {
    func loadVideo(_ post: VideoPost, _ videoView: UIView)
    func sendRatingToFirebase(_ post: VideoPost, _ rating: Double)
    //func observeRatingFromFirebase(_ post: VideoPost, _ videoRating: CosmosView)
}

class VideoPostViewCell: UITableViewCell {
    
    var delegate : VideoPostDelegate? = nil
    var videoPost : VideoPost?
    
    @IBOutlet weak var profileImageView: UIImageView! {
        didSet{
            profileImageView.layer.cornerRadius = profileImageView.frame.width/2
            profileImageView.layer.masksToBounds = true
        }
    }
    
    @IBOutlet weak var userNameLabel: UILabel!
    
    @IBOutlet var userRatingButtons: [UIButton]!
    
    @IBOutlet var ratingLabelCollection: [UILabel]!
    
    @IBOutlet weak var videoView: UIView!
    
    @IBOutlet weak var previewImageView: UIImageView!
    
    @IBOutlet weak var playVideoButton: UIButton! {
        didSet{
            playVideoButton.addTarget(self, action: #selector(playVideoButtonTapped), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var commentButton: UIButton!
    
    @IBOutlet weak var challengeButton: UIButton!
    
    @IBOutlet weak var exploreButton: UIButton!
    
    @IBOutlet weak var hashtagLabel: UILabel!
    
    @IBOutlet weak var userRatingView: CosmosView! {
        didSet{
            userRatingView.didFinishTouchingCosmos = { rating in
                self.cosmosViewTapped(rating)
            }
        }
    }
    
    @IBOutlet weak var publicRatingView: CosmosView! {
        didSet{
            publicRatingView.settings.fillMode = .precise
        }
    }
    
    @IBOutlet weak var ratingLabel: UILabel!

    
    static let cellIdentifier = "VideoPostViewCell"
    static let cellNib = UINib(nibName: VideoPostViewCell.cellIdentifier, bundle: Bundle.main)
    
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func playVideoButtonTapped() {
        if delegate != nil {
            if let _videoPost = videoPost,
                let _videoView = videoView {
                delegate?.loadVideo(_videoPost, _videoView)
            }
        }
    }
        
//    func observeRating() -> Double {
//        if delegate != nil {
//            if let _videoPost = videoPost,
//                let _videoRating = userRatingView {
//                delegate?.observeRatingFromFirebase(_videoPost, _videoRating)            }
//        }
//        return 0.0
//    }

    func cosmosViewTapped(_ rating: Double) {
        
        if delegate != nil {
            if let _videoPost = videoPost {
                delegate?.sendRatingToFirebase(_videoPost, rating)            }
        }
    }
}
