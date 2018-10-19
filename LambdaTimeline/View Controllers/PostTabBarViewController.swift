//
//  PostTabBarViewController.swift
//  LambdaTimeline
//
//  Created by Linh Bouniol on 10/18/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit

protocol PostControllerProtocol: class {
    var postController: PostController? { get set }
}

class PostTabBarViewController: UITabBarController {
    
    let postController = PostController()

    override func viewDidLoad() {
        super.viewDidLoad()

        passPostControllerToChildViewControllers()
    }
    
    func passPostControllerToChildViewControllers() {
        for child in children {
            // get navigation controller first, since the tab bar goes to navigation then to the other vc
            guard let navigationController = child as? UINavigationController else { return }
            
            guard let vc = navigationController.topViewController as? PostControllerProtocol else { return }
            vc.postController = postController
        }
    }
}
