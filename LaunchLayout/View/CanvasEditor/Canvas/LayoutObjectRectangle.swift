//
//  LayoutObjectRectangle.swift
//  TestMouseEvent
//
//  Created by 陳劭任 on 2022/3/22.
//

import Cocoa

class LayoutObjectRectangle: DraggableResizableView {
    
    private var keyMonitor: Any?
    
    var appPath: String?
    
    var filePath: String? {
        
        didSet {
            guard let filePath = filePath else { return }

            ThumbNailGenerator.generateThumbnailRepresentations(filePath: filePath) { thumbnail in
                
                guard let thumbnail = thumbnail else { return }
                
                self.thumbnailImageView.image = thumbnail.nsImage

            }
            guard let iconImageView = self.fileIconImageView else { return }
            
            iconImageView.image = NSWorkspace.shared.icon(forFile: filePath)
            
            self.replaceFilePathLabel(with: filePath)
            
        }
    }
    
    private var thumbnailImageView: NSImageView!
    
    private var closeBtn: LayoutObjectRectCloseBtn!
    
    private var fileNameLbl: NSTextField!
    
    private var fileIconImageView: NSImageView!
    
    override var frame: NSRect {
        didSet {
            self.setSubviewItemsFrame()
        }
    }
    
    init(appPath: String, filePath: String, frame: CGRect) {
        
        super.init(frame: frame)
        
        //init with another function, to trigger property didSet observe
        self.initProperty(appPath: appPath, filePath: filePath)
        
        self.setDefaultBorder()
        
        self.addSubviewItems()
        
        self.setSubviewItemsFrame()
        
    }
    
    convenience init(duplicateRectangle: LayoutObjectRectangle) {
        
        guard let appPath = duplicateRectangle.appPath,
              let filePath = duplicateRectangle.filePath else {
            fatalError("LayoutObjectRectangle should not with app Path or file Path nil!!")
        }
        
        self.init(appPath: appPath,
                  filePath: filePath,
                  frame: duplicateRectangle.frame)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func mouseDown(with event: NSEvent) {
        
        guard event.clickCount == 1 else { return }
        
        self.window?.endEditing(for: nil)
        
        self.removeConstraint()
        
        //需先將canvas上的其他 LayoutObject 清除 monitor
        self.clearSelectedOnCanvas()
        
        self.addSelection()
        
//        print("LayoutObject appPath => \(self.appPath)")
//        print("LayoutObject filePath => \(self.filePath)")
        
    }
    
    override func mouseUp(with event: NSEvent) {
        
        if event.clickCount == 2 {
            print("double click LayoutObjectRect")
            
            guard let canvasView = self.superview as? CanvasView else { return }
            
            canvasView.showDialogueAskingPaths(defaultAppPath: self.appPath,
                                               defaultFilePath: self.filePath,
                                               callbackPath: { appPath, filePath in
                guard let appPath = appPath, let filePath = filePath else { return }
                self.appPath = appPath
                self.filePath = filePath
                
            }, completionHandler: nil)
            
            return
        }
        
        self.updateConstraintToCurrent()
        
    }
    
    override func mouseExited(with event: NSEvent) {
        
        self.closeBtn.isHidden = true

    }
    
    override func mouseMoved(with event: NSEvent) {
        
        guard let canvasView = superview as? CanvasView else { return }
        
        let locationInCanvas = canvasView.convert(event.locationInWindow, from: nil)
        
        if self.frame.contains(locationInCanvas) { self.closeBtn.isHidden = false }
        
        let locationInView = convert(event.locationInWindow, from: nil)
        
        let isHoverCloseBtn = self.closeBtn.frame.contains(locationInView)
        
        self.closeBtn.setCloseBtnHover(isHover: isHoverCloseBtn)
        
        guard !isHoverCloseBtn else { return }
        
        super.mouseMoved(with: event)
        
    }
    
    private func initProperty(appPath: String, filePath: String) {
        
        self.appPath = appPath
        
        self.filePath = filePath
        
    }
    
    private func clearSelectedOnCanvas() {
        
        guard let canvas = self.superview as? CanvasView else { return }
        
        canvas.clearCurrentSelected()
    }
    
    private func addSelection() {
        
        guard self.keyMonitor == nil else { return }
        
        self.keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 51 {
                self.remove()
                return nil
            }
            return event
        }
        
        self.layer?.borderWidth = 2
        
        self.layer?.borderColor = NSColor(hex: 0x6A8AA5).cgColor
        
        guard let canvas = self.superview as? CanvasView else { return }
        
        canvas.bringSubviewToFront(self)
    }
    
