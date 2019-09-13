//
//  XMLInvalidNode.swift
//  XML2Swift
//
//  Created by Igor Kotkovets on 12/27/17.
//

import Foundation
import libxml2

class XMLInvalidNode: XMLNode {
    override var kind: XMLNode.Kind {
        return .invalid
    }

    override var stringValue: String? {
        set {
            // TODO: IMPLEMENT
        }
        get {
            return nil
        }
    }

    override var nextSibling: XMLNode? {
        return nil
    }

    override var children: [XMLNode]? {
        return []
    }
}
