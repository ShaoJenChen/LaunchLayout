//
//  AppDelegate.swift
//  TestMouseEvent
//
//  Created by 陳劭任 on 2022/3/22.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var statusMenu: NSMenu!
    
    private var systemStatusBar = NSStatusBar.system
    
    private var statusItem: NSStatusItem!
    
    private var activity: NSObjectProtocol?
    
    var meetingDataHandler: MeetingDataHandler?
    
//    private var menuHandler = MenuHandler()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        self.activity = ProcessInfo.processInfo.beginActivity(options: ProcessInfo.ActivityOptions.userInitiated, reason: "I dont want to nap")
        
        NSApp.appearance = NSAppearance(named: .aqua)
        
        //configure status bar item
        self.configureStatusBarItem()
        
        //Observe screen change to set screen with extend mode
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification,
                                               object: NSApplication.shared,
                                               queue: OperationQueue.main) { notification in
            self.setAllDisplaysExtendMode()
        }
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        
        self.meetingDataHandler?.save()
        
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        
        if flag == false {
            
            self.showMyRootWindow(type: RootWindowController.self)
            
        }
        return true
    }
    
    private func showMyRootWindow<T>(type: T.Type) where T: NSWindowController {
        
        for window in NSApp.windows {
                        
            if (window.delegate?.isKind(of: T.self)) == true {
                
                NSApp.activate(ignoringOtherApps: true)
                
                window.makeKeyAndOrderFront(self)
                
                print("window -> \(window)")

            }
            
        }
        
    }
    
    private func configureStatusBarItem() {
        
        self.statusItem = self.systemStatusBar.statusItem(withLength: NSStatusItem.variableLength)
        
        let logoIcon = NSImage(named: NSImage.Name("StatusIcon"))
                
        self.statusItem.button?.image = logoIcon
        
//        self.statusMenu.delegate = self.menuHandler
        
        self.statusItem.menu = self.statusMenu
        
    }

    private func setAllDisplaysExtendMode() {
        
        guard CGDisplayIsInMirrorSet(CGMainDisplayID()) != 0 else { return }
        
        let maxDisplays = 16
        
        var onlineDspys = Array<CGDirectDisplayID>(repeating: 0, count: maxDisplays)
        
        var config: CGDisplayConfigRef?
        
        var error = CGBeginDisplayConfiguration(&config)
        
        guard error == .success else {
            print("CGBeginDisplayConfiguration error")
            return
        }
        
        var onlineDisplayCount = CGDisplayCount()
        
        error = CGGetOnlineDisplayList(UInt32(maxDisplays),
                                       &onlineDspys,
                                       &onlineDisplayCount)
        
        guard error == .success else {
            print("CGGetOnlineDisplayList error")
            return
        }
        
        var secondaryDspys = [CGDirectDisplayID]()
        
        secondaryDspys.append(contentsOf: onlineDspys.filter({$0 != CGMainDisplayID() && $0 != 0 }))
        
        secondaryDspys.forEach({CGConfigureDisplayMirrorOfDisplay(config, $0, kCGNullDirectDisplay)})
        
        error = CGCompleteDisplayConfiguration(config, CGConfigureOption.permanently)
        
        guard error == .success else {
            print("CGCompleteDisplayConfiguration error")
            return
        }
        
    }
}
