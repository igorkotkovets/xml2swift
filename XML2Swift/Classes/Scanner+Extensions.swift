//
//  Scanner+Extensions.swift
//  XML2Swift
//
//  Created by igork on 9/12/19.
//

import Foundation

extension Scanner {
    /// Returns a string, scanned until a character from a given character set are encountered, or the remainder of the scanner's string. Returns `nil` if the scanner is already `atEnd`.
    func scanUpToCharacters(from set: CharacterSet) -> String? {
        var value: NSString? = ""
        if scanUpToCharacters(from: set, into: &value) {
            return value as String?
        }
        return nil
    }

    /// Returns the given string if scanned, or `nil` if not found.
    func scanString(_ str: String) -> String? {
        var value: NSString? = ""
        if scanString(str, into: &value){
            return value as String?
        }
        return nil
    }

    public var currentIndex: String.Index {
        get {
            let string = self.string
            var index = string._toUTF16Index(scanLocation)

            var delta = 0
            while index != string.endIndex && index.samePosition(in: string) == nil {
                delta += 1
                index = string._toUTF16Index(scanLocation + delta)
            }

            return index
        }
        set { scanLocation = string._toUTF16Offset(newValue) }
    }

}
