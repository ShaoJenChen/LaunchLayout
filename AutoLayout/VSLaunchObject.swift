//
//  VSLaunchObject.swift
//  AutoLayout
//
//  Created by 陳劭任 on 2021/10/18.
//

import Cocoa

struct VSLaunchObject {
    
    var filePath: String
    
    var size: CGSize
    
    var position: CGPoint
    
    var application: NSMetadataItem
    
    var appBundleID: String? {
        get {
            guard let bundleID = application.value(forAttribute: String(kMDItemCFBundleIdentifier)) as? String else { return nil }
            
            return bundleID
        }
    }
    
    var appIcon: NSImage? {
        get {
            guard let appPath = application.value(forAttribute: String(kMDItemPath)) as? String else { return nil }
            
            let icon = NSWorkspace.shared.icon(forFile: appPath)
            
            return icon
        }
    }
}

extension AXUIElement {
    
    var documentPath: String? {
        get {
            var documentFilePath: AnyObject?
            
            AXUIElementCopyAttributeValue(self, kAXDocumentAttribute as CFString, &documentFilePath)
            
            guard let filePath = (documentFilePath as? NSString)?.removingPercentEncoding?.replacingOccurrences(of: "file://", with: "")
            else {
                print("filePath nil or remove Percent Encoding fail")
                return nil
            }
            
            return filePath
        }
    }
    
}
