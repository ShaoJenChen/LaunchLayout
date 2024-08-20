//
//  AudioManager.swift
//  MeetingTool
//
//  Created by 陳劭任 on 2022/10/20.
//

import Cocoa
import AVFoundation
import SimplyCoreAudio

protocol VQEProtocol {
    
    func getSpeakerList() -> [String]
    
    func getMicrophoneList() -> [String]
    
    func noiseReductionStart(speakerIndex: Int32)
    
    func noiseReductionStop()
    
    func echoCancellationStart(speakerIndex: Int32, microphoneIndex: Int32)
    
    func echoCancellationStop()
    
    func observeDeviceChanged(_ observer: @escaping (([String], [String]) -> Void))
}

class AudioManager: VQEProtocol {
    
    private var vqeWrapper: VoiceQualityEnhancementWrapper?
    
    private let simply = SimplyCoreAudio()
    
    private var observers = [NSObjectProtocol]()
    
    init?() async {
        //init VQE Wrapper
        async let isGranted = await AVCaptureDevice.requestAccess(for: .audio)
        
        guard await isGranted else { return nil }
        
        print("isGranted \(await isGranted)")
        
        self.vqeWrapper = VoiceQualityEnhancementWrapper()
    }
    
    func noiseReductionStart(speakerIndex: Int32) {
        
        self.vqeWrapper?.startNoiseReductionSpeaker(speakerIndex)
        
    }
    
    func noiseReductionStop() {
        
        self.vqeWrapper?.stopNoiseReductionSpeaker()
        
    }
    
    func echoCancellationStart(speakerIndex: Int32, microphoneIndex: Int32) {
        
        self.vqeWrapper?.startNoiseReductionMic(speakerIndex, forMic: microphoneIndex)
        
    }
    
    func echoCancellationStop() {
        
        self.vqeWrapper?.stopNoiseReductionMic()
        
    }
    
    func getSpeakerList() -> [String] {
        
        return self.vqeWrapper?.getOutputSpkList(true) as! [String]
        
    }
    
    func getMicrophoneList() -> [String] {
        
        return self.vqeWrapper?.getInputMicList(true) as! [String]
        
    }
    
    func observeDeviceChanged(_ observer: @escaping (([String], [String]) -> Void)) {
        
        let newObserver = NotificationCenter.default.addObserver(forName: .deviceListChanged,
                                                                 object: nil,
                                                                 queue: .main,
                                                                 using: { notification in
                        
            NSLog("observed deviceListChanged!")
            
            guard let addedDevices = notification.userInfo?["addedDevices"] as? [AudioDevice] else { return }
            
            guard let removedDevices = notification.userInfo?["removedDevices"] as? [AudioDevice] else { return }
            
            observer(addedDevices.map({$0.name}), removedDevices.map({$0.name}))
            
        })
                                                                 
        self.observers.append(newObserver)
    }
 
    deinit {
        print("AudioManager deinit")
        self.observers.forEach({ NotificationCenter.default.removeObserver($0) })
        
    }
}
