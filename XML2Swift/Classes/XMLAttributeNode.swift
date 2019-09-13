//
//  XMLAttributeNode.swift
//  XML2Swift
//
//  Created by Igor Kotkovets on 12/26/17.
//

import Foundation
import libxml2

class XMLAttributeNode: XMLNode {
//    var attrsNsPtr: xmlNsPtr?

    static func node(withAttr primitive: xmlAttrPtr, owner: XMLNode?) -> XMLAttributeNode {
        return XMLAttributeNode(withAttr: primitive, owner: owner)
    }

    init(withAttr primitive: xmlAttrPtr, owner: XMLNode?) {
        super.init(withPrimitive: primitive, owner: owner)
    }
}
