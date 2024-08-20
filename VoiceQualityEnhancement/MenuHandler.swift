//
//  MenuHandler.swift
//  MeetingTool
//
//  Created by 陳劭任 on 2022/10/13.
//

import Cocoa

enum ListType {
    case SPK
    case MIC
}

class MenuHandler: NSObject {
    
    private var menu: NSMenu?
    
    private var audioManager: VQEProtocol?
    
    private var noiseReductionObservation: NSKeyValueObservation?
    
    private var echoCancellationObservation: NSKeyValueObservation?
    
    override init() {
        super.init()
        
        Task {
            
            self.audioManager = await AudioManager()
            
            self.observeDeviceChanged()
        }
    }
    
    // MARK: - VEC operation function
    private func noiseReduction(isEnable: Bool) {
        
        guard let audioManager = self.audioManager else { return }
        
        guard isEnable else { audioManager.noiseReductionStop(); return }
        
        guard let selectedSpkIndex = self.getSelectedIndex(of: .SPK) else { return }
        
        audioManager.noiseReductionStart(speakerIndex: selectedSpkIndex)
    }
    
    private func restartNoiseReduction() {
        
        self.noiseReduction(isEnable: false)
        
        Thread.sleep(forTimeInterval: 0.5)
        
        self.noiseReduction(isEnable: true)
    }
    
    private func echoCancellation(isEnable: Bool) {
        
        guard let audioManager = self.audioManager else { return }
        
        guard isEnable else { audioManager.echoCancellationStop(); return }
        
        guard let selectedSpkIndex = self.getSelectedIndex(of: .SPK) else { return }
        
        guard let selectedMicIndex = self.getSelectedIndex(of: .MIC) else { return }
        
        audioManager.echoCancellationStart(speakerIndex: selectedSpkIndex, microphoneIndex: selectedMicIndex)
        
    }
    
    private func restartEchoCancellation() {
        
        self.echoCancellation(isEnable: false)
        
        Thread.sleep(forTimeInterval: 0.5)
        
        self.echoCancellation(isEnable: true)
    }
    
    private func getList(of type: ListType) -> [String] {
        
        guard let audioManager = self.audioManager else { return [] }
        
        switch type {
        case .SPK:
            return audioManager.getSpeakerList()
        case .MIC:
            return audioManager.getMicrophoneList()
        }
        
    }
    
    // MARK: - Memu item selected
    @objc private func selected(sender: NSMenuItem) {
        
        guard let menu = self.menu,
              let toggleView = menu.items.first?.view as? ToggleView else { return }
        
        func handleMenuItemState() {
            
            let speakerIndexTuple = self.getIndexTuple(of: .SPK)
            
            let microphoneIndexTuple = self.getIndexTuple(of: .MIC)
            
            let speakerRange = speakerIndexTuple.titleIndex + 1 ..< speakerIndexTuple.endSeparatorIndex
            
            let microphoneRange = microphoneIndexTuple.titleIndex + 1 ..< microphoneIndexTuple.endSeparatorIndex
            
            let selectedIndex = menu.index(of: sender)
            
            if speakerRange ~= selectedIndex { menu.items[speakerRange].forEach({ $0.state = .off }) }
            
            if microphoneRange ~= selectedIndex { menu.items[microphoneRange].forEach({ $0.state = .off }) }
            
            sender.state = .on
            
        }
        
        handleMenuItemState()
        
        guard toggleView.isEchoCancellationOn else { self.restartNoiseReduction(); return }
        
        guard toggleView.isNoiseReductionOn else { self.restartEchoCancellation(); return }
        
        self.restartNoiseReduction()
        
        Thread.sleep(forTimeInterval: 0.5)
        
        self.restartEchoCancellation()
        
    }
    
