//
//  DialogueViewController.swift
//  TestMouseEvent
//
//  Created by 陳劭任 on 2022/3/26.
//

import Cocoa

class LayoutObjectDialogueViewController: NSViewController {
    
    @IBOutlet private var confirmButton: NSButton!
    
    @IBOutlet private var appPathLabel: NSTextField!
    
    @IBOutlet private var filePathLabel: NSTextField!
    
    @IBOutlet private var fileImage: NSImageView!
    
    @IBOutlet private var selectFileBtn: NSButton!
    
    @IBOutlet private var selectAppBtn: NSButton!
    
    @IBOutlet private var cancelBtn: NSButton!
    
    private var openPanel: VSOpenPanel!

    var callBackPath: ((String?, String?) -> Void)?

    var currentLayoutObjectURLs: [URL]?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        self.openPanel = VSOpenPanel(dialogueViewController: self)
        
        print("LayoutObjectDialogueViewController init")
    }
    
    private var applicationPath: String? {
        willSet {
            guard let path = newValue else {
                
                self.appPathLabel.stringValue = ""
                
                return
            }
            
            self.appPathLabel.stringValue = path
        }
        didSet {
            self.confirmButton.isEnabled = self.inputValidation()
        }
    }
    
    fileprivate var filePath: String? {
        willSet {
            guard let path = newValue else {
                
                self.filePathLabel.stringValue = ""
                
                return
            }
            
            self.filePathLabel.stringValue = path
            
            let icon = NSWorkspace.shared.icon(forFile: path)
            
            self.fileImage.image = icon
        }
        didSet {
            self.confirmButton.isEnabled = self.inputValidation()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupBtns()
        
    }

    func setDefault(appPath: String?, filePath: String?) {
        self.applicationPath = appPath
        self.filePath = filePath
    }
    
    private func inputValidation() -> Bool {
        guard let applicationPath = applicationPath,
              let filePath = filePath else { return false }
        
        return !applicationPath.isEmpty && !filePath.isEmpty
        
    }
    
    private func setupBtns() {
        
        let attribute = [NSAttributedString.Key.foregroundColor : NSColor(hex: 0x6A8AA5)]
        
        let doneBtnAttr = [NSAttributedString.Key.foregroundColor : NSColor(hex: 0xFFFFFF)]
        
        self.selectFileBtn.attributedTitle = NSAttributedString(string: "Select File",
                                                                attributes: attribute)
        
        self.selectAppBtn.attributedTitle = NSAttributedString(string: "Select App",
                                                               attributes: attribute)
        
        self.cancelBtn.attributedTitle = NSAttributedString(string: "Cancel",
                                                            attributes: attribute)
        
        self.confirmButton.attributedTitle = NSAttributedString(string: "Done",
                                                            attributes: doneBtnAttr)
        
        self.confirmButton.wantsLayer = true
        
        self.confirmButton.layer?.backgroundColor = NSColor(hex: 0x6A8AA5).cgColor
        
        self.confirmButton.layer?.cornerRadius = 5
        
        
    }
    
    @IBAction func chooseFile(_ sender: NSButton!) {
        
        self.openPanel.openPanelState = .SelectFile
        
        self.openPanel.beginSheetModal(for: self.view.window!) { response in
            guard response == .OK else { return }
            
            guard let filePath = self.openPanel.url?.path else { return }
            
            self.filePath = filePath
            
            let pathExtension = URL(fileURLWithPath: filePath).pathExtension
            
            guard let appID = MappingRule.applicationIDs(with: pathExtension).first else { return }
            
            guard let appPath = getAppPath(with: appID) else { return }
            
            self.applicationPath = appPath
        }

    }
    
    @IBAction func chooseApplication(_ sender: NSButton!) {
        
        self.openPanel.openPanelState = .SelectApp
        
        let applicationsPath = "/Applications" as NSString
        
        self.openPanel.directoryURL = URL(fileURLWithPath: applicationsPath.expandingTildeInPath, isDirectory: false)
        
        self.openPanel.beginSheetModal(for: self.view.window!) { response in
            
            guard response == .OK else { return }
            
            guard let appPath = self.openPanel.url?.path else { return }
            
            self.applicationPath = appPath
            
        }
    }
    
    @IBAction func end(_ sender: NSButton!) {
        
        guard let window = self.view.window,
                let parent = window.sheetParent else { return }
        
        if let callBackPath = self.callBackPath {
            
            callBackPath(self.applicationPath, self.filePath)

        }
        
        parent.endSheet(window, returnCode: .OK)
        
    }
    
    @IBAction func cancel(_ sender: NSButton!) {
        guard let window = self.view.window,
                let parent = window.sheetParent else { return }
        
        parent.endSheet(window, returnCode: .cancel)
    }
    
    deinit {
        print("LayoutObjectDialogueViewController deinit")
    }
}

class VSOpenPanel: NSOpenPanel {
    
    fileprivate enum OpenPanelState {
        case none
        case SelectFile
        case SelectApp
    }
    
    fileprivate var openPanelState: OpenPanelState = .none
    
    private var allMDItems: [NSMetadataItem] = getMDItems()

    private weak var dialogueViewController: LayoutObjectDialogueViewController?
    
    convenience init(dialogueViewController: LayoutObjectDialogueViewController) {
        
        self.init()
        
        self.delegate = self
        
        self.dialogueViewController = dialogueViewController
        
        print("VSOpenPanel init")
    }
    
    deinit {
        print("VSOpenPanel deinit")
    }
}

extension VSOpenPanel: NSOpenSavePanelDelegate {
    
    func panel(_ sender: Any, shouldEnable url: URL) -> Bool {
     
        guard let panel = sender as? VSOpenPanel else { return false }
        
        switch panel.openPanelState {
            
        case .SelectFile:
            
            let extensionName = url.pathExtension
            
            guard extensionName != "app" else { return false }
            
            guard !url.path.contains("/Applications") else { return false }
            
            //check exist file path
            if let currentMeetingRecordURLs = self.dialogueViewController?.currentLayoutObjectURLs,
               currentMeetingRecordURLs.contains(url) { return false }
            
            //Enable Directory
            if url.hasDirectoryPath && extensionName.isEmpty { return true }
            
            return MappingRule.supportedFileExtensionNames().contains(extensionName)
        
        case .SelectApp:
            
            guard url.pathExtension == "app" else { return false }
            
            guard let bundleID = getAppID(with: url.path, from: self.allMDItems) else { return false }
            
            guard let filePath = self.dialogueViewController?.filePath else {
    
                return MappingRule.supportedAppIDs().contains(bundleID)
                
            }
            
            let filePathExtension = URL(fileURLWithPath: filePath).pathExtension
            
            let appIDs = MappingRule.applicationIDs(with: filePathExtension)
            
            return appIDs.contains(bundleID)
            
        default:
            return false
        }
        
    }
    
}
