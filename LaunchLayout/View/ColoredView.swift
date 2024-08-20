//
//  ColoredView.swift
//  ColorProWheelConsole
//
//  Created by 陳劭任 on 2021/9/10.
//

import Cocoa

//@IBDesignable
class ColoredView: NSView {

    @IBInspectable var backgroundColor: NSColor = .windowBackgroundColor {
        
        didSet {
            
            self.needsDisplay = true
            
        }
        
    }
    
    override func draw(_ dirtyRect: NSRect) {
        
        super.draw(dirtyRect)
        
        self.backgroundColor.setFill()
        
        self.bounds.fill()
        
    }
    
}

class HiddenScroller: NSScroller {

    // @available(macOS 10.7, *)
    // let NSScroller tell NSScrollView that its own width is 0, so that it will not really occupy the drawing area.
    override class func scrollerWidth(for controlSize: ControlSize, scrollerStyle: Style) -> CGFloat {
        0
    }
    
}
