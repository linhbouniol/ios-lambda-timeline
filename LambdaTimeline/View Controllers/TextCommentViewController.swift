//
//  TextCommentViewController.swift
//  LambdaTimeline
//
//  Created by Linh Bouniol on 10/16/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit

class TextCommentViewController: UIViewController {
    
    var post: Post!
    var postController: PostController!
    
    @IBOutlet weak var commentTextField: UITextField!
    
    @IBAction func done(_ sender: Any) {
        guard let commentText = commentTextField?.text else { return }
        
        self.postController.addComment(with: commentText, to: &self.post)
        
        dismiss(animated: true, completion: nil)
    }
}
