//
//  Constants.swift
//  XML2Swift_Tests
//
//  Created by Igor Kotkovets on 12/25/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

struct TestConstants {
    static let xmlFilePath: String = {
        let path = Bundle(for: XMLDocumentTests.self).path(forResource: "template", ofType: "xml")
        return path!
    }()

    static let kdbV4FilePath: String = {
        let path = Bundle(for: XMLDocumentTests.self).path(forResource: "kdbv4payload", ofType: "xml")
        return path!
    }()

    static let xmlNodeTestsFilePath: String = {
        let path = Bundle(for: XMLDocumentTests.self).path(forResource: "XMLNodeTests", ofType: "xml")
        return path!
    }()
}
