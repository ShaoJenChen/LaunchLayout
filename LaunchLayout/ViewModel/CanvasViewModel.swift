//
//  CanvasViewModel.swift
//  TestMouseEvent
//
//  Created by 陳劭任 on 2022/6/14.
//

import Foundation
import AppKit

typealias ViewModelProtocols = LaunchConverter & MeetingDataHandler & CanvasViewDataSource & ObserveProtocol & CanvasViewDelegate & MeetingRecordDataSource & MeetingRecordDelegate

protocol MeetingDataHandler {
        
    func clearSavingData()
    
    func save()
}

protocol MeetingRecordDataSource {
    
    func numberOfMeetingRecord() -> Int?
    
    func meetingNameOf(index: Int) -> String?
    
}

protocol MeetingRecordDelegate {
    
    func addNewMeetingRecord()
    
    func removeMeetingRecord(of index: Int)
    
    func duplicateMeetingRecord(by index: Int)
    
    func rearrangedMeetingRecord(from: Int, to: Int)
    
    func modifyMeetingRecord(name: String, of index: Int)
    
}

protocol LaunchConverter {
        
    func convert(canvasView: CanvasView, screenIndex: Int) -> [VSLaunchObject]?
    
}

protocol CanvasConverter {
    
    func convert(canvas: Canvas) -> CanvasView
    
    func convert(canvasView: CanvasView) -> Canvas
    
}

protocol ObserveProtocol {
    
    var currentUUID: Observable<NSUUID> { get }
        
    var simpleObserveCanvas: Observable<NSNull> { get }
    
    func observeMeetingList(_ selectedMeetingRecordIndex: Observable<NSNumber>?)
    
    var canvasSelection: Observable<NSNumber> { get }
    
    func observeScreenList(_ selectedCanvasIndex: Observable<NSNumber>?)
    
    var meetingRecordCount: Observable<NSNumber> { get }
    
}

protocol CanvasViewDataSource {
    
    func currentRecordCanvasViews() -> [CanvasView]?
    
    func canvasViews(recordUUID: UUID) -> [CanvasView]?
    
}

protocol CanvasViewDelegate {
    
    func addNewCanvasToCurrentRecord(_ completion: ((CanvasView) -> Void) )
        
    func removeCanvasFromCurrentRecord(index: Int, _ completion: (() -> ()))
    
    func rearrangedCanvasViews(from: Int, to: Int)
    
    func editCanvasName(of index: Int, newName: String)
}

fileprivate let MeetingDataKeyValue = "MeetingDatas"

class CanvasViewModel: ObserveProtocol {
    
    var currentUUID: Observable<NSUUID> = Observable(nil)
    
    var simpleObserveCanvas: Observable<NSNull> = Observable(nil)
    
    var canvasSelection: Observable<NSNumber> = Observable(nil)
    
    var meetingRecordCount: Observable<NSNumber> = Observable(nil)
    
    private var currentRecord: MeetingRecord? {
        get {
            
            guard let currentUUID = self.currentUUID.value as? UUID else { return nil }
            
            guard let meetingRecord = self.meetingRecords.first(where: { $0.uuid == currentUUID }) else { return nil }
            
            return meetingRecord
            
        }
    }
    
    private var meetingRecords = [MeetingRecord]() {
        didSet {
            
            self.meetingRecordCount.value = NSNumber(value: meetingRecords.count)
            
        }
    }
    
    private var meetingData: MeetingData? {
        didSet {
            
            guard let meetingData = self.meetingData else { return }
            
            if meetingData.versionCode < Bundle.main.appVersionLong {
                //need data migration
            }
            
            self.meetingRecords = meetingData.meetings.map({ meeting -> MeetingRecord in
                
                let canvasViews = meeting.canvases.map({
                    //don't care default size, canvas view will auto resize
                    self.convert(canvas: $0)
                    
                })
                
                return MeetingGenerator.generateMeeting(uuid: meeting.uuid,
                                                        name: meeting.meetingName,
                                                        timeStamp: meeting.timeStamp,
                                                        canvasViews: canvasViews)
                
            })
            
        }
    }
    
    init() {
        
        self.loadDataFromUserDefault()

        self.setViewModelToAppDelegate()
        
    }
    
