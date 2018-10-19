//
//  MapViewController.swift
//  LambdaTimeline
//
//  Created by Linh Bouniol on 10/18/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, PostControllerProtocol, MKMapViewDelegate {
    
    var postController: PostController?
    var currentAnnotations: [Post] = []
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        postController?.observePosts { (_) in
            DispatchQueue.main.async {
                self.updateAnnotations()
            }
        }
    }
    
    func updateAnnotations() {
        mapView.removeAnnotations(currentAnnotations)
        currentAnnotations = postController!.posts
        mapView.addAnnotations(currentAnnotations)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        // get post from annotation, (pin on map)
        guard let post = view.annotation as? Post else { return }
        
        switch post.mediaType {
        case .image:
            self.performSegue(withIdentifier: "ViewImagePost", sender: nil)
        case .video:
            self.performSegue(withIdentifier: "ViewVideoPost", sender: nil)
        default:
            break
        }
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AddImagePost" {
            let destinationVC = segue.destination as? ImagePostViewController
            destinationVC?.postController = postController
            
        } else if segue .identifier == "AddVideoPost" {
            let videoVC = segue.destination as? VideoPostViewController
            videoVC?.postController = postController
            
        } else if segue.identifier == "ViewImagePost" {
            
            let destinationVC = segue.destination as? ImagePostDetailTableViewController
            
            // get post from selected pin
            guard let post = mapView.selectedAnnotations.first as? Post else { return }
            
            destinationVC?.postController = postController
            destinationVC?.post = post
            
            //destinationVC?.imageData = cache.value(for: postID)
            
            /*
             The image doesn't show up because the way the app is currently set up, the collection view loads and caches the images for its cells, then passes that imageData to the detail VC.
             In this case, we're not loading any images for the map view, so we don't have an image to give to the detail VC.
             The reason why video works is because all we do is provide a post, which allows us to pass the media url to AVURLAsset, and it takes care of loading and displaying the video.
             */
            
        } else if segue.identifier == "ViewVideoPost" {
            
            let destinationVC = segue.destination as? VideoPostDetailTableViewController
            
            // get post from selected pin
            guard let post = mapView.selectedAnnotations.first as? Post else { return }
            
            destinationVC?.postController = postController
            destinationVC?.post = post
        }
    }
    
}
