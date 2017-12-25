//
//  XMLDocument.swift
//  XML2Swift
//
//  Created by Igor Kotkovets on 12/22/17.
//

import Foundation
import libxml2

public class XMLDocument: XMLNodeGeneric {
    let cXmlNodePtr: xmlDocPtr

    public convenience init?(withRead ioread: @escaping xmlInputReadCallback, close ioclose: @escaping xmlInputCloseCallback, context: UnsafeMutableRawPointer, options mask: Int) {
        xmlKeepBlanksDefault(0)
        guard let doc = xmlReadIO(ioread, ioclose, context, nil, nil, Int32(mask)) else {
            return nil
        }

        self.init(withDocument: doc, owner: nil)
    }

    public init(withDocument primitive: xmlDocPtr, owner: XMLNodeGeneric?) {
        self.cXmlNodePtr = primitive
        super.init(withOwner: owner)
    }

    public func rootElement() -> XMLElement? {
        if let rootNode = xmlDocGetRootElement(cXmlNodePtr) {
            return XMLElement.node(withElement: rootNode, owner: self)
        }

        return nil
    }
}
