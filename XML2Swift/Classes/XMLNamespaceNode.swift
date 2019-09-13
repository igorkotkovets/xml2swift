//
//  XMLNamespaceNode.swift
//  XML2Swift
//
//  Created by Igor Kotkovets on 12/26/17.
//

import Foundation
import libxml2

class XMLNamespaceNode: XMLNode {
    let nsParentPtr: xmlNodePtr?

    init(withNamespace primitive: xmlNsPtr, nsParent: xmlNodePtr?, owner: XMLNode) {
        self.nsParentPtr = nsParent
        super.init(withPrimitive: primitive, owner: nil)
    }

    static func node(withNamespace primitive: xmlNsPtr, nsParent: xmlNodePtr, owner: XMLNode) -> XMLNamespaceNode {
        return XMLNamespaceNode(withNamespace: primitive, nsParent: nsParent, owner: owner)
    }

    override var children: [XMLNode]? {
        return nil;
    }
}
