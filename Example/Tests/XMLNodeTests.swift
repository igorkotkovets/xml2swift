//
//  XMLNodeTests.swift
//  XML2Swift_Tests
//
//  Created by igork on 6/20/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
import CleanTests
import XML2Swift

class XMLNodeTests: XCTestCase {

    var xmlDocument: XMLDocument!
    var rootElement: XMLElement?

    override func setUp() {
        super.setUp()

        let fileHandle = FileHandle(forReadingAtPath: TestConstants.xmlNodeTestsFilePath)!
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

        rootElement = xmlDocument?.rootElement()
    }

    func testThatReturnsNextNode() {
        let metaNode = rootElement?.next
        XCTAssertNotNil(metaNode)
        XCTAssertEqual(metaNode!.name!, "Meta")

        let generatorNode = metaNode?.next
        XCTAssertNotNil(generatorNode)
        XCTAssertEqual(generatorNode!.name!, "Generator")

        let headerHashNode = generatorNode?.next
        XCTAssertNotNil(headerHashNode)
        XCTAssertEqual(headerHashNode!.name, nil)

    }

}
