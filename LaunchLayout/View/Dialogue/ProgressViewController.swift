//
//  ProgressViewController.swift
//  MeetingTool
//
//  Created by 陳劭任 on 2022/7/4.
//

import Cocoa

class ProgressViewController: NSViewController {

    @IBOutlet var indicator: NSProgressIndicator!
    
    @IBOutlet var messageLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.indicator.startAnimation(self)
        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
    }
    
}

extension ProgressViewController: LaunchMessageDelegate {
    
    func showMessage(msg: String) {
        
        if !Thread.current.isMainThread {
            
            DispatchQueue.main.async {
                
                self.messageLabel.stringValue = msg

            }
            
            return
            
        }
        
        self.messageLabel.stringValue = msg
        
    }
    
}
