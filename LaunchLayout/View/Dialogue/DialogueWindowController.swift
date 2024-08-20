//
//  DialogueWindowController.swift
//  TestMouseEvent
//
//  Created by 陳劭任 on 2022/3/26.
//

import Cocoa

class DialogueWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
        
        self.window?.styleMask.remove(.resizable)
        
    }
    
}
