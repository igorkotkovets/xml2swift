//
//  XMLDocument.swift
//  XML2Swift
//
//  Created by Igor Kotkovets on 12/22/17.
//

import Foundation

// Input options
//  NSXMLNodeOptionsNone
//  NSXMLNodePreserveAll
//  NSXMLNodePreserveNamespaceOrder
//  NSXMLNodePreserveAttributeOrder
//  NSXMLNodePreserveEntities
//  NSXMLNodePreservePrefixes
//  NSXMLNodePreserveCDATA
//  NSXMLNodePreserveEmptyElements
//  NSXMLNodePreserveQuotes
//  NSXMLNodePreserveWhitespace
//  NSXMLNodeLoadExternalEntities
//  NSXMLNodeLoadExternalEntitiesSameOriginOnly

//  NSXMLDocumentTidyHTML
//  NSXMLDocumentTidyXML

//  NSXMLDocumentValidate

// Output options
//  NSXMLNodePrettyPrint
//  NSXMLDocumentIncludeContentTypeDeclaration

extension XMLDocument {

    /*!
     @typedef XMLDocument.ContentKind
     @abstract Define what type of document this is.
     @constant XMLDocument.ContentKind.xml The default document type
     @constant XMLDocument.ContentKind.xhtml Set if XMLNode.Options.documentTidyHTML is set and HTML is detected
     @constant XMLDocument.ContentKind.html Outputs empty tags without a close tag, eg <br>
     @constant XMLDocument.ContentKind.text Output the string value of the document
     */
    public enum ContentKind : UInt {

        case xml
        case xhtml
        case html
        case text
    }
}

/*!
 @class XMLDocument
 @abstract An XML Document
 @discussion Note: if the application of a method would result in more than one element in the children array, an exception is thrown. Trying to add a document, namespace, attribute, or node with a parent also throws an exception. To add a node with a parent first detach or create a copy of it.
 */
open class XMLDocument : XMLNode {
    private var _xmlDoc: _XMLDocPtr {
        return _XMLDocPtr(_xmlNode)
    }

    public init?(withRead ioread: @escaping xmlInputReadCallback,
                 close ioclose: @escaping xmlInputCloseCallback,
                 context: UnsafeMutableRawPointer, options mask: Int) {
        xmlKeepBlanksDefault(0)
        guard let doc = xmlReadIO(ioread, ioclose, context, nil, nil, Int32(mask)) else {
            return nil
        }
        super.init(withPrimitive: doc)
    }

    public convenience init() {
        self.init(rootElement: nil)
    }

    /*!
     @method initWithXMLString:options:error:
     @abstract Returns a document created from either XML or HTML, if the HTMLTidy option is set. Parse errors are returned in <tt>error</tt>.
     */
    public convenience init(xmlString string: String, options mask: XMLNode.Options = []) throws {
        _SetupXMLParser()
        guard let data = string.data(using: .utf8) else {
            // TODO: Throw an error
            fatalError("String: '\(string)' could not be converted to NSData using UTF-8 encoding")
        }

        try self.init(data: data, options: mask)
    }

    /*!
     @method initWithContentsOfURL:options:error:
     @abstract Returns a document created from the contents of an XML or HTML URL. Connection problems such as 404, parse errors are returned in <tt>error</tt>.
     */
    public convenience init(contentsOf url: URL, options mask: XMLNode.Options = []) throws {
        _SetupXMLParser()
        let data = try Data(contentsOf: url, options: .mappedIfSafe)

        try self.init(data: data, options: mask)
    }

    /*!
     @method initWithData:options:error:
     @abstract Returns a document created from data. Parse errors are returned in <tt>error</tt>.
     */
    public init(data: Data, options mask: XMLNode.Options = []) throws {
        _SetupXMLParser()
        let docPtr: _XMLDocPtr = _XMLDocPtrFromDataWithOptions(unsafeBitCast(data as NSData, to: CFData.self), UInt32(mask.rawValue))
        super.init(ptr: _XMLNodePtr(docPtr))

        if mask.contains(.documentValidate) {
            try validate()
        }
    }

    /*!
     @method initWithRootElement:
     @abstract Returns a document with a single child, the root element.
     */
    public init(rootElement element: XMLElement?) {
        _SetupXMLParser()
        precondition(element?.parent == nil)

        super.init(kind: .document, options: [])
        if let element = element {
            _XMLDocSetRootElement(_xmlDoc, element._xmlNode)
            _childNodes.insert(element)
        }
    }

    /*!
     @method characterEncoding
     @abstract Sets the character encoding to an IANA type.
     */
    open var characterEncoding: String? {
        get {
            let returned = _XMLDocCopyCharacterEncoding(_xmlDoc)
            return returned == nil ? nil : unsafeBitCast(returned!, to: NSString.self) as String
        }
        set {
            if let value = newValue {
                _XMLDocSetCharacterEncoding(_xmlDoc, value)
            } else {
                _XMLDocSetCharacterEncoding(_xmlDoc, nil)
            }
        }
    }

    /*!
     @method version
     @abstract Sets the XML version. Should be 1.0 or 1.1.
     */
    open var version: String? {
        get {
            let returned = _XMLDocCopyVersion(_xmlDoc)
            return returned == nil ? nil : unsafeBitCast(returned!, to: NSString.self) as String
        }
        set {
            if let value = newValue {
                precondition(value == "1.0" || value == "1.1")
                _XMLDocSetVersion(_xmlDoc, value)
            } else {
                _XMLDocSetVersion(_xmlDoc, nil)
            }
        }
    }

