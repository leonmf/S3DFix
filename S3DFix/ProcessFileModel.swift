//
//  ProcessFile.swift
//  S3DFix
//
//  Created by LEON GROSSMAN on 10/17/15.
//  Copyright © 2015 LEON GROSSMAN. All rights reserved.
//

import Foundation

class ProcessFileModel {
    
    //var fileName:String
    var resolutionThreshold:Float
    var extrusionThreshold:Float
    
    var resThresh:Float {
        get {
            return resolutionThreshold
        }
        set {
            resolutionThreshold = newValue
        }
    }
    var extThresh:Float {
        get {
            return extrusionThreshold
        }
        set {
            extrusionThreshold = newValue
        }
    }

    init() {
        self.resolutionThreshold = 0.01
        self.extrusionThreshold = 0.0005
    }
    
    init(resolutionThreshold:Float, extrusionThreshold:Float) {
        self.resolutionThreshold = resolutionThreshold
        self.extrusionThreshold = extrusionThreshold
    }

    

    func startsWith(s:String, prefix:String) -> Bool {
        var result:Bool = false
        
        //if s.characters.count >= prefix.characters.count {
        //    let strSub = s.substringWithRange(s.startIndex.advancedBy(0)...s.startIndex.advancedBy(prefix.characters.count-1))
        //    result = (strSub == prefix)
        //}
        
        result = (s.characters.count >= prefix.characters.count && s.hasPrefix(prefix))

        return result
    
    }

    func find_first_not_of(var i:Int, searchString:String, keyString:String) -> Int {
        //Create an array of charactes in the string to search
        let chars = searchString.characters.map{ String($0) }
        //Counterintuitively, we're going to search the key
        var searchIndex = keyString.characters.indexOf(Character(chars[i]))
        while (searchIndex != nil && i<chars.count-1) {
            i++
            searchIndex = keyString.characters.indexOf(Character(chars[i]))
        }
        
        if(searchIndex != nil && i == chars.count - 1) {
            i++
        }
        return i
    }
    
    func getEndIdx(i:Int, searchString:String) -> Int {
        
        let strSub = searchString.substringFromIndex(searchString.startIndex.advancedBy(i))
        let iEnd = strSub.characters.indexOf(" ")
        if iEnd==nil {
            return searchString.characters.count
        } else {
            let iE = strSub.startIndex.distanceTo(iEnd!)
            let iCum = i + iE
            //print(iCum)
            return iCum
        }
        
    }
    
    func getParameter(s:String,c:Character) -> (found:Bool, result:Float) {
        //Get the index of the desired search character
        let i = s.characters.indexOf(c)
        //If we found the search character, extract the float value
        if i != nil {
            
            //We're basically searching for the first non-numeric character.
            //The index found by the indexof is not actually an integer.
            //This is probably because of double byte character sets.
            //We have to convert the string index into an actual index.
            var index = s.startIndex.distanceTo(i!)
            //We wish to start searching at the next character
            index += 1
            //Find the first character not part of a number
            //let endIndex = find_first_not_of(index, searchString: s, keyString: k)
            //Running this way takes 86% of the time it takes to do the proper way
            let endIndex = getEndIdx(index, searchString: s)
            
            //let endIndex = find_first_not_of(index, searchString: s, keyString: "01234567890.")
            let strValue = s.substringWithRange(s.startIndex.advancedBy(index)..<s.startIndex.advancedBy((endIndex)))
            
            if (Float(strValue) != nil) {
                let val = Float(strValue)!
                return (true , val)
            } else {
                return (false, 0)
            }
        } else {
            //We didn't find the search character
            return (false,0)
        }
        
    }
    
    func xyDistance(a:String, b:String) -> Float {
        
        let aX = getParameter(a, c: "X")
        if (!aX.found) {return -1}
        
        let aY = getParameter(a, c: "Y")
        if (!aX.found) {return -1}
        
        let bX = getParameter(b, c: "X")
        if (!aX.found) {return -1}
        
        let bY = getParameter(b, c: "Y")
        if (!aX.found) {return -1}
        
        let dX = bX.result - aX.result
        let dY = bY.result - aY.result
        return sqrtf(dX*dX + dY*dY)
    }
    
    
    
