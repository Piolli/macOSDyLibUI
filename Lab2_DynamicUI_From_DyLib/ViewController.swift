//
//  ViewController.swift
//  Lab2_DynamicUI_From_DyLib
//
//  Created by Alexandr on 13.10.2019.
//  Copyright © 2019 Alexandr. All rights reserved.
//

import Cocoa

typealias getView = @convention(c) () -> NSView
typealias getInfo = @convention(c) () -> [String: String]
typealias perform = @convention(c) ([Double]) -> [Double]

typealias setOutput = @convention(c) (NSTextView) -> Void
typealias setInput = @convention(c) (NSTextView) -> Void

typealias getPerformForQueue = @convention(c) () -> (() -> Void)

class ViewController: NSViewController {
    
    let appName = "Lab2_DynamicUI_From_DyLib.app"
    
    var buttonsSelector: [ButtonSelector] = []
    var performQueue: [() -> Void] = []
    
    @IBOutlet var inputTextView: NSTextView!
    @IBOutlet var outputTextView: NSTextView!
    @IBOutlet var logTextView: NSTextView!
    
    @IBOutlet weak var containerView: NSStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let libs = getDyLibNamesInAppFolder()
        plog(libs)
        
        for liba in libs {
            let gotView = loadDyLibView(path: liba)
            containerView.addArrangedSubview(gotView)
        }
    }

    func plog<T : CustomDebugStringConvertible>(_ str: T) {
        logTextView.string.append(str.debugDescription)
        logTextView.string.append("\n\n")
        logTextView.scrollToEndOfDocument(nil)
        
        print(str.debugDescription)
        print("\n\n")
    }
    
    @IBAction func addToQueue(_ sender: NSButton) {
        performQueue.removeAll()
    }
    
    @IBAction func performQueue(_ sender: NSButton) {
        let savedInput = inputTextView.string
        
        for i in 0..<performQueue.count {
            if i == 0 {
                performQueue[i]()
            } else {
                inputTextView.string = outputTextView.string
                performQueue[i]()
            }
        }
        
        inputTextView.string = savedInput
        
        plog("Queue was performed with \(performQueue.count) items")
        performQueue.removeAll()
    }
}

//MARK: - work with dylib
extension ViewController {
    
    @objc func callbackForPerform(items: [Double]) -> Void {
        self.outputTextView.string = items.description
    }
    
    func loadDyLibView(path: String) -> NSView {
        if let handle = dlopen(path, RTLD_NOW | RTLD_GLOBAL) {
            
            plog(getInfoAbout(dyLib: handle))
            
            if let sym = dlsym(handle, "setOutput") {
                let f = unsafeBitCast(sym, to: setOutput.self)
                f(outputTextView)
            }
            
            if let sym = dlsym(handle, "setInput") {
                let f = unsafeBitCast(sym, to: setInput.self)
                f(inputTextView)
            }
            
            if let sym = dlsym(handle, "getView") {
                let f = unsafeBitCast(sym, to: getView.self)
                let box = f()
                let receivedView = box
                
                let queueButton = NSButton()
                queueButton.title = "Add to Queue"
                queueButton.frame = CGRect(x: 100, y: 50, width: 100, height: 25)
            
                let selector = ButtonSelector(button: queueButton, callback: {
                    if let sym = dlsym(handle, "getPerformForQueue") {
                        let f = unsafeBitCast(sym, to: getPerformForQueue.self)
                        self.performQueue.append(f())
                    } else {
                        self.plog("getPerformForQueue ERROR")
                    }
                    if let error = dlerror() {
                        print(String(cString: error))
                        self.plog(String(cString: error) + "\n")
                    }
                })
                
                buttonsSelector.append(selector)
                
                receivedView.addSubview(queueButton)
                
                return receivedView
            }
             
            if let error = dlerror() {
                print(String(cString: error))
                plog(String(cString: error) + "\n")
            }

            dlclose(handle)
        } else {
            plog("handle is null")
        }
        if let error = dlerror() {
            print(String(cString: error))
            plog(String(cString: error) + "\n")
        }
        return NSView()
    }
    
    func getInfoAbout(dyLib: UnsafeMutableRawPointer) -> [String: String] {
        if let sym = dlsym(dyLib, "getInfo") {
            let f = unsafeBitCast(sym, to: getInfo.self)
            return f()
        }
        return [:]
    }
    
    func getDyLibNamesInAppFolder() -> [String] {
        var dylibs: [String] = []
        let fileManager = FileManager.default
        
        var path = Bundle.main.bundlePath.replacingOccurrences(of: appName, with: "")
        let enumerator: FileManager.DirectoryEnumerator = fileManager.enumerator(atPath: path)!
        
        while let element = enumerator.nextObject() as? String {
            if element.hasSuffix(".dylib") {
                dylibs.append(element)
            }
        }
        
        return dylibs
    }
    
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


