//
//  XMLNode.swift
//  XML2Swift
//
//  Created by Igor Kotkovets on 12/22/17.
//

import Foundation
import libxml2

struct _xmlKind {
    let ignore: UnsafeRawPointer
    let type: xmlElementType
}

enum XMLNodeKind {
    case invalid
    case document
    case element
    case attribute
    case namespace
    case processingInstruction
    case comment
    case dtd
    case entityDeclaration
    case attributeDeclaration
    case elementDeclaration
    case notationDeclaration
}

extension xmlElementType {
    func toNodeKind() -> XMLNodeKind {
        switch self {
        case XML_DOCUMENT_NODE:
            return .document
        case XML_ELEMENT_NODE:
            return .element
        case XML_ATTRIBUTE_NODE:
            return .attribute
        case XML_NAMESPACE_DECL:
            return .namespace
        case XML_PI_NODE:
            return .processingInstruction
        case XML_COMMENT_NODE:
            return .comment
        case XML_TEXT_NODE:
            return .comment
        case XML_DTD_NODE:
            return .dtd
        case XML_ENTITY_DECL:
            return .entityDeclaration
        case XML_ATTRIBUTE_DECL:
            return .attributeDeclaration
        case XML_ELEMENT_DECL:
            return .elementDeclaration
        case XML_NOTATION_NODE:
            return .notationDeclaration
        default:
            return .invalid
        }
    }
}

// TODO: Remove extension, add business logic to class
extension xmlNode {
    func isXMLNodePtr() -> Bool {
        switch self.type {
        case XML_ELEMENT_NODE, XML_PI_NODE, XML_COMMENT_NODE, XML_TEXT_NODE, XML_CDATA_SECTION_NODE:
            return true
        default:
            return false
        }
    }
}

public class XMLNode: XMLNodeGeneric {
    var name: String?
    var value: String?
    var index: UInt?
    var level: UInt?
    var rootDocument: XMLDocument?
    var parent: XMLNode?
    var childCount: UInt?
    var children: [XMLNode]?
    
    let cXmlNodePtr: xmlNodePtr

    public init?(withPrimitive primitive: xmlNodePtr, owner: XMLNodeGeneric?) {
        self.cXmlNodePtr = primitive
        super.init(withOwner: owner)
    }

    var kind: XMLNodeKind {
        return cXmlNodePtr.pointee.type.toNodeKind()
    }

    var uri: String? {
        set {
            if cXmlNodePtr.pointee.isXMLNodePtr() {
                if (cXmlNodePtr.pointee.ns != nil) {
                    type(of:self).remove(namespace: cXmlNodePtr.pointee.ns, from: cXmlNodePtr)
                }
            }

            guard let `newValue` = newValue else {
                return
            }

            let namespace: xmlNsPtr = xmlNewNs(nil, newValue.xmlChar(), nil)
            namespace.pointee.next = cXmlNodePtr.pointee.nsDef
            cXmlNodePtr.pointee.nsDef = namespace
            cXmlNodePtr.pointee.ns = namespace
        }
        get {
            if cXmlNodePtr.pointee.isXMLNodePtr() {
                if let namespace = cXmlNodePtr.pointee.ns {
                    return String(withXmlChar: namespace.pointee.href)
                }
            }

            return nil
        }
    }

    static func element(withName aname: String) -> XMLElement? {
        return XMLElement(withName: aname)
    }

    static func element(withName aname: String, uri: String) -> XMLElement? {
        return XMLElement(withName: aname)
    }

    

    static func remove(namespace: xmlNsPtr, from node: xmlNodePtr) {
        detach(namespace: namespace, from: node)
        xmlFreeNs(namespace)
    }

    static func detach(namespace: xmlNsPtr, from node: xmlNodePtr) {
        if node.pointee.ns == namespace {
            node.pointee.ns = nil
        }

        var attr = node.pointee.properties
        while attr != nil {
            if attr?.pointee.ns == namespace {
                attr?.pointee.ns = nil
            }
            attr = attr?.pointee.next
        }

        var child = node.pointee.children
        while child != nil {

            child = child?.pointee.next
        }
    }
}
