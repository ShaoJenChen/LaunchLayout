//
//  DialogueManager.swift
//  TestMouseEvent
//
//  Created by 陳劭任 on 2022/4/26.
//

import Cocoa

private let _manager = DialogueManager()

enum DialogueType: String {
    
    case LayoutObjectOnCanvas = "LayoutObjectDialogueViewController"
    
    case LaunchIndicator = "ProgressViewController"
    
}

class DialogueManager: NSObject {

    public class var shared: DialogueManager {
        
        return _manager
        
    }
    
    private var dialogueWindowController: DialogueWindowController? = {
       
        let dialogueWindowController = NSStoryboard.main?.instantiateController(withIdentifier: "DialogueWindowController") as? DialogueWindowController

        return dialogueWindowController
        
    }()
    
    public func dialogueWindowController(dialogueType: DialogueType) -> DialogueWindowController? {
        
        let contentViewController = NSStoryboard.main?.instantiateController(withIdentifier: dialogueType.rawValue) as? NSViewController
        
        self.dialogueWindowController?.contentViewController = contentViewController
        
        return self.dialogueWindowController
    }
}