    // MARK: - Adjust menu items
    private func reloadLists() {
        
        guard let menu = menu else { return }
                
        func createMenuItems(formerlySelectedName: String?, of type: ListType) {
            
            let lists = self.getList(of: type)
            
            let menuItems = lists.map { name -> NSMenuItem in
                
                let newMenuItem = NSMenuItem(title: name,
                                             action: #selector(selected(sender:)),
                                             keyEquivalent: "")
                
                newMenuItem.target = self
                
                newMenuItem.indentationLevel = 1
                
                newMenuItem.state = name == formerlySelectedName ? .on : .off
                
                newMenuItem.isEnabled = false
                
                return newMenuItem
            }
            
            if menuItems.filter({ $0.state == .on }).isEmpty { menuItems.first?.state = .on }
            
            menuItems.forEach({
                
                menu.insertItem($0, at: self.getIndexTuple(of: type).endSeparatorIndex)
                
            })
            
        }
        
        func removeMenuItems(from: Int, to: Int) {
            
            var lastPosition = to - 1
            
            while lastPosition > from {
                
                menu.removeItem(at: lastPosition)
                
                lastPosition -= 1
                
            }
            
        }
        
        func reloadList(type: ListType) {
            
            let indexTuple = self.getIndexTuple(of: type)
            
            let formerlySelectedName = self.getFormerlySelectedTitle(from: indexTuple.titleIndex,
                                                                     to: indexTuple.endSeparatorIndex)
            
            removeMenuItems(from: indexTuple.titleIndex,
                            to: indexTuple.endSeparatorIndex)
            
            createMenuItems(formerlySelectedName: formerlySelectedName, of: type)
            
        }
        
        reloadList(type: .SPK)
        
        reloadList(type: .MIC)
    }
    
    private func getSpeakerIndexRange() -> Range<Int> {
        
        let speakerIndexTuple = self.getIndexTuple(of: .SPK)
        
        let firstSpeakerIndex = speakerIndexTuple.titleIndex + 1
        
        let speakerEndSeparatorIndex = speakerIndexTuple.endSeparatorIndex
        
        return firstSpeakerIndex ..< speakerEndSeparatorIndex
    }
    
    private func getMicIndexRange() -> Range<Int> {
        
        let microphoneIndexTuple = self.getIndexTuple(of: .MIC)
        
        let firstMicphoneIndex = microphoneIndexTuple.titleIndex + 1
        
        let micEndSeparatorIndex = microphoneIndexTuple.endSeparatorIndex
        
        return firstMicphoneIndex ..< micEndSeparatorIndex
    }
    
    private func refreshMenuItemsState() {
        
        guard let menu = menu else { return }
        
        func spkList(isEnable: Bool) {
            
            let speakerIndexRange = self.getSpeakerIndexRange()
            
            menu.items.filter({ speakerIndexRange ~= menu.index(of: $0) })
                .forEach({ $0.isEnabled = isEnable })
        }
        
        func micList(isEnable: Bool) {
            
            let micIndexRange = self.getMicIndexRange()
            
            menu.items.filter({ micIndexRange ~= menu.index(of: $0)})
                .forEach({ $0.isEnabled = isEnable })
        }
        
        func allList(isEnable: Bool) {
            spkList(isEnable: isEnable)
            micList(isEnable: isEnable)
        }
        
        guard let toggleView = menu.items.first?.view as? ToggleView else { return }
        
        switch (toggleView.isNoiseReductionOn, toggleView.isEchoCancellationOn)  {
        case (false, false): //NR OFF, EC OFF, All list disable
            allList(isEnable: false)
        case (true, false): //NR ON, EC OFF, Speaker list enable, Mic list disable
            spkList(isEnable: true)
            micList(isEnable: false)
        case (true, true), (false, true): //(NR ON, EC ON || NR OFF, EC ON) All list enable
            allList(isEnable: true)
        }
        
    }
    
    private func checkIsListEmpty() {
        
        guard let toggleView = self.menu?.items.first?.view as? ToggleView else { return }
        
        self.getList(of: .SPK).isEmpty ? toggleView.disableAllToggle() : toggleView.enableAllToggle()
        
        self.getList(of: .MIC).isEmpty ? toggleView.disableECToggle() : toggleView.enableECToggle()
        
    }
    
    // MARK: - Observe toggle
    private func addToggleObservations() {
        
        guard let toggleView = self.menu?.items.first?.view as? ToggleView else { return }
        
        self.noiseReductionObservation = toggleView.observe(\.isNoiseReductionOn,
                                                             options: [.new],
                                                             changeHandler: { [weak self] (audioControlView, changedValue) in
            guard let self = self else { return }
            
            self.refreshMenuItemsState()
            
            self.noiseReduction(isEnable: changedValue.newValue!)
            
        })
        
        self.echoCancellationObservation = toggleView.observe(\.isEchoCancellationOn,
                                                               options: [.new],
                                                               changeHandler: { [weak self] audioControlView, changedValue in
            guard let self = self else { return }
            
            self.refreshMenuItemsState()
            
            self.echoCancellation(isEnable: changedValue.newValue!)
            
        })
        
    }
    
