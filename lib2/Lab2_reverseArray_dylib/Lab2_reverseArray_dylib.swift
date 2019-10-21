//
//  Lab2_reverseArray_dylib.swift
//  Lab2_reverseArray_dylib
//
//  Created by Alexandr on 13.10.2019.
//  Copyright © 2019 Alexandr. All rights reserved.
//

import Foundation

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

let switchView = NSSwitch(frame: NSRect(x: 0, y: 0, width: 200, height: 50))

var isReverseState: NSControl.StateValue = .off {
    didSet {
        print("did set isReverse: \(isReverseState)")
    }
}
var outputTextView: NSTextView!
var inputTextView: NSTextView!

@_cdecl("getInfo")
public func getInfo() -> [String: String] {
    return [
        "author": "sanya",
        "description": "reverse array",
        "version": "1.0"
    ]
}

private func invokePerform(reverse: NSControl.StateValue = isReverseState) {
    let input = inputTextView.string
        .components(separatedBy: " ")
        .map { (item) -> Double in
            return Double(item)!
        }
    
    let output: [Double] = reverse == .on ? input.reversed() : input
    
    outputTextView.string = output.map({ String($0) }).joined(separator: " ")
    
    print("invokePerform called with reverse: \(reverse) input: \(input)")
}

@_cdecl("getPerformForQueue")
public func getPerformForQueue() -> (() -> Void) {
    performButtonWasTapped(nil)
    let captured = switchView.state
    return { invokePerform(reverse: captured) }
}

@_cdecl("setOutput")
public func setOutput(textView: NSTextView) {
    outputTextView = textView
}

@_cdecl("setInput")
public func setInput(textView: NSTextView) {
    inputTextView = textView
}

func performButtonWasTapped(_ sender: NSButton?) {
    isReverseState = switchView.state
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
    
    let performButton = NSButton()
    performButton.title = "Perform"
    performButton.frame = CGRect(x: 0, y: 50, width: 100, height: 25)
    
    performButtonSelector = ButtonSelector(button: performButton, callback: {
        performButtonWasTapped(nil)
        invokePerform()
    })
    
    let myView = NSView(frame: NSRect(x: 200, y: 200, width: 100, height: 20))
    myView.addSubview(performButton)
    myView.addSubview(switchView)
    
    return myView
}
