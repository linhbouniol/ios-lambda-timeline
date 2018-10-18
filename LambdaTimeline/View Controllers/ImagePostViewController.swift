//
//  ImagePostViewController.swift
//  LambdaTimeline
//
//  Created by Spencer Curtis on 10/12/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit
import Photos

class ImagePostViewController: ShiftableViewController {
    
    // MARK: - Properties
    
    var postController: PostController!
    var post: Post?
    
    var imageData: Data? {
        didSet {
            guard let imageData = imageData else { return }
            
            // save image
            image = UIImage(data: imageData)
        }
    }
    
    var image: UIImage? {
        didSet {
            updateViews()
        }
    }
    
    private let filter = CIFilter(name: "CIColorControls")!
    private let filter2 = CIFilter(name: "CIHueAdjust")!
    private let filter3 = CIFilter(name: "CIColorPosterize")!
    private let context = CIContext(options: nil) // use this to render ciimage back to cgimage
    
    // MARK: - Outlets/Actions
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var chooseImageButton: UIButton!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var postButton: UIBarButtonItem!
    
    @IBOutlet weak var brightnessSlider: UISlider!
    @IBOutlet weak var contrastSlider: UISlider!
    @IBOutlet weak var saturationSlider: UISlider!
    @IBOutlet weak var hueSlider: UISlider!
    @IBOutlet weak var posterizeSlider: UISlider!
    
    @IBAction func createPost(_ sender: Any) {
        
        // hide the keyboard when you tap Post, editing is done
        view.endEditing(true)
        
        guard let imageData = imageView.image?.jpegData(compressionQuality: 0.1),
            let title = titleTextField.text, title != "" else {
                presentInformationalAlertController(title: "Uh-oh", message: "Make sure that you add a photo and a caption before posting.")
                return
        }
        
        postController.createPost(with: title, ofType: .image, mediaData: imageData, ratio: imageView.image?.ratio) { (success) in
            guard success else {
                DispatchQueue.main.async {
                    self.presentInformationalAlertController(title: "Error", message: "Unable to create post. Try again.")
                }
                return
            }
            
            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @IBAction func chooseImage(_ sender: Any) {
        
        let authorizationStatus = PHPhotoLibrary.authorizationStatus()
        
        switch authorizationStatus {
        case .authorized:
            presentImagePickerController()
        case .notDetermined:
            
            PHPhotoLibrary.requestAuthorization { (status) in
                
                guard status == .authorized else {
                    NSLog("User did not authorize access to the photo library")
                    self.presentInformationalAlertController(title: "Error", message: "In order to access the photo library, you must allow this application access to it.")
                    return
                }
                
                self.presentImagePickerController()
            }
            
        case .denied:
            self.presentInformationalAlertController(title: "Error", message: "In order to access the photo library, you must allow this application access to it.")
        case .restricted:
            self.presentInformationalAlertController(title: "Error", message: "Unable to access the photo library. Your device's restrictions do not allow access.")
            
        }
        presentImagePickerController()
    }
    
    @IBAction func changeBrightness(_ sender: UISlider) {
        updateViews()
    }
    
    @IBAction func changeContrast(_ sender: UISlider) {
        updateViews()
    }
    
    @IBAction func changeSaturation(_ sender: UISlider) {
        updateViews()
    }
    
    @IBAction func changeHue(_ sender: UISlider) {
        updateViews()
    }
    
    @IBAction func changePosterize(_ sender: UISlider) {
        updateViews()
    }
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setImageViewHeight(with: 1.0)
        
        updateViews()
    }
    
    // MARK: - Methods
    
    private func setImageViewHeight(with aspectRatio: CGFloat) {
        
        imageHeightConstraint.constant = imageView.frame.size.width * aspectRatio
        
        view.layoutSubviews()
    }
    
    private func updateViews() {
        
//        guard let imageData = imageData,
//            let originalImage = UIImage(data: imageData) else {
//                title = "New Post"
//                return
//        }
        guard let originalImage = image else {
            title = "New Post"
            return
        }
        
        title = post?.title
        
        setImageViewHeight(with: originalImage.ratio)
        
        imageView.image = image(byFiltering: originalImage)
        
        chooseImageButton.setTitle("", for: [])
    }
    
    private func image(byFiltering image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return image } // just return the image, if filtering failed
        
        let ciImage = CIImage(cgImage: cgImage)
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(brightnessSlider.value, forKey: kCIInputBrightnessKey)
        filter.setValue(contrastSlider.value, forKey: kCIInputContrastKey)
        filter.setValue(saturationSlider.value, forKey: kCIInputSaturationKey)
        
        filter2.setValue(filter.outputImage, forKey: kCIInputImageKey)
        filter2.setValue(hueSlider.value, forKey: kCIInputAngleKey)
        
        filter3.setValue(filter2.outputImage, forKey: kCIInputImageKey)
        filter3.setValue(posterizeSlider.value, forKey: "inputLevels")
        
        guard let outputCIImage = filter3.outputImage, let outputCGImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) else {
            return nil
        }// extent means the entire image
        
        return UIImage(cgImage: outputCGImage)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    private func presentImagePickerController() {
        
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            presentInformationalAlertController(title: "Error", message: "The photo library is unavailable")
            return
        }
        
        let imagePicker = UIImagePickerController()
        
        imagePicker.delegate = self
        
        imagePicker.sourceType = .photoLibrary
        
        present(imagePicker, animated: true, completion: nil)
    }
    
}

extension ImagePostViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        chooseImageButton.setTitle("", for: [])
        
        picker.dismiss(animated: true, completion: nil)
        
        guard let chosenImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
        
//        imageView.image = image
        image = chosenImage
        brightnessSlider.isEnabled = true
        contrastSlider.isEnabled = true
        saturationSlider.isEnabled = true
        hueSlider.isEnabled = true
        posterizeSlider.isEnabled = true
        
//        setImageViewHeight(with: chosenImage.ratio)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
