//
//  CanvasGenerator.swift
//  TestMouseEvent
//
//  Created by 陳劭任 on 2022/6/14.
//

import Foundation

fileprivate let defaultName = "Canvas"

private let canvasViewDefaultRect = CGRect(x: 0,
                                           y: 0,
                                           width: 300,
                                           height: 200)

class CanvasGenerator {
    
    class func generateCanvasView(frame: NSRect = canvasViewDefaultRect,
                                  existNames: [String] = [String](),
                                  viewModel: CanvasViewDataSource? = nil) -> CanvasView {
        
        let newName = self.namingNewCanvas(exsitNames: existNames)
        
        let newCanvas = CanvasView(frame: frame, name: newName, viewModel: viewModel)
        
        return newCanvas
        
    }
    
    class func generateCanvasView(frame: NSRect = canvasViewDefaultRect,
                                  name: String,
                                  viewModel: CanvasViewDataSource? = nil) -> CanvasView {
        
        return CanvasView(frame: frame, name: name, viewModel: viewModel)
        
    }
    
    class func generateCanvasView(duplicateCanvasView: CanvasView) -> CanvasView {
        
        return CanvasView(duplicateCanvasView: duplicateCanvasView)
        
    }
    
    private class func namingNewCanvas(exsitNames: [String]) -> String {
        
        guard exsitNames.count > 0 else { return defaultName }
        
        var newNumber = 0
        
        var newName = defaultName
                
        while (exsitNames.contains(newName)) {
            
            newNumber += 1
            
            if !exsitNames.contains(newName + String(newNumber)) {
                
                newName += String(newNumber)
            }
            
        }
        
        return newName
    }
    
}
