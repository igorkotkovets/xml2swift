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
    var xmlDocument: XMLDocument!

    override func setUp() {
        super.setUp()

        let fileHandle = FileHandle(forReadingAtPath: TestConstants.kdbV4FilePath)!
        let fileStream = FileInputStream(withFileHandle: fileHandle)
        let inputStream: XML2Swift.InputStream = fileStream
        let stream = inputStream as AnyObject
        let contextAsPtr = Unmanaged.passUnretained(stream).toOpaque()

        xmlDocument = XMLDocument(withRead: { (ctx: UnsafeMutableRawPointer?, int8Buffer: UnsafeMutablePointer<Int8>?, len: Int32) -> Int32 in
            let context: AnyObject = Unmanaged.fromOpaque(ctx!).takeUnretainedValue()
            let pstream = context as! XML2Swift.InputStream
            return int8Buffer!.withMemoryRebound(to: UInt8.self, capacity: Int(len)) { (uin8Buffer) -> Int32 in
                let readLength = pstream.read(uin8Buffer, maxLength: Int(len))
                return Int32(readLength)
            }
        }, close: { (ctx) -> Int32 in
            return 0
        }, context: contextAsPtr, options: 0)
    }
    
    func testThatReturnRootElement() {
        let fileHandle = FileHandle(forReadingAtPath: TestConstants.xmlFilePath)!
        let fileStream = FileInputStream(withFileHandle: fileHandle)
        let inputStream: XML2Swift.InputStream = fileStream
        let stream = inputStream as AnyObject
        let contextAsPtr = Unmanaged.passUnretained(stream).toOpaque()

        let xmlDocument = XMLDocument(withRead: { (ctx: UnsafeMutableRawPointer?, int8Buffer: UnsafeMutablePointer<Int8>?, len: Int32) -> Int32 in
            let context: AnyObject = Unmanaged.fromOpaque(ctx!).takeUnretainedValue()
            let pstream = context as! XML2Swift.InputStream
            return int8Buffer!.withMemoryRebound(to: UInt8.self, capacity: Int(len)) { (uin8Buffer) -> Int32 in
                let readLength = pstream.read(uin8Buffer, maxLength: Int(len))
                return Int32(readLength)
            }
        }, close: { (ctx) -> Int32 in
            return 0
        }, context: contextAsPtr, options: 0)

        let element = xmlDocument?.rootElement()
        assertPairsEqual(expected: "note", actual: element?.name)
        assertPairsEqual(expected: 4, actual: element?.childCount)
    }

    func testThatReturnRootElementForKdbV4() {
        let fileHandle = FileHandle(forReadingAtPath: TestConstants.kdbV4FilePath)!
        let fileStream = FileInputStream(withFileHandle: fileHandle)
        let xmlStream: XML2Swift.InputStream = fileStream
        let stream = xmlStream as AnyObject
        let contextAsPtr = Unmanaged.passUnretained(stream).toOpaque()

        let xmlDocument = XMLDocument(withRead: { (ctx: UnsafeMutableRawPointer?, int8Buffer: UnsafeMutablePointer<Int8>?, len: Int32) -> Int32 in
            let context: AnyObject = Unmanaged.fromOpaque(ctx!).takeUnretainedValue()
            let pstream = context as! XML2Swift.InputStream
            return int8Buffer!.withMemoryRebound(to: UInt8.self, capacity: Int(len)) { (uin8Buffer) -> Int32 in
                let readLength = pstream.read(uin8Buffer, maxLength: Int(len))
                return Int32(readLength)
            }
        }, close: { (ctx) -> Int32 in
            return 0
        }, context: contextAsPtr, options: 0)

        let element = xmlDocument?.rootElement()
        assertPairsEqual(expected: "KeePassFile", actual: element?.name)
        assertPairsEqual(expected: 2, actual: element?.childCount)
    }

    func testThatObtainAllElementsRecursive() {
        let fileHandle = FileHandle(forReadingAtPath: TestConstants.kdbV4FilePath)!
        let fileStream = FileInputStream(withFileHandle: fileHandle)
        let inputStream: XML2Swift.InputStream = fileStream
        let stream = inputStream as AnyObject
        let contextAsPtr = Unmanaged.passUnretained(stream).toOpaque()

        let xmlDocument = XMLDocument(withRead: { (ctx: UnsafeMutableRawPointer?, int8Buffer: UnsafeMutablePointer<Int8>?, len: Int32) -> Int32 in
            let context: AnyObject = Unmanaged.fromOpaque(ctx!).takeUnretainedValue()
            let pstream = context as! XML2Swift.InputStream
            return int8Buffer!.withMemoryRebound(to: UInt8.self, capacity: Int(len)) { (uin8Buffer) -> Int32 in
                let readLength = pstream.read(uin8Buffer, maxLength: Int(len))
                return Int32(readLength)
            }
        }, close: { (ctx) -> Int32 in
            return 0
        }, context: contextAsPtr, options: 0)

        let element = xmlDocument?.rootElement()
        printRecursive(node: element)
        
    }

    func printRecursive(node: XMLNode?) {
        print("\(node?.name ?? "") value: \(node?.stringValue ?? "")")

        for i in 0..<(node?.childCount ?? 0) {
            printRecursive(node: node?.child(at: i))
        }
    }

}
