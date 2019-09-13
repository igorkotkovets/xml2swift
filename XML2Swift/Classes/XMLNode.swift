//
//  XMLNode.swift
//  XML2Swift
//
//  Created by Igor Kotkovets on 12/22/17.
//

import Foundation
import CoreFoundation
import libxml2

extension XMLNode {
    /*!
     @typedef NSXMLNodeKind
     */
    public enum Kind : UInt {


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
}

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

open class XMLNode: NSObject, NSCopying {


    /*!
     @method stringValue:
     @abstract Sets the content of the node. Setting the stringValue removes all existing children including processing instructions and comments. Setting the string value on an element creates a single text node child. The getter returns the string value of the node, which may be either its content or child text nodes, depending on the type of node. Elements are recursed and text nodes concatenated in document order with no intervening spaces.
     */
    open var stringValue: String? {
        get {
            switch kind {
            case .entityDeclaration:
                let returned = _XMLCopyEntityContent(_XMLEntityPtr(_xmlNode))
                return returned == nil ? nil : unsafeBitCast(returned!, to: NSString.self) as String

            case .namespace:
                let returned = _XMLNamespaceCopyValue(_xmlNode)
                return returned == nil ? nil : unsafeBitCast(returned!, to: NSString.self) as String

            case .element:
                // As with Darwin, children's string values are just concanated without spaces.
                return children?.compactMap({ $0.stringValue }).joined() ?? ""

            default:
                let returned = _XMLNodeCopyContent(_xmlNode)
                return returned == nil ? nil : unsafeBitCast(returned!, to: NSString.self) as String
            }
        }
        set {
            switch kind {
            case .namespace:
                if let newValue = newValue {
                    precondition(URL(string: newValue) != nil, "namespace stringValue must be a valid href")
                }
                _XMLNamespaceSetValue(_xmlNode, newValue, Int64(newValue?.utf8.count ?? 0))

            case .comment, .text:
                _XMLNodeSetContent(_xmlNode, newValue)

            default:
                _removeAllChildNodesExceptAttributes() // in case anyone is holding a reference to any of these children we're about to destroy
                if let string = newValue {
                    let returned = _XMLEncodeEntities(_XMLNodeGetDocument(_xmlNode), string)
                    let newContent = returned == nil ? "" : unsafeBitCast(returned!, to: NSString.self) as String
                    _XMLNodeSetContent(_xmlNode, newContent)
                } else {
                    _XMLNodeSetContent(_xmlNode, nil)
                }
            }
        }
    }

    private func _removeAllChildNodesExceptAttributes() {
        for node in _childNodes {
            if node.kind != .attribute {
                _XMLUnlinkNode(node._xmlNode)
                _childNodes.remove(node)
            }
        }
    }

    internal func _removeAllChildren() {
        var nextChild = _XMLNodeGetFirstChild(_xmlNode)
        while let child = nextChild {
            nextChild = _XMLNodeGetNextSibling(child)
            _XMLUnlinkNode(child)
        }
        _childNodes.removeAll(keepingCapacity: true)
    }

    var index: UInt?
    var level: UInt?
    var parent: XMLNode?
    internal let _xmlNode: _XMLNodePtr!
    internal var _xmlDocument: XMLDocument?

    /*!
     @method description
     @abstract Used for debugging. May give more information than XMLString.
     */
    open override var description: String {
        return xmlString
    }

    /*!
     @method XMLString
     @abstract The representation of this node as it would appear in an XML document.
     */
    open var xmlString: String {
        return xmlString(options: [])
    }

    /*!
     @method XMLStringWithOptions:
     @abstract The representation of this node as it would appear in an XML document, with various output options available.
     */
    open func xmlString(options: Options) -> String {
        return unsafeBitCast(_XMLCopyStringWithOptions(_xmlNode, UInt32(options.rawValue)), to: NSString.self) as String
    }

