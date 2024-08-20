//
//  UserInterectionDisabledImageView.swift
//  TestMouseEvent
//
//  Created by 陳劭任 on 2022/4/21.
//

import Cocoa

class UserInteractionDisabledImageView: NSImageView {
    
    override init(frame frameRect: NSRect) {
        
        super.init(frame: frameRect)
        
        self.image = NSImage(named: "corner_Arrow")
        
        self.imageScaling = .scaleAxesIndependently
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }
}
