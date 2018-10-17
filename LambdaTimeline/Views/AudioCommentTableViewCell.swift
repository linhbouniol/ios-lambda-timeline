//
//  AudioCommentTableViewCell.swift
//  LambdaTimeline
//
//  Created by Linh Bouniol on 10/16/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit
import AVFoundation

class AudioCommentTableViewCell: UITableViewCell, AVAudioPlayerDelegate  {

    private var player: AVAudioPlayer?
    
    var data: Data? {// cell is reused so data changes
        didSet {
            guard let data = data else { return }
            
            do {
                player = try AVAudioPlayer(data: data)
                player?.delegate = self
            } catch {
                NSLog("Error making audio player: \(error)")
            }
        }
    }
    
    private var playTimeTimer: Timer? {
        willSet {
            playTimeTimer?.invalidate()
        }
    }
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    
    
    @IBAction func play(_ sender: Any) {
        let isPlaying = player?.isPlaying ?? false
        
        if isPlaying {
            // Already playing, so stop playback
            player?.pause()
            playButton.setTitle("Play", for: .normal)
            playTimeTimer = nil
        } else {
            let session = AVAudioSession.sharedInstance()
            
            do {
                try session.setCategory(.playAndRecord, mode: .default, options: [])
                try session.overrideOutputAudioPort(.speaker)
                try session.setActive(true, options: []) // session is acive whenever the app starts up
            } catch {
                NSLog("Error setting up audio session: \(error)")
            }
            
            player?.play()
            playButton.setTitle("Pause", for: .normal)
            
            playTimeTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] (timer) in
                
                guard let currentTime = self?.player?.currentTime, let duration = self?.player?.duration else { return }
                
                self?.progressBar.progress = Float(currentTime / duration)
            }
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playButton.setTitle("Play", for: .normal)
        playTimeTimer = nil
        progressBar.progress = 0
    }
}
