//
//  UserTableViewCell.swift
//  SkateChalllengeApp
//
//  Created by Max Jala on 08/05/2017.
//  Copyright © 2017 Max Jala. All rights reserved.
//

import UIKit

class UserTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var profileImageView: UIImageView!  {
        didSet{
            profileImageView.layer.cornerRadius = profileImageView.frame.width/2
            profileImageView.layer.masksToBounds = true
        }
    }
    
    @IBOutlet weak var userNameLabel: UILabel!
    
    static let cellIdentifier = "UserTableViewCell"
    static let cellNib = UINib(nibName: UserTableViewCell.cellIdentifier, bundle: Bundle.main)

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
