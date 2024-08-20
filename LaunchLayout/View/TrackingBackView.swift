//
//  MeetingItemBackView.swift
//  MeetingTool
//
//  Created by 陳劭任 on 2022/8/5.
//

import Cocoa

class TrackingBackView: VSTrackingView {
    
    @objc dynamic var isHover: Bool = false {
        
        didSet { isHover ? NSCursor.pointingHand.set() : NSCursor.arrow.set() }
        
    }
    
    @objc dynamic var hoverPoint: NSPoint = .zero
    
    override func rightMouseDown(with event: NSEvent) {
        
        guard let menu = self.menu else { return }
        
        let popUpPoint = self.convert(event.locationInWindow, from: nil)
        
        menu.popUp(positioning: nil, at: popUpPoint, in: self)
                
    }
    
    override func mouseMoved(with event: NSEvent) {
        
        self.isHover = true
        
        self.hoverPoint = convert(event.locationInWindow, from: nil)
    }
    
    override func mouseExited(with event: NSEvent) {
        
        self.isHover = false
    }
    
}