    private func loadDataFromUserDefault() {
        
        guard let meetingDatas = UserDefaults.standard.string(forKey: MeetingDataKeyValue)?.data(using: .utf8) else { return }
        
        let jsonDecoder = JSONDecoder()

        jsonDecoder.dateDecodingStrategy = .secondsSince1970

        do {
            
            self.meetingData = try jsonDecoder.decode(MeetingData.self, from: meetingDatas)
                        
        } catch let decodeError {
            
            fatalError("\(decodeError)")
            
        }
        
    }
    
    //ObserveProtocol
    func observeMeetingList(_ selectedMeetingRecordIndex: Observable<NSNumber>?) {
        selectedMeetingRecordIndex?.bind { [weak self] (value, oldValue) in
            
            guard let self = self else { return }
            
            var selectedUUID: NSUUID?
            
            if let selectedIndex = value as? Int {
                
                guard 0 ..< self.meetingRecords.count ~= selectedIndex else { return }
                
                selectedUUID = self.meetingRecords[selectedIndex].uuid as NSUUID
                
            }
            
            self.currentUUID.value = selectedUUID
        }
        
    }
    
    func observeScreenList(_ selectedCanvasIndex: Observable<NSNumber>?) {
        selectedCanvasIndex?.bind({ [weak self] (value, oldValue) in
            
            guard let self = self else { return }
            
            guard let selectedIndex = value as? NSNumber else { return }
            
            self.canvasSelection.value = selectedIndex
            
        })
        
    }
    //ObserveProtocol End
    
    private func setViewModelToAppDelegate() {
        
        guard let appdelegate = NSApplication.shared.delegate as? AppDelegate else { return }
        
        appdelegate.meetingDataHandler = self
        
    }
    
}

extension CanvasViewModel: LaunchConverter {
    
    func convert(canvasView: CanvasView, screenIndex: Int) -> [VSLaunchObject]? {
        
        let canvas = self.convert(canvasView: canvasView)
        
        guard 0 ..< NSScreen.screens.count ~= screenIndex else { return nil }
        
        let screen = NSScreen.screens[screenIndex]
        
        let screenHeight = screen.frame.height - NSStatusBar.system.thickness
        
        let vsLaunchObjects = canvas.launchObjects.compactMap { layoutObject -> VSLaunchObject? in
            
            let size = CGSize(width: CGFloat(layoutObject.widthRatio) * screen.frame.width,
                              height: CGFloat(layoutObject.heightRatio) * screenHeight)
            
            let xPoint = screen.frame.origin.x + CGFloat(layoutObject.leftPaddingRatio) * screen.frame.width
            
            let topPaddingDistance: CGFloat = CGFloat(layoutObject.topPaddingRatio) * screenHeight + NSStatusBar.system.thickness
            
            //The screen containing the menu bar is always the first object (index 0) in the array returned by the screens method.
            let apiAxisY: CGFloat = NSScreen.screens[0].frame.maxY
            
            let topBorderOfScreen = screen.frame.maxY
            
            let yOffSet = topBorderOfScreen > apiAxisY ? apiAxisY - topBorderOfScreen : abs(topBorderOfScreen - apiAxisY)
            
            let yPoint = yOffSet + topPaddingDistance
            
            let originPoint = CGPoint(x: xPoint, y: yPoint)
            
            guard let metaDataItem = getMDItem(with: layoutObject.applicationPath) else { return nil }
            
            return VSLaunchObject(filePath: layoutObject.filePath,
                                  size: size,
                                  position: originPoint,
                                  application: metaDataItem)
            
        }
        
        return vsLaunchObjects
        
    }
    
}

extension CanvasViewModel: CanvasConverter {
    
