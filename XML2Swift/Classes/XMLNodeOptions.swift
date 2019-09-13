import Foundation
import ObjectiveC

extension XMLNode {


    /*!
     @enum Init, input, and output options
     @constant NSXMLNodeIsCDATA This text node is CDATA
     @constant NSXMLNodeExpandEmptyElement This element should be expanded when empty, ie &lt;a>&lt;/a>. This is the default.
     @constant NSXMLNodeCompactEmptyElement This element should contract when empty, ie &lt;a/>
     @constant NSXMLNodeUseSingleQuotes Use single quotes on this attribute or namespace
     @constant NSXMLNodeUseDoubleQuotes Use double quotes on this attribute or namespace. This is the default.
     @constant NSXMLNodeNeverEscapeContents When generating a string representation of an XML document, don't escape the reserved characters '<' and '&' in Text nodes

     @constant NSXMLNodeOptionsNone Use the default options
     @constant NSXMLNodePreserveAll Turn all preservation options on
     @constant NSXMLNodePreserveNamespaceOrder Preserve the order of namespaces
     @constant NSXMLNodePreserveAttributeOrder Preserve the order of attributes
     @constant NSXMLNodePreserveEntities Entities should not be resolved on output
     @constant NSXMLNodePreservePrefixes Prefixes should not be chosen based on closest URI definition
     @constant NSXMLNodePreserveCDATA CDATA should be preserved
     @constant NSXMLNodePreserveEmptyElements Remember whether an empty element was in expanded or contracted form
     @constant NSXMLNodePreserveQuotes Remember whether an attribute used single or double quotes
     @constant NSXMLNodePreserveWhitespace Preserve non-content whitespace
     @constant NSXMLNodePromoteSignificantWhitespace When significant whitespace is encountered in the document, create Text nodes representing it rather than removing it. Has no effect if NSXMLNodePreserveWhitespace is also specified
     @constant NSXMLNodePreserveDTD Preserve the DTD until it is modified

     @constant NSXMLDocumentTidyHTML Try to change HTML into valid XHTML
     @constant NSXMLDocumentTidyXML Try to change malformed XML into valid XML

     @constant NSXMLDocumentValidate Valid this document against its DTD

     @constant NSXMLNodeLoadExternalEntitiesAlways Load all external entities instead of just non-network ones
     @constant NSXMLNodeLoadExternalEntitiesSameOriginOnly Load non-network external entities and external entities from urls with the same domain, host, and port as the document
     @constant NSXMLNodeLoadExternalEntitiesNever Load no external entities, even those that don't require network access

     @constant NSXMLNodePrettyPrint Output this node with extra space for readability
     @constant NSXMLDocumentIncludeContentTypeDeclaration Include a content type declaration for HTML or XHTML
     */
    public struct Options : OptionSet {
        public let rawValue : UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }

        public static let nodeIsCDATA = Options(rawValue: 1 << 0)
        public static let nodeExpandEmptyElement = Options(rawValue: 1 << 1)
        public static let nodeCompactEmptyElement = Options(rawValue: 1 << 2)
        public static let nodeUseSingleQuotes = Options(rawValue: 1 << 3)
        public static let nodeUseDoubleQuotes = Options(rawValue: 1 << 4)
        public static let nodeNeverEscapeContents = Options(rawValue: 1 << 5)

        public static let documentTidyHTML = Options(rawValue: 1 << 9)
        public static let documentTidyXML = Options(rawValue: 1 << 10)
        public static let documentValidate = Options(rawValue: 1 << 13)

        public static let nodeLoadExternalEntitiesAlways = Options(rawValue: 1 << 14)
        public static let nodeLoadExternalEntitiesSameOriginOnly = Options(rawValue: 1 << 15)
        public static let nodeLoadExternalEntitiesNever = Options(rawValue: 1 << 19)

        public static let documentXInclude = Options(rawValue: 1 << 16)
        public static let nodePrettyPrint = Options(rawValue: 1 << 17)
        public static let documentIncludeContentTypeDeclaration = Options(rawValue: 1 << 18)

        public static let nodePreserveNamespaceOrder = Options(rawValue: 1 << 20)
        public static let nodePreserveAttributeOrder = Options(rawValue: 1 << 21)
        public static let nodePreserveEntities = Options(rawValue: 1 << 22)
        public static let nodePreservePrefixes = Options(rawValue: 1 << 23)
        public static let nodePreserveCDATA = Options(rawValue: 1 << 24)
        public static let nodePreserveWhitespace = Options(rawValue: 1 << 25)
        public static let nodePreserveDTD = Options(rawValue: 1 << 26)
        public static let nodePreserveCharacterReferences = Options(rawValue: 1 << 27)
        public static let nodePromoteSignificantWhitespace = Options(rawValue: 1 << 28)
        public static let nodePreserveEmptyElements = Options([.nodeExpandEmptyElement, .nodeCompactEmptyElement])
        public static let nodePreserveQuotes = Options([.nodeUseSingleQuotes, .nodeUseDoubleQuotes])
        public static let nodePreserveAll = Options(rawValue: 0xFFF00000).union([.nodePreserveNamespaceOrder, .nodePreserveAttributeOrder, .nodePreserveEntities, .nodePreservePrefixes, .nodePreserveCDATA, .nodePreserveEmptyElements, .nodePreserveQuotes, .nodePreserveWhitespace, .nodePreserveDTD, .nodePreserveCharacterReferences])
    }
}
