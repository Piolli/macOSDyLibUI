//
//  macosDyLib.swift
//  macosDyLib
//
//  Created by Alexandr on 09.10.2019.
//  Copyright © 2019 Alexandr. All rights reserved.
//

import Foundation
import Cocoa
import SwiftUI

let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 50))
var multiplyFromTextField: Double = 0 {
    didSet {
        print("did set mult: \(multiplyFromTextField)")
    }
}
var onQueueAdding: (() -> Void)?
var outputTextView: NSTextView!
var inputTextView: NSTextView!

@_cdecl("getInfo")
public func getInfo() -> [String: String] {
    return [
        "author": "sanya",
        "description": "sort array",
        "version": "1.1"
    ]
}

@_cdecl("perform")
public func perform(source: [Double]) -> [Double] {
    let result = source.map { $0 * multiplyFromTextField }
    
    return result
}

private func invokePerform(mult: Double = multiplyFromTextField) {
    let input = inputTextView.string
        .components(separatedBy: " ")
        .map { (item) -> Double in
            return Double(item)!
        }
    
    let output = input
        .map({ $0 * mult })
        .map({ String($0) })
    
    outputTextView.string = output.joined(separator: " ")
    
    print("invokePerform called with mult: \(mult) input: \(input)")
}

@_cdecl("getPerformForQueue")
public func getPerformForQueue() -> (() -> Void) {
    performButtonWasTapped(nil)
    let extractedMult = Double(textField.cell!.title)!
    return { invokePerform(mult: extractedMult) }
}

@_cdecl("setOutput")
public func setOutput(textView: NSTextView) {
    outputTextView = textView
}

@_cdecl("setInput")
public func setInput(textView: NSTextView) {
    inputTextView = textView
}

class ObserveValue : NSObject, NSTextFieldDelegate {
    
    let changedText: (Double) -> Void
    
    init(changedText: @escaping (Double) -> Void) {
        self.changedText = changedText
    }
    
    func controlTextDidChange(_ obj: Notification) {
//        if let textField = obj.object as? NSTextField {
        let text = (obj.object as! NSTextField).cell?.title
            changedText(Double(text!)!)
//        }
    }
}

func performButtonWasTapped(_ sender: NSButton?) {
    multiplyFromTextField = Double(textField.cell!.title)!
}

class ButtonSelector {
    
    let callback: () -> Void
    
    init(button: NSButton, callback: @escaping () -> Void) {
        self.callback = callback
        button.target = self
        button.action = #selector(performFunc(_:))
    }
    
    @objc func performFunc(_ sender: NSButton) {
        callback()
    }
}

var performButtonSelector: ButtonSelector?
var getPerformForQueueButtonSelector: ButtonSelector?

@_cdecl("getView")
public func getView() -> NSView {
//    let observeTF = ObserveValue { (newMult) in
//        multiplyFromTextField = newMult
//        print("new mult: \(multiplyFromTextField)")
//    }
    
    //--------------------------
    let performButton = NSButton()
    performButton.title = "Perform"
    performButton.frame = CGRect(x: 0, y: 50, width: 100, height: 25)
    
    performButtonSelector = ButtonSelector(button: performButton, callback: {
        multiplyFromTextField = Double(textField.cell!.title)!
        print("new mult: \(multiplyFromTextField)")
        invokePerform()
    })
    
    //---------------------
    
//    let queueButton = NSButton()
//    queueButton.title = "Perform"
//    queueButton.frame = CGRect(x: 100, y: 50, width: 100, height: 25)
//
//    getPerformForQueueButtonSelector = ButtonSelector(button: queueButton, callback: {
//        queueCallback(getPerformForQueue())
//    })
//
    //---------------------
//    textField.delegate = observeTF
    
    let myView = NSView(frame: NSRect(x: 200, y: 200, width: 100, height: 20))
    myView.addSubview(performButton)
//    myView.addSubview(queueButton)
    myView.addSubview(textField)
    
    return myView
}