    /*!
     @method standalone
     @abstract Set whether this document depends on an external DTD. If this option is set the standalone declaration will appear on output.
     */
    open var isStandalone: Bool {
        get {
            return _XMLDocStandalone(_xmlDoc)
        }
        set {
            _XMLDocSetStandalone(_xmlDoc, newValue)
        }
    }//primitive

    /*!
     @method documentContentKind
     @abstract The kind of document.
     */
    open var documentContentKind: XMLDocument.ContentKind  {
        get {
            let properties = _XMLDocProperties(_xmlDoc)

            if properties & Int32(_kXMLDocTypeHTML) != 0 {
                return .html
            }

            return .xml
        }

        set {
            var properties = _XMLDocProperties(_xmlDoc)
            switch newValue {
            case .html:
                properties |= Int32(_kXMLDocTypeHTML)

            default:
                properties &= ~Int32(_kXMLDocTypeHTML)
            }

            _XMLDocSetProperties(_xmlDoc, properties)
        }
    }//primitive

    /*!
     @method MIMEType
     @abstract Set the MIME type, eg text/xml.
     */
    open var mimeType: String?

    /*!
     @method DTD
     @abstract Set the associated DTD. This DTD will be output with the document.
     */
    /*@NSCopying*/ open var dtd: XMLDTD? {
        get {
            return XMLDTD._objectNodeForNode(_XMLDocDTD(_xmlDoc)!)
        }
        set {
            if let currDTD = _XMLDocDTD(_xmlDoc) {
                if _XMLNodeGetPrivateData(currDTD) != nil {
                    let DTD = XMLDTD._objectNodeForNode(currDTD)
                    _XMLUnlinkNode(currDTD)
                    _childNodes.remove(DTD)
                } else {
                    _XMLFreeDTD(currDTD)
                }
            }

            if let value = newValue {
                guard let dtd = value.copy() as? XMLDTD else {
                    fatalError("Failed to copy DTD")
                }
                _XMLDocSetDTD(_xmlDoc, dtd._xmlDTD)
                _childNodes.insert(dtd)
            } else {
                _XMLDocSetDTD(_xmlDoc, nil)
            }
        }
    }//primitive

    /*!
     @method setRootElement:
     @abstract Set the root element. Removes all other children including comments and processing-instructions.
     */
    open func setRootElement(_ root: XMLElement) {
        precondition(root.parent == nil)

        for child in _childNodes {
            child.detach()
        }

        _XMLDocSetRootElement(_xmlDoc, root._xmlNode)
        _childNodes.insert(root)
    }

    /*!
     @method rootElement
     @abstract The root element.
     */
    open func rootElement() -> XMLElement? {
        guard let rootPtr = _XMLDocRootElement(_xmlDoc) else {
            return nil
        }

        return XMLNode._objectNodeForNode(rootPtr) as? XMLElement
    }

    open override var childCount: Int {
        return _XMLNodeGetElementChildCount(_xmlNode)
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
     @method XMLData
     @abstract Invokes XMLDataWithOptions with XMLNode.Options.none.
     */
    /*@NSCopying*/ open var xmlData: Data { return xmlData() }

    /*!
     @method XMLDataWithOptions:
     @abstract The representation of this node as it would appear in an XML document, encoded based on characterEncoding.
     */
    open func xmlData(options: XMLNode.Options = []) -> Data {
        let string = xmlString(options: options)
        // TODO: support encodings other than UTF-8

        return string.data(using: .utf8) ?? Data()
    }

    /*!
     @method objectByApplyingXSLT:arguments:error:
     @abstract Applies XSLT with arguments (NSString key/value pairs) to this document, returning a new document.
     */
    @available(*, unavailable, message: "XSLT application is not currently supported")
    open func object(byApplyingXSLT xslt: Data, arguments: [String : String]?) throws -> Any {
        fatalError("\(#function) is not yet implemented", file: #file, line: #line)
    }

    /*!
     @method objectByApplyingXSLTString:arguments:error:
     @abstract Applies XSLT as expressed by a string with arguments (NSString key/value pairs) to this document, returning a new document.
     */
    @available(*, unavailable, message: "XSLT application is not currently supported")
    open func object(byApplyingXSLTString xslt: String, arguments: [String : String]?) throws -> Any {
        fatalError("\(#function) is not yet implemented", file: #file, line: #line)
    }

    /*!
     @method objectByApplyingXSLTAtURL:arguments:error:
     @abstract Applies the XSLT at a URL with arguments (NSString key/value pairs) to this document, returning a new document. Error may contain a connection error from the URL.
     */
    @available(*, unavailable, message: "XSLT application is not currently supported")
    open func objectByApplyingXSLT(at xsltURL: URL, arguments argument: [String : String]?) throws -> Any {
        fatalError("\(#function) is not yet implemented", file: #file, line: #line)
    }

    open func validate() throws {
        var unmanagedError: Unmanaged<CFError>? = nil
        let result = _XMLDocValidate(_xmlDoc, &unmanagedError)
        if !result,
            let unmanagedError = unmanagedError {
            let error = unmanagedError.takeRetainedValue()
            throw error
        }
    }

    internal override class func _objectNodeForNode(_ node: _XMLNodePtr) -> XMLDocument {
        precondition(_XMLNodeGetType(node) == _kXMLTypeDocument)

        if let privateData = _XMLNodeGetPrivateData(node) {
            return unsafeBitCast(privateData, to: XMLDocument.self)
        }

        return XMLDocument(ptr: node)
    }

    internal override init(ptr: _XMLNodePtr) {
        super.init(ptr: ptr)
    }
}
