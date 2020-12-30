//
//  Speech.swift
//  ShowAndTell
//
//  Created by 張瑋恩 on 2020/12/15.
//  Copyright © 2020 Tsao. All rights reserved.
//

import Foundation
import Speech
@IBDesignable
class speechView: SFSpeechRecognizerDelegate {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh_TW"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    
    
    
    
    
}
