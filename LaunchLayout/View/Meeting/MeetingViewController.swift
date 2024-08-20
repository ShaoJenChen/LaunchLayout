//
//  MeetingGroupsViewController.swift
//  MeetingTool
//
//  Created by 陳劭任 on 2022/7/14.
//

import Cocoa

class MeetingViewController: NSViewController {
    
    @IBOutlet var addMeetingBtn: NSButton!
    
    @IBOutlet var meetingRecordContainer: NSView!
    
    var meetingRecordDataSource: (MeetingRecordDataSource & ObserveProtocol)?
    
    var meetingRecordDelegate: MeetingRecordDelegate?
    
    var selectedMeetingRecordIndex: Observable<NSNumber>? = Observable(nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        self.initMeetingCollectionViewController()
        
        self.setupMeetingBtn()
        
    }
    
    private func initMeetingCollectionViewController() {
        
        let meetingCollectionViewController = NSStoryboard.main?.instantiateController(withIdentifier: "MeetingCollectionViewController") as! MeetingCollectionViewController
        
        self.addChild(meetingCollectionViewController)
        
        meetingCollectionViewController.view.frame = self.meetingRecordContainer.bounds
        meetingCollectionViewController.view.autoresizingMask = [.height, .width]
        
        self.meetingRecordContainer.addSubview(meetingCollectionViewController.view)
        
    }
    
    private func setupMeetingBtn() {
        
        self.addMeetingBtn.wantsLayer = true
        
        self.addMeetingBtn.layer?.backgroundColor = NSColor(hex: 0x6A8AA5).cgColor
        
        self.addMeetingBtn.layer?.cornerRadius = 8.0
        
    }
    
    @IBAction func addNewMeeting(_ sender: NSButton) {
        
        self.meetingRecordDelegate?.addNewMeetingRecord()
        
        guard let meetingCollectionViewController = self.children.first(where: { $0 is MeetingCollectionViewController }) as? MeetingCollectionViewController else { return }
        
        meetingCollectionViewController.meetingCollectionView.reloadData()
        
        meetingCollectionViewController.meetingCollectionView.selectionIndexPaths = [IndexPath(item: 0, section: 0)]
        
        self.selectedMeetingRecordIndex?.value = NSNumber(value: 0)
        
    }
    
}
