//
//  ScreenCollectionViewController.swift
//  MeetingTool
//
//  Created by 陳劭任 on 2022/8/12.
//

import Cocoa

protocol MappingDelegate {
    
    func mapping(screenIndex: Int, canvasViewIndex: Int,_ duplication: ((_ duplicatedScreenIndex: Int) -> Void))
    
}

class ScreenCollectionViewController: NSViewController {
    
    @IBOutlet var screenCollectionView: NSCollectionView!
    
    private var canvasViewDataSource: CanvasViewDataSource? {
        
        get {
            
            guard let screenListViewController = self.parent as? ScreenListViewController else { return nil }
            
            return screenListViewController.viewModel
            
        }
        
    }
    
    var mappingDelegate: MappingDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        self.screenCollectionView.register(ScreenItem.self,
                                           forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ScreenItem"))
        
    }
    
    override func viewWillLayout() {
        super.viewWillLayout()
        
        self.screenCollectionView.collectionViewLayout?.invalidateLayout()

    }
    
}

extension ScreenCollectionViewController: NSCollectionViewDelegateFlowLayout {
  
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        
        let width = collectionView.bounds.width - 20
       
        return CGSize(width: width, height: width)
    }
    
}

extension ScreenCollectionViewController: NSCollectionViewDataSource {
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return NSScreen.screens.count
    
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        
        let screenItem = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ScreenItem"),
                                                 for: indexPath) as! ScreenItem
        
        screenItem.screenName.stringValue = NSScreen.screens[indexPath.item].localizedName
                
        screenItem.popUpBtn.menu = self.generateMenu(screenIndex: indexPath.item)
        
        return screenItem
        
    }
    
}

extension ScreenCollectionViewController {
    
    private func generateMenu(screenIndex: Int) -> NSMenu {
        
        func generateMenuItem(title: String, action: Selector) -> NSMenuItem {
            
            let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
            
            item.target = self
            
            return item
            
        }
        
        let menu = VSMenu(screenIndex: screenIndex)
        
        let defaultItem = generateMenuItem(title: "not selected",
                                           action: #selector(didSelected(_:)))
        
        menu.items = [defaultItem]
        
        guard let canvasViews = self.canvasViewDataSource?.currentRecordCanvasViews() else { return menu }
        
        let menuitems = canvasViews.map({ generateMenuItem(title: $0.name,
                                                           action: #selector(didSelected(_:))) })
        
        menu.items += menuitems
        
        return menu
    }
    
    @objc private func didSelected(_ sender: NSMenuItem) {
        
        guard let menu = sender.menu as? VSMenu else { return }
        
        let itemIndex = menu.index(of: sender)
        
        self.mappingDelegate?.mapping(screenIndex: menu.getScreenIndex(),
                                      canvasViewIndex: itemIndex - 1) { [weak self] duplicationIndex in
            
            guard let self = self else { return }
            
            guard let screenItem = self.screenCollectionView.item(at: duplicationIndex) as? ScreenItem else { return }
            
            screenItem.popUpBtn.selectItem(at: 0)
            
        }
        
    }
    
}

class VSMenu: NSMenu {
    
    private var screenIndex: Int!
    
    convenience init(screenIndex: Int) {
        
        self.init()
        
        self.screenIndex = screenIndex
        
    }
    
    func getScreenIndex() -> Int {
        
        return self.screenIndex
        
    }
    
}
