//
//  VideoPostCollectionViewCell.swift
//  LambdaTimeline
//
//  Created by Linh Bouniol on 10/17/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit
import AVFoundation

class VideoPostCollectionViewCell: UICollectionViewCell {
    
    var post: Post? {
        didSet {
            updateViews()
        }
    }
    
    private var player: AVPlayer = AVPlayer()
    private var playbackObserver: NSObjectProtocol? = nil
    
    @IBOutlet weak var playbackView: PlaybackView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var labelBackgroundView: UIView!
    @IBOutlet weak var playButton: UIButton!
    
    @IBAction func togglePlayback(_ sender: Any) {
        
        if playButton.isSelected {
            playButton.isSelected = false
            player.pause()
        } else {
            playButton.isSelected = true
            player.play()
        }
    }
    
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
    
    func setVideoURL(_ url: URL) {
        
        // make playback asset with the url, asset represents the video file itself
        let asset = AVURLAsset(url: url)
        
        // tell the playerLayer to use the player we just made
        playbackView.playerLayer.player = player
        playbackView.playerLayer.videoGravity = .resizeAspectFill
        
        playbackObserver = nil
        
        // make a player item with the asset, and tell player to play it
        player.replaceCurrentItem(with: AVPlayerItem(asset: asset))
        
        playbackObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player.currentItem, queue: .main) { _ in
            self.player.seek(to: CMTime.zero)
            self.player.play()
        }
        
    }
}
