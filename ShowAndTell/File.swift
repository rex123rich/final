    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh_TW"))!

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?

    private var recognitionTask: SFSpeechRecognitionTask?

    private let audioEngine = AVAudioEngine()


    @IBOutlet weak var textview: UITextView!
    //
    @IBOutlet weak var recordbutton: UIButton!
    // MARK: View Controller Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Disable the record buttons until authorization has been granted.
        recordbutton.isEnabled = false
    }

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
                    self.recordbutton.isEnabled = true
                    
                case .denied:
                    self.recordbutton.isEnabled = false
                    self.recordbutton.setTitle("User denied access to speech recognition", for: .disabled)
                    
                case .restricted:
                    self.recordbutton.isEnabled = false
                    self.recordbutton.setTitle("Speech recognition restricted on this device", for: .disabled)
                    
                case .notDetermined:
                    self.recordbutton.isEnabled = false
                    self.recordbutton.setTitle("Speech recognition not yet authorized", for: .disabled)
                    
                default:
                    self.recordbutton.isEnabled = false
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
                self.textView.text = result.bestTranscription.formattedString
                isFinal = result.isFinal
                print("Text \(result.bestTranscription.formattedString)")
            }
            
            if error != nil || isFinal {
                // Stop recognizing speech if there is a problem.
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.recognitionRequest = nil
                self.recognitionTask = nil

                self.recordbutton.isEnabled = true
                self.recordbutton.setTitle("Start Recording", for: [])
            }
        }

        // Configure the microphone input.
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        // Let the user know to start talking.
        textView.text = "(Go ahead, I'm listening)"
    }

    // MARK: SFSpeechRecognizerDelegate

    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            recordbutton.isEnabled = true
            recordbutton.setTitle("Start Recording", for: [])
        } else {
            recordbutton.isEnabled = false
            recordbutton.setTitle("Recognition Not Available", for: .disabled)
        }
    }

    // MARK: Interface Builder actions

    @IBAction func recordButtonTapped() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recordbutton.isEnabled = false
            recordbutton.setTitle("Stopping", for: .disabled)
        } else {
            do {
                try startRecording()
                recordbutton.setTitle("Stop Recording", for: [])
            } catch {
                recordbutton.setTitle("Recording Not Available", for: [])
            }
        }
    }

    // Keep a reference to the download progress so you can check that the model
    // is available before you use it.
    //----------------------------------------------------