    func convert(canvas: Canvas) -> CanvasView {
        
        func convert(launchObject: LaunchObject, superViewFrame: CGRect) -> LayoutObjectRectangle {
            
            let layoutObjectWidth = superViewFrame.width * CGFloat(launchObject.widthRatio)
            
            let layoutObjectHeight = superViewFrame.height * CGFloat(launchObject.heightRatio)
            
            let layoutObjectX = superViewFrame.width * CGFloat(launchObject.leftPaddingRatio)
            
            let layoutObjectY =
            superViewFrame.height - (superViewFrame.height * CGFloat(launchObject.topPaddingRatio)) - layoutObjectHeight
            
            let layoutObjectFrame = CGRect(x: layoutObjectX,
                                           y: layoutObjectY,
                                           width: layoutObjectWidth,
                                           height: layoutObjectHeight)
            
            return LayoutObjectRectangle(appPath: launchObject.applicationPath,
                                         filePath: launchObject.filePath,
                                         frame: layoutObjectFrame)
            
        }
        
        let canvasView = CanvasGenerator.generateCanvasView(name: canvas.canvasName,
                                                            viewModel: self)
        
        let layoutObjectRectangles = canvas.launchObjects.map({
            convert(launchObject: $0, superViewFrame: canvasView.frame)
        })
        
        layoutObjectRectangles.forEach({
            
            canvasView.addSubview($0)
            
            canvasView.addObjectConstraint(object: $0)
            
        })
        
        return canvasView
    }
    
    func convert(canvasView: CanvasView) -> Canvas {
        
        func convert(layoutObjectRectangle: LayoutObjectRectangle, superViewFrame: CGRect) -> LaunchObject {
            
            let leftPaddingRatio = layoutObjectRectangle.frame.minX / superViewFrame.width
            
            let topPaddingRatio = (superViewFrame.height - layoutObjectRectangle.frame.maxY) / superViewFrame.height
            
            let widthRatio = layoutObjectRectangle.frame.width / superViewFrame.width
            
            let heightRatio = layoutObjectRectangle.frame.height / superViewFrame.height
            
            return LaunchObject(applicationPath: layoutObjectRectangle.appPath ?? "",
                                filePath: layoutObjectRectangle.filePath ?? "",
                                leftPaddingRatio: Float(leftPaddingRatio),
                                topPaddingRatio: Float(topPaddingRatio),
                                widthRatio: Float(widthRatio),
                                heightRatio: Float(heightRatio))
            
        }
        
        let layoutObjectRectangles = canvasView.subviews.filter({ $0 is LayoutObjectRectangle }) as! [LayoutObjectRectangle]
        
        let layoutObjects = layoutObjectRectangles.map({
            convert(layoutObjectRectangle: $0, superViewFrame: canvasView.frame)
        })
        
        let canvas = Canvas(canvasName: canvasView.name,
                            launchObjects: layoutObjects)
        
        return canvas
    }
    
}

extension CanvasViewModel: MeetingDataHandler {

    func clearSavingData() {
        
        UserDefaults.standard.clearData()
        
    }
    
    func save() {
        
        let meetings = self.meetingRecords.map({ meetingRecord -> Meeting in
            
            let canvases = meetingRecord.canvasViews.map({ self.convert(canvasView: $0) })
            
            return Meeting(uuid: meetingRecord.uuid,
                           meetingName: meetingRecord.meetingName,
                           timeStamp: meetingRecord.timeStamp,
                           canvases: canvases)
            
        })
        
        let meetingData = MeetingData(meetings: meetings, versionCode: Bundle.main.appVersionLong)
        
        let jsonEncoder = JSONEncoder()
        
        jsonEncoder.outputFormatting = .prettyPrinted
        
        jsonEncoder.dateEncodingStrategy = .secondsSince1970
                
        guard let jsonData = try? jsonEncoder.encode(meetingData) else { return }
        
        let jsonString = String(data: jsonData, encoding: .utf8)
        
        UserDefaults.standard.setValue(jsonString, forKey: MeetingDataKeyValue)
        
        UserDefaults.standard.synchronize()
        
    }
    
}

extension CanvasViewModel: MeetingRecordDataSource {
    
    func numberOfMeetingRecord() -> Int? {
        
        return self.meetingRecords.count
        
    }
    
    func meetingNameOf(index: Int) -> String? {
        
        guard 0 ..< self.meetingRecords.count ~= index else { return nil }
        
        return self.meetingRecords[index].meetingName
        
    }
    
}

extension CanvasViewModel: MeetingRecordDelegate {
    
    func addNewMeetingRecord() {
        
        let existMeetingNames = self.meetingRecords.map({ $0.meetingName })
        
        let newCanvasView = CanvasGenerator.generateCanvasView(viewModel: self)
        
        let newMeeting = MeetingGenerator.generateMeeting(existNames: existMeetingNames,
                                                          canvasViews: [newCanvasView])
        
        self.meetingRecords.insert(newMeeting, at: 0)
        
    }
    
