//
//  VSTrackingView.swift
//  MeetingTool
//
//  Created by 陳劭任 on 2022/11/21.
//

import Cocoa

class VSTrackingView: NSView {

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        trackingAreas.forEach({ removeTrackingArea($0) })
        
        addTrackingArea(NSTrackingArea(rect: self.bounds,
                                       options: [.mouseMoved,
                                                 .mouseEnteredAndExited,
                                                 .activeInActiveApp],
                                       owner: self))
    }
    
}
