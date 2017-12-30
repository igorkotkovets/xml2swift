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

    public init(withElement primitive: xmlNodePtr, owner: XMLNode?) {
        super.init(withPrimitive: primitive, owner: owner)
    }

    public convenience init?(withName name: String, uri: String) {
        guard let node: xmlNodePtr = xmlNewNode(nil, name.xmlChar()) else {
            return nil
        }

        self.init(withElement: node, owner: nil)
    }

    static func node(withElement primitive: xmlNodePtr, owner: XMLNode?) -> XMLElement {
        return XMLElement(withElement: primitive, owner: owner)
    }

    public func elements(forName name: String) -> [XMLElement] {
        let tuple = XMLNode.split(name: name)
        if let prefix = tuple.prefix,
            prefix.lengthOfBytes(using: .utf8) > 0 {
            let node = UnsafeMutablePointer<xmlNode>(OpaquePointer(xmlPtr))
            if let namespace = xmlSearchNs(node.pointee.doc, node, prefix.xmlChar()) {
                let uri = String(cString: namespace.pointee.href)
                return elements(forName: name, localName: tuple.localName, prefix: prefix, uri: uri)
            }
        }

        return elements(forName: name, localName: tuple.localName, prefix: tuple.prefix, uri: nil)
    }

    public func elements(forLocalName localName: String,
                         uri URI: String?) -> [XMLElement] {
        // TODO: IMPLEMENT
        return []
    }

    func elements(forName: String, localName: String?, prefix: String?, uri: String?) -> [XMLElement] {
        var result = [XMLElement]()
        let hasPrefix = (prefix?.lengthOfBytes(using: .utf8) ?? 0) > 0
        let xmlName = forName.xmlChar()
        let xmlLocalName = localName?.xmlChar()
        let xmlUri = uri?.xmlChar()
        let node = UnsafeMutablePointer<xmlNode>(OpaquePointer(xmlPtr))
        var child = node.pointee.children
        while child != nil {
            if XMLNode.isXMLNode(node.pointee) {
                var match = false
                if uri == nil {
                    match = xmlStrEqual(child?.pointee.name, xmlName!) > 0
                } else {
                    let nameMatch = xmlStrEqual(child?.pointee.name, xmlName) > 0
                    let localNameMatch = xmlStrEqual(child?.pointee.name, xmlLocalName) > 0
                    var uriMatch = false
                    if child?.pointee.ns != nil {
                        uriMatch = xmlStrEqual(child?.pointee.ns.pointee.href, xmlUri) > 0
                    }

                    if hasPrefix {
                        match = nameMatch || (localNameMatch && uriMatch)
                    } else {
                        match = nameMatch && uriMatch
                    }
                }

                if match {
                    result.append(XMLElement.node(withElement: child!, owner: self))
                }
            }

            child = child?.pointee.next
        }

        return result
    }
}

extension XMLElement {
    public func element(forName name: String) -> XMLElement? {
        return elements(forName: name).first
    }
}
