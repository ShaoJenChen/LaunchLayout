//
//  LogoView.swift
//  ColorProWheelConsole
//
//  Created by 陳劭任 on 2021/12/3.
//

import Cocoa

//@IBDesignable
class LogoView: NSView {
    
    @IBInspectable var backgroundColor: NSColor? {
        didSet { needsDisplay = true }
    }
    
    override var wantsUpdateLayer: Bool {
        return true
    }
    
    override func updateLayer() {
        guard let layer = layer else { return }
        layer.backgroundColor = backgroundColor?.cgColor
    }
}
