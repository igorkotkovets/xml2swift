//
//  Constants.swift
//  XML2Swift_Tests
//
//  Created by Igor Kotkovets on 12/25/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

struct Constants {
    static let xmlFilePath: String = {
        let path = Bundle(for: XMLDocumentTests.self).path(forResource: "template", ofType: "xml")
        return path!
    }()
}
