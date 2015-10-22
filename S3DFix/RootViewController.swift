//
//  RootViewController.swift
//  S3DFix
//
//  Created by LEON GROSSMAN on 10/17/15.
//  Copyright © 2015 LEON GROSSMAN. All rights reserved.
//

//This is currently very, very slow - 2015-10-21
import Cocoa

class RootViewController: NSViewController {

    @IBOutlet weak var labelStatus: NSTextField!
    @IBOutlet weak var txtXYRes: NSTextField!
    @IBOutlet weak var txtERes: NSTextField!
    
    let S3DParse = ProcessFileModel(resolutionThreshold: 0.01, extrusionThreshold: 0.001)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
 
    
    @IBAction func processFile(sender: AnyObject) {
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let fileName = openFile()
        
        if fileName != nil {
            labelStatus.stringValue = "Processing \(fileName!)"
            
            S3DParse.resolutionThreshold = txtXYRes.floatValue
            S3DParse.extrusionThreshold = txtERes.floatValue
            
            let result = S3DParse.Process(fileName!)
            let endTime = CFAbsoluteTimeGetCurrent()
            let runTime:Float = Float(endTime - startTime)
            labelStatus.stringValue = result + " in \(runTime.string(1)) seconds"
        } else {
            labelStatus.stringValue = "Please select a valid file to process"
        }
    }
    
    
    override func awakeFromNib() {
        txtXYRes.floatValue = 0.01
        txtERes.floatValue = 0.001
        
    }
    
    func openFile() -> String? {
        
        let myFileDialog: NSOpenPanel = NSOpenPanel()
        myFileDialog.runModal()
        
        // Get the path to the file chosen in the NSOpenPanel
        let path = myFileDialog.URL?.path
        return path
        
        // Make sure that a path was chosen
        
        
    }
}

//Format float values into strings
//http://stackoverflow.com/questions/24051314/precision-string-format-specifier-in-swift
extension Float {
    func string(fractionDigits:Int) -> String {
        let formatter = NSNumberFormatter()
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        return formatter.stringFromNumber(self) ?? "\(self)"
    }
}

