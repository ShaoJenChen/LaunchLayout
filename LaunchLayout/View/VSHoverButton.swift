//
//  VSHoverButton.swift
//  MeetingTool
//
//  Created by 陳劭任 on 2022/8/3.
//

import Cocoa

enum HoverState {
    
    case Hover
    
    case NotHover
    
}

class VSHoverButton: NSButton {

    fileprivate var hoverState: HoverState = .NotHover {
        
        didSet {
            var paletteColors = [NSColor]()
            
            switch hoverState {
            case .Hover:
                paletteColors = [.white, .systemGray.withAlphaComponent(1)]
                NSCursor.arrow.set()
            case .NotHover:
                paletteColors = [.white, .systemGray.withAlphaComponent(0.5)]
            }
            
            let config = NSImage.SymbolConfiguration(paletteColors: paletteColors)
            
            self.image = NSImage(systemSymbolName: "xmark.circle.fill",
                                 accessibilityDescription: nil)?.withSymbolConfiguration(config)
        }
        
    }
    
}

class ItemDeleteBtn: VSHoverButton {
    
    func setHover(_ isHover: Bool) {
        
        self.hoverState = isHover ? .Hover : .NotHover

    }
    
}

class LayoutObjectRectCloseBtn: VSHoverButton {
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        self.target = self
        
        self.action = #selector(self.clickClose(sender:))
        
        self.imagePosition = .imageOnly
        
        self.imageScaling = .scaleProportionallyUpOrDown
        
        self.isBordered = false
        
        self.isTransparent = false
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func clickClose(sender: LayoutObjectRectCloseBtn) {
        
        guard let layoutObjectRectangle = superview as? LayoutObjectRectangle else { return }
        
        layoutObjectRectangle.remove()
        
    }
    
    func setCloseBtnHover(isHover: Bool) {
        
        self.hoverState = isHover ? .Hover : .NotHover
        
        if isHover { NSCursor.arrow.set() }

    }
    
}

class PointingBtn: VSTrackingBtn {
    
    override func mouseMoved(with event: NSEvent) {
        
        NSCursor.pointingHand.set()
        
    }
    
    override func mouseExited(with event: NSEvent) {
        
        NSCursor.arrow.set()
    }
}
