//
//  CamViewController.swift
//  RapsodoApp
//
//  Created by Ömer Faruk Başaran on 8.05.2023.
//

import UIKit
import AVFoundation
import MediaWatermark
import RealmSwift

class CamViewController: UIViewController,AVCaptureFileOutputRecordingDelegate {
    
    var captureSession = AVCaptureSession()
    var videoDevice: AVCaptureDevice?
    var audioDevice: AVCaptureDevice?
    var videoInput: AVCaptureDeviceInput?
    var audioInput: AVCaptureDeviceInput?
    var movieFileOutput = AVCaptureMovieFileOutput()
    var isRecording = false
    var shotId = ""
    var indexSection = 0
    var indexRow = 0
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var waitLabel: UILabel!
    var recordButton = UIButton()
    //var realm = try! Realm()
    var playerObjects = [Player]()
    
    var finalURL = URL(string: "")
    
    override func viewDidLoad() {
        super.viewDidLoad()

        fetchDataFromRealm()
        

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        activityIndicator.isHidden = true
        waitLabel.isHidden = true
        // AVCaptureSession özelleştirme
        let sessionQueue = DispatchQueue(label: "session queue")
        
        func startSession() {
            sessionQueue.async {
                self.captureSession.startRunning()
            }
        }
        
        captureSession.beginConfiguration()
        
        // Video aygıtını bulma ve tanımlama
        videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        do {
            // AVCaptureDeviceInput örneğini oluşturma
            videoInput = try AVCaptureDeviceInput(device: videoDevice!)
            if captureSession.canAddInput(videoInput!) {
                captureSession.addInput(videoInput!)
            }
        } catch {
            print("Kamera error \(error.localizedDescription)")
        }
        
        // Audio aygıtını bulma ve tanımlama
        audioDevice = AVCaptureDevice.default(for: .audio)
        do {
            // AVCaptureDeviceInput örneğini oluşturma
            audioInput = try AVCaptureDeviceInput(device: audioDevice!)
            if captureSession.canAddInput(audioInput!) {
                captureSession.addInput(audioInput!)
            }
        } catch {
            print("Mic error \(error.localizedDescription)")
        }
        
        // AVCaptureMovieFileOutput örneğini yapılandırma
        if captureSession.canAddOutput(movieFileOutput) {
            captureSession.addOutput(movieFileOutput)
        }
        
        // Video çıkışını yapılandırma
        let connection = movieFileOutput.connection(with: .video)
        if connection?.isVideoStabilizationSupported ?? false {
            connection?.preferredVideoStabilizationMode = .auto
        }
        if connection?.isVideoOrientationSupported ?? false {
            connection?.videoOrientation = .portrait
        }
        
        // AVCaptureSession yapılandırmasını bitirme
        captureSession.commitConfiguration()
        
        // Video görüntüsünü ekranda gösterme için AVCaptureVideoPreviewLayer örneği oluşturma
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(previewLayer, at: 0)
        
        // Kamera kayıt düğmesi oluşturma
        recordButton = UIButton(frame: CGRect(x: view.bounds.width/2 - 30, y: view.bounds.height - 80, width: 60, height: 60))
        recordButton.backgroundColor = UIColor.systemRed
        recordButton.layer.cornerRadius = 30
        recordButton.addTarget(self, action: #selector(recordButtonTapped(_:)), for: .touchUpInside)
        view.addSubview(recordButton)
        
    }
    
    // Kayıt düğmesine tıklandığında çalışacak işlev
    @objc func recordButtonTapped(_ sender: UIButton) {
        if !isRecording {
            // Kayıt başlatma
            let outputPath = NSTemporaryDirectory() + "\(shotId).mov"
            let outputFileURL = URL(fileURLWithPath: outputPath)
            DispatchQueue(label: "session queue").async {
                self.movieFileOutput.startRecording(to: outputFileURL, recordingDelegate: self)
            }
            
            isRecording = true
            sender.backgroundColor = UIColor.systemGreen
        } else {
            // Kayıt durdurma
            movieFileOutput.stopRecording()
            isRecording = false
            sender.backgroundColor = UIColor.systemRed
        }
    }
    
    // Kaydedildiğinde çalışacak işlev
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if error != nil {
            print("Path:\(outputFileURL)")
            print("Hata: Video kaydedilemedis(didFinishRecordingTo).")
        } else {
            
            processVideo(url: outputFileURL, indexSection: indexSection, indexRow: indexRow)
            activityIndicator.isHidden = false
            waitLabel.isHidden = false
        }
    }
    func saveToRealmURL(playerObjects: [Player],URL:String) {
        DispatchQueue.main.async {
            //let realm = try! Realm()
            try! realm.write {
                playerObjects[self.indexSection].shots[self.indexRow].videoURL = URL
                    realm.add(playerObjects, update: .modified)
                
                    print("URL added")
                
            }
        }
    }
    func fetchDataFromRealm() {
        DispatchQueue.main.async {
           // let realm = try! Realm()
            let players = realm.objects(Player.self)
            self.playerObjects = Array(players)
            print("readed")
           
        }
    }
    func saveVideoToDirectory(videoURL: URL) {
        let fileManager = FileManager.default
        
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let videosDirectory = documentsDirectory.appendingPathComponent("RapsodoVideos")
        
        // "RapsodoVideos" klasörü yoksa, oluşturun
        if !fileManager.fileExists(atPath: videosDirectory.path) {
            do {
                try fileManager.createDirectory(at: videosDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("RapsodoVideos klasörü oluşmadı")
                return
            }
        }
        let outputURL = videosDirectory.appendingPathComponent("\(shotId).mov")
        finalURL = outputURL
        // Kameradan kaydedilen videonun URL'sini "RapsodoVideos" klasörüne kopyalayın
        do {
            try fileManager.moveItem(at: videoURL, to: outputURL)
            
            print("kaydedildi \(outputURL)")
            
            //playerObjects[indexSection].shots[indexRow].videoURL = outputURL.absoluteString
            saveToRealmURL(playerObjects: playerObjects, URL: outputURL.absoluteString)
            
        } catch {
            print("Paths:\(outputURL)")
            print("Hata: URLye kaydedilemedi.")
        }
    }
    
    // AVCaptureSession başlatma
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue(label: "session queue").async {
            self.captureSession.startRunning()
        }
        
    }
    
