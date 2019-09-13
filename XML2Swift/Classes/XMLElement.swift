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

    /*!
     @method initWithName:
     @abstract Returns an element <tt>&lt;name>&lt;/name></tt>.
     */
    public convenience init(name: String) {
        self.init(name: name, uri: nil)
    }


    /*!
     @method initWithName:URI:
     @abstract Returns an element whose full QName is specified.
     */
    public init(name: String, uri URI: String?) {
        _SetupXMLParser()
        super.init(kind: .element, options: [])
        self.uri = URI
        self.name = name
    }


    /*!
     @method initWithName:stringValue:
     @abstract Returns an element with a single text node child <tt>&lt;name>string&lt;/name></tt>.
     */
    public convenience init(name: String, stringValue string: String?) {
        _SetupXMLParser()
        self.init(name: name, uri: nil)
        if let string = string {
            let child = _XMLNewTextNode(string)
            _XMLNodeAddChild(_xmlNode, child)
        }
    }


    /*!
     @method initWithXMLString:error:
     @abstract Returns an element created from a string. Parse errors are collected in <tt>error</tt>.
     */
    public convenience init(xmlString string: String) throws {
        _SetupXMLParser()

        // If we prepend the XML line to the string
        let docString = """
        <?xml version="1.0" encoding="utf-8" standalone="yes"?>\(string)
        """
        // we can use the document string parser to get the element
        let doc = try XMLDocument(xmlString: docString, options: [])
        // We know the doc has a root element and first child or else the above line would have thrown
        self.init(ptr: _XMLCopyNode(_XMLNodeGetFirstChild(doc._xmlNode)!, true))
    }


    public convenience override init(kind: XMLNode.Kind, options: XMLNode.Options = []) {
        _SetupXMLParser()
        self.init(name: "", uri: nil)
    }

    /*!
     @method elementsForName:
     @abstract Returns all of the child elements that match this name.
     */
    open func elements(forName name: String) -> [XMLElement] {
        return self.filter({ _XMLNodeGetType($0._xmlNode) == _kXMLTypeElement }).filter({ $0.name == name }).compactMap({ $0 as? XMLElement })
    }

    /*!
     @method elementsForLocalName:URI
     @abstract Returns all of the child elements that match this localname URI pair.
     */
    open func elements(forLocalName localName: String, uri URI: String?) -> [XMLElement] {
        return self.filter({ _XMLNodeGetType($0._xmlNode) == _kXMLTypeElement }).filter({ $0.localName == localName && $0.uri == uri }).compactMap({ $0 as? XMLElement })
    }

    /*!
     @method addAttribute:
     @abstract Adds an attribute. Attributes with duplicate names replace the old one.
     */
    open func addAttribute(_ attribute: XMLNode) {
        guard let cfname = _XMLNodeCopyName(attribute._xmlNode) else {
            fatalError("Attributes must have a name!")
        }

        let name = unsafeBitCast(cfname, to: NSString.self) as String

        removeAttribute(forName: name)
        _XMLCompletePropURI(attribute._xmlNode, _xmlNode);
        addChild(attribute)
    }

    /*!
     @method removeAttributeForName:
     @abstract Removes an attribute based on its name.
     */
    open func removeAttribute(forName name: String) {
        if let prop = _XMLNodeHasProp(_xmlNode, name, nil) {
            let propNode = XMLNode._objectNodeForNode(_XMLNodePtr(prop))
            _childNodes.remove(propNode)
            // We can't use `xmlRemoveProp` because someone else may still have a reference to this attribute
            _XMLUnlinkNode(_XMLNodePtr(prop))
        }
    }

    /*!
     @method setAttributes
     @abstract Set the attributes. In the case of duplicate names, the first attribute with the name is used.
     */
    open var attributes: [XMLNode]? {
        get {
            var result: [XMLNode] = []
            var nextAttribute = _XMLNodeProperties(_xmlNode)
            while let attribute = nextAttribute {
                result.append(XMLNode._objectNodeForNode(attribute))
                nextAttribute = _XMLNodeGetNextSibling(attribute)
            }
            return !result.isEmpty ? result : nil // This appears to be how Darwin does it
        }

        set {
            removeAttributes()

            guard let attributes = newValue else {
                return
            }

            for attribute in attributes {
                addAttribute(attribute)
            }
        }
    }

    private func removeAttributes() {
        var nextAttribute = _XMLNodeProperties(_xmlNode)
        while let attribute = nextAttribute {
            var shouldFreeNode = true
            if let privateData = _XMLNodeGetPrivateData(attribute) {
                _childNodes.remove(unsafeBitCast(privateData, to: XMLNode.self))

                shouldFreeNode = false
            }

            let temp = _XMLNodeGetNextSibling(attribute)
            _XMLUnlinkNode(attribute)
            if shouldFreeNode {
                _XMLFreeNode(attribute)
            }

            nextAttribute = temp
        }
    }

    /*!
     @method setAttributesWithDictionary:
     @abstract Set the attributes based on a name-value dictionary.
     */
    open func setAttributesWith(_ attributes: [String : String]) {
        removeAttributes()
        for (name, value) in attributes {
            addAttribute(XMLNode.attribute(withName: name, stringValue: value) as! XMLNode)
        }
    }

    /*!
     @method attributeForName:
     @abstract Returns an attribute matching this name.
     */
    open func attribute(forName name: String) -> XMLNode? {
        guard let attribute = _XMLNodeHasProp(_xmlNode, name, nil) else { return nil }
        return XMLNode._objectNodeForNode(attribute)
    }

    /*!
     @method attributeForLocalName:URI:
     @abstract Returns an attribute matching this localname URI pair.
     */
    open func attribute(forLocalName localName: String, uri URI: String?) -> XMLNode? {
        guard let attribute = _XMLNodeHasProp(_xmlNode, localName, URI) else { return nil }
        return XMLNode._objectNodeForNode(attribute)
    }

    /*!
     @method addNamespace:URI:
     @abstract Adds a namespace. Namespaces with duplicate names are not added.
     */
    open func addNamespace(_ aNamespace: XMLNode) {
        if ((namespaces ?? []).compactMap({ $0.name }).contains(aNamespace.name ?? "")) {
            return
        }
        _XMLAddNamespace(_xmlNode, aNamespace._xmlNode)
    }

    /*!
     @method addNamespace:URI:
     @abstract Removes a namespace with a particular name.
     */
    open func removeNamespace(forPrefix name: String) {
        _XMLRemoveNamespace(_xmlNode, name)
    }

    /*!
     @method namespaces
     @abstract Set the namespaces. In the case of duplicate names, the first namespace with the name is used.
     */
    open var namespaces: [XMLNode]? {
        get {
            var count: Int = 0
            if let result = _XMLNamespaces(_xmlNode, &count) {
                defer {
                    free(result)
                }
                let namespacePtrs = UnsafeBufferPointer<_XMLNodePtr>(start: result, count: count)
                return namespacePtrs.map { XMLNode._objectNodeForNode($0) }
            }

            return nil
        }

        set {
            if var nodes = newValue?.map({ $0._xmlNode }) {
                nodes.withUnsafeMutableBufferPointer { bufPtr in
                    let address = bufPtr.baseAddress
                    _XMLSetNamespaces(_xmlNode, address, bufPtr.count)
                }
            } else {
                _XMLSetNamespaces(_xmlNode, nil, 0);
            }
        }
    }

    /*!
     @method namespaceForPrefix:
     @abstract Returns the namespace matching this prefix.
     */
    open func namespace(forPrefix name: String) -> XMLNode? {
        return (namespaces ?? []).first { $0.name == name }
    }

    /*!
     @method resolveNamespaceForName:
     @abstract Returns the namespace who matches the prefix of the name given. Looks in the entire namespace chain.
     */
    open func resolveNamespace(forName name: String) -> XMLNode? {
        // Legitimate question: why not use XMLNode's methods?
        // Because Darwin does the split manually here, and we want to match that rather than asking libxml2.
        let prefix: String
        if let colon = name.firstIndex(of: ":") {
            prefix = String(name[name.startIndex ..< colon])
        } else {
            prefix = ""
        }

        var current: XMLElement? = self
        while let examined = current {
            if let namespace = examined.namespace(forPrefix: prefix) {
                return namespace
            }

            current = examined.parent as? XMLElement
            guard current?.kind == .element else { break }
        }

        if !prefix.isEmpty {
            return XMLNode.predefinedNamespace(forPrefix: prefix)
        }

        return nil
    }

    /*!
     @method resolvePrefixForNamespaceURI:
     @abstract Returns the URI of this prefix. Looks in the entire namespace chain.
     */
    open func resolvePrefix(forNamespaceURI namespaceURI: String) -> String? {
        var current: XMLElement? = self
        while let examined = current {
            if let namespace = (examined.namespaces ?? []).first(where: { $0.stringValue == namespaceURI }) {
                return namespace.name
            }

            current = examined.parent as? XMLElement
            guard current?.kind == .element else { break }
        }

        if let namespace = XMLNode._defaultNamespacesByURI[namespaceURI] {
            return namespace.name
        }

        return nil
    }

    /*!
     @method insertChild:atIndex:
     @abstract Inserts a child at a particular index.
     */
    open func insertChild(_ child: XMLNode, at index: Int) {
        _insertChild(child, atIndex: index)
    }

    /*!
     @method insertChildren:atIndex:
     @abstract Insert several children at a particular index.
     */
    open func insertChildren(_ children: [XMLNode], at index: Int) {
        _insertChildren(children, atIndex: index)
    }

    /*!
     @method removeChildAtIndex:atIndex:
     @abstract Removes a child at a particular index.
     */
    open func removeChild(at index: Int) {
        _removeChildAtIndex(index)
    }

    /*!
     @method setChildren:
     @abstract Removes all existing children and replaces them with the new children. Set children to nil to simply remove all children.
     */
    open func setChildren(_ children: [XMLNode]?) {
        _setChildren(children)
    }

    /*!
     @method addChild:
     @abstract Adds a child to the end of the existing children.
     */
    open func addChild(_ child: XMLNode) {
        _addChild(child)
    }

    /*!
     @method replaceChildAtIndex:withNode:
     @abstract Replaces a child at a particular index with another child.
     */
    open func replaceChild(at index: Int, with node: XMLNode) {
        _replaceChildAtIndex(index, withNode: node)
    }

    /*!
     @method normalizeAdjacentTextNodesPreservingCDATA:
     @abstract Adjacent text nodes are coalesced. If the node's value is the empty string, it is removed. This should be called with a value of NO before using XQuery or XPath.
     */
    open func normalizeAdjacentTextNodesPreservingCDATA(_ preserve: Bool) {
        // Replicate Darwin behavior: no change occurs at all in this case.
        guard childCount != 1 else { return }

        var text = ""
        var index = 0
        let count = childCount
        var children: [XMLNode] = []

        while index < count {
            let child = self.children![index]
            let isText = child.kind == .text
            let isCDataToPreserve = preserve ? (isText && child.isCData) : false

            if isText && !isCDataToPreserve {
                if let stringValue = child.stringValue {
                    text.append(contentsOf: stringValue)
                }
            } else {
                if !text.isEmpty {
                    let mergedText = XMLNode.text(withStringValue: text) as! XMLNode
                    children.append(mergedText)
                    text = ""
                }
                if child.kind == .element, let child = child as? XMLElement {
                    child.normalizeAdjacentTextNodesPreservingCDATA(preserve)
                }
                children.append(child)
            }

            index += 1
        }

        if !text.isEmpty {
            children.append(XMLNode.text(withStringValue: text) as! XMLNode)
        }

        self.setChildren(children)
    }

    internal override class func _objectNodeForNode(_ node: _XMLNodePtr) -> XMLElement {
        precondition(_XMLNodeGetType(node) == _kXMLTypeElement)

        if let privateData = _XMLNodeGetPrivateData(node) {
            return unsafeBitCast(privateData, to: XMLElement.self)
        }

        return XMLElement(ptr: node)
    }

    internal override init(ptr: _XMLNodePtr) {
        super.init(ptr: ptr)
    }
}

extension XMLElement {
    public func element(forName name: String) -> XMLElement? {
        return elements(forName: name).first
    }
}