    public func removeSelection() {
        
        guard let keyMonitor = self.keyMonitor else { return }
        
        NSEvent.removeMonitor(keyMonitor)
        
        self.keyMonitor = nil
        
        self.setDefaultBorder()
    }
    
    private func setDefaultBorder() {
        
        self.layer?.borderWidth = 1
        
        self.layer?.borderColor = NSColor(hex: 0x6A8AA5).withAlphaComponent(0.5).cgColor
        
    }
    
    private func updateConstraintToCurrent() {
        
        guard let canvasView = self.superview as? CanvasView else { return }
        
        let newRect = CGRect(x: self.frame.origin.x,
                             y: self.frame.origin.y,
                             width: self.bounds.size.width,
                             height: self.bounds.size.height)
        
        canvasView.updateConstraint(object: self, newRect: newRect)
    }
    
    private func removeConstraint() {
        
        guard let canvasView = self.superview as? CanvasView else { return }
        
        canvasView.removeConstraint(object: self)
    }
    
    private func addSubviewItems() {
        
        self.thumbnailImageView = NSImageView(frame:
                                                NSRect(origin: .zero,
                                                       size: CGSize(width: 60, height: 100)))
        
        self.addSubview(self.thumbnailImageView)

        self.fileIconImageView = NSImageView(frame: NSRect(x: 5,
                                                           y: 5,
                                                           width: 40,
                                                           height: 40))
        
        self.fileIconImageView.image = NSWorkspace.shared.icon(forFile: self.filePath ?? "")
        
        self.addSubview(self.fileIconImageView)
        
        self.fileNameLbl = NSTextField(labelWithString:
                                        URL(fileURLWithPath: self.filePath ?? "").lastPathComponent)
        
        self.addSubview(self.fileNameLbl)
        
        self.closeBtn = LayoutObjectRectCloseBtn(frame: NSRect(origin: .zero,
                                                               size: CGSize(width: 50, height: 50)))
        
        self.addSubview(self.closeBtn)
        
        self.closeBtn.isHidden = true
    }
    
    private func setSubviewItemsFrame() {
        //縮圖置中
        let center = self.bounds.center()
        
        let imageOriginX = center.x - self.thumbnailImageView.bounds.width / 2
        
        let imageOriginY = center.y - self.thumbnailImageView.bounds.height / 2
        
        self.thumbnailImageView.frame.origin = CGPoint(x: imageOriginX, y: imageOriginY)
        
        //檔案名稱
        self.fileNameLbl.frame = NSRect(x: self.fileIconImageView.frame.maxX,
                                        y: 13,
                                        width: 300,
                                        height: 20)
        
        //移除按扭
        let closeBtnOrigin = CGPoint(x: self.bounds.maxX - self.closeBtn.bounds.width - 5,
                                     y: self.bounds.maxY - self.closeBtn.bounds.height - 5)
        self.closeBtn.frame.origin = closeBtnOrigin
    }
    
    private func replaceFilePathLabel(with filePath: String) {
        
        self.fileNameLbl.removeFromSuperview()
        
        self.fileNameLbl = NSTextField(labelWithString:
                                        URL(fileURLWithPath: filePath).lastPathComponent)
        
        self.addSubview(self.fileNameLbl)
        
        self.setSubviewItemsFrame()
    }
    
    func remove() {
        
        self.removeSelection()
        
        guard let canvasView = self.superview as? CanvasView else { return }

        self.removeFromSuperview()
        
        canvasView.needsLayout = true

    }
    
}