    func isRedundant(a:String, b:String) -> Bool {
        
        //If we don't have a motion line, return.
        if (!startsWith(a, prefix:"G1") || !startsWith(b, prefix:"G1")) {
            return false;
        }
        
        //Get the extrusion parameter for line 1
        let aE = getParameter(a, c:"E");
        //Determine if extrusion is part of the line
        if (!aE.found) {return false}
        //Get the extrusion parameter for line 2
        let bE = getParameter(b, c:"E");
        //Determine if extrusion is part of the line.
        if (!bE.found) {return false}
        
        //Check to see if extrusion is greater than the threshold or not.  If greater return false.
        
        if (fabsf(aE.result - bE.result) < extrusionThreshold) {
            
            // this distance check is probably unnecessary as travel moves are automatically filtered out (they don't have an E parameter)
            let dist = xyDistance(a,b: b)
            
            if (dist < 0) {return false} // no distance data
            //If we didn't move far enough, flag the line for filtering.
            return (dist < resolutionThreshold)
            
        }


        return false
        
    }

    func Process(path : String) -> String {
        
        var parsedPath = splitPath(path)
        var outPath = parsedPath.p + parsedPath.n + "-parsed.gcode"
        var iFile = 0
        var fileData = ""
        var totalCount = 0
        var duplicateCount = 0
        var output = false
        var relativeMotion = false
        var previousLine = ""
        
        //Don't allow overwrite of duplicate file
        while NSFileManager.defaultManager().fileExistsAtPath(outPath)
        {
            iFile++
            outPath = parsedPath.p + parsedPath.n + "-parsed-\(iFile).gcode"
        }
        
        //Open and read file
        if let aStreamReader = StreamReader(path: path) {
            defer {
                aStreamReader.close()
            }
            //While there's data, read it line by line.
            while let line = aStreamReader.nextLine() {
                //Add 1 to the total line count
                totalCount++
              
                
                // don't filter relative motion gcode
                if (startsWith(line,prefix:"G91")) {
                    relativeMotion = true;
                } else if (startsWith(line,prefix:"G90")) {
                    relativeMotion = false;
                }


                
                // ignore redundant gcode
                if (!relativeMotion && startsWith(line, prefix:"G1") && isRedundant(previousLine, b:line)) {
                    //record this as a duplicate line that was filtered out.
                    duplicateCount++;
                } else {
                    //Add line to the data to write.
                    fileData += line + "\n"
                    //Since this line was unique, make it the last valid line.
                    previousLine = line
                }

            }
        }


        //Write the file to disk and return our results
        var retVal = "Processing failed!"
        if (writeFile(outPath, fileData: fileData)) {
            retVal = "Finished: \(duplicateCount) / \(totalCount) Lines Removed"
        }
        //empty variable?
        fileData = ""
        return retVal
        
        
        
    }
    
    
    func writeFile(outPath:String, fileData:String) -> Bool {
        do {
            try fileData.writeToFile(outPath, atomically: true, encoding: NSUTF8StringEncoding)
            return true
        }
        catch {
            return false
        }
    }
    
    func splitPath(fPath:String) -> (p:String,n:String)
    {
        let strArr = fPath.characters.split{$0=="/"}.map(String.init)
        //print (strArr)
        var rootPath = "/"
        for var i = 0; i<=strArr.count - 2;i++
        {
            rootPath += strArr[i] + "/"
        }
        let nameString:String = strArr[strArr.count-1]
        let strArr2 = nameString.characters.split{$0=="."}.map(String.init)
        
        return(rootPath,strArr2[0])
    }
    
    
    
    
}









extension NSOutputStream {
    
    /// Write String to outputStream
    ///
    /// - parameter string:                The string to write.
    /// - parameter encoding:              The NSStringEncoding to use when writing the string. This will default to UTF8.
    /// - parameter allowLossyConversion:  Whether to permit lossy conversion when writing the string.
    ///
    /// - returns:                         Return total number of bytes written upon success. Return -1 upon failure.
    
    func write(string: String, encoding: NSStringEncoding = NSUTF8StringEncoding, allowLossyConversion: Bool = true) -> Int {
        if let data = string.dataUsingEncoding(encoding, allowLossyConversion: allowLossyConversion) {
            var bytes = UnsafePointer<UInt8>(data.bytes)
            var bytesRemaining = data.length
            var totalBytesWritten = 0
            
            while bytesRemaining > 0 {
                let bytesWritten = self.write(bytes, maxLength: bytesRemaining)
                if bytesWritten < 0 {
                    return -1
                }
                
                bytesRemaining -= bytesWritten
                bytes += bytesWritten
                totalBytesWritten += bytesWritten
            }
            
            return totalBytesWritten
        }
        
        return -1
    }
    
}