    func removeMeetingRecord(of index: Int) {
        
        self.meetingRecords.remove(at: index)
        
    }
    
    func duplicateMeetingRecord(by index: Int) {
        
        guard 0 ..< self.meetingRecords.count ~= index else { return }
        
        let meetingRecord = self.meetingRecords[index]
        
        let existMeetingNames = self.meetingRecords.map({ $0.meetingName })
        
        let newCanvasViews = meetingRecord.canvasViews.map({
            
            CanvasGenerator.generateCanvasView(duplicateCanvasView: $0)
            
        })
        
        let newMeeting = MeetingGenerator.generateMeeting(existNames: existMeetingNames,
                                                          canvasViews: newCanvasViews)
        
        self.meetingRecords.insert(newMeeting, at: index)
        
    }
    
    func rearrangedMeetingRecord(from: Int, to: Int) {
        
        let reorderedRecords = self.reorder(array: self.meetingRecords, from: from, to: to)
        
        self.meetingRecords = reorderedRecords
        
    }
    
    func modifyMeetingRecord(name: String, of index: Int) {
        
        guard 0 ..< self.meetingRecords.count ~= index else { return }
        
        self.meetingRecords[index].meetingName = name
        
    }
    
}

extension CanvasViewModel: CanvasViewDataSource {
    
    func currentRecordCanvasViews() -> [CanvasView]? {
        
        return self.currentRecord?.canvasViews
        
    }
    
    func canvasViews(recordUUID: UUID) -> [CanvasView]? {
        
        guard let meetingRecords = self.meetingRecords.first(where: { $0.uuid == recordUUID }) else { return nil }
        
        return meetingRecords.canvasViews
        
    }
    
}

extension CanvasViewModel: CanvasViewDelegate {
    
    func addNewCanvasToCurrentRecord(_ completion: ((CanvasView) -> Void)) {
        
        guard let meetingRecord = self.currentRecord else { return }
        
        let existCanvasNames = meetingRecord.canvasViews.map({ $0.name })
        
        let newCanvasView = CanvasGenerator.generateCanvasView(existNames: existCanvasNames,
                                                               viewModel: self)
        
        meetingRecord.canvasViews.append(newCanvasView)
        
        self.simpleObserveCanvas.value = NSNull()
        
        completion(newCanvasView)
    }
    
    func removeCanvasFromCurrentRecord(index: Int, _ completion: (() -> ())) {
        
        guard let meetingRecord = self.currentRecord else { return }
        
        guard meetingRecord.canvasViews.count > 1 else { return }
        
        meetingRecord.canvasViews.remove(at: index)
        
        self.simpleObserveCanvas.value = NSNull()
        
        completion()
    }
    
    func rearrangedCanvasViews(from: Int, to: Int) {
        
        guard let currentCanvasViews = self.currentRecordCanvasViews() else { return }
        
        let resultCanvasViews = self.reorder(array: currentCanvasViews, from: from, to: to)
        
        guard let meetingRecord = self.currentRecord else { return }
        
        meetingRecord.canvasViews = resultCanvasViews
        
        self.simpleObserveCanvas.value = NSNull()
    }
    
    func editCanvasName(of index: Int, newName: String) {
        
        guard let currentCanvasViews = self.currentRecordCanvasViews() else { return }
        
        guard 0 ..< currentCanvasViews.count ~= index else { return }
        
        currentCanvasViews[index].name = newName
        
        self.simpleObserveCanvas.value = NSNull()
    }
    
}

extension CanvasViewModel {
    
    func reorder<T>(array: [T], from: Int, to: Int) -> [T] {
        
        guard 0 ..< array.count ~= from else { return [T]() }
        
        guard 0 ..< array.count ~= to else { return [T]() }
        
        let lowerBound = min(from, to)
        
        let upperBound = max(from, to)
        
        let range = Range(lowerBound ... upperBound)
        
        let meetingRecordForShift = Array(array[range])
        
        let shiftDistance = to > from ? 1 : -1
        
        let shiftedArray = meetingRecordForShift.shift(withDistance: shiftDistance)
        
        var resultArray = Array(array)
        
        resultArray.replaceSubrange(range, with: shiftedArray)
        
        return resultArray
    }
    
}