    /*!
     @method canonicalXMLStringPreservingComments:
     @abstract W3 canonical form (http://www.w3.org/TR/xml-c14n). The input option NSXMLNodePreserveWhitespace should be set for true canonical form.
     */
    open func canonicalXMLStringPreservingComments(_ comments: Bool) -> String {
        var result = ""
        switch kind {
        case .text:
            let scanner = Scanner(string: self.stringValue ?? "")
            let toReplace = CharacterSet(charactersIn: "&<>\r")
            while let string = scanner.scanUpToCharacters(from: toReplace) {
                result += string
                if scanner.scanString("&") != nil {
                    result += "&amp;"
                } else if scanner.scanString("<") != nil {
                    result += "&lt;"
                } else if scanner.scanString(">") != nil {
                    result += "&gt;"
                } else if scanner.scanString("\r") != nil {
                    result += "&#xD;"
                } else {
                    fatalError("We scanned up to one of the characters to replace, but couldn't find it when we went to consume it.")
                }
            }
            result += scanner.string[scanner.currentIndex...]


        case .comment:
            if comments {
                result = "<!--\(stringValue ?? "")-->"
            }

        default: break
        }

        return result
    }

    /*!
     @method nodesForXPath:error:
     @abstract Returns the nodes resulting from applying an XPath to this node using the node as the context item ("."). normalizeAdjacentTextNodesPreservingCDATA:NO should be called if there are adjacent text nodes since they are not allowed under the XPath/XQuery Data Model.
     @returns An array whose elements are a kind of NSXMLNode.
     */
    open func nodes(forXPath xpath: String) throws -> [XMLNode] {
        guard let nodes = _XMLNodesForXPath(_xmlNode, xpath) else {
            return []
        }

        var result: [XMLNode] = []
        for i in 0..<CFArrayGetCount(nodes as! CFArray) {
            let nodePtr = CFArrayGetValueAtIndex(nodes as! CFArray, i)!
            result.append(XMLNode._objectNodeForNode(_XMLNodePtr(mutating: nodePtr)))
        }

        return result
    }