    // MARK: - Observe Device Changed
    private func observeDeviceChanged() {
        
        guard let audioManager = audioManager else { return }
                
        audioManager.observeDeviceChanged { [weak self] (addedNames, removedNames)  in
            
            guard let self = self else { return }
            
            guard let toggleView = self.menu?.items.first?.view as? ToggleView else { return }
                        
            NSLog("addedNames \(addedNames), removedNames \(removedNames)")
            
            guard !removedNames.isEmpty else { return }
            
            guard let selectedSpeakerItem = self.menu?.items[self.getSpeakerIndexRange()]
                .first(where: { $0.state == .on }) else { return }
            
            guard let selectedMicItem = self.menu?.items[self.getMicIndexRange()]
                .first(where: { $0.state == .on }) else { return }
            
            let isNeedHandleNR = toggleView.isNoiseReductionOn &&
            removedNames.contains(selectedSpeakerItem.title)
            
            let isNeedHandleEC = toggleView.isEchoCancellationOn &&
            (removedNames.contains(selectedSpeakerItem.title) ||
             removedNames.contains(selectedMicItem.title))
            
            guard isNeedHandleNR || isNeedHandleEC else { return }
            
            if isNeedHandleNR {
                
                toggleView.isNoiseReductionOn.toggle()
                
                toggleView.turnOffNRSwitch()
            }
            
            if isNeedHandleEC {
                
                toggleView.isEchoCancellationOn.toggle()
                
                toggleView.turnOffECSwitch()
            }
            
            AlertGenerator.launchAlertInMainThread(with: "The speaker/mic is changed please choose your speaker/mic and restart the noise reduction/echo cancellation")
            
        }
        
    }
    
    // MARK: - Get menu item index
    private func getIndexTuple(of type: ListType) -> (titleIndex: Int, endSeparatorIndex: Int) {
        
        enum MenuTitleType: String {
            case Speaker
            case SpeakerEndSeparator
            case Microphone
            case MicrophoneEndSeparator
        }
        
        func getMenutItemIndex(title: MenuTitleType) -> Int {
            
            guard let menu = menu else { fatalError() }
            
            let itemIndex = menu.indexOfItem(withTitle: title.rawValue)
            
            guard itemIndex != -1 else {
                fatalError("MenuItem title not found.")
            }
            
            return itemIndex
            
        }
        
        switch type {
        case .SPK:
            return (getMenutItemIndex(title: .Speaker), getMenutItemIndex(title: .SpeakerEndSeparator))
        case .MIC:
            return (getMenutItemIndex(title: .Microphone), getMenutItemIndex(title: .MicrophoneEndSeparator))
        }
    }
    
    private func getSelectedIndex(of type: ListType) -> Int32? {
        
        let indexTuple = self.getIndexTuple(of: type)
        
        guard let formerlySelectedTitle = self.getFormerlySelectedTitle(from: indexTuple.titleIndex,
                                                                        to: indexTuple.endSeparatorIndex)
        else { return nil }
        
        let list = self.getList(of: type)
        
        guard let selectedIndex = list.firstIndex(of: formerlySelectedTitle) else { return nil }
        
        return Int32(selectedIndex)
        
    }
    
    // MARK: - Read formerly selection
    private func getFormerlySelectedTitle(from: Int, to: Int) -> String? {
        
        guard let menu = menu else { return nil }
        
        let itemsInRange = menu.items.filter({ from ..< to ~= menu.index(of: $0) })
        
        guard let priorSelectedItem = itemsInRange.filter({ $0.state == .on }).first else { return nil }
        
        return priorSelectedItem.title
    }
    
}

extension MenuHandler: NSMenuDelegate {
    
    func menuWillOpen(_ menu: NSMenu) {
        
        self.menu = menu
        
        self.reloadLists()
        
        self.refreshMenuItemsState()
        
        self.checkIsListEmpty()
        
        self.addToggleObservations()
        
    }
    
}
