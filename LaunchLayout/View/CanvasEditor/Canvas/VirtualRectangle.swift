//
//  VirtualRectangle.swift
//  TestMouseEvent
//
//  Created by 陳劭任 on 2022/3/23.
//

import Cocoa

class VirtualRectangle: ColoredView {

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    convenience init(frame frameRect: NSRect, color: NSColor) {
        self.init(frame: frameRect)
        self.backgroundColor = color.withAlphaComponent(0.1)
        self.wantsLayer = true
        self.layer?.borderWidth = 2
        self.layer?.borderColor = color.withAlphaComponent(0.5).cgColor
    }
}
