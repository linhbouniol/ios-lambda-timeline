//
//  AudioCommentViewController.swift
//  LambdaTimeline
//
//  Created by Linh Bouniol on 10/16/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit
import AVFoundation

class AudioCommentViewController: UIViewController, AVAudioPlayerDelegate {
    
    // MARK: - Properties
    
    var post: Post!
    var postController: PostController!
    
    private var player: AVAudioPlayer?
    
    private var playTimeTimer: Timer? {
        willSet {
            playTimeTimer?.invalidate()
        }
    }
    
    private var recorder: AVAudioRecorder?
    
    // MARK: - Outlets/Actions
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    
    @IBAction func record(_ sender: Any) {
        let isRecording = recorder?.isRecording ?? false
        if isRecording {
            // already recording
            recorder?.stop()
            playTimeTimer = nil
            
            // after recording, create a player with the url
            if let url = recorder?.url {
                player = try! AVAudioPlayer(contentsOf: url)
                player?.delegate = self
            }
        } else {
            // start recording (always create a new recording)
            let format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 1)!
            recorder = try! AVAudioRecorder(url: newRecordingURL(), format: format)
            recorder?.record()
            
            startPollingPlayTime()
        }
        updateViews()
    }
    
    @IBAction func play(_ sender: Any) {
        let isPlaying = player?.isPlaying ?? false
        
        if isPlaying {
            // Already playing, so stop playback
            player?.pause()
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
            startPollingPlayTime()
        }
        updateViews()
    }
    
    @IBAction func done(_ sender: Any) {
        guard let audioURL = recorder?.url else { return }
        
        postController.addAudioComment(with: audioURL, to: post)
        
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Methods
    
    private func updateViews() {
        guard isViewLoaded else { return }
        
        // if player is playing => true, if player not playing => false, if player is nil => false
        let isPlaying = player?.isPlaying ?? false
        let playButtonTitle = isPlaying ? "Pause" : "Play"
        playButton.setTitle(playButtonTitle, for: .normal)
        
        let isRecording = recorder?.isRecording ?? false
        let recordButtonTitle = isRecording ? "Stop" : "Record"
        recordButton.setTitle(recordButtonTitle, for: .normal)
        
        if isRecording {
            let currentTime = recorder?.currentTime ?? 0
            timeLabel.text = stringFromTimeInterval(timeInterval: currentTime)
        } else {
            let currentTime = player?.currentTime ?? 0
            timeLabel.text = stringFromTimeInterval(timeInterval: currentTime)
        }
    }
    
    private func startPollingPlayTime() { // grab the time every 0.05 second
        playTimeTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] (timer) in
            self?.updateViews()
        }
    }
    
    private func newRecordingURL() -> URL {
        let fm = FileManager.default
        let documentsDir = try! fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return documentsDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("caf")
    }
    
    private func stringFromTimeInterval(timeInterval: TimeInterval) -> String {
        let timeIntervalAsInt = Int(timeInterval)
        let tenths = Int((timeInterval - floor(timeInterval)) * 10)
        let seconds = timeIntervalAsInt % 60
        let minutes = (timeIntervalAsInt / 60) % 60
        let hours = timeIntervalAsInt / 3600
        
        return String(format: "%02ld:%02ld:%02ld.%ld", hours, minutes, seconds, tenths)
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        updateViews()
        playTimeTimer = nil
    }
}
