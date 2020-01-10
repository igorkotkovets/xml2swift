//
//  NSObjCRuntime.swift
//  XML2Swift
//
//  Created by Igor Kotkovets on 1/10/20.
//

import Foundation

internal func NSUnsupported(_ fn: String = #function, file: StaticString = #file, line: UInt = #line) -> Never {
    #if os(Android)
    NSLog("\(fn) is not supported on this platform. \(file):\(line)")
    #endif
    fatalError("\(fn) is not supported on this platform", file: file, line: line)
}

internal func NSUnimplemented(_ fn: String = #function, file: StaticString = #file, line: UInt = #line) -> Never {
    #if os(Android)
    NSLog("\(fn) is not yet implemented. \(file):\(line)")
    #endif
    fatalError("\(fn) is not yet implemented", file: file, line: line)
}
