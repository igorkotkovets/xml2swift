//
//  XMLDTDNode.swift
//  XML2Swift
//
//  Created by igork on 9/10/19.
//

import CoreFoundation


/*!
 @typedef XMLDTDNodeKind
 @abstract The subkind of a DTD node kind.
 */
extension XMLDTDNode {
    public enum DTDKind : UInt {


        case general

        case parsed

        case unparsed

        case parameter

        case predefined


        case cdataAttribute

        case idAttribute

        case idRefAttribute

        case idRefsAttribute

        case entityAttribute

        case entitiesAttribute

        case nmTokenAttribute

        case nmTokensAttribute

        case enumerationAttribute

        case notationAttribute


        case undefinedDeclaration

        case emptyDeclaration

        case anyDeclaration

        case mixedDeclaration

        case elementDeclaration
    }
}

/*!
 @class XMLDTDNode
 @abstract The nodes that are exclusive to a DTD
 @discussion Every DTD node has a name. Object value is defined as follows:<ul>
 <li><b>Entity declaration</b> - the string that that entity resolves to eg "&lt;"</li>
 <li><b>Attribute declaration</b> - the default value, if any</li>
 <li><b>Element declaration</b> - the validation string</li>
 <li><b>Notation declaration</b> - no objectValue</li></ul>
 */
open class XMLDTDNode: XMLNode {

    /*!
     @method initWithXMLString:
     @abstract Returns an element, attribute, entity, or notation DTD node based on the full XML string.
     */
    public init?(xmlString string: String) {
        _SetupXMLParser()
        guard let ptr = _XMLParseDTDNode(string) else { return nil }
        super.init(ptr: ptr)
    } //primitive

    public override init(kind: XMLNode.Kind, options: XMLNode.Options = []) {
        _SetupXMLParser()
        let ptr: _XMLNodePtr

        switch kind {
        case .elementDeclaration:
            ptr = _XMLDTDNewElementDesc(nil, nil)!

        default:
            super.init(kind: kind, options: options)
            return
        }

        super.init(ptr: ptr)
    }

    /*!
     @method dtdKind
     @abstract Sets the DTD sub kind.
     */
    open var dtdKind: XMLDTDNode.DTDKind {
        switch _XMLNodeGetType(_xmlNode) {
        case _kXMLDTDNodeTypeElement:
            switch _XMLDTDElementNodeGetType(_xmlNode) {
            case _kXMLDTDNodeElementTypeAny:
                return .anyDeclaration

            case _kXMLDTDNodeElementTypeEmpty:
                return .emptyDeclaration

            case _kXMLDTDNodeElementTypeMixed:
                return .mixedDeclaration

            case _kXMLDTDNodeElementTypeElement:
                return .elementDeclaration

            default:
                return .undefinedDeclaration
            }

        case _kXMLDTDNodeTypeEntity:
            switch _XMLDTDEntityNodeGetType(_xmlNode) {
            case _kXMLDTDNodeEntityTypeInternalGeneral:
                return .general

            case _kXMLDTDNodeEntityTypeExternalGeneralUnparsed:
                return .unparsed

            case _kXMLDTDNodeEntityTypeExternalParameter:
                fallthrough
            case _kXMLDTDNodeEntityTypeInternalParameter:
                return .parameter

            case _kXMLDTDNodeEntityTypeInternalPredefined:
                return .predefined

            case _kXMLDTDNodeEntityTypeExternalGeneralParsed:
                return .general

            default:
                fatalError("Invalid entity declaration type")
            }

        case _kXMLDTDNodeTypeAttribute:
            switch _XMLDTDAttributeNodeGetType(_xmlNode) {
            case _kXMLDTDNodeAttributeTypeCData:
                return .cdataAttribute

            case _kXMLDTDNodeAttributeTypeID:
                return .idAttribute

            case _kXMLDTDNodeAttributeTypeIDRef:
                return .idRefAttribute

            case _kXMLDTDNodeAttributeTypeIDRefs:
                return .idRefsAttribute

            case _kXMLDTDNodeAttributeTypeEntity:
                return .entityAttribute

            case _kXMLDTDNodeAttributeTypeEntities:
                return .entitiesAttribute

            case _kXMLDTDNodeAttributeTypeNMToken:
                return .nmTokenAttribute

            case _kXMLDTDNodeAttributeTypeNMTokens:
                return .nmTokensAttribute

            case _kXMLDTDNodeAttributeTypeEnumeration:
                return .enumerationAttribute

            case _kXMLDTDNodeAttributeTypeNotation:
                return .notationAttribute

            default:
                fatalError("Invalid attribute declaration type")
            }

        case _kXMLTypeInvalid:
            return unsafeBitCast(0, to: DTDKind.self) // this mirrors Darwin

        default:
            fatalError("This is not actually a DTD node!")
        }
    }

    /*!
     @method isExternal
     @abstract True if the system id is set. Valid for entities and notations.
     */
    open var isExternal: Bool {
        return systemID != nil
    } //primitive

    /*!
     @method openID
     @abstract Sets the open id. This identifier should be in the default catalog in /etc/xml/catalog or in a path specified by the environment variable XML_CATALOG_FILES. When the public id is set the system id must also be set. Valid for entities and notations.
     */
    open var publicID: String? {
        get {
            let returned = _XMLDTDNodeCopyPublicID(_xmlNode)
            return returned == nil ? nil : unsafeBitCast(returned!, to: NSString.self) as String
        }
        set {
            if let value = newValue {
                _XMLDTDNodeSetPublicID(_xmlNode, value)
            } else {
                _XMLDTDNodeSetPublicID(_xmlNode, nil)
            }
        }
    }

    /*!
     @method systemID
     @abstract Sets the system id. This should be a URL that points to a valid DTD. Valid for entities and notations.
     */
    open var systemID: String? {
        get {
            let returned = _XMLDTDNodeCopySystemID(_xmlNode)
            return returned == nil ? nil : unsafeBitCast(returned!, to: NSString.self) as String
        }
        set {
            if let value = newValue {
                _XMLDTDNodeSetSystemID(_xmlNode, value)
            } else {
                _XMLDTDNodeSetSystemID(_xmlNode, nil)
            }
        }
    }

    /*!
     @method notationName
     @abstract Set the notation name. Valid for entities only.
     */
    open var notationName: String? {
        get {
            guard dtdKind == .unparsed else {
                return nil
            }

            let returned = _XMLCopyEntityContent(_xmlNode)
            return returned == nil ? nil : unsafeBitCast(returned!, to: NSString.self) as String
        }
        set {
            guard dtdKind == .unparsed else {
                return
            }

            if let value = newValue {
                _XMLNodeSetContent(_xmlNode, value)
            } else {
                _XMLNodeSetContent(_xmlNode, nil)
            }
        }
    }//primitive

    internal override class func _objectNodeForNode(_ node: _XMLNodePtr) -> XMLDTDNode {
        let type = _XMLNodeGetType(node)
        precondition(type == _kXMLDTDNodeTypeAttribute ||
            type == _kXMLDTDNodeTypeNotation  ||
            type == _kXMLDTDNodeTypeEntity    ||
            type == _kXMLDTDNodeTypeElement)

        if let privateData = _XMLNodeGetPrivateData(node) {
            return unsafeBitCast(privateData, to: XMLDTDNode.self)
        }

        return XMLDTDNode(ptr: node)
    }

    internal override init(ptr: _XMLNodePtr) {
        super.init(ptr: ptr)
    }
}
