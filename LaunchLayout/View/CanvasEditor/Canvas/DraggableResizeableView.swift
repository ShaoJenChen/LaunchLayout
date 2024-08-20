//
//  DraggableResizeableView.swift
//  TestMouseEvent
//
//  Created by 陳劭任 on 2022/4/22.
//

import Cocoa

enum CornerBorderPosition {
    case topLeft, topRight, bottomRight, bottomLeft
    case top, left, right, bottom
    case none
}

class DraggableResizableView: VSTrackingView {
    
    private let resizableArea: CGFloat = 5
    
    private var cursorPosition: CornerBorderPosition = .none {
        didSet {
            switch self.cursorPosition {
            case .bottomRight, .topLeft:
                NSCursor(image:
                            NSImage(byReferencingFile: "/System/Library/Frameworks/WebKit.framework/Versions/Current/Frameworks/WebCore.framework/Resources/northWestSouthEastResizeCursor.png")!,
                         hotSpot: NSPoint(x: 8, y: 8)).set()
            case .bottomLeft, .topRight:
                NSCursor(image:
                            NSImage(byReferencingFile: "/System/Library/Frameworks/WebKit.framework/Versions/A/Frameworks/WebCore.framework/Versions/A/Resources/northEastSouthWestResizeCursor.png")!,
                         hotSpot: NSPoint(x: 8, y: 8)).set()
            case .top, .bottom:
                NSCursor.resizeUpDown.set()
            case .left, .right:
                NSCursor.resizeLeftRight.set()
            case .none:
                NSCursor.openHand.set()
            }
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        self.wantsLayer = true
        
        self.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.75).cgColor
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func mouseExited(with event: NSEvent) {
        NSCursor.arrow.set()
    }
    
    override func mouseMoved(with event: NSEvent) {
        
        let locationInView = convert(event.locationInWindow, from: nil)
        
        self.cursorPosition = self.cursorCornerBorderPosition(locationInView)
    }
    
    override func mouseDragged(with event: NSEvent) {
        
        guard let rectChecker = superview as? CanvasView else { return }
        
        let deltaX = event.deltaX
        let deltaY = event.deltaY
        
        switch self.cursorPosition {
        case .topLeft:
            if rectChecker.isValidWidth(width: self.frame.size.width - deltaX),
               rectChecker.isValidHeight(height: self.frame.size.height - deltaY),
               rectChecker.isGreaterMinX(x: self.frame.origin.x + deltaX),
               rectChecker.isLessMaxY(y: self.frame.origin.y + self.frame.height - deltaY) {
                
                self.frame.size.width -= deltaX
                
                self.frame.size.height -= deltaY
                
                self.frame.origin.x += deltaX
                
            }
        case .bottomLeft:
            if rectChecker.isValidWidth(width: self.frame.size.width - deltaX),
               rectChecker.isValidHeight(height: self.frame.size.height + deltaY),
               rectChecker.isGreaterMinX(x: self.frame.origin.x + deltaX),
               rectChecker.isGreaterMinY(y: self.frame.origin.y - deltaY) {
                
                self.frame.origin.x += deltaX
                
                self.frame.origin.y -= deltaY
                
                self.frame.size.width -= deltaX
                
                self.frame.size.height += deltaY
                
            }
        case .topRight:
            if rectChecker.isValidWidth(width: self.frame.size.width + deltaX),
               rectChecker.isValidHeight(height: self.frame.size.height - deltaY),
               rectChecker.isLessMaxX(x: self.frame.origin.x + self.frame.width + deltaX),
               rectChecker.isLessMaxY(y: self.frame.origin.y + self.frame.height - deltaY) {
                
                self.frame.size.width += deltaX
                
                self.frame.size.height -= deltaY
                
            }
        case  .bottomRight:
            if rectChecker.isValidWidth(width: self.frame.size.width + deltaX),
               rectChecker.isValidHeight(height: self.frame.size.height + deltaY),
               rectChecker.isLessMaxX(x: self.frame.origin.x + self.frame.width + deltaX),
               rectChecker.isGreaterMinY(y: self.frame.origin.y - deltaY) {
                
                self.frame.origin.y -= deltaY
                
                self.frame.size.width += deltaX
                
                self.frame.size.height += deltaY
                
            }
        case .top:
            if rectChecker.isValidHeight(height: self.frame.size.height - deltaY),
               rectChecker.isLessMaxY(y: self.frame.origin.y + self.frame.height - deltaY) {
                
                self.frame.size.height -= deltaY
                
            }
        case .bottom:
            if rectChecker.isValidHeight(height: self.frame.size.height + deltaY),
               rectChecker.isGreaterMinY(y: self.frame.origin.y - deltaY) {
                
                self.frame.size.height += deltaY
                
                self.frame.origin.y -= deltaY
                
            }
        case .left:
            if rectChecker.isValidWidth(width: self.frame.size.width - deltaX),
               rectChecker.isGreaterMinX(x: self.frame.origin.x + deltaX) {
                
                self.frame.size.width -= deltaX
                
                self.frame.origin.x += deltaX
                
            }
        case .right:
            if rectChecker.isValidWidth(width: self.frame.size.width + deltaX),
               rectChecker.isLessMaxX(x: self.frame.origin.x + self.frame.size.width + deltaX) {
                
                self.frame.size.width += deltaX
                
            }
        case .none:
            self.frame.origin.x += deltaX
            self.frame.origin.y -= deltaY
        }
        
        self.repositionView()
        
    }
    
    @discardableResult
    private func cursorCornerBorderPosition(_ locationInView: CGPoint) -> CornerBorderPosition {
        
        if locationInView.x < resizableArea,
           locationInView.y < resizableArea {
            return .bottomLeft
        }
        if self.bounds.width - locationInView.x < resizableArea,
           locationInView.y < resizableArea {
            return .bottomRight
        }
        if locationInView.x < resizableArea,
           self.bounds.height - locationInView.y < resizableArea {
            return .topLeft
        }
        if self.bounds.height - locationInView.y < resizableArea,
           self.bounds.width - locationInView.x < resizableArea {
            return .topRight
        }
        if locationInView.x < resizableArea {
            return .left
        }
        if self.bounds.width - locationInView.x < resizableArea {
            return .right
        }
        if locationInView.y < resizableArea {
            return .bottom
        }
        if self.bounds.height - locationInView.y < resizableArea {
            return .top
        }
        
        return .none
    }
    
    private func repositionView() {
        
        guard let superView = superview else { return }
        
        if self.frame.minX < superView.frame.minX {
            self.frame.origin.x = superView.frame.minX
        }
        if self.frame.minY < superView.frame.minY {
            self.frame.origin.y = superView.frame.minY
        }
        
        if self.frame.maxX > superView.frame.maxX {
            self.frame.origin.x = superView.frame.maxX - self.frame.size.width
        }
        if self.frame.maxY > superView.frame.maxY {
            self.frame.origin.y = superView.frame.maxY - self.frame.size.height
        }
    }
}