    // AVCaptureSession durdurma
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isRecording {
            movieFileOutput.stopRecording()
            isRecording = false
        }
        captureSession.stopRunning()
    }
    
    func processVideo(url: URL,indexSection: Int, indexRow: Int){
        
        //var returnedURL: URL
        if let item = MediaItem(url: url) {
            let itemHeightSize = item.size.height
            
            let pointValue = String(playerObjects[indexSection].shots[indexRow].point)
            let attributes = [ NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: itemHeightSize/11) ]
            let attrStr = NSAttributedString(string: pointValue, attributes: attributes)
            let pointElement = MediaElement(text: attrStr)
            pointElement.frame = CGRect(x: item.size.width - item.size.width/4 + item.size.width/24  , y: item.size.height/1.25, width: item.size.width/5, height: itemHeightSize/11)
            
            let pointStr = "Point"
            let pointAttributes = [ NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: itemHeightSize/31) ]
            let pointAttrStr = NSAttributedString(string: pointStr, attributes: pointAttributes)
            let pointStrElement = MediaElement(text: pointAttrStr)
            pointStrElement.frame = CGRect(x: item.size.width - item.size.width/4 + item.size.width/22  , y: item.size.height/1.35, width: item.size.width/5, height: itemHeightSize/31)
            
            let segmentValue = String(playerObjects[indexSection].shots[indexRow].segment)
            let attributes2 = [ NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: itemHeightSize/11) ]
            let attrStr2 = NSAttributedString(string: segmentValue, attributes: attributes2)
            let segmentElement = MediaElement(text: attrStr2)
            segmentElement.frame = CGRect(x: item.size.width - item.size.width/4 + item.size.width/24  , y: item.size.height/1.6, width: item.size.width/5, height: itemHeightSize/11)
            
            let segmentStr = "Segment"
            let segmentAttributes = [ NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: itemHeightSize/36) ]
            let segmenttAttrStr = NSAttributedString(string: segmentStr, attributes: segmentAttributes)
            let segmentStrElement = MediaElement(text: segmenttAttrStr)
            segmentStrElement.frame = CGRect(x: item.size.width - item.size.width/4 + item.size.width/22  , y: 4*item.size.height/7, width: item.size.width/5, height: itemHeightSize/31)
        
            var inOutValue = ""
            if playerObjects[indexSection].shots[indexRow].InOut {
                inOutValue = "In"
            } else {
                inOutValue = "Out"
            }
            let attributes3 = [ NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: itemHeightSize/16) ]
            let attrStr3 = NSAttributedString(string: inOutValue, attributes: attributes3)
            let inOutElement = MediaElement(text: attrStr3)
            inOutElement.frame = CGRect(x: item.size.width - item.size.width/4 + item.size.width/22  , y: 3*item.size.height/7, width: item.size.width/5, height: itemHeightSize/11)
            
            let xPosValue = String(round(playerObjects[indexSection].shots[indexRow].ShotPosX * 1000)/1000)
            let attributes4 = [ NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: itemHeightSize/34) ]
            let attrStr4 = NSAttributedString(string: xPosValue, attributes: attributes4)
            let xPosElement = MediaElement(text: attrStr4)
            xPosElement.frame = CGRect(x: item.size.width - item.size.width/4 + item.size.width/24  , y: item.size.height/3, width: item.size.width/4, height: itemHeightSize/30)
            
            let xPostStr = "X Pos"
            let xPosAttributes = [ NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: itemHeightSize/31) ]
            let xPosAttrStr = NSAttributedString(string: xPostStr, attributes: xPosAttributes)
            let xPosStrElement = MediaElement(text: xPosAttrStr)
            xPosStrElement.frame = CGRect(x: item.size.width - item.size.width/4 + item.size.width/16  , y: item.size.height/3.5, width: item.size.width/5, height: itemHeightSize/31)
            
            let yPosValue = String(round(playerObjects[indexSection].shots[indexRow].ShotPosY * 1000)/1000)
            let attributes5 = [ NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: itemHeightSize/34) ]
            let attrStr5 = NSAttributedString(string: yPosValue, attributes: attributes5)
            let yPosElement = MediaElement(text: attrStr5)
            yPosElement.frame = CGRect(x: item.size.width - item.size.width/4 + item.size.width/24  , y: item.size.height/6, width: item.size.width/5, height: itemHeightSize/31)
            
            let yPostStr = "Y Pos"
            let yPosAttributes = [ NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: itemHeightSize/31) ]
            let yPosAttrStr = NSAttributedString(string: yPostStr, attributes: yPosAttributes)
            let yPosStrElement = MediaElement(text: yPosAttrStr)
            yPosStrElement.frame = CGRect(x: item.size.width - item.size.width/4 + item.size.width/16  , y: item.size.height/20, width: item.size.width/5, height: itemHeightSize/11)
            
            let blackImage = UIImage(named: "black")
            let transparentColor = UIColor.white.withAlphaComponent(0.5)
            let transparentImage = blackImage?.imageWithAlpha(alpha: 0.7, backgroundColor: transparentColor)
            let backElement = MediaElement(image: transparentImage!)
            backElement.frame = CGRect(x: item.size.width - item.size.width/4 , y: 0, width: item.size.width/4, height: item.size.height)
            
            item.add(elements: [ backElement,pointElement, pointStrElement,segmentElement, segmentStrElement,inOutElement, xPosElement, xPosStrElement, yPosElement, yPosStrElement])
            
            let mediaProcessor = MediaProcessor()
            
            mediaProcessor.processElements(item: item) { result, error in
                DispatchQueue.main.async { [self] in
                    if let error = error {
                        // Hata durumunda yapılacak işlemler
                        print("Hata: ", error.localizedDescription)
                    } else if let processedUrl = result.processedUrl {
                        // Başarılı durumda yapılacak işlemler
                        self.finalURL = processedUrl
                        self.saveVideoToDirectory(videoURL: processedUrl)
                        self.performSegue(withIdentifier: "recordOverSegue", sender: nil)
                    }
                }
            }
        }
        
    }
    
}
extension UIImage {
    func imageWithAlpha(alpha: CGFloat, backgroundColor: UIColor? = nil) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        guard let ctx = UIGraphicsGetCurrentContext(), let _ = cgImage else { return nil }
        
        let rect = CGRect(origin: .zero, size: size)
        backgroundColor?.setFill()
        ctx.fill(rect)
        
        draw(in: rect, blendMode: .normal, alpha: alpha)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
/*
 // MARK: - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
 // Get the new view controller using segue.destination.
 // Pass the selected object to the new view controller.
 }
 */
