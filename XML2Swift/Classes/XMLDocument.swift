//
//  XMLDocument.swift
//  XML2Swift
//
//  Created by Igor Kotkovets on 12/22/17.
//

import Foundation
import libxml2

public class XMLDocument: XMLNodeComponent {
    let cXmlNodePtr: xmlDocPtr

    public convenience init?(withRead ioread: @escaping xmlInputReadCallback,
                             close ioclose: @escaping xmlInputCloseCallback,
                             context: UnsafeMutableRawPointer, options mask: Int) {
        xmlKeepBlanksDefault(0)
        guard let doc = xmlReadIO(ioread, ioclose, context, nil, nil, Int32(mask)) else {
            return nil
        }

        self.init(withDocument: doc)
    }

    public init(withDocument primitive: xmlDocPtr) {
        self.cXmlNodePtr = primitive
    }

    public func rootElement() -> XMLElement? {
        if let rootNode = xmlDocGetRootElement(cXmlNodePtr) {
            return XMLElement.node(withElement: rootNode, owner: self)
        }

        return nil
    }

    public var name: String? {
        guard let xmlName = cXmlNodePtr.pointee.name else {
            return nil
        }

        let result = String(withXmlChar: xmlName)
        return result
    }

    public var childCount: UInt {
        var result: UInt = 0
        var child = cXmlNodePtr.pointee.children
        while child != nil {
            result += 1
            child = child?.pointee.next
        }

        return result
    }
}
