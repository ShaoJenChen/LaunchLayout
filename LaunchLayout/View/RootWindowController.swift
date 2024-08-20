//
//  RootWindowController.swift
//  TestMouseEvent
//
//  Created by 陳劭任 on 2022/4/19.
//

import Cocoa

class RootWindowController: NSWindowController, NSWindowDelegate {

    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }

    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        
        return frameSize
    }
    
    func windowDidBecomeMain(_ notification: Notification) {
        
        ///Encounter NSCollectionView wrong size calculating as app launched.
        ///It cause NSCollectionViewItem and NSScrollView content size wrong.
        ///I have surveyed various post of related problems on stack overflow,
        ///elegancy solution not found till now.
        ///So I set the window size manually to trigger recalculating of content size.
        ///It has looks solved after examination.
        guard let window = self.window else { return }
        
        var rect = window.contentRect(forFrameRect: window.frame)
        
        rect.size = CGSize(width: rect.width + 0.001, height: rect.height + 0.001)
        
        let frame = window.frameRect(forContentRect: rect)
        
        window.setFrame(frame, display: true, animate: true)
        ///(2022/8/16 SJ.Chen)
    }
    
}
