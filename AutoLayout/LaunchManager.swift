//
//  LaunchManager.swift
//  MeetingTool
//
//  Created by 陳劭任 on 2022/6/12.
//

import Cocoa

private let _manager = LaunchManager()

protocol LaunchMessageDelegate {
    
    func showMessage(msg: String)
    
}

class LaunchManager: NSObject {
    
    public class var shared: LaunchManager {
        
        return _manager
        
    }
    
    var messageDelegate: LaunchMessageDelegate?
    
    public func launchApps(launchObjects: [VSLaunchObject]) async -> [NSRunningApplication] {
        
        @Sendable func openApp(with url: URL) async -> NSRunningApplication? {
            
            let runningApp = try? await NSWorkspace.shared.openApplication(at: url,
                                                                           configuration: NSWorkspace.OpenConfiguration())
            
            return runningApp
        }
        
        //filter not exist files
        let existObjects = launchObjects.filter({ FileManager.default.fileExists(atPath: $0.filePath) })
        
        //grouping by app
        let groupDict = Dictionary(grouping: existObjects, by: { $0.appBundleID })
        
        dump(groupDict)
        
        var runningApps = [NSRunningApplication?]()
        
        for launchObjects in groupDict.values {
            
            guard let appBundleID = launchObjects.first?.appBundleID else { return runningApps.compactMap({$0}) }
            
            guard let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: appBundleID) else { return runningApps.compactMap({$0}) }
            
            self.messageDelegate?.showMessage(msg: "Launching \(appBundleID)")
            
            async let runningApp = openApp(with: appUrl)
            
            await runningApps.append(runningApp)
        }
        
        return runningApps.compactMap({$0})
        
    }
    
    public func makesureAppsWorked(apps: [NSRunningApplication] ) async {
        
        for app in apps {
            async let isShow = !app.isHidden
            if await isShow { continue }
        }
        
        return
        
    }
    
    public func openFilesAndLayout(runningApps: [NSRunningApplication], launchObjects: [VSLaunchObject]) async {
        
        @Sendable func settingWindowFrame(launchObject: VSLaunchObject) async {
            
            var unSafeLaunchObject = launchObject
            
            let runningApp = runningApps.first(where: { $0.bundleIdentifier == launchObject.appBundleID })
            
            guard let runningAppPID = runningApp?.processIdentifier else { return }
            
            let applicationRef = AXUIElementCreateApplication(runningAppPID)
            
            var uiElementsValue: AnyObject?
            
            while true {
                
                Thread.sleep(forTimeInterval: 0.5)
                
                let getElementsError = AXUIElementCopyAttributeValue(applicationRef, kAXWindowsAttribute as CFString, &uiElementsValue)
                
                guard getElementsError == .success else { continue }
                
                guard let uiElements = uiElementsValue as? [AXUIElement] else { continue }
                
                guard let targetUIElement = uiElements.first(where: { $0.documentPath == launchObject.filePath})
                else { continue }
                
                guard let positionValue = AXValueCreate(.cgPoint, &unSafeLaunchObject.position) else {
                    continue
                }
                
                self.messageDelegate?.showMessage(msg: "Setting position...")
                
                let settingPositionError = AXUIElementSetAttributeValue(targetUIElement, kAXPositionAttribute as CFString, positionValue)
                
                guard settingPositionError == .success else { continue }
                
                Thread.sleep(forTimeInterval: 0.5)
                
                guard let sizeValue = AXValueCreate(.cgSize, &unSafeLaunchObject.size) else {
                    continue
                }
                
                self.messageDelegate?.showMessage(msg: "Setting size...")
                
                let settingSizeError = AXUIElementSetAttributeValue(targetUIElement, kAXSizeAttribute as CFString, sizeValue)
                
                guard settingSizeError == .success else { continue }
                
                return
            }
            
        }
        
        //filter not exist files
        let existObjects = launchObjects.filter({ FileManager.default.fileExists(atPath: $0.filePath) })
        
        for launchObject in existObjects {
            
            let fileURL = URL(fileURLWithPath: launchObject.filePath)
            
            self.messageDelegate?.showMessage(msg: "open file \(launchObject.filePath)")
            
            let _ = try? await NSWorkspace.shared.open(fileURL,
                                                       configuration: NSWorkspace.OpenConfiguration())
            
            self.messageDelegate?.showMessage(msg: "\(launchObject.filePath) has open.")
            
            await settingWindowFrame(launchObject: launchObject)
        }
        
        return
    }
    
}
