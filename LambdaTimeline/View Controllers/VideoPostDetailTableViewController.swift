//
//  VideoPostDetailTableViewController.swift
//  LambdaTimeline
//
//  Created by Linh Bouniol on 10/17/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit
import AVFoundation

class VideoPostDetailTableViewController: UITableViewController {
    
    var post: Post! {
        didSet {
            updateViews()
        }
    }
    
    var postController: PostController!
    
    private var player: AVPlayer = AVPlayer()
    private var playbackObserver: NSObjectProtocol? = nil
    
    private var operations = [URL : Operation]()
    private let mediaFetchQueue = OperationQueue()
    private let cache = Cache<URL, Data>()
    
    @IBOutlet weak var playbackView: PlaybackView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!

    @IBAction func togglePlayback(_ sender: Any) {
        if playButton.isSelected {
            playButton.isSelected = false
            player.pause()
        } else {
            playButton.isSelected = true
            player.play()
        }
        
        /*
         Starts off with playButton selected (true), then the player calls play(), next time playButton is selected, then set isSelected to false and pause() the player.
         */
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateViews()
        
        self.tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tableView.reloadData()
    }
    
    func updateViews() {
        guard isViewLoaded else { return } // always check to make sure view is loaded
        let url = post.mediaURL
        
        // make playback asset with the url, asset represents the video file itself
        let asset = AVURLAsset(url: url)
        
        // tell the playerLayer to use the player we just made
        playbackView.playerLayer.player = player
        playbackView.playerLayer.videoGravity = .resizeAspectFill
        
        playbackObserver = nil
        
        // make a player item with the asset, and tell player to play it
        player.replaceCurrentItem(with: AVPlayerItem(asset: asset))
        
        // observe the player to see when it finished playing, when it did, call play() on player
        // this allows the video to loop until we tapped pause
        playbackObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player.currentItem, queue: .main) { _ in
            self.player.seek(to: CMTime.zero)
            self.player.play()
        }
        
        title = post.title
        
        titleLabel.text = post.title
        authorLabel.text = post.author.displayName
    }
    
    // MARK: - Table view data source
    
    @IBAction func createComment(_ sender: Any) {
        
        let actionSheet = UIAlertController(title: "Add a comment", message: "Choose type:", preferredStyle: .alert)
        
        actionSheet.addAction(UIAlertAction(title: "Text", style: .default, handler: { (action) in
            self.performSegue(withIdentifier: "ShowTextCommentVC", sender: self)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: { (action) in
            self.performSegue(withIdentifier: "ShowAudioCommentVC", sender: self)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return (post?.comments.count ?? 0) - 1
        return (post?.comments.count ?? 1) - 1
        
        /*
         -1 because the first entry is the post's title
         Can't have ?? 0) -1, because if the post is nil, then there will be 0 - 1 rows and this would crashed.
         */
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let comment = post?.comments[indexPath.row + 1]
        
        if let text = comment?.text {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TextCommentCell", for: indexPath)
            cell.textLabel?.text = text
            cell.detailTextLabel?.text = comment?.author.displayName
            return cell
        } else if comment?.url != nil {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AudioCommentCell", for: indexPath) as! AudioCommentTableViewCell
            
            // load from server
            loadAudio(for: cell, forItemAt: indexPath)
            
            cell.authorLabel?.text = comment?.author.displayName
            return cell
        } else {
            // should never get to this step (comment is always either a text or audio). this is so swift can be happy.
            return UITableViewCell()
        }
    }
    
    func loadAudio(for audioCell: AudioCommentTableViewCell, forItemAt indexPath: IndexPath) {
        let comment = post?.comments[indexPath.row + 1]
        
        guard let url = comment?.url else { return }
        
        if let mediaData = cache.value(for: url) {
            audioCell.data = mediaData
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
            return
        }
        
        // if there's no data in the cache, we want to fetch the data from the server at the url
        let fetchOp = FetchMediaOperation(mediaURL: url, postController: postController)
        
        let cacheOp = BlockOperation {
            if let data = fetchOp.mediaData {
                self.cache.cache(value: data, for: url)
                DispatchQueue.main.async {
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                }
            }
        }
        
        // once everything completes
        let completionOp = BlockOperation {
            defer { self.operations.removeValue(forKey: url) }
            
            // make sure cell is still the same cell
            if let currentIndexPath = self.tableView.indexPath(for: audioCell),
                currentIndexPath != indexPath {
                print("Got image for now-reused cell")
                return
            }
            
            // make sure there is data, and saves it to the cell
            if let data = fetchOp.mediaData {
                audioCell.data = data
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        }
        
        cacheOp.addDependency(fetchOp) // cache wont get call until fetch is done
        completionOp.addDependency(fetchOp) // completion wont get call until fetch is done
        
        // ok for completion to be called when cache isnt done
        
        mediaFetchQueue.addOperation(fetchOp)
        mediaFetchQueue.addOperation(cacheOp)
        OperationQueue.main.addOperation(completionOp)
        
        // assign the fetching of audio data to operations dictionary at that url, so we could cancel when we need to
        operations[url] = fetchOp
    }
    
    /*
     Don't want to use cache and operation for videos because they are usually large files so we don't want to store them.
     We want to fetch from the server every time we playback the recording.
     */
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let textVC = segue.destination as? TextCommentViewController {
            textVC.postController = postController
            textVC.post = post
        } else if let audioVC = segue.destination as? AudioCommentViewController {
            audioVC.postController = postController
            audioVC.post = post
        }
    }
}
