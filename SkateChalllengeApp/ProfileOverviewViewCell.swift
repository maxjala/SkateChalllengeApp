//
//  ProfileOverviewViewCell.swift
//  SkateChalllengeApp
//
//  Created by Max Jala on 08/05/2017.
//  Copyright © 2017 Max Jala. All rights reserved.
//

import UIKit

protocol ProfileViewCellDelegate {
    func loadVideo(_ post: VideoPost, _ videoView: UIView)
    func configureFollowButton(_ user: User, _ editFollowBtn: UIButton)
}

class ProfileOverviewViewCell: UITableViewCell {
    
    @IBOutlet weak var profileImageView: UIImageView! {
        didSet{
            profileImageView.layer.cornerRadius = profileImageView.frame.width/2
            profileImageView.layer.masksToBounds = true
        }
    }
    
    @IBOutlet weak var noOfPostsLabel: UILabel!
    
    @IBOutlet weak var noOfFollowersLabel: UILabel!
    
    @IBOutlet weak var noOfFollowingLabel: UILabel!
    
    @IBOutlet weak var editProfileButton: UIButton!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var stanceLabel: UILabel!
    
    @IBOutlet weak var bioTextView: UITextView!
    
    static let cellIdentifier = "ProfileOverviewViewCell"
    static let cellNib = UINib(nibName: ProfileOverviewViewCell.cellIdentifier, bundle: Bundle.main)
    
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
