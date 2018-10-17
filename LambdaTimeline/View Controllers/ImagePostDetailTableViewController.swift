//
//  ImagePostDetailTableViewController.swift
//  LambdaTimeline
//
//  Created by Spencer Curtis on 10/14/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit

class ImagePostDetailTableViewController: UITableViewController {
    
    
    var post: Post!
    var postController: PostController!
    var imageData: Data?
    
    private var operations = [URL : Operation]()
    private let mediaFetchQueue = OperationQueue()
    private let cache = Cache<URL, Data>()
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var imageViewAspectRatioConstraint: NSLayoutConstraint!
    
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
        
        guard let imageData = imageData,
            let image = UIImage(data: imageData) else { return }
        
        title = post?.title
        
        imageView.image = image
        
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
        return (post?.comments.count ?? 0) - 1
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
