//
//  Extensions.swift
//  MeetingTool
//
//  Created by 陳劭任 on 2022/7/22.
//

import Cocoa

extension Bundle {
    
    public var appName: String { return getInfo("CFBundleName") }
    
    public var displayName: String { return getInfo("CFBundleDisplayName") }
    
    public var language: String { return getInfo("CFBundleDevelopmentRegion") }
    
    public var identifier: String { return getInfo("CFBundleIdentifier") }
    
    public var copyright: String {
        
        return getInfo("NSHumanReadableCopyright").replacingOccurrences(of: "\\\\n", with: "\n")
        
    }
    
    public var appBuild: String { return getInfo("CFBundleVersion") }
    
    public var appVersionLong: String { return getInfo("CFBundleShortVersionString") }
    
    private func getInfo(_ str: String) -> String {
        
        return self.infoDictionary?[str] as? String ?? "info not found"
        
    }
    
}

extension NSColor {
    
    convenience init(hex: Int, alpha: Double = 1.0) {
        
        let red = Double((hex & 0xFF0000) >> 16) / 255.0
        
        let green = Double((hex & 0xFF00) >> 8) / 255.0
        
        let blue = Double((hex & 0xFF)) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
        
    }
    
}

extension NSRect {
    
    public func center() -> CGPoint {
        
        let centerX = self.minX + self.width/2
        
        let centerY = self.minY + self.height/2
        
        return CGPoint(x: centerX, y: centerY)
        
    }
    
}

extension Array {
    
    public func shift(withDistance distance: Int = 1) -> Array<Element> {
        
        guard let index = distance >= 0 ?
                self.index(startIndex, offsetBy: distance, limitedBy: endIndex) :
                    self.index(endIndex, offsetBy: distance, limitedBy: startIndex)
        else { return self }
        
        return Array(self[index ..< endIndex] + self[startIndex ..< index])
        
    }
    
}

extension UserDefaults {
    
    public func clearData() {
        
        guard let domainName = Bundle.main.bundleIdentifier else { return }
        
        removePersistentDomain(forName: domainName)
        
        synchronize()
    }
    
}
