//
//  AlertGenerator.swift
//  MeetingTool
//
//  Created by 陳劭任 on 2022/10/25.
//

import Cocoa

class AlertGenerator {
    
    class func launchAlertInMainThread(with message: String, icon: NSImage? = nil) {
        
        func showAlert() {
            
            let alert = NSAlert()
            
            alert.messageText = message
            
            alert.alertStyle = .warning
            
            alert.icon = icon
            
            let okBtn = alert.addButton(withTitle: "OK")
            
            okBtn.bezelColor = NSColor(hex: 0xB0D9F0)
            
            NSRunningApplication.current.activate(options: .activateIgnoringOtherApps)
            
            alert.runModal()
            
        }
        
        guard Thread.isMainThread else { DispatchQueue.main.async { showAlert() }; return }
        
        showAlert()
    }
    
    class func launchAlert(with message: String) -> NSApplication.ModalResponse {
        
        let alert = NSAlert()
        
        alert.messageText = message
        
        alert.alertStyle = .critical
        
        let okBtn = alert.addButton(withTitle: "OK")
        
        okBtn.bezelColor = NSColor(hex: 0xB0D9F0)
        
        alert.addButton(withTitle: "Cancel")
        
        NSRunningApplication.current.activate(options: .activateIgnoringOtherApps)
        
        let response = alert.runModal()
        
        //1000 means confirm, 1001 means cancel.
        return response
        
    }
    
}
