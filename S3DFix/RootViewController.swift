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
    
    let S3DParse = ProcessFileModel(resolutionThreshold: 0.01, extrusionThreshold: 0.001)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
 
    
    @IBAction func processFile(sender: AnyObject) {
        
        let fileName = openFile()
        
        if fileName != nil {
            labelStatus.stringValue = "Processing \(fileName!)"
            
            
            let result = S3DParse.Process(fileName!)
            //let result = fix.Process(fileName!)
            labelStatus.stringValue = result
        } else {
            labelStatus.stringValue = "Please select a valid file to process"
        }
    }
    
    
    override func awakeFromNib() {
        //labelStatus.stringValue = "Test"
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
