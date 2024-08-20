//
//  ToggleView.swift
//  MeetingTool
//
//  Created by 陳劭任 on 2022/10/3.
//

import Cocoa

class ToggleView: NSView {

    @IBOutlet private var noiseReductionSwitch: NSSwitch!
    
    @IBOutlet private var echoCancellationSwitch: NSSwitch!
    
    @objc dynamic var isNoiseReductionOn: Bool = false
    
    @objc dynamic var isEchoCancellationOn: Bool = false
    
    @IBAction private func noiseReductionToggled(_ sender: VQESwitch) {
        
        self.isNoiseReductionOn = sender.state.rawValue != 0
        
    }
    
    @IBAction private func echoCancellationToggled(_ sender: VQESwitch) {
        
        self.isEchoCancellationOn = sender.state.rawValue != 0
        
    }
    
    private func disableNRToggle() {
        
        self.turnOffNRSwitch()
        
        self.noiseReductionSwitch.isEnabled = false
        
    }
    
    internal func disableECToggle() {
        
        self.turnOffECSwitch()
        
        self.echoCancellationSwitch.isEnabled = false
        
    }
    
    private func enableNRToggle() {
        
        self.noiseReductionSwitch.isEnabled = true
        
    }
    
    internal func enableECToggle() {
        
        self.echoCancellationSwitch.isEnabled = true
        
    }
    
    internal func disableAllToggle() {
        
        self.disableNRToggle()
        
        self.disableECToggle()
        
    }
    
    internal func enableAllToggle() {
        
        self.enableNRToggle()
        
        self.enableECToggle()
        
    }
    
    internal func turnOffNRSwitch() {
        
        self.noiseReductionSwitch.state = .off
        
    }
    
    internal func turnOffECSwitch() {
        
        self.echoCancellationSwitch.state = .off
        
    }
}

class VQESwitch: NSSwitch {

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
    
}
