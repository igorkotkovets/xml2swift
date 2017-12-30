//
//  XMLDocument.swift
//  XML2Swift
//
//  Created by Igor Kotkovets on 12/22/17.
//

import Foundation
import libxml2

public class XMLDocument: XMLNode {
    public init?(withRead ioread: @escaping xmlInputReadCallback,
                 close ioclose: @escaping xmlInputCloseCallback,
                 context: UnsafeMutableRawPointer, options mask: Int) {
        xmlKeepBlanksDefault(0)
        guard let doc = xmlReadIO(ioread, ioclose, context, nil, nil, Int32(mask)) else {
            return nil
        }

        super.init(withPrimitive: doc)
    }

    public init(withDocument primitive: xmlDocPtr) {
        super.init(withPrimitive: primitive)
    }

    static func node(withDocument primitive: xmlDocPtr) -> XMLDocument {
        return XMLDocument(withDocument: primitive)
    }

    public func rootElement() -> XMLElement? {
        let node = UnsafeMutablePointer<xmlDoc>(OpaquePointer(xmlPtr))
        if let rootNode = xmlDocGetRootElement(node) {
            return XMLElement.node(withElement: rootNode, owner: self)
        }

        return nil
    }

    override public var name: String? {
        let node = UnsafeMutablePointer<xmlDoc>(OpaquePointer(xmlPtr))
        guard let xmlName = node.pointee.name else {
            return nil
        }

        let result = String(cString: xmlName)
        return result
    }

    override public var childCount: Int {
        let node = UnsafeMutablePointer<xmlDoc>(OpaquePointer(xmlPtr))
        var result = 0
        var child = node.pointee.children
        while child != nil {
            result += 1
            child = child?.pointee.next
        }

        return result
    }

    override public func child(at index: Int) -> XMLNode? {
        return nil
    }
}
