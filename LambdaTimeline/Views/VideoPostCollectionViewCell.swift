//
//  VideoPostCollectionViewCell.swift
//  LambdaTimeline
//
//  Created by Linh Bouniol on 10/17/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit

class VideoPostCollectionViewCell: UICollectionViewCell {
    
    var post: Post? {
        didSet {
            updateViews()
        }
    }
    
    @IBOutlet weak var playbackView: PlaybackView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var labelBackgroundView: UIView!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupLabelBackgroundView()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        titleLabel.text = ""
        authorLabel.text = ""
    }
    
    func setupLabelBackgroundView() {
        labelBackgroundView.layer.cornerRadius = 8
        labelBackgroundView.clipsToBounds = true
    }
    
    func updateViews() {
        guard let post = post else { return }
        
        titleLabel.text = post.title
        authorLabel.text = post.author.displayName
    }
    
    func setVideoURL(_ url: URL?) {
        // do something
    }
}