    /*!
     @method objectsForXQuery:constants:error:
     @abstract Returns the objects resulting from applying an XQuery to this node using the node as the context item ("."). Constants are a name-value dictionary for constants declared "external" in the query. normalizeAdjacentTextNodesPreservingCDATA:NO should be called if there are adjacent text nodes since they are not allowed under the XPath/XQuery Data Model.
     @returns An array whose elements are kinds of NSArray, NSData, NSDate, NSNumber, NSString, NSURL, or NSXMLNode.
     */
    @available(*, unavailable, message: "XQuery is not available")
    open func objects(forXQuery xquery: String, constants: [String : Any]?) throws -> [Any] {
        fatalError("\(#function) is not yet implemented", file: #file, line: #line)
    }

    @available(*, unavailable, message: "XQuery is not available")
    open func objects(forXQuery xquery: String) throws -> [Any] {
        fatalError("\(#function) is not yet implemented", file: #file, line: #line)
    }

    internal var _childNodes: Set<XMLNode> = []

    deinit {
        guard _xmlNode != nil else { return }

        for node in _childNodes {
            node.detach()
        }

        _xmlDocument = nil

        switch kind {
        case .document:
            _XMLFreeDocument(_XMLDocPtr(_xmlNode))

        case .DTDKind:
            _XMLFreeDTD(_XMLDTDPtr(_xmlNode))

        case .attribute:
            _XMLFreeProperty(_xmlNode)

        default:
            _XMLFreeNode(_xmlNode)
        }
    }

    internal init(ptr: _XMLNodePtr) {
        _SetupXMLParser()
        precondition(_XMLNodeGetPrivateData(ptr) == nil, "Only one XMLNode per xmlNodePtr allowed")

        _xmlNode = ptr
        super.init()

        if let parent = _XMLNodeGetParent(_xmlNode) {
            let parentNode = XMLNode._objectNodeForNode(parent)
            parentNode._childNodes.insert(self)
        }


        _XMLNodeSetPrivateData(_xmlNode, Unmanaged.passRetained(self).toOpaque())

        if let documentPtr = _XMLNodeGetDocument(_xmlNode) {
            if documentPtr != ptr {
                _xmlDocument = XMLDocument._objectNodeForNode(documentPtr)
            }
        }
    }

    /*!
     @method initWithKind:options:
     @abstract Inits a node with fidelity options as description NSXMLNodeOptions.h
     */
    public init(kind: XMLNode.Kind, options: XMLNode.Options = []) {
        _SetupXMLParser()

        switch kind {
        case .document:
            let docPtr = _XMLNewDoc("1.0")
            _XMLDocSetStandalone(docPtr, false) // same default as on Darwin
            _xmlNode = _XMLNodePtr(docPtr)

        case .element:
            _xmlNode = _XMLNewNode(nil, "")

        case .attribute:
            _xmlNode = _XMLNodePtr(_XMLNewProperty(nil, "", nil, ""))

        case .DTDKind:
            _xmlNode = _XMLNewDTD(nil, "", "", "")

        case .namespace:
            _xmlNode = _XMLNewNamespace("", "")

        default:
            _xmlNode = nil
        }

        super.init()

        if let node = _xmlNode {
            withOpaqueUnretainedReference {
                _XMLNodeSetPrivateData(node, $0)
            }
        }
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        return copy(with: nil)
    }

    init(withPrimitive primitive: xmlDocPtr) {
        _xmlNode = UnsafeMutableRawPointer(primitive)
    }

    init(withPrimitive primitive: xmlNodePtr, owner: XMLNode?) {
        _xmlNode = UnsafeMutableRawPointer(primitive)
    }

    init(withPrimitive primitive: xmlAttrPtr, owner: XMLNode?) {
        _xmlNode = UnsafeMutableRawPointer(primitive)
    }

    init(withPrimitive primitive: xmlNsPtr, owner: XMLNode?) {
        _xmlNode = UnsafeMutableRawPointer(primitive)
    }

    /*!
     @method document:
     @abstract Returns an empty document.
     */
    open class func document() -> Any {
        return XMLDocument(rootElement: nil)
    }

    /*!
     @method documentWithRootElement:
     @abstract Returns a document
     @param element The document's root node.
     */
    open class func document(withRootElement element: XMLElement) -> Any {
        return XMLDocument(rootElement: element)
    }

    /*!
     @method elementWithName:
     @abstract Returns an element <tt>&lt;name>&lt;/name></tt>.
     */
    open class func element(withName name: String) -> Any {
        return XMLElement(name: name)
    }

    /*!
     @method elementWithName:URI:
     @abstract Returns an element whose full QName is specified.
     */
    open class func element(withName name: String, uri: String) -> Any {
        return XMLElement(name: name, uri: uri)
    }

    /*!
     @method elementWithName:stringValue:
     @abstract Returns an element with a single text node child <tt>&lt;name>string&lt;/name></tt>.
     */
    open class func element(withName name: String, stringValue string: String) -> Any {
        return XMLElement(name: name, stringValue: string)
    }

    /*!
     @method elementWithName:children:attributes:
     @abstract Returns an element children and attributes <tt>&lt;name attr1="foo" attr2="bar">&lt;-- child1 -->child2&lt;/name></tt>.
     */
    open class func element(withName name: String, children: [XMLNode]?, attributes: [XMLNode]?) -> Any {
        let element = XMLElement(name: name)
        element.setChildren(children)
        element.attributes = attributes

        return element
    }

    /*!
     @method attributeWithName:stringValue:
     @abstract Returns an attribute <tt>name="stringValue"</tt>.
     */
    open class func attribute(withName name: String, stringValue: String) -> Any {
        let attribute = _XMLNewProperty(nil, name, nil, stringValue)

        return XMLNode(ptr: attribute)
    }

    /*!
     @method attributeWithLocalName:URI:stringValue:
     @abstract Returns an attribute whose full QName is specified.
     */
    open class func attribute(withName name: String, uri: String, stringValue: String) -> Any {
        let attribute: _XMLNodePtr = _XMLNewProperty(nil, name, uri, stringValue)

        return XMLNode(ptr: attribute)
    }

    /*!
     @method namespaceWithName:stringValue:
     @abstract Returns a namespace <tt>xmlns:name="stringValue"</tt>.
     */
    open class func namespace(withName name: String, stringValue: String) -> Any {
        let node: _XMLNamespacePtr = _XMLNewNamespace(name, stringValue)
        return XMLNode(ptr: node)
    }

    /*!
     @method processingInstructionWithName:stringValue:
     @abstract Returns a processing instruction <tt>&lt;?name stringValue></tt>.
     */
    public class func processingInstruction(withName name: String, stringValue: String) -> Any {
        let node: _XMLNodePtr = _XMLNewProcessingInstruction(name, stringValue)
        return XMLNode(ptr: node)
    }

    /*!
     @method commentWithStringValue:
     @abstract Returns a comment <tt>&lt;--stringValue--></tt>.
     */
    open class func comment(withStringValue stringValue: String) -> Any {
        let node: _XMLNodePtr = _XMLNewComment(stringValue)
        return XMLNode(ptr: node)
    }

    /*!
     @method textWithStringValue:
     @abstract Returns a text node.
     */
    open class func text(withStringValue stringValue: String) -> Any {
        let node: _XMLNodePtr = _XMLNewTextNode(stringValue)
        return XMLNode(ptr: node)
    }

    /*!
     @method DTDNodeWithXMLString:
     @abstract Returns an element, attribute, entity, or notation DTD node based on the full XML string.
     */
    open class func dtdNode(withXMLString string: String) -> Any? {
        _SetupXMLParser()
        guard let node = _XMLParseDTDNode(string) else { return nil }

        return XMLDTDNode(ptr: node)
    }

    /*!
     @method rootDocument
     @abstract The encompassing document or nil.
     */
    open var rootDocument: XMLDocument? {
        guard let doc = _XMLNodeGetDocument(_xmlNode) else { return nil }

        return XMLNode._objectNodeForNode(_XMLNodePtr(doc)) as? XMLDocument
    }

    /*!
     @method kind
     @abstract Returns an element, attribute, entity, or notation DTD node based on the full XML string.
     */
    open var kind: XMLNode.Kind  {
        switch _XMLNodeGetType(_xmlNode) {
        case _kXMLTypeElement:
            return .element

        case _kXMLTypeAttribute:
            return .attribute

        case _kXMLTypeDocument:
            return .document

        case _kXMLTypeDTD:
            return .DTDKind

        case _kXMLDTDNodeTypeElement:
            return .elementDeclaration

        case _kXMLDTDNodeTypeEntity:
            return .entityDeclaration

        case _kXMLDTDNodeTypeNotation:
            return .notationDeclaration

        case _kXMLDTDNodeTypeAttribute:
            return .attributeDeclaration

        case _kXMLTypeNamespace:
            return .namespace

        case _kXMLTypeProcessingInstruction:
            return .processingInstruction

        case _kXMLTypeComment:
            return .comment

        case _kXMLTypeCDataSection: fallthrough
        case _kXMLTypeText:
            return .text

        default:
            return .invalid
        }
    }

    internal var isCData: Bool {
        return _XMLNodeGetType(_xmlNode) == _kXMLTypeCDataSection;
    }

    /*!
     @method children
     @abstract An immutable array of child nodes. Relevant for documents, elements, and document type declarations.
     */
    open var children: [XMLNode]? {
        switch kind {
        case .document:
            fallthrough
        case .element:
            fallthrough
        case .DTDKind:
            return Array<XMLNode>(self as XMLNode)

        default:
            return nil
        }
    }

    public var next: XMLNode? {
        if let firstChild = children?.first {
            return firstChild
        }

        if let nextSibling = nextSibling {
            return nextSibling
        }

        return nil
    }

    /*!
     @method detach:
     @abstract Detaches this node from its parent.
     */
    open func detach() {
        guard let parentPtr = _XMLNodeGetParent(_xmlNode) else { return }
        _XMLUnlinkNode(_xmlNode)

        guard let parentNodePtr = _XMLNodeGetPrivateData(parentPtr) else { return }

        let parent = unsafeBitCast(parentNodePtr, to: XMLNode.self)
        parent._childNodes.remove(self)
    }

    /*!
     @method XPath
     @abstract Returns the XPath to this node, for example foo/bar[2]/baz.
     */
    open var xPath: String? {
        guard _XMLNodeGetDocument(_xmlNode) != nil else { return nil }

        let returned = _XMLCopyPathForNode(_xmlNode)
        return returned == nil ? nil : unsafeBitCast(returned!, to: NSString.self) as String
    }

    /*!
     @method localName
     @abstract Returns the local name bar if this attribute or element's name is foo:bar
     */
    open var localName: String? {
        let returned = _XMLNodeCopyLocalName(_xmlNode)
        return returned == nil ? nil : unsafeBitCast(returned!, to: NSString.self) as String
    }

    /*!
     @method prefix
     @abstract Returns the prefix foo if this attribute or element's name if foo:bar
     */
    open var prefix: String? {
        let returned = _XMLNodeCopyPrefix(_xmlNode)
        return returned == nil ? nil : unsafeBitCast(returned!, to: NSString.self) as String
    }

    /*!
     @method URI
     @abstract Set the URI of this element, attribute, or document. For documents it is the URI of document origin. Getter returns the URI of this element, attribute, or document. For documents it is the URI of document origin and is automatically set when using initWithContentsOfURL.
     */
    open var uri: String? {
        get {
            let returned = _XMLNodeCopyURI(_xmlNode)
            return returned == nil ? nil : unsafeBitCast(returned!, to: NSString.self) as String
        }
        set {
            if let URI = newValue {
                _XMLNodeSetURI(_xmlNode, URI)
            } else {
                _XMLNodeSetURI(_xmlNode, nil)
            }
        }
    }

    /*!
     @method localNameForName:
     @abstract Returns the local name bar in foo:bar.
     */
    open class func localName(forName name: String) -> String {
        if let localName = _XMLSplitQualifiedName(name) {
            return String(cString: localName)
        } else {
            return name
        }
    }

    /*!
     @method localNameForName:
     @abstract Returns the prefix foo in the name foo:bar.
     */
    open class func prefix(forName name: String) -> String? {
        var size: size_t = 0
        if _XMLGetLengthOfPrefixInQualifiedName(name, &size) {
            return name.withCString {
                $0.withMemoryRebound(to: UInt8.self, capacity: size) {
                    return String(decoding: UnsafeBufferPointer(start: $0, count: size), as: UTF8.self)
                }
            }
        } else {
            return nil
        }
    }

    /*!
     @method predefinedNamespaceForPrefix:
     @abstract Returns the namespace belonging to one of the predefined namespaces xml, xs, or xsi
     */
    private static func defaultNamespace(prefix: String, value: String) -> XMLNode {
        let node = XMLNode(kind: .namespace)
        node.name = prefix
        node.objectValue = value
        return node
    }
    private static let _defaultNamespaces: [XMLNode] = [
        XMLNode.defaultNamespace(prefix: "xml", value: "http://www.w3.org/XML/1998/namespace"),
        XMLNode.defaultNamespace(prefix: "xml", value: "http://www.w3.org/2001/XMLSchema"),
        XMLNode.defaultNamespace(prefix: "xml", value: "http://www.w3.org/2001/XMLSchema-instance"),
    ]

    internal static let _defaultNamespacesByPrefix: [String: XMLNode] =
        Dictionary(XMLNode._defaultNamespaces.map { ($0.name!, $0) }, uniquingKeysWith: { old, _ in old })

    internal static let _defaultNamespacesByURI: [String: XMLNode] =
        Dictionary(XMLNode._defaultNamespaces.map { ($0.stringValue!, $0) }, uniquingKeysWith: { old, _ in old })

    open class func predefinedNamespace(forPrefix name: String) -> XMLNode? {
        return XMLNode._defaultNamespacesByPrefix[name]
    }

    /*!
     @method nextSibling:
     @abstract Returns the next sibling, or nil if there isn't one.
     */
    /*@NSCopying*/ open var nextSibling: XMLNode? {
        guard let next = _XMLNodeGetNextSibling(_xmlNode) else { return nil }

        return XMLNode._objectNodeForNode(next)
    }

    /*!
     @method name
     @abstract Sets the nodes name. Applicable for element, attribute, namespace, processing-instruction, document type declaration, element declaration, attribute declaration, entity declaration, and notation declaration.
     */
    open var name: String? {
        get {
            switch kind {
            case .comment, .text:
                // As with Darwin, name is always nil when the node is comment or text.
                return nil
            case .namespace:
                return _XMLNamespaceCopyPrefix(_xmlNode).map({ unsafeBitCast($0, to: NSString.self) as String }) ?? ""
            default:
                return _XMLNodeCopyName(_xmlNode).map({ unsafeBitCast($0, to: NSString.self) as String })
            }
        }
        set {
            switch kind {
            case .document:
                // As with Darwin, ignore the name when the node is document.
                break
            case .notationDeclaration:
                // Use _CFXMLNodeForceSetName because
                // _CFXMLNodeSetName ignores the new name when the node is notation declaration.
                _XMLNodeForceSetName(_xmlNode, newValue)
            case .namespace:
                _XMLNamespaceSetPrefix(_xmlNode, newValue, Int64(newValue?.utf8.count ?? 0))
            default:
                if let newName = newValue {
                    _XMLNodeSetName(_xmlNode, newName)
                } else {
                    _XMLNodeSetName(_xmlNode, "")
                }
            }
        }
    }

    private var _objectValue: Any? = nil

    /*!
     @method objectValue
     @abstract Sets the content of the node. Setting the objectValue removes all existing children including processing instructions and comments. Setting the object value on an element creates a single text node child.
     */
    open var objectValue: Any? {
        get {
            if let value = _objectValue {
                return value
            } else {
                return stringValue
            }
        }
        set {
            _objectValue = newValue
            if let describableValue = newValue as? CustomStringConvertible {
                stringValue = "\(describableValue.description)"
            } else if let value = newValue {
                stringValue = "\(value)"
            } else {
                stringValue = nil
            }
        }
    }

    /*!
     @method childCount
     @abstract The amount of children, relevant for documents, elements, and document type declarations.
     */
    open var childCount: Int {
        return self.children?.count ?? 0
    }

    /*!
     @method childAtIndex:
     @abstract Returns the child node at a particular index.
     */
    open func child(at index: Int) -> XMLNode? {
        precondition(index >= 0)
        precondition(index < childCount)

        return self[self.index(startIndex, offsetBy: index)]
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

    internal class func _objectNodeForNode(_ node: _XMLNodePtr) -> XMLNode {
        switch _XMLNodeGetType(node) {
        case _kXMLTypeElement:
            return XMLElement._objectNodeForNode(node)

        case _kXMLTypeDocument:
            return XMLDocument._objectNodeForNode(node)

        case _kXMLTypeDTD:
            return XMLDTD._objectNodeForNode(node)

        case _kXMLDTDNodeTypeEntity:
            fallthrough
        case _kXMLDTDNodeTypeElement:
            fallthrough
        case _kXMLDTDNodeTypeNotation:
            fallthrough
        case _kXMLDTDNodeTypeAttribute:
            return XMLDTDNode._objectNodeForNode(node)

        default:
            if let _private = _XMLNodeGetPrivateData(node) {
                return unsafeBitCast(_private, to: XMLNode.self)
            }

            return XMLNode(ptr: node)
        }
    }

    // libxml2 believes any node can have children, though XMLNode disagrees.
    // Nevertheless, this belongs here so that XMLElement and XMLDocument can share
    // the same implementation.
    internal func _insertChild(_ child: XMLNode, atIndex index: Int) {
        precondition(index >= 0)
        precondition(index <= childCount)
        precondition(child.parent == nil)

        _childNodes.insert(child)

        if index == 0 {
            let first = _XMLNodeGetFirstChild(_xmlNode)!
            _XMLNodeAddPrevSibling(first, child._xmlNode)
        } else {
            let currChild = self.child(at: index - 1)!._xmlNode
            _XMLNodeAddNextSibling(currChild!, child._xmlNode)
        }
    }

    // see above
    internal func _insertChildren(_ children: [XMLNode], atIndex index: Int) {
        for (childIndex, node) in children.enumerated() {
            _insertChild(node, atIndex: index + childIndex)
        }
    }

    /*!
     @method removeChildAtIndex:atIndex:
     @abstract Removes a child at a particular index.
     */
    // See above!
    internal func _removeChildAtIndex(_ index: Int) {
        guard let child = child(at: index) else {
            fatalError("index out of bounds")
        }

        _childNodes.remove(child)
        _XMLUnlinkNode(child._xmlNode)
    }

    // see above
    internal func _setChildren(_ children: [XMLNode]?) {
        _removeAllChildren()
        guard let children = children else {
            return
        }

        for child in children {
            _addChild(child)
        }
    }

    /*!
     @method addChild:
     @abstract Adds a child to the end of the existing children.
     */
    // see above
    internal func _addChild(_ child: XMLNode) {
        precondition(child.parent == nil)

        _XMLNodeAddChild(_xmlNode, child._xmlNode)
        _childNodes.insert(child)
    }

    /*!
     @method replaceChildAtIndex:withNode:
     @abstract Replaces a child at a particular index with another child.
     */
    // see above
    internal func _replaceChildAtIndex(_ index: Int, withNode node: XMLNode) {
        let child = self.child(at: index)!
        _childNodes.remove(child)
        _XMLNodeReplaceNode(child._xmlNode, node._xmlNode)
        _childNodes.insert(node)
    }
}

internal protocol _NSXMLNodeCollectionType: Collection { }

extension XMLNode: _NSXMLNodeCollectionType {

    public struct Index: Comparable {
        fileprivate let node: _XMLNodePtr?
        fileprivate let offset: Int?
    }

    public subscript(index: Index) -> XMLNode {
        return XMLNode._objectNodeForNode(index.node!)
    }

    public var startIndex: Index {
        let node = _XMLNodeGetFirstChild(_xmlNode)
        return Index(node: node, offset: node.map { _ in 0 })
    }

    public var endIndex: Index {
        return Index(node: nil, offset: nil)
    }

    public func index(after i: Index) -> Index {
        precondition(i.node != nil, "can't increment endIndex")
        let nextNode = _XMLNodeGetNextSibling(i.node!)
        return Index(node: nextNode, offset: nextNode.map { _ in i.offset! + 1 } )
    }
}

extension XMLNode.Index {
    public static func ==(lhs: XMLNode.Index, rhs: XMLNode.Index) -> Bool {
        return lhs.offset == rhs.offset
    }

    public static func <(lhs: XMLNode.Index, rhs: XMLNode.Index) -> Bool {
        switch (lhs.offset, rhs.offset) {
        case (nil, nil):
            return false
        case (nil, _?):
            return false
        case (_?, nil):
            return true
        case (let lhsOffset?, let rhsOffset?):
            return lhsOffset < rhsOffset
        }
    }
}

