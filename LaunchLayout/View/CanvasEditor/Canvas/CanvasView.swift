//
//  CanvasView.swift
//  TestMouseEvent
//
//  Created by 陳劭任 on 2022/3/22.
//

import Cocoa
import SnapKit

fileprivate let virtualRectangleID = "virtualRectangle"

class CanvasView: VSTrackingView {
    
    internal var name: String
    
    private var mouseDownLocation: NSPoint?
    
    internal var viewModel: CanvasViewDataSource?
    
    lazy var backImageView: NSImageView = {
                
        let backImage = NSImage(named: "CanvasBackView")
        
        let imageView = NSImageView(frame: self.bounds)
        
        imageView.image = backImage
        
        imageView.imageScaling = .scaleProportionallyUpOrDown
        
        return imageView
        
    }()
    
    init(frame: NSRect, name: String, viewModel: CanvasViewDataSource? = nil) {
        
        self.name = name
        
        self.viewModel = viewModel
        
        super.init(frame: frame)
        
        self.wantsLayer = true

        self.layer?.backgroundColor = NSColor(hex: 0xF0F4F7).cgColor
        
        self.layer?.borderWidth = 0.5
        
        self.layer?.borderColor = NSColor(hex: 0x6B8AA5).withAlphaComponent(0.5).cgColor
                
        self.autoresizingMask = [.width, .height]
    }
    
