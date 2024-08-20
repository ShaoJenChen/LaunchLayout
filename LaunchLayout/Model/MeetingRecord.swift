//
//  MeetingRecord.swift
//  MeetingTool
//
//  Created by 陳劭任 on 2022/7/15.
//

import Foundation

class MeetingRecord {
    
    var uuid: UUID
    
    var meetingName: String
    
    var timeStamp: Date
    
    var canvasViews: [CanvasView]
 
    init(uuid: UUID, name: String, timeStamp: Date, canvasViews: [CanvasView]) {
        
        self.uuid = uuid
        
        self.meetingName = name
        
        self.timeStamp = timeStamp
        
        self.canvasViews = canvasViews
        
    }
}
