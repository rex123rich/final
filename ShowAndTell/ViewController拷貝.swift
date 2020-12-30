//
//  ViewController.swift
//  TestML
//
//  Created by Tsao on 2017/12/5.
//  Copyright © 2017年 Tsao. All rights reserved.
//

import UIKit
import Firebase
import CoreML
import AVFoundation
import Speech

let options = TranslatorOptions(sourceLanguage: .en, targetLanguage: .zh)
let englishGermanTranslator = NaturalLanguage.naturalLanguage().translator(options: options)
let frModel = TranslateRemoteModel.translateRemoteModel(language: .zh)
let progress = ModelManager.modelManager().download(frModel,conditions: ModelDownloadConditions(allowsCellularAccess: false,allowsBackgroundDownloading: true))

let localModels = ModelManager.modelManager().downloadedTranslateModels

class ViewController: UIViewController, SFSpeechRecognizerDelegate{
    var speechtextout:String=""
    var textbox:Array=["","",""]
    var text1:Array=["","",""]
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh_TW"))!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()
    
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        tap.isEnabled = false
    }
    
    @IBOutlet weak var buttonview: UILabel!
    @IBOutlet var tap: UITapGestureRecognizer!
    @IBOutlet weak var speechview: UITextView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    //-----------------------------------------------------------------
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Configure the SFSpeechRecognizer object already
        // stored in a local member variable.
        speechRecognizer.delegate = self
        
        // Asynchronously make the authorization request.
        SFSpeechRecognizer.requestAuthorization { authStatus in

            // Divert to the app's main thread so that the UI
            // can be updated.
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.tap.isEnabled = true
                    
                case .denied:
                    self.tap.isEnabled = false
                    self.buttonview.text = "User denied access to speech recognition"
                    
                case .restricted:
                    self.tap.isEnabled = false
                    self.buttonview.text = "Speech recognition restricted on this device"
                    
                case .notDetermined:
                    self.tap.isEnabled = false
                    self.buttonview.text = "Speech recognition not yet authorized"
                    
                default:
                    self.tap.isEnabled = false
                }
            }
        }
    }
    private func startRecording() throws {
        
        // Cancel the previous task if it's running.
        recognitionTask?.cancel()
        self.recognitionTask = nil
        
        // Configure the audio session for the app.
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        let inputNode = audioEngine.inputNode

        // Create and configure the speech recognition request.
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object") }
        recognitionRequest.shouldReportPartialResults = true
        
        // Keep speech recognition data on device
        if #available(iOS 13, *) {
            recognitionRequest.requiresOnDeviceRecognition = false
        }
        
        // Create a recognition task for the speech recognition session.
        // Keep a reference to the task so that it can be canceled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                // Update the text view with the results.
                self.speechview.text = result.bestTranscription.formattedString
                self.speechtextout = result.bestTranscription.formattedString
                isFinal = result.isFinal
                print("Text \(result.bestTranscription.formattedString)")
            }
            
            if error != nil || isFinal {
                // Stop recognizing speech if there is a problem.
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.recognitionRequest = nil
                self.recognitionTask = nil

                self.tap.isEnabled = true
                self.buttonview.text = "已經準備好開始聆聽"
                self.speak(x: "已經準備好開始聆聽")

                
                if self.speechtextout == "讀取" {
                    self.play()
                    self.speak(x: "讀取中")
                }else if self.speechtextout == "下一張" {
                    self.switchImage()
                    self.speak(x: "下一張")
                    self.play()
                }else if self.speechtextout == "瀏覽"{
                    self.takePhoto()
                    self.speak(x: "瀏覽")
                }
            }
        }
        // Configure the microphone input.
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        // Let the user know to start talking.
        speechtextout = ""
        speechview.text = "開始說吧,我正在聽"
        speak(x: "開始說吧 我正在聽")
        
        audioEngine.prepare()
        try audioEngine.start()
        
    }
    
    
    @IBAction func taptapped(_ sender: Any) {
        end()
        speechview.resignFirstResponder()
        textView.resignFirstResponder()
    }
    
    func end() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            tap.isEnabled = false
            self.buttonview.text = "Stopping"
        } else {
            do {
                try startRecording()
                self.buttonview.text = "正在聆聽"
            } catch {
                self.buttonview.text = "Recording Not Available"
            }
        }
    }
    // MARK: SFSpeechRecognizerDelegate
    
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            tap.isEnabled = true
            self.buttonview.text = "Start Recording"
        } else {
            tap.isEnabled = false
            self.buttonview.text = "Recognition Not Available"
        }
    }
    
    //--------------------------------------------------------------------
    let showAndTell = ShowAndTell()
    var currentImage: UIImage = UIImage(named: "COCO_train2014_000000005340.jpg")! {
        didSet {
            self.imageView.image = currentImage
        }
    }

   
    
    func switchImage() {
        var imgs = [ "COCO_train2014_000000005303.jpg",
          "COCO_train2014_000000005336.jpg",
          "COCO_train2014_000000005359.jpg",
          "COCO_train2014_000000005377.jpg",
          "COCO_train2014_000000005434.jpg",
          "COCO_train2014_000000005472.jpg",
          "COCO_train2014_000000005312.jpg",
          "COCO_train2014_000000005339.jpg",
          "COCO_train2014_000000005360.jpg",
          "COCO_train2014_000000005383.jpg",
          "COCO_train2014_000000005435.jpg",
          "COCO_train2014_000000005482.jpg",
          "COCO_train2014_000000005313.jpg",
          "COCO_train2014_000000005340.jpg",
          "COCO_train2014_000000005362.jpg",
          "COCO_train2014_000000005396.jpg",
          "COCO_train2014_000000005453.jpg",
          "COCO_train2014_000000005483.jpg",
          "COCO_train2014_000000005324.jpg",
          "COCO_train2014_000000005344.jpg",
          "COCO_train2014_000000005368.jpg",
          "COCO_train2014_000000005424.jpg",
          "COCO_train2014_000000005459.jpg",
          "COCO_train2014_000000005500.jpg",
          "COCO_train2014_000000005326.jpg",
          "COCO_train2014_000000005345.jpg",
          "COCO_train2014_000000005373.jpg",
          "COCO_train2014_000000005425.jpg",
          "COCO_train2014_000000005469.jpg",
          "COCO_train2014_000000005505.jpg",
          "COCO_train2014_000000005335.jpg",
          "COCO_train2014_000000005355.jpg",
          "COCO_train2014_000000005376.jpg",
          "COCO_train2014_000000005430.jpg",
          "COCO_train2014_000000005471.jpg" ]
        let random = Int(arc4random_uniform(UInt32(imgs.count)))
        self.currentImage = UIImage(named:imgs[random])!
    }
    func play() {
            textView.text = nil
            let Rate:Float=1.1
            var sum=1
            var textout:String=""
            let startTime = Date()
            let results = showAndTell.predict(image: self.currentImage, beamSize: 3, maxWordNumber: 30)
            
            NotificationCenter.default.addObserver(
                forName: .firebaseMLModelDownloadDidSucceed,
                object: nil,
                queue: nil
            ) { [weak self] notification in
                guard let strongSelf = self,
                    let userInfo = notification.userInfo,
                    let model = userInfo[ModelDownloadUserInfoKey.remoteModel.rawValue]
                        as? TranslateRemoteModel,
                    model == frModel
                    else { return }
                // The model was downloaded and is available on the device
            }


            NotificationCenter.default.addObserver(
                forName: .firebaseMLModelDownloadDidFail,
                object: nil,
                queue: nil
            ) { [weak self] notification in
                guard let strongSelf = self,
                    let userInfo = notification.userInfo,
                    let model = userInfo[ModelDownloadUserInfoKey.remoteModel.rawValue]
                        as? TranslateRemoteModel
                    else { return }
                let error = userInfo[ModelDownloadUserInfoKey.error.rawValue]
                // ...
            }
            
            let conditions = ModelDownloadConditions(
                allowsCellularAccess: false,
                allowsBackgroundDownloading: true
            )
            englishGermanTranslator.downloadModelIfNeeded(with: conditions) { error in
                guard error == nil else { return }

                // Model downloaded successfully. Okay to start translating.
            }
            
            //.......................
            GSMessage.showMessageAddedTo("Time elapsed：\(Date().timeIntervalSince(startTime) * 1000)ms", type: .info, options: nil, inView: self.view, inViewController: self)
            var index = -1
            text1 = results.sorted(by: {$0.score > $1.score}).map({
                
                var x = $0.readAbleSentence.suffix($0.readAbleSentence.count - 1)
                if $0.sentence.last == Caption.endID {
                    _ = x.removeLast()
                }
                if(sum == 1){
                    textout = String.init(x.joined(separator: " ").capitalizingFirstLetter())
                    sum=0
                    print(textout)
                }
                englishGermanTranslator.translate(String.init(x.joined(separator: " ").capitalizingFirstLetter())){translatedText, String in
                    guard String == nil,
                    let translatedText = translatedText
                    else { return }
                    //print(translatedText)
                    self.textView.text = translatedText
                    //print(self.textbox[sum2])
                    //sum2=sum2+1
                }
                index += 1
                print(speechtextout)
                print("1")
                print(textbox[index])
                return String.init(format: "Probability:%.3f‱ \n \(textbox[index])", pow(2, $0.score) * 10000.0)
            })//.joined(separator: "\n\n")
            
            //.......................
            
            speak(x: textbox[0])
            speechtextout = ""
            
        
        }
    func speak(x:String)  {
        let speach = AVSpeechUtterance(string: x)
        speach.voice = AVSpeechSynthesisVoice(language: "zh-TW")
        
        let synzer = AVSpeechSynthesizer()
        synzer.speak(speach)
    }
    
    
    
    func takePhoto() {
        self.getCameraOn(self, canEdit: false)
        speechtextout = ""
    }
    
    func getCameraOn(_ onVC: UIViewController, canEdit: Bool) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self as! UIImagePickerControllerDelegate & UINavigationControllerDelegate
            imagePicker.sourceType = .camera;
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerController.InfoKey.originalImage.rawValue] as! UIImage
        self.currentImage = image
        picker.dismiss(animated: true, completion: nil)
    }
}

extension String {
    func substring(_ from: Int) -> String {
        let start = index(startIndex, offsetBy: from)
        return String(self[start ..< endIndex])
    }
    
    func capitalizingFirstLetter() -> String {
        return prefix(1).uppercased() + dropFirst()
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}