    convenience init(duplicateCanvasView: CanvasView) {
        self.init(frame: duplicateCanvasView.frame,
                  name: duplicateCanvasView.name,
                  viewModel: duplicateCanvasView.viewModel)
        
        guard let layoutObjectRectangles = duplicateCanvasView.subviews.filter({ $0 is LayoutObjectRectangle }) as? [LayoutObjectRectangle] else { return }
        
        let newObjectRectangles = layoutObjectRectangles.map({
            LayoutObjectRectangle(duplicateRectangle: $0)
        })
        
        newObjectRectangles.forEach({
            
            self.addSubview($0)
            
            self.addObjectConstraint(object: $0)
            
        })
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layout() {
        super.layout()
                
        if self.backImageView.superview == nil {
            
            self.addSubview(self.backImageView)
            
            self.backImageView.snp.makeConstraints { make in
                
                make.leading.trailing.top.bottom.equalToSuperview()
                
            }
            
        }
        
        let rectViews = self.subviews.filter({ !($0 is NSImageView) })
                        
        self.backImageView.isHidden = rectViews.count > 0 ? true : false
        
    }
    
    override func mouseDown(with event: NSEvent) {
        
        self.mouseDownImpl(with: event)
        
        // We need to use a mouse-tracking loop as otherwise mouseUp events are not delivered when the mouse button is released outside the view.
        while true {
            guard let nextEvent = self.window?.nextEvent(matching:
                                                            [.leftMouseUp,
                                                             .leftMouseDragged,
                                                             .keyDown]) else { continue }
            let mouseLocation = self.convert(nextEvent.locationInWindow, from: nil)
            let isInside = self.bounds.contains(mouseLocation)
            
            switch nextEvent.type {
            case .leftMouseDragged:
                self.mouseDraggedImpl(with: nextEvent,
                                      mouseLocation: mouseLocation,
                                      isInside: isInside)
                
            case .leftMouseUp:
                self.mouseUpImpl(with: nextEvent,
                                 mouseLocation: mouseLocation,
                                 isInside: isInside)
                return
                
            case .keyDown:
                if nextEvent.keyCode == 53 {
                    print("pressed esc")
                    self.clearVirtualRectangles()
                    return
                }
            default:
                break
            }
        }
    }
    
    override func mouseMoved(with event: NSEvent) {
        
        let locationInView = convert(event.locationInWindow, from: nil)
        
        let layoutObjects = self.subviews.filter({ $0 is LayoutObjectRectangle })
        
        guard layoutObjects.lazy.filter({ NSPointInRect(locationInView, $0.frame) }).count == 0 else { return }
        
        NSCursor.crosshair.set()
    }
    
    override func mouseExited(with event: NSEvent) {
        
        NSCursor.arrow.set()
    }
    
    private func mouseDownImpl(with event: NSEvent) {
        print("mouseDown")
        self.window?.endEditing(for: nil)
        let mouseLocation = self.convert(event.locationInWindow, from: nil)
        print("mouse down location is \(mouseLocation)")
        self.mouseDownLocation = mouseLocation
        
    }
    
    private func mouseDraggedImpl(with event: NSEvent, mouseLocation: NSPoint, isInside: Bool) {
        print("mouseDrag isInside: \(isInside)")
        
        func virtualRectangle(with id: String, draggingLocation: NSPoint) -> VirtualRectangle? {
            
            guard let mouseDownLocation = mouseDownLocation else { return nil }
            
            var frame = NSRect(x: min(mouseDownLocation.x, draggingLocation.x),
                               y: min(mouseDownLocation.y, draggingLocation.y),
                               width: abs(mouseDownLocation.x - draggingLocation.x),
                               height: abs(mouseDownLocation.y - draggingLocation.y))
            
            if !self.bounds.contains(frame) {
                let virtualRect = NSRectToCGRect(frame)
                let canvasRect = NSRectToCGRect(self.bounds)
                let newRect = canvasRect.intersection(virtualRect)
                frame = NSRectFromCGRect(newRect)
            }
                        
            let color: NSColor = self.isValidWidth(width: frame.width) && self.isValidHeight(height: frame.height) ? .green : .red
            
            let virtualRect = VirtualRectangle(frame: frame,
                                               color: color)
            
            virtualRect.identifier = NSUserInterfaceItemIdentifier(id)
            
            return virtualRect
            
        }
        
        self.clearVirtualRectangles()
        
        if let newVirtualRectangle = virtualRectangle(with: virtualRectangleID,
                                                      draggingLocation: mouseLocation) {
            self.addSubview(newVirtualRectangle)
            
            self.addObjectConstraint(object: newVirtualRectangle)
        }
    }
    
    private func mouseUpImpl(with event: NSEvent, mouseLocation: NSPoint, isInside: Bool) {
        print("mouseUp isInside: \(isInside)")
        
        //1. 抓出目前在 Canvas 上的所有 layoutObject, 清除選取
        self.clearCurrentSelected()
        
        //2. 若有經過gragging 產生 virtual rectangle 需 pop up 詢問視窗
        guard let frame = self.getLastVirtualRectangle() else { return }
        
        guard frame.width >= self.bounds.width/3,
              frame.height >= self.bounds.height/3 else {
            self.clearVirtualRectangles()
            return
        }
        
        var layoutAppPath: String?
        var layoutFilePath: String?
        
        self.showDialogueAskingPaths(defaultAppPath: nil,
                                     defaultFilePath: nil,
                                     callbackPath: { (appPath: String?, filePath: String?) in
            layoutAppPath = appPath
            layoutFilePath = filePath
        },
                                     completionHandler: { response in
            //重新取得一次最新的，避免有拉動過視窗的大小，frame會有異動
            guard let frame = self.getLastVirtualRectangle() else { return }
            
            self.clearVirtualRectangles()
            
            switch response {
            case .OK:
                guard let appPath = layoutAppPath,
                      let filePath = layoutFilePath else { return }
                
                let layoutObject = LayoutObjectRectangle(appPath: appPath,
                                                         filePath: filePath,
                                                         frame: frame)
                
                self.addSubview(layoutObject)
                
                self.addObjectConstraint(object: layoutObject)
                
            case .cancel:
                break
            default:
                break
            }
        })
        
    }
    
    private func clearVirtualRectangles() {

        self.subviews.removeAll(where: { $0.identifier?.rawValue == virtualRectangleID })
        
        self.needsLayout = true
        
    }
    
    private func getLastVirtualRectangle() -> NSRect? {

        self.subviews.first(where: { $0.identifier?.rawValue == virtualRectangleID })?.frame
        
    }
    
    internal func clearCurrentSelected() {
        let _ = self.subviews.map({
            guard let layoutObject = $0 as? LayoutObjectRectangle else { return }
            
            layoutObject.removeSelection()
            
        })
    }
    
    internal func addObjectConstraint<T: NSView>(object: T) {
        
        let widthRatio = object.frame.width / self.bounds.width
        let heightRatio = object.frame.height / self.bounds.height
        
        let xRatio = (object.frame.origin.x + object.frame.width) / self.bounds.width
        let yRatio = (self.bounds.height - object.frame.origin.y) / self.bounds.height
        
        object.snp.makeConstraints { make in
            make.width.equalToSuperview().multipliedBy(widthRatio)
            make.height.equalToSuperview().multipliedBy(heightRatio)
            make.trailing.equalToSuperview().multipliedBy(xRatio)
            make.bottom.equalToSuperview().multipliedBy(yRatio)
        }
        
    }
    
    internal func updateConstraint(object: LayoutObjectRectangle, newRect: NSRect) {
        
        let widthRatio = newRect.width / self.bounds.width
        let heightRatio = newRect.height / self.bounds.height
        
        let xRatio = (newRect.origin.x + newRect.width) / self.bounds.width
        let yRatio = (self.bounds.height - newRect.origin.y) / self.bounds.height
        
        object.snp.remakeConstraints { make in
            make.width.equalToSuperview().multipliedBy(widthRatio)
            make.height.equalToSuperview().multipliedBy(heightRatio)
            make.trailing.equalToSuperview().multipliedBy(xRatio)
            make.bottom.equalToSuperview().multipliedBy(yRatio)
        }
        
    }
    
    internal func removeConstraint(object: LayoutObjectRectangle) {
        object.snp.removeConstraints()
    }
    
    internal func bringSubviewToFront(_ view: NSView) {
        var theView = view
        self.sortSubviews({(viewA,viewB,rawPointer) in
            let view = rawPointer?.load(as: NSView.self)
            
            switch view {
            case viewA:
                return ComparisonResult.orderedDescending
            case viewB:
                return ComparisonResult.orderedAscending
            default:
                return ComparisonResult.orderedSame
            }
        }, context: &theView)
    }
    
    internal func showDialogueAskingPaths(defaultAppPath: String?,
                                          defaultFilePath: String?,
                                          callbackPath: ((String?, String?) -> Void)?,
                                          completionHandler: ((NSApplication.ModalResponse) -> Void)?) {
        
        guard let dialogueWindowController = DialogueManager.shared.dialogueWindowController(dialogueType: .LayoutObjectOnCanvas),
              let dialogueWindow = dialogueWindowController.window
        else { return }
        
        guard let layoutObjectDialogue = dialogueWindowController.contentViewController
                as? LayoutObjectDialogueViewController else { return }
        
        layoutObjectDialogue.currentLayoutObjectURLs = self.getCurrentURLs()
        
        if let appPath = defaultAppPath, let filePath = defaultFilePath {
            layoutObjectDialogue.setDefault(appPath: appPath, filePath: filePath)
        }
        
        if let callbackPath = callbackPath {
            layoutObjectDialogue.callBackPath = callbackPath
        }
        
        self.window?.beginSheet(dialogueWindow, completionHandler: completionHandler)
    }
    
    private func getCurrentURLs() -> [URL]? {
        
        return self.viewModel?.currentRecordCanvasViews().flatMap({ canvasViews -> [URL] in
            
            let rectangles = canvasViews.flatMap({ $0.subviews.filter({$0 is LayoutObjectRectangle})}) as! [LayoutObjectRectangle]
            
            return rectangles.compactMap { rectangle -> URL? in
                
                guard let filePath = rectangle.filePath else { return nil }
                
                return URL(fileURLWithPath: filePath)
            }
            
        })
        
    }
    
    deinit {
        print("canvas view deinit")
    }
}

protocol RectChecker {
    
    func isValidWidth(width: CGFloat) -> Bool
    
    func isValidHeight(height: CGFloat) -> Bool
    
    func isGreaterMinX(x: CGFloat) -> Bool
    
    func isGreaterMinY(y: CGFloat) -> Bool
    
    func isLessMaxX(x: CGFloat) -> Bool
    
    func isLessMaxY(y: CGFloat) -> Bool
}

extension CanvasView: RectChecker {
    
    func isValidWidth(width: CGFloat) -> Bool {
        
        return self.frame.width/3 ... self.frame.width ~= width
        
    }
    
    func isValidHeight(height: CGFloat) -> Bool {
        
        return self.frame.height/3 ... self.frame.height ~= height
        
    }
    
    func isGreaterMinX(x: CGFloat) -> Bool {
        
        return x >= self.frame.minX
        
    }
    
    func isGreaterMinY(y: CGFloat) -> Bool {
        
        return y >= self.frame.minY
        
    }
    
    func isLessMaxX(x: CGFloat) -> Bool {
        
        return x <= self.frame.maxX
        
    }
    
    func isLessMaxY(y: CGFloat) -> Bool {
        
        return y <= self.frame.maxY
        
    }
    
}
