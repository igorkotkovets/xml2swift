//
//  XMLElement.swift
//  XML2Swift
//
//  Created by Igor Kotkovets on 12/22/17.
//

import Foundation
import libxml2

public class XMLElement: XMLNode {
    public convenience init?(withName name: String) {
        guard let node: xmlNodePtr = xmlNewNode(nil, name.xmlChar()) else {
            return nil
        }

        self.init(withElement: node, owner: nil)
    }

    public init?(withElement primitive: xmlNodePtr, owner: XMLNodeComponent?) {
        super.init(withPrimitive: primitive, owner: owner)
    }

    public convenience init?(withName name: String, uri: String) {
        guard let node: xmlNodePtr = xmlNewNode(nil, name.xmlChar()) else {
            return nil
        }

        self.init(withElement: node, owner: nil)
    }

    static func node(withElement primitive: xmlNodePtr, owner: XMLNodeComponent?) -> XMLElement? {
        return XMLElement(withElement: primitive, owner: owner)
    }
}
