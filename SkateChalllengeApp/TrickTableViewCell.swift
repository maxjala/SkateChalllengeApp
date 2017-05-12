//
//  TrickTableViewCell.swift
//  SkateChalllengeApp
//
//  Created by Max Jala on 10/05/2017.
//  Copyright © 2017 Max Jala. All rights reserved.
//

import UIKit
import Cosmos

//protocol TrickCellDelegate {
//    func loadVideo(_ post: VideoPost, _ videoView: UIView)
//    func sendRatingToFirebase(_ post: VideoPost, _ rating: Double)
//    //func observeRatingFromFirebase(_ post: VideoPost, _ videoRating: CosmosView)
//    func passTrickTag(_ post: VideoPost)
//}

class TrickTableViewCell: UITableViewCell {
    
    //Preview Stack
    @IBOutlet weak var previewView: UIView! {
        didSet{
            previewView.isHidden = false
        }
    }
    
    @IBOutlet weak var thumbnailImageView: UIImageView!
    
    @IBOutlet weak var profilePicImageView: UIImageView!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var ratingView: CosmosView!
    
    @IBOutlet weak var trickTextView: UITextView!
    
    //FullView Stack
    
    @IBOutlet weak var fullView: UIView! {
        didSet{
            fullView.isHidden = true
        }
    }
    
    @IBOutlet weak var profileImageView: UIImageView!
    
    @IBOutlet weak var fullNameLabel: UILabel!
    
    @IBOutlet weak var fullRatingView: CosmosView!
    
    @IBOutlet weak var playVideoButton: UIButton!
    
    @IBOutlet weak var videoView: UIView!
    
    @IBOutlet weak var fullPreviewView: UIImageView!
    
    @IBOutlet weak var commentButton: UIButton!
    
    @IBOutlet weak var userRatingView: CosmosView!
    
    @IBOutlet weak var challengeButton: UIButton!
    
    @IBOutlet weak var searchButton: UIButton!
    
    @IBOutlet weak var trickLabel: UILabel!
    
    @IBOutlet weak var timeSinceLabel: UILabel!
    
    static let cellIdentifier = "TrickTableViewCell"
    static let cellNib = UINib(nibName: TrickTableViewCell.cellIdentifier, bundle: Bundle.main)
    
    var delegate : VideoPostDelegate? = nil
    var videoPost : VideoPost?
    
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
    
    func exploreButtonTapped() {
        if delegate != nil {
            if let _videoPost = videoPost {
                delegate?.passTrickTag(_videoPost)           }
        }
    }
    
    func cosmosViewTapped(_ rating: Double) {
        
        if delegate != nil {
            if let _videoPost = videoPost {
                delegate?.sendRatingToFirebase(_videoPost, rating)
            }
        }
    }
    
    
    
    
}
