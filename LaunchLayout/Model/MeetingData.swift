//
//  MeetingData.swift
//  TestMouseEvent
//
//  Created by 陳劭任 on 2022/6/14.
//

import Foundation

struct MeetingData: Codable {
    
    var meetings: [Meeting]
    
    var versionCode: String
    
    enum CodingKeys: String, CodingKey {
        
        case meetings = "MeetingGroups"
        
        case versionCode = "version"
    }
    
}

struct Meeting: Codable {
    
    var uuid: UUID
    
    var meetingName: String
    
    var timeStamp: Date
    
    var canvases: [Canvas]
    
    enum CodingKeys: String, CodingKey {
        
        case uuid = "UUID"
        
        case meetingName = "GroupName"
        
        case canvases = "Canvases"
        
        case timeStamp = "TimeStamp"
    }
    
}

struct Canvas: Codable {
    
    var canvasName: String
    
    var launchObjects: [LaunchObject]
    
    enum CodingKeys: String, CodingKey {
        
        case canvasName = "CanvasName"
        
        case launchObjects = "LayoutObjects"
        
    }
}

struct LaunchObject: Codable {
    
    var applicationPath: String
    
    var filePath: String
    
    var leftPaddingRatio: Float
    
    var topPaddingRatio: Float
    
    var widthRatio: Float
    
    var heightRatio: Float
    
    enum CodingKeys: String, CodingKey {
        
        case applicationPath = "ApplicationPath"
        
        case filePath = "FilePath"
        
        case leftPaddingRatio = "LeftPaddingRatio"
        
        case topPaddingRatio = "TopPaddingRatio"
        
        case widthRatio = "WidthRatio"
        
        case heightRatio = "HeightRatio"
    }
}
