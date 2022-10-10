//
//  ViewController.swift
//  FlowerClassifier
//
//  Created by Vlad V on 09.10.2022.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON

class ViewController: UIViewController {
    
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    let imagePicker = UIImagePickerController()
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    
    var parameters : [String:String] = [
        "format" : "json",
        "action" : "query",
        "prop" : "extracts",
        "exintro" : "",
        "explaintext" : "",
        "titles" : "flowerName",
        "indexpageids" : "",
        "redirects" : "1",
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
    }
    
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true)
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            if let clImage = CIImage(image: userPickedImage) {
                detect(flowerImage: clImage)
            }
            imageView.image = userPickedImage
        }
        
        imagePicker.dismiss(animated: true)
    }
    
    
    func detect(flowerImage image: CIImage){
        
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Loading CoreML failed.")
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Model failed to posses image.")
            }
            //print(results)
            if let saveResultF = results.first {
                self.title = saveResultF.identifier
                self.parameters["titles"] = saveResultF.identifier
                self.performRequest(flowerName: saveResultF.identifier)
            }
            
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        do{
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    func performRequest(flowerName: String) {
        AF.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { response in
            
            switch response.result{
            case .success(let value):
                let json = JSON(value)
                let pageid = json["query"]["pageids"][0].stringValue
                self.descriptionLabel.text = json["query"]["pages"][pageid]["extract"].stringValue
            
            case .failure(let error):
                print(error)
            }
            
        }
    }
}
