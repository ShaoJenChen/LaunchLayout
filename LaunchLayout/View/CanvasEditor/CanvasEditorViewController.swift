//
//  BackGroundBoard.swift
//  TestMouseEvent
//
//  Created by 陳劭任 on 2022/3/22.
//

import Cocoa

class CanvasEditorViewController: NSViewController {
    
    @IBOutlet var canvasContainer: NSView!
    
    @IBOutlet private var tabContainer: NSView!
        
    @IBOutlet private var tabControlPanel: NSStackView!
    
    @IBOutlet private var backgroundImgView: NSImageView!
    
    @IBOutlet private var addCanvasBtn: NSButton!
        
    var viewModel: (ObserveProtocol & CanvasViewDataSource & CanvasViewDelegate)?
    
    private lazy var meetingListener: ListenerClosure = { [weak self] (uuid, old_uuid) in
        
        guard let self = self else { return }
        
        if let old_uuid = old_uuid as? UUID { self.clearPreviousViewSelected(for: old_uuid) }
        
        let isNeedDisplayCanvas = uuid != nil
        
        self.setControlPanel(isHidden: !isNeedDisplayCanvas)
        
        if isNeedDisplayCanvas { self.loadCanvasViews() }
        
        if !isNeedDisplayCanvas { self.releaseCanvasViews() }
        
    }
    
    private lazy var canvasSelectedListener: ListenerClosure = { [weak self] (selectedIndex, oldSelectedIndex) in
        
        guard let self = self else { return }
        
        guard let selectedIndex = selectedIndex as? Int else { return }
        
        guard let canvasViews = self.viewModel?.currentRecordCanvasViews() else { return }
        
        guard 0 ..< canvasViews.count ~= selectedIndex else { return }
        
        self.didSelect(canvasView: canvasViews[selectedIndex])
        
        self.tabCollectionVC?.tabCollectionView.selectionIndexPaths = [IndexPath(item: selectedIndex,
                                                                                section: 0)]
        
    }
    
    private lazy var meetingRecordCountListener: ListenerClosure = { [weak self] (value, old_value) in
        
        guard let self = self else { return }
        
        if let meetingCount = value as? Int, meetingCount == 0 {
            
            self.backgroundImgView.image = meetingCount == 0 ? NSImage(named: "NoMeetingImg") : nil
            
        }
    }
    
    private var tabCollectionVC: TabCollectionViewController? {
        get {
            
            guard let tabCollectionVC = self.children.first(where: {
                $0 is TabCollectionViewController
            }) as? TabCollectionViewController else { return nil }
            
            return tabCollectionVC
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.settingAddCanvasBtn()
        
        self.initTabController()
                
        self.viewModel?.currentUUID.bind(self.meetingListener)
        
        self.viewModel?.canvasSelection.bind(self.canvasSelectedListener)
        
        self.viewModel?.meetingRecordCount.bind(self.meetingRecordCountListener,
                                                isCallImmediately: true)
        
    }

    override func viewDidAppear() {
        super.viewDidAppear()

    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func addCanvas(_ sender: NSButton) {
        
        self.viewModel?.addNewCanvasToCurrentRecord({ [weak self] canvasView in
            
            guard let tabCollectionVC = self?.tabCollectionVC else { return }
            
            tabCollectionVC.tabCollectionView.reloadData()
            
            guard let currentCanvasCount = self?.viewModel?.currentRecordCanvasViews()?.count else { return }
            
            let lastIndexPath = IndexPath(item: currentCanvasCount - 1, section: 0)
            
            tabCollectionVC.tabCollectionView.selectItems(at: [lastIndexPath],
                                                          scrollPosition: .centeredHorizontally)
            
            self?.didSelect(canvasView: canvasView)
            
        })
        
    }
        
    @IBAction func scrollTabToLeftOrRight(_ sender: NSButton) {
        
        guard let tabCollectionVC = self.tabCollectionVC else { return }
        
        var currentVisibleRect = tabCollectionVC.tabCollectionView.visibleRect
        
        guard let itemWidth = tabCollectionVC.tabCollectionView.visibleItems().first?.view.frame.width
        else { return }

        currentVisibleRect.origin.x += itemWidth * CGFloat(sender.tag)

        let _ = tabCollectionVC.tabCollectionView.scrollToVisible(currentVisibleRect)
        
    }
    
    private func initTabController() {
        
        let tabCollectionViewController = NSStoryboard.main?.instantiateController(withIdentifier: "TabCollectionViewController") as! TabCollectionViewController
        
        tabCollectionViewController.canvasTabDelegate = self
        
        tabCollectionViewController.viewModel = self.viewModel
        
        self.addChild(tabCollectionViewController)
        
        tabCollectionViewController.view.frame = self.tabContainer.bounds
        tabCollectionViewController.view.autoresizingMask = [.height, .width]
        
        self.tabContainer.addSubview(tabCollectionViewController.view)
        
    }
    
    private func settingAddCanvasBtn() {
     
        self.addCanvasBtn.wantsLayer = true
        
        self.addCanvasBtn.layer?.backgroundColor = NSColor.white.cgColor
                
        self.addCanvasBtn.layer?.borderWidth = 0.8
        
        self.addCanvasBtn.layer?.borderColor = NSColor(hex: 0x6B8AA5).withAlphaComponent(0.5).cgColor
        
    }
    
    private func releaseCanvasViews() {
        
        self.canvasContainer.subviews.forEach({ $0.removeFromSuperview() })
        
        guard let tabCollectionVC = self.tabCollectionVC else { return }
        
        tabCollectionVC.tabCollectionView.reloadData()
        
        tabCollectionVC.tabCollectionView.backgroundColors = [NSColor(hex: 0xF0F4F7)]
        
    }
    
    private func loadCanvasViews() {
        
        guard let tabCollectionVC = self.tabCollectionVC else { return }
        
        tabCollectionVC.tabCollectionView.reloadData()
        
        tabCollectionVC.tabCollectionView.selectItems(at: [IndexPath(item: 0, section: 0)],
                                                      scrollPosition: .centeredHorizontally)
        
        tabCollectionVC.tabCollectionView.backgroundColors = [.white]
        
        guard let canvasViews = self.viewModel?.currentRecordCanvasViews() else { return }
        
        guard let firstCanvasView = canvasViews.first else { return }

        self.didSelect(canvasView: firstCanvasView)
    }
    
    private func clearPreviousViewSelected(for old_uuid: UUID) {
        
        guard let previousCanvasViews = self.viewModel?.canvasViews(recordUUID: old_uuid) else { return }
        
        previousCanvasViews.forEach({ $0.clearCurrentSelected() })
        
    }
    
    private func setControlPanel(isHidden: Bool) {
                
        self.tabControlPanel.isHidden = isHidden
        
        self.addCanvasBtn.isHidden = isHidden
    }
}

extension CanvasEditorViewController: CanvasTabDelegate {
    
    func didSelect(canvasView: CanvasView) {
        
        canvasView.frame = self.canvasContainer.bounds

        self.canvasContainer.subviews.forEach({ $0.removeFromSuperview() })
        
        self.canvasContainer.addSubview(canvasView)
        
    }
    
}
