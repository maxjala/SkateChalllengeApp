//
//  VideoPostViewCell.swift
//  SkateChalllengeApp
//
//  Created by Max Jala on 02/05/2017.
//  Copyright © 2017 Max Jala. All rights reserved.
//

import UIKit
import SwiftyStarRatingView

protocol VideoPostDelegate {
    func loadVideo(_ post: VideoPost, _ videoView: UIView)
    //func goToProfile(_ post: PicturePost)
    func sendStarRating(_ post: VideoPost, _ starView: SwiftyStarRatingView)
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
    
    @IBOutlet weak var userStarRatingView: SwiftyStarRatingView! {
        didSet{
            userStarRatingView.accurateHalfStars = false
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(starViewTapped(_:)))
            userStarRatingView.addGestureRecognizer(gestureRecognizer)
        }
    }
    
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
    
    func starViewTapped(_:UITapGestureRecognizer) {
        if delegate != nil {
            if let _videoPost = videoPost,
                let _starView = userStarRatingView {
                delegate?.sendStarRating(_videoPost, _starView)
            }
        }
    }
    
    
    func playVideoButtonTapped() {
        if delegate != nil {
            if let _videoPost = videoPost,
                let _videoView = videoView {
                delegate?.loadVideo(_videoPost, _videoView)
            }
        }
    }
    
}
