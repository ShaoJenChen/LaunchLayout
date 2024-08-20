//
//  Observable.swift
//  MeetingTool
//
//  Created by 陳劭任 on 2022/7/16.
//

import Foundation

typealias ListenerClosure = @convention(block) (_ T: AnyObject?, _ O: AnyObject?) -> ()

class Observable<T: AnyObject> {

    var value: T? {
        
        didSet {
            
            self.listeners.forEach({ unsafeBitCast($0, to: ListenerClosure.self)(value, oldValue) })
            
        }
        
    }
    
    private var listeners: [AnyObject] = []
    
    init(_ value: T?) {
        
        self.value = value
        
    }
    
    func bind(_ listener: @escaping ListenerClosure, isCallImmediately: Bool = false) {
        
        let anyObject = unsafeBitCast(listener, to: AnyObject.self)
        
        self.listeners.append(anyObject)
        
        if isCallImmediately {
            
            self.listeners.forEach({ unsafeBitCast($0, to: ListenerClosure.self)(value, nil) })
            
        }
        
    }

    func unbind(_ listener: @escaping ListenerClosure) {

        let anyObject = unsafeBitCast(listener, to: AnyObject.self)
                
        self.listeners.removeAll(where: { $0 === anyObject })
        
    }
    
}
