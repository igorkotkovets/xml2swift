//
//  XMLDocumentTests.swift
//  XML2Swift_Tests
//
//  Created by Igor Kotkovets on 12/25/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import XCTest
import CleanTests
import XML2Swift

class XMLDocumentTests: XCTestCase {

//    func ioReadCallback(@convention(c) ctx: UnsafeMutableRawPointer?, int8Buffer: UnsafeMutablePointer<Int8>?, len: Int32) -> Int32 {
//
//    }

    func testThatReturnRootElement() {
        let fileHandle = FileHandle(forReadingAtPath: Constants.xmlFilePath)!
        let fileStream = FileInputStream(withFileHandle: fileHandle)
        let contextAsPtr = Unmanaged.passRetained(fileStream).toOpaque()
        let callback = { (ctx: UnsafeMutableRawPointer?, int8Buffer: UnsafeMutablePointer<Int8>?, len: Int32) -> Int32 in
            let context : FileInputStream = Unmanaged.fromOpaque(ctx!).takeRetainedValue()
            return int8Buffer!.withMemoryRebound(to: UInt8.self, capacity: Int(len)) { (uin8Buffer) -> Int32 in
                let readLength = context.read(uin8Buffer, maxLength: Int(len))
                return Int32(readLength)
            }
        }

        let xmlDocument = XMLDocument(withRead: { (ctx: UnsafeMutableRawPointer?, int8Buffer: UnsafeMutablePointer<Int8>?, len: Int32) -> Int32 in
            let context : FileInputStream = Unmanaged.fromOpaque(ctx!).takeRetainedValue()
            return int8Buffer!.withMemoryRebound(to: UInt8.self, capacity: Int(len)) { (uin8Buffer) -> Int32 in
                let readLength = context.read(uin8Buffer, maxLength: Int(len))
                return Int32(readLength)
            }
        }, close: { (ctx) -> Int32 in
            return 0
        }, context: contextAsPtr, options: 0)

        let element = xmlDocument?.rootElement()
    }
    
}
