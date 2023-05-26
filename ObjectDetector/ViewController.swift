//
//  ViewController.swift
//  ObjectDetector
//
//  Created by Tung Tran on 5/20/23.
//

import UIKit
import Vision

extension CGImagePropertyOrientation {
    init(_ uiImageOrientation: UIImage.Orientation) {
        switch uiImageOrientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        default: self = .up
        }
    }
}

class ViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var resultLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let image1 = UIImage(named: "image1")!
        imageView.image = image1
        detectInfo(image: image1) { numberOfFaces, numberOfTexts, text in
            self.resultLabel.text = """
            Faces: \(numberOfFaces)
            Texts: \(numberOfTexts)
            ---
            \(text)
            """
        }
    }
    
    private func detectInfo(image: UIImage, completion: @escaping (_ numberOfFaces: Int, _ numberOfTexts: Int, _ text: String) -> Void) {
        guard let cgImage = image.cgImage else {
            print("Image not found!")
            completion(0, 0, "")
            return
        }
        
        var numberOfFaces = 0
        var numberOfTexts = 0
        var recognizedText = ""
        let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage, orientation: CGImagePropertyOrientation(image.imageOrientation))
        
        let facialRequest = detectFaces { numFaces in
            numberOfFaces = numFaces
        }
        let textRequest = detectTexts { numTexts in
            numberOfTexts = numTexts
        }
        let parseTextRequest = parseText { text in
            recognizedText = text
        }
        #if targetEnvironment(simulator)
            facialRequest?.usesCPUOnly = true
            textRequest?.usesCPUOnly = true
            parseTextRequest?.usesCPUOnly = true
        #endif
        
        let requests = [facialRequest, textRequest, parseTextRequest].compactMap { $0 }
        
        do {
            try imageRequestHandler.perform(requests)
            completion(numberOfFaces, numberOfTexts, recognizedText)
        } catch {
            print("Fail to detect objects: \(error)")
            completion(0, 0, "")
            return
        }
    }
    
    private func detectFaces(completion: @escaping (_ numFaces: Int) -> Void) -> VNRequest? {
        return VNDetectFaceRectanglesRequest { request, error in
            if let error = error {
                print("Fail to detect faces: \(error)")
                completion(0)
                return
            }
            
            guard let results = request.results as? [VNFaceObservation] else {
                print("No result!")
                completion(0)
                return
            }
            
            completion(results.count)
        }
    }
    
    private func detectTexts(completion: @escaping (_ numTexts: Int) -> Void) -> VNRequest? {
        return VNDetectTextRectanglesRequest { request, error in
            if let error = error {
                print("Fail to detect texts: \(error)")
                completion(0)
                return
            }
            
            guard let results = request.results as? [VNTextObservation] else {
                print("No result!")
                completion(0)
                return
            }
            
            
            completion(results.count)
        }
    }
    
    private func parseText(completion: @escaping (_ text: String) -> Void) -> VNRequest? {
        return VNRecognizeTextRequest { request, error in
            if let error = error {
                print("Fail to parse text: \(error)")
                completion("")
                return
            }
            
            guard let results = request.results as? [VNRecognizedTextObservation] else {
                print("No result!")
                completion("")
                return
            }
            
            var texts: [String] = []
            texts = results.compactMap {
                return $0.topCandidates(1).first?.string
            }
            
            completion(texts.joined(separator: "\n"))
        }
    }
}
