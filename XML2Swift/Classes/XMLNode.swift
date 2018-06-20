//
//  XMLNode.swift
//  XML2Swift
//
//  Created by Igor Kotkovets on 12/22/17.
//

import Foundation
import libxml2

extension xmlElementType {
    func toNodeKind() -> XMLNode.Kind {
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
            return .text
        case XML_COMMENT_NODE:
            return .comment
        case XML_DTD_NODE:
            return .DTDKind
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
extension XMLNode {
    static func isXMLNode(_ node: xmlNode) -> Bool {
        switch node.type {
        case XML_ELEMENT_NODE, XML_PI_NODE, XML_COMMENT_NODE, XML_TEXT_NODE, XML_CDATA_SECTION_NODE:
            return true
        default:
            return false
        }
    }

    static func isXMLDtd(_ node: xmlNode) -> Bool {
        return node.type == XML_DTD_NODE
    }

    static func split(name: String?) -> (prefix: String?, localName: String?) {
        guard let `name` = name else {
            return ("", nil)
        }

        guard let range = name.rangeOfCharacter(from: [":"]) else {
            return ("", name)
        }

        return (name.substring(to: range.lowerBound),
                name.substring(from: range.upperBound))
    }
}

public class XMLNode {
    
    public enum Kind {
        case invalid
        case document
        case element
        case attribute
        case namespace
        case processingInstruction
        case comment
        case text
        case DTDKind
        case entityDeclaration
        case attributeDeclaration
        case elementDeclaration
        case notationDeclaration
    }

    public var stringValue: String? {
        set {

        }

        get {
            let node = UnsafeMutablePointer<xmlNode>(OpaquePointer(xmlPtr))
            guard XMLNode.isXMLNode(node.pointee) == true,
            let content = xmlNodeGetContent(node) else {
                return nil
            }

            let result = String(cString: content)
            xmlFree(content)
            return result
        }
    }
    var index: UInt?
    var level: UInt?
    var parent: XMLNode?
    let owner: XMLNode?
    let xmlPtr: UnsafeMutableRawPointer

    init(withPrimitive primitive: xmlDocPtr) {
        xmlPtr = UnsafeMutableRawPointer(primitive)
        self.owner = nil
    }

    init(withPrimitive primitive: xmlNodePtr, owner: XMLNode?) {
        xmlPtr = UnsafeMutableRawPointer(primitive)
        self.owner = owner
    }

    init(withPrimitive primitive: xmlAttrPtr, owner: XMLNode?) {
        xmlPtr = UnsafeMutableRawPointer(primitive)
        self.owner = owner
    }

    init(withPrimitive primitive: xmlNsPtr, owner: XMLNode?) {
        xmlPtr = UnsafeMutableRawPointer(primitive)
        self.owner = owner
    }

    var rootDocument: XMLDocument? {
        let node = UnsafeMutablePointer<xmlNode>(OpaquePointer(xmlPtr))
        guard let docPtr = node.pointee.doc else {
            return nil
        }

        return XMLDocument.node(withDocument: docPtr)
    }

    public var kind: Kind {
        let node = UnsafeMutablePointer<xmlNode>(OpaquePointer(xmlPtr))
        return node.pointee.type.toNodeKind()
    }

    public var children: [XMLNode]? {
        var result = [XMLNode]()
        let node = UnsafeMutablePointer<xmlNode>(OpaquePointer(xmlPtr))

        var child = node.pointee.children
        while child != nil {
            result.append(XMLNode.node(withUnknown: child!, owner: self))
            child = child?.pointee.next
        }

        return result
    }

    public var next: XMLNode? {
        return nil
    }

    public var name: String? {
        let node = UnsafeMutablePointer<xmlNode>(OpaquePointer(xmlPtr))
        guard let xmlName = node.pointee.name else {
            return nil
        }

        var result = String(cString: xmlName)
        if XMLNode.isXMLNode(node.pointee),
        result.contains(":") == true,
        node.pointee.ns != nil,
        let prefixXmlChar = node.pointee.ns.pointee.prefix {
            let prefix = String(cString: prefixXmlChar)
            result = prefix + ":" + result
        }

        return result
    }

    public var childCount: Int {
        let node = UnsafeMutablePointer<xmlNode>(OpaquePointer(xmlPtr))
        guard XMLNode.isXMLNode(node.pointee) || XMLNode.isXMLDtd(node.pointee) else {
            return 0
        }

        var result = 0
        var child = node.pointee.children
        while child != nil {
            result += 1
            child = child?.pointee.next
        }

        return result
    }

    public func child(at index: Int) -> XMLNode? {
        let node = UnsafeMutablePointer<xmlNode>(OpaquePointer(xmlPtr))
        guard XMLNode.isXMLNode(node.pointee) || XMLNode.isXMLDtd(node.pointee) else {
            return nil
        }

        var i = 0
        var child = node.pointee.children
        while child != nil {
            if i == index {
                return XMLNode.node(withUnknown: child!, owner: self)
            }

            i += 1
            child = child?.pointee.next
        }

        return nil
    }

    static func node(withUnknown primitive: xmlNodePtr, owner: XMLNode) -> XMLNode {
        if primitive.pointee.type == XML_DOCUMENT_NODE {
            return XMLDocument.node(withDocument: primitive.withMemoryRebound(to: xmlDoc.self,
                                                                              capacity: 1) { bytes -> xmlDocPtr in
                return UnsafeMutablePointer(bytes)
            })
        } else if primitive.pointee.type == XML_ELEMENT_NODE {
            return XMLElement.node(withElement: primitive, owner: owner)
        } else {
            return XMLNode(withPrimitive: primitive, owner: owner)
        }
    }

    var uri: String? {
        set {
            let node = UnsafeMutablePointer<xmlNode>(OpaquePointer(xmlPtr))
            if XMLNode.isXMLNode(node.pointee) {
                if node.pointee.ns != nil {
                    type(of: self).remove(namespace: node.pointee.ns, from: node)
                }
            }

            guard let `newValue` = newValue else {
                return
            }

            let namespace: xmlNsPtr = xmlNewNs(nil, newValue.xmlChar(), nil)
            namespace.pointee.next = node.pointee.nsDef
            node.pointee.nsDef = namespace
            node.pointee.ns = namespace
        }
        get {
            let node = UnsafeMutablePointer<xmlNode>(OpaquePointer(xmlPtr))
            if XMLNode.isXMLNode(node.pointee) {
                if let namespace = node.pointee.ns {
                    return String(cString: namespace.pointee.href)
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
