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
            let attr = UnsafeMutablePointer<xmlAttr>(OpaquePointer(xmlPtr))
            guard let children = attr.pointee.children else {
                return nil
            }

            return String(cString: children.pointee.content)
        }
    }
}
