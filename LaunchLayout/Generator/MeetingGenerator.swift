//
//  MeetingGenerator.swift
//  MeetingTool
//
//  Created by 陳劭任 on 2022/8/1.
//

import Foundation

fileprivate let defaultName = "Meeting"

class MeetingGenerator {
    
    class func generateMeeting(existNames: [String] = [String](),
                               canvasViews: [CanvasView] = []) -> MeetingRecord {
        
        let newName = self.namingNewMeeting(existNames: existNames)
        
        return MeetingRecord(uuid: UUID(),
                             name: newName,
                             timeStamp: Date(),
                             canvasViews: canvasViews)
        
    }
    
    class func generateMeeting(uuid: UUID,
                               name: String,
                               timeStamp: Date,
                               canvasViews: [CanvasView] = []) -> MeetingRecord {
        
        return MeetingRecord(uuid: uuid,
                             name: name,
                             timeStamp: timeStamp,
                             canvasViews: canvasViews)
        
    }
    
    private class func namingNewMeeting(existNames: [String]) -> String {
        
        guard existNames.count > 0 else { return defaultName }
        
        var newNumber = 0
        
        var newName = defaultName
        
        while (existNames.contains(newName)) {
            
            newNumber += 1
            
            if !existNames.contains(newName + String(newNumber)) {
                
                newName += String(newNumber)
            }
            
        }
        
        return newName
        
    }
    
}
