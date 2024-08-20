//
//  ScreenListViewController.swift
//  MeetingTool
//
//  Created by 陳劭任 on 2022/7/16.
//

import Cocoa

class ScreenListViewController: NSViewController {
    
    var viewModel: (ObserveProtocol & CanvasViewDataSource & LaunchConverter)?
    
    private var lastScreenCount = NSScreen.screens.count
    
    @IBOutlet var screenListContainer: NSView!
    
    @IBOutlet var launchBtn: NSButton!
    
    private var screenCanvasMap = [Int: CanvasView]()
    
    private lazy var reloadListener: ListenerClosure = { [weak self] (newValue, oldValue) in
        
        guard let self = self else { return }
        
        guard let screenCollectionVC = self.children.first as? ScreenCollectionViewController else { return }
        
        screenCollectionVC.screenCollectionView.reloadData()
        
        self.screenCanvasMap.removeAll()
        
    }
    
    var selectedCanvasIndex: Observable<NSNumber>? = Observable(nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.viewModel?.currentUUID.bind(reloadListener)

        self.viewModel?.simpleObserveCanvas.bind(reloadListener)
        
        self.initScreenCollectionView()
        
        self.setupLaunchBtn()
        
        self.observeScreens(reloadListener)
        
    }
    
    private func setupLaunchBtn() {
        
        self.launchBtn.wantsLayer = true
        
        self.launchBtn.layer?.backgroundColor = NSColor(hex: 0x6A8AA5).cgColor
        
        self.launchBtn.layer?.cornerRadius = 8.0
        
    }
    
    private func initScreenCollectionView() {
        
        let screenCollectionVC = NSStoryboard.main?.instantiateController(withIdentifier: "ScreenCollectionViewController") as! ScreenCollectionViewController

        self.addChild(screenCollectionVC)

        screenCollectionVC.view.frame = self.screenListContainer.bounds

        screenCollectionVC.view.autoresizingMask = [.height, .width]

        screenCollectionVC.mappingDelegate = self
        
        self.screenListContainer.addSubview(screenCollectionVC.view)
        
    }
    
    private func observeScreens(_ listener: @escaping ListenerClosure) {
        
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification,
                                               object: NSApplication.shared,
                                               queue: OperationQueue.main) { notification in
            
            let newCount = NSScreen.screens.count
            
            guard newCount != self.lastScreenCount else { return }
        
            self.lastScreenCount = newCount
            
            listener(nil, nil)
            
        }
        
    }
    
    @IBAction func launch(_ sender: NSButton) {
        
        let allLayoutObjects = self.screenCanvasMap.compactMap({
            
            self.viewModel?.convert(canvasView: $1, screenIndex: $0)

        }).flatMap({$0})

        guard !allLayoutObjects.isEmpty else { AlertGenerator.launchAlertInMainThread(with: "Empty launch file.")
            return
        }

        //Dialogue
        guard let dialogueWindowController =
                DialogueManager.shared.dialogueWindowController(dialogueType: .LaunchIndicator),
              let dialogueWindow = dialogueWindowController.window
        else { return }

        self.view.window?.beginSheet(dialogueWindow)

        guard let progressVC = dialogueWindow.contentViewController as? ProgressViewController else { return }
        
        LaunchManager.shared.messageDelegate = progressVC
        
        Task {
            
            async let runningApps = LaunchManager.shared.launchApps(launchObjects: allLayoutObjects)
            
            await LaunchManager.shared.makesureAppsWorked(apps: runningApps)
            
            print("confirm Apps Launched")
            
            await LaunchManager.shared.openFilesAndLayout(runningApps: runningApps,
                                                 launchObjects: allLayoutObjects)
            
            print("openFilesAndLayout finish")
            
            self.view.window?.endSheet(dialogueWindow, returnCode: .OK)
        }
        
    }
    
    deinit {
        
        print("ScreenListViewController deinit")
        
//        self.viewModel?.currentUUID.unbind(self.listener)
        
    }
    
}

extension ScreenListViewController: MappingDelegate {
    
    func mapping(screenIndex: Int, canvasViewIndex: Int, _ duplication: ((_ duplicatedScreenIndex: Int) -> Void)) {
        
        guard let canvasViews = self.viewModel?.currentRecordCanvasViews() else { return }
        
        guard 0 ..< canvasViews.count ~= canvasViewIndex else {
            
            self.screenCanvasMap.removeValue(forKey: screenIndex)
            
            print("self.launchMap => \(self.screenCanvasMap)")
            
            return
        }
        
        if let duplicatedItem = self.screenCanvasMap.filter({ $0.value == canvasViews[canvasViewIndex] })
            .first {
            
            let duplicatedScreenIndex = duplicatedItem.key
            
            guard duplicatedScreenIndex != screenIndex else { return }
            
            self.screenCanvasMap.removeValue(forKey: duplicatedScreenIndex)
            
            duplication(duplicatedScreenIndex)
            
        }
        
        self.screenCanvasMap[screenIndex] = canvasViews[canvasViewIndex]
        
        print("self.launchMap => \(self.screenCanvasMap)")
        
        self.selectedCanvasIndex?.value = NSNumber(value: canvasViewIndex)
        
    }
    
}

