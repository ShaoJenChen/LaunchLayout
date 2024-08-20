//
//  MappingRule.swift
//  MeetingTool
//
//  Created by 陳劭任 on 2022/6/28.
//

import Foundation
import Algorithms

final class MappingRule {
    
    private static var mappingTable = ["com.microsoft.Word": ["doc", "docx"],
                                       "com.microsoft.Excel": ["xls", "xlsx"],
                                       "com.microsoft.Powerpoint": ["ppt", "pptx"]]
    
    class func supportedFileExtensionNames() -> [String] {
        
        Array(self.mappingTable.values.flatMap({ $0 }).uniqued())
        
    }
    
    class func supportedAppIDs() -> [String] {

        Array(self.mappingTable.keys)

    }
    
    class func applicationIDs(with extensionName: String) -> [String] {
        
        self.mappingTable.keys.filter({ key in
            
            guard let extensionNames = self.mappingTable[key] else { return false }
            
            return extensionNames.contains(extensionName)
            
        })
        
    }
    
}
