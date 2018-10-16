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
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var imageViewAspectRatioConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateViews()
        
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
        
//        var commentTextField: UITextField?
//
//        alert.addTextField { (textField) in
//            textField.placeholder = "Comment:"
//            commentTextField = textField
//        }
        
//        let addCommentAction = UIAlertAction(title: "Add Comment", style: .default) { (_) in
//
//            guard let commentText = commentTextField?.text else { return }
//
//            self.postController.addComment(with: commentText, to: &self.post!)
//
//            DispatchQueue.main.async {
//                self.tableView.reloadData()
//            }
//        }
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

//        alert.addAction(addCommentAction)
//        alert.addAction(cancelAction)

        self.present(actionSheet, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (post?.comments.count ?? 0) - 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath)
        
        let comment = post?.comments[indexPath.row + 1]
        
        cell.textLabel?.text = comment?.text
        cell.detailTextLabel?.text = comment?.author.displayName
        
        return cell
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let textVC = segue.destination as? TextCommentViewController {
            textVC.postController = postController
            textVC.post = post
        }
    }
}
