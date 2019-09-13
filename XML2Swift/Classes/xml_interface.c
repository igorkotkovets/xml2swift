//
//  xml_interface.c
//  XML2Swift
//
//  Created by igork on 9/8/19.
//

#include "xml_interface.h"

/*
 libxml2 does not have nullability annotations and does not import well into swift when given potentially differing versions of the library that might be installed on the host operating system. This is a simple C wrapper to simplify some of that interface layer to libxml2.
 */

CFIndex _kXMLInterfaceRecover = XML_PARSE_RECOVER;
CFIndex _kXMLInterfaceNoEnt = XML_PARSE_NOENT;
CFIndex _kXMLInterfaceDTDLoad = XML_PARSE_DTDLOAD;
CFIndex _kXMLInterfaceDTDAttr = XML_PARSE_DTDATTR;
CFIndex _kXMLInterfaceDTDValid = XML_PARSE_DTDVALID;
CFIndex _kXMLInterfaceNoError = XML_PARSE_NOERROR;
CFIndex _kXMLInterfaceNoWarning = XML_PARSE_NOWARNING;
CFIndex _kXMLInterfacePedantic = XML_PARSE_PEDANTIC;
CFIndex _kXMLInterfaceNoBlanks = XML_PARSE_NOBLANKS;
CFIndex _kXMLInterfaceSAX1 = XML_PARSE_SAX1;
CFIndex _kXMLInterfaceXInclude = XML_PARSE_XINCLUDE;
CFIndex _kXMLInterfaceNoNet = XML_PARSE_NONET;
CFIndex _kXMLInterfaceNoDict = XML_PARSE_NODICT;
CFIndex _kXMLInterfaceNSClean = XML_PARSE_NSCLEAN;
CFIndex _kXMLInterfaceNoCdata = XML_PARSE_NOCDATA;
CFIndex _kXMLInterfaceNoXIncnode = XML_PARSE_NOXINCNODE;
CFIndex _kXMLInterfaceCompact = XML_PARSE_COMPACT;
CFIndex _kXMLInterfaceOld10 = XML_PARSE_OLD10;
CFIndex _kXMLInterfaceNoBasefix = XML_PARSE_NOBASEFIX;
CFIndex _kXMLInterfaceHuge = XML_PARSE_HUGE;
CFIndex _kXMLInterfaceOldsax = XML_PARSE_OLDSAX;
CFIndex _kXMLInterfaceIgnoreEnc = XML_PARSE_IGNORE_ENC;
CFIndex _kXMLInterfaceBigLines = XML_PARSE_BIG_LINES;

CFIndex _kXMLTypeInvalid = 0;
CFIndex _kXMLTypeDocument = XML_DOCUMENT_NODE;
CFIndex _kXMLTypeElement = XML_ELEMENT_NODE;
CFIndex _kXMLTypeAttribute = XML_ATTRIBUTE_NODE;
CFIndex _kXMLTypeProcessingInstruction = XML_PI_NODE;
CFIndex _kXMLTypeComment = XML_COMMENT_NODE;
CFIndex _kXMLTypeText = XML_TEXT_NODE;
CFIndex _kXMLTypeCDataSection = XML_CDATA_SECTION_NODE;
CFIndex _kXMLTypeDTD = XML_DTD_NODE;
CFIndex _kXMLDocTypeHTML = XML_DOC_HTML;
CFIndex _kXMLTypeNamespace = 22; // libxml2 does not define namespaces as nodes, so we have to fake it

CFIndex _kXMLDTDNodeTypeEntity = XML_ENTITY_DECL;
CFIndex _kXMLDTDNodeTypeAttribute = XML_ATTRIBUTE_DECL;
CFIndex _kXMLDTDNodeTypeElement = XML_ELEMENT_DECL;
CFIndex _kXMLDTDNodeTypeNotation = XML_NOTATION_NODE;

CFIndex _kXMLDTDNodeElementTypeUndefined = XML_ELEMENT_TYPE_UNDEFINED;
CFIndex _kXMLDTDNodeElementTypeEmpty = XML_ELEMENT_TYPE_EMPTY;
CFIndex _kXMLDTDNodeElementTypeAny = XML_ELEMENT_TYPE_ANY;
CFIndex _kXMLDTDNodeElementTypeMixed = XML_ELEMENT_TYPE_MIXED;
CFIndex _kXMLDTDNodeElementTypeElement = XML_ELEMENT_TYPE_ELEMENT;

CFIndex _kXMLDTDNodeEntityTypeInternalGeneral = XML_INTERNAL_GENERAL_ENTITY;
CFIndex _kXMLDTDNodeEntityTypeExternalGeneralParsed = XML_EXTERNAL_GENERAL_PARSED_ENTITY;
CFIndex _kXMLDTDNodeEntityTypeExternalGeneralUnparsed = XML_EXTERNAL_GENERAL_UNPARSED_ENTITY;
CFIndex _kXMLDTDNodeEntityTypeInternalParameter = XML_INTERNAL_PARAMETER_ENTITY;
CFIndex _kXMLDTDNodeEntityTypeExternalParameter = XML_EXTERNAL_PARAMETER_ENTITY;
CFIndex _kXMLDTDNodeEntityTypeInternalPredefined = XML_INTERNAL_PREDEFINED_ENTITY;

CFIndex _kXMLDTDNodeAttributeTypeCData = XML_ATTRIBUTE_CDATA;
CFIndex _kXMLDTDNodeAttributeTypeID = XML_ATTRIBUTE_ID;
CFIndex _kXMLDTDNodeAttributeTypeIDRef = XML_ATTRIBUTE_IDREF;
CFIndex _kXMLDTDNodeAttributeTypeIDRefs = XML_ATTRIBUTE_IDREFS;
CFIndex _kXMLDTDNodeAttributeTypeEntity = XML_ATTRIBUTE_ENTITY;
CFIndex _kXMLDTDNodeAttributeTypeEntities = XML_ATTRIBUTE_ENTITIES;
CFIndex _kXMLDTDNodeAttributeTypeNMToken = XML_ATTRIBUTE_NMTOKEN;
CFIndex _kXMLDTDNodeAttributeTypeNMTokens = XML_ATTRIBUTE_NMTOKENS;
CFIndex _kXMLDTDNodeAttributeTypeEnumeration = XML_ATTRIBUTE_ENUMERATION;
CFIndex _kXMLDTDNodeAttributeTypeNotation = XML_ATTRIBUTE_NOTATION;

CFIndex _kXMLNodePreserveWhitespace = 1 << 25;
CFIndex _kXMLNodeCompactEmptyElement = 1 << 2;
CFIndex _kXMLNodePrettyPrint = 1 << 17;
CFIndex _kXMLNodeLoadExternalEntitiesNever = 1 << 19;
CFIndex _kXMLNodeLoadExternalEntitiesAlways = 1 << 14;

// We define this structure because libxml2's "notation" node does not contain the fields
// nearly all other libxml2 node fields contain, that we use extensively.
typedef struct {
    void * _private;
    xmlElementType type;
    const xmlChar* name;
    xmlNodePtr children;
    xmlNodePtr last;
    xmlNodePtr parent;
    xmlNodePtr next;
    xmlNodePtr prev;
    xmlDocPtr doc;
    xmlNotationPtr notation;
} _XMLNotation;

_XMLDTDNodePtr _Nullable _XMLDTDNewElementDesc(_XMLDTDPtr dtd, const unsigned char* name) {
    bool freeDTD = false;
    if (!dtd) {
        dtd = xmlNewDtd(NULL, (const xmlChar*)"tempDTD", NULL, NULL);
        freeDTD = true;
    }

    if (!name) {
        name = (const xmlChar*)"";
    }

    xmlElementPtr result = xmlAddElementDecl(NULL, dtd, name, XML_ELEMENT_TYPE_ANY, NULL);

    if (freeDTD) {
        _XMLUnlinkNode(result);
        xmlFreeDtd(dtd);
    }

    return result;
}

static inline void _removeHashEntry(xmlHashTablePtr table, const xmlChar* name, xmlNodePtr node);
static inline void _removeHashEntry(xmlHashTablePtr table, const xmlChar* name, xmlNodePtr node) {
    if (xmlHashLookup(table, name) == node) {
        xmlHashRemoveEntry(table, name, NULL);
    }
}

void _XMLUnlinkNode(_XMLNodePtr node) {
    // DTD DECL nodes have references in the parent DTD's various hash tables.
    // For some reason, libxml2's xmlUnlinkNode doesn't actually remove those references for
    // anything other than entities, and even then only if there is a parent document!
    // To make matters worse, when you run xmlFreeDtd on the dtd, it actually deallocs everything
    // that it has a hash table reference to in addition to all of it's children. So, we need
    // to manually remove the node from the correct hash table before we can unlink it.
    switch (((xmlNodePtr)node)->type) {
        case XML_ELEMENT_DECL:
        {
            xmlElementPtr elemDecl = (xmlElementPtr)node;
            xmlDtdPtr dtd = elemDecl->parent;
            _removeHashEntry(dtd->elements, elemDecl->name, node);
        }
            break;

        case XML_ENTITY_DECL:
        {
            xmlEntityPtr entityDecl = (xmlEntityPtr)node;
            xmlDtdPtr dtd = entityDecl->parent;
            _removeHashEntry(dtd->entities, entityDecl->name, node);
            _removeHashEntry(dtd->pentities, entityDecl->name, node);
        }
            break;

        case XML_ATTRIBUTE_DECL:
        {
            xmlAttributePtr attrDecl = (xmlAttributePtr)node;
            xmlDtdPtr dtd = attrDecl->parent;
            if (xmlHashLookup3(dtd->attributes, attrDecl->name, NULL, attrDecl->elem) == node) {
                xmlHashRemoveEntry3(dtd->attributes, attrDecl->name, NULL, attrDecl->elem, NULL);
            }
        }
            break;

        case XML_NOTATION_NODE:
        {
            // Since we're handling notation nodes instead of libxml2, we need to do some extra work here
            xmlNotationPtr notation = ((_XMLNotation*)node)->notation;
            xmlDtdPtr dtd = (xmlDtdPtr)((_XMLNotation*)node)->parent;
            _removeHashEntry(dtd->notations, notation->name, (xmlNodePtr)notation);
            return;
        }

        default:
            break;
    }
    xmlUnlinkNode(node);
}

_XMLNodePtr _XMLNodeGetNextSibling(_XMLNodePtr node) {
    return ((xmlNodePtr)node)->next;
}

_XMLNodePtr _XMLNodeGetPrevSibling(_XMLNodePtr node) {
    return ((xmlNodePtr)node)->prev;
}

_XMLNodePtr _XMLNodeGetParent(_XMLNodePtr node) {
    return ((xmlNodePtr)node)->parent;
}

bool _XMLDocStandalone(_XMLDocPtr doc) {
    return ((xmlDocPtr)doc)->standalone == 1;
}

void _XMLDocSetStandalone(_XMLDocPtr doc, bool standalone) {
    ((xmlDocPtr)doc)->standalone = standalone ? 1 : 0;
}

_XMLNodePtr _XMLDocRootElement(_XMLDocPtr doc) {
    return xmlDocGetRootElement(doc);
}

void _XMLDocSetRootElement(_XMLDocPtr doc, _XMLNodePtr node) {
    xmlDocSetRootElement(doc, node);
}

CFStringRef _XMLDocCopyCharacterEncoding(_XMLDocPtr doc) {
    return CFStringCreateWithCString(NULL, (const char*)((xmlDocPtr)doc)->encoding, kCFStringEncodingUTF8);
}

void _XMLDocSetCharacterEncoding(_XMLDocPtr doc,  const unsigned char* _Nullable  encoding) {
    xmlDocPtr docPtr = (xmlDocPtr)doc;

    if (docPtr->encoding) {
        xmlFree((xmlChar*)docPtr->encoding);
    }

    docPtr->encoding = xmlStrdup(encoding);
}

CFStringRef _XMLDocCopyVersion(_XMLDocPtr doc) {
    return CFStringCreateWithCString(NULL, (const char*)((xmlDocPtr)doc)->version, kCFStringEncodingUTF8);
}

void _XMLDocSetVersion(_XMLDocPtr doc, const unsigned char* version) {
    xmlDocPtr docPtr = (xmlDocPtr)doc;

    if (docPtr->version) {
        xmlFree((xmlChar*)docPtr->version);
    }

    docPtr->version = xmlStrdup(version);
}

int _XMLDocProperties(_XMLDocPtr doc) {
    return ((xmlDocPtr)doc)->properties;
}

void _XMLDocSetProperties(_XMLDocPtr doc, int newProperties) {
    ((xmlDocPtr)doc)->properties = newProperties;
}

_XMLDTDPtr _Nullable _XMLDocDTD(_XMLDocPtr doc) {
    return xmlGetIntSubset(doc);
}

void _XMLDocSetDTD(_XMLDocPtr doc, _XMLDTDPtr _Nullable dtd) {
    if (!dtd) {
        ((xmlDocPtr)doc)->intSubset = NULL;
        return;
    }

    xmlDocPtr docPtr = (xmlDocPtr)doc;
    xmlDtdPtr dtdPtr = (xmlDtdPtr)dtd;
    docPtr->intSubset = dtdPtr;
    if (docPtr->children == NULL) {
        xmlAddChild(doc, dtd);
    } else {
        xmlAddPrevSibling(docPtr->children, dtd);
    }
}

CFIndex _XMLNodeGetElementChildCount(_XMLNodePtr node) {
    return xmlChildElementCount(node);
}

void _XMLNodeAddChild(_XMLNodePtr node, _XMLNodePtr child) {
    if (((xmlNodePtr)node)->type == XML_NOTATION_NODE) {// the "artificial" node we created
        if (((xmlNodePtr)node)->type == XML_DTD_NODE) {// the only circumstance under which this actually makes sense
            xmlNotationPtr notation = ((_XMLNotation*)child)->notation;
            xmlDtdPtr dtd = (xmlDtdPtr)node;

            if (dtd->notations == NULL) {
                xmlDictPtr dict = dtd->doc ? dtd->doc->dict : NULL;
                dtd->notations = xmlHashCreateDict(0, dict);
            }
            xmlHashAddEntry(dtd->notations, notation->name, notation);
        }
        return;
    }
    xmlAddChild(node, child);
}

void _XMLNodeAddPrevSibling(_XMLNodePtr node, _XMLNodePtr prevSibling) {
    xmlAddPrevSibling(node, prevSibling);
}

void _XMLNodeAddNextSibling(_XMLNodePtr node, _XMLNodePtr nextSibling) {
    xmlAddNextSibling(node, nextSibling);
}

void _XMLNodeReplaceNode(_XMLNodePtr node, _XMLNodePtr replacement) {
    xmlReplaceNode(node, replacement);
}

_XMLDocPtr _XMLNewDoc(const unsigned char* version) {
    return xmlNewDoc(version);
}

_XMLNodePtr _XMLNewProcessingInstruction(const unsigned char* name, const unsigned char* value) {
    return xmlNewPI(name, value);
}

_XMLNodePtr _XMLNewNode(_XMLNamespacePtr namespace, const char* name) {
    return xmlNewNode(namespace, (const xmlChar*)name);
}

_XMLNodePtr _XMLCopyNode(_XMLNodePtr node, bool recursive) {
    int recurse = recursive ? 1 : 0;
    switch (((xmlNodePtr)node)->type) {
        case XML_DOCUMENT_NODE:
            return xmlCopyDoc(node, recurse);

        case XML_DTD_NODE:
            return xmlCopyDtd(node);

        default:
            return xmlCopyNode(node, recurse);
    }
}

_XMLNodePtr _XMLNewTextNode(const unsigned char* value) {
    return xmlNewText(value);
}

_XMLNodePtr _XMLNewComment(const unsigned char* value) {
    return xmlNewComment(value);
}

_XMLNodePtr _XMLNewProperty(_XMLNodePtr node, const unsigned char* name, const unsigned char* uri, const unsigned char* value) {
    xmlNodePtr nodePtr = (xmlNodePtr)node;
    xmlChar *prefix = NULL;
    xmlChar *localName = xmlSplitQName2(name, &prefix);

    _XMLNodePtr result;
    if (uri == NULL && localName == NULL) {
        result = xmlNewProp(node, name, value);
    } else {
        xmlNsPtr ns = xmlNewNs(nodePtr, uri, localName ? prefix : NULL);
        result = xmlNewNsProp(nodePtr, ns, localName ? localName : name, value);
    }

    if (localName) {
        xmlFree(localName);
    }
    if (prefix) {
        xmlFree(prefix);
    }
    return result;
}

const char* _XMLNodeCopyURI(_XMLNodePtr node) {
    xmlNodePtr nodePtr = (xmlNodePtr)node;
    switch (nodePtr->type) {
        case XML_ATTRIBUTE_NODE:
        case XML_ELEMENT_NODE:
            if (nodePtr->ns && nodePtr->ns->href) {
                return (const char*)nodePtr->ns->href;
            } else if (nodePtr->nsDef && nodePtr->nsDef->href) {
                return (const char*)nodePtr->nsDef->href;
            } else {
                return NULL;
            }

        case XML_DOCUMENT_NODE:
        {
            xmlDocPtr doc = (xmlDocPtr)node;
            return (const char*)doc->URL;
        }

        default:
            return NULL;
    }
}

void _XMLNodeSetURI(_XMLNodePtr node, const unsigned char* URI) {
    xmlNodePtr nodePtr = (xmlNodePtr)node;
    switch (nodePtr->type) {
        case XML_ATTRIBUTE_NODE:
        case XML_ELEMENT_NODE:

            if (!URI) {
                if (nodePtr->nsDef) {
                    xmlFree(nodePtr->nsDef);
                }
                nodePtr->nsDef = NULL;
                return;
            }

            xmlNsPtr ns = xmlSearchNsByHref(nodePtr->doc, nodePtr, URI);
            if (!ns) {
                if (nodePtr->nsDef && (nodePtr->nsDef->href == NULL)) {
                    nodePtr->nsDef->href = xmlStrdup(URI);
                    return;
                }

                ns = xmlNewNs(nodePtr, URI, NULL);
            }

            xmlSetNs(nodePtr, ns);
            break;

        case XML_DOCUMENT_NODE:
        {
            xmlDocPtr doc = (xmlDocPtr)node;
            if (doc->URL) {
                xmlFree((xmlChar*)doc->URL);
            }
            doc->URL = xmlStrdup(URI);
        }
            break;

        default:
            return;
    }
}



_XMLDocPtr _XMLDocPtrFromDataWithOptions(CFDataRef data, unsigned int options) {
    uint32_t xmlOptions = 0;

    if ((options & _kXMLNodePreserveWhitespace) == 0) {
        xmlOptions |= XML_PARSE_NOBLANKS;
    }

    if (options & _kXMLNodeLoadExternalEntitiesNever) {
        xmlOptions &= ~(XML_PARSE_NOENT);
    } else {
        xmlOptions |= XML_PARSE_NOENT;
    }

    if (options & _kXMLNodeLoadExternalEntitiesAlways) {
        xmlOptions |= XML_PARSE_DTDLOAD;
    }

    xmlOptions |= XML_PARSE_RECOVER;
    xmlOptions |= XML_PARSE_NSCLEAN;

    return xmlReadMemory((const char*)CFDataGetBytePtr(data), CFDataGetLength(data), NULL, NULL, xmlOptions);
}

static inline xmlChar* _getQName(xmlNodePtr node) {
    const xmlChar* prefix = NULL;
    const xmlChar* ncname = node->name;

    switch (node->type) {
        case XML_DOCUMENT_NODE:
        case XML_NOTATION_NODE:
        case XML_DTD_NODE:
        case XML_ELEMENT_DECL:
        case XML_ATTRIBUTE_DECL:
        case XML_ENTITY_DECL:
        case XML_NAMESPACE_DECL:
        case XML_XINCLUDE_START:
        case XML_XINCLUDE_END:
            break;

        default:
            if (node->ns != NULL) {
                prefix = node->ns->prefix;
            }
    }

    return xmlBuildQName(ncname, prefix, NULL, 0);
}

CFStringRef _XMLNodeCopyLocalName(_XMLNodePtr node) {
    xmlChar* prefix = NULL;
    const xmlChar* result = xmlSplitQName2(_getQName((xmlNodePtr)node), &prefix);
    if (result == NULL) {
        result = ((xmlNodePtr)node)->name;
    }

    return CFStringCreateWithCString(NULL, (const char*)result, kCFStringEncodingUTF8);
}

CFStringRef _Nullable _XMLNamespaceCopyPrefix(_XMLNodePtr node) {
    xmlNsPtr ns = ((xmlNodePtr)node)->ns;

    if (ns->prefix == NULL) {
        return NULL;
    }

    return CFStringCreateWithCString(NULL, (const char*)ns->prefix, kCFStringEncodingUTF8);
}

static inline const xmlChar* _getNamespacePrefix(const char* name) {
    // It is "default namespace" if `name` is empty.
    // Default namespace is represented by `NULL` in libxml2.
    return (name == NULL || name[0] == '\0') ? NULL : (const xmlChar*)name;
}

_XMLNodePtr _XMLNewNamespace(const char* name, const char* stringValue) {
    const xmlChar* namespaceName = _getNamespacePrefix(name);
    xmlNsPtr ns = xmlNewNs(NULL, (const xmlChar*)stringValue, namespaceName);
    xmlNodePtr node = xmlNewNode(ns, (const xmlChar*)"");
    node->type = _kXMLTypeNamespace;

    return node;
}

CFStringRef _XMLCopyStringWithOptions(_XMLNodePtr node, uint32_t options) {
    if (((xmlNodePtr)node)->type == XML_ENTITY_DECL &&
        ((xmlEntityPtr)node)->etype == XML_INTERNAL_PREDEFINED_ENTITY) {
        // predefined entities need special handling, libxml2 just tosses an error and returns a NULL string
        // if we try to use xmlSaveTree on a predefined entity
        CFMutableStringRef result = CFStringCreateMutable(NULL, 0);
        CFStringAppend(result, CFStringCreateWithCString(NULL, "<!ENTITY ", kCFStringEncodingUTF8));
        CFStringAppendCString(result, (const char*)((xmlEntityPtr)node)->name, kCFStringEncodingUTF8);
        CFStringAppend(result, CFStringCreateWithCString(NULL, " \"", kCFStringEncodingUTF8));
        CFStringAppendCString(result, (const char*)((xmlEntityPtr)node)->content, kCFStringEncodingUTF8);
        CFStringAppend(result, CFStringCreateWithCString(NULL, "\">", kCFStringEncodingUTF8));

        return result;
    } else if (((xmlNodePtr)node)->type == XML_NOTATION_NODE) {
        // This is not actually a thing that occurs naturally in libxml2
        xmlNotationPtr notation = ((_XMLNotation*)node)->notation;
        CFMutableStringRef result = CFStringCreateMutable(NULL, 0);
        CFStringAppend(result, CFStringCreateWithCString(NULL, "<!NOTATION ", kCFStringEncodingUTF8));
        CFStringAppendCString(result, (const char*)notation->name, kCFStringEncodingUTF8);
        CFStringAppend(result, CFStringCreateWithCString(NULL, " ", kCFStringEncodingUTF8));
        if (notation->PublicID == NULL && notation->SystemID != NULL) {
            CFStringAppend(result, CFStringCreateWithCString(NULL, "SYSTEM ", kCFStringEncodingUTF8));
        } else if (notation->PublicID != NULL) {
            CFStringAppend(result, CFStringCreateWithCString(NULL, "PUBLIC \"", kCFStringEncodingUTF8));
            CFStringAppendCString(result, (const char*)notation->PublicID, kCFStringEncodingUTF8);
            CFStringAppend(result, CFStringCreateWithCString(NULL, "\"", kCFStringEncodingUTF8));
        }

        if (notation->SystemID != NULL) {
            CFStringAppend(result, CFStringCreateWithCString(NULL, "\"", kCFStringEncodingUTF8));
            CFStringAppendCString(result, (const char*)notation->SystemID, kCFStringEncodingUTF8);
            CFStringAppend(result, CFStringCreateWithCString(NULL, "\"", kCFStringEncodingUTF8));
        }

        CFStringAppend(result, CFStringCreateWithCString(NULL, " >", kCFStringEncodingUTF8));

        return result;
    }

    xmlBufferPtr buffer = xmlBufferCreate();

    uint32_t xmlOptions = XML_SAVE_AS_XML;

    if (options & _kXMLNodePreserveWhitespace) {
        xmlOptions |= XML_SAVE_WSNONSIG;
    }

    if (!(options & _kXMLNodeCompactEmptyElement)) {
        xmlOptions |= XML_SAVE_NO_EMPTY;
    }

    if (options & _kXMLNodePrettyPrint) {
        xmlOptions |= XML_SAVE_FORMAT;
    }

    xmlSaveCtxtPtr ctx = xmlSaveToBuffer(buffer, "utf-8", xmlOptions);
    xmlSaveTree(ctx, node);
    int error = xmlSaveClose(ctx);

    if (error == -1) {
        return CFStringCreateWithCString(NULL, "", kCFStringEncodingUTF8);
    }

    const xmlChar* bufferContents = xmlBufferContent(buffer);

    CFStringRef result = CFStringCreateWithCString(NULL, (const char*)bufferContents, kCFStringEncodingUTF8);

    xmlBufferFree(buffer);

    return result;
}

CFArrayRef _XMLNodesForXPath(_XMLNodePtr node, const unsigned char* xpath) {

    if (((xmlNodePtr)node)->doc == NULL) {
        return NULL;
    }

    if (((xmlNodePtr)node)->type == XML_DOCUMENT_NODE) {
        node = ((xmlDocPtr)node)->children;
    }

    xmlXPathContextPtr context = xmlXPathNewContext(((xmlNodePtr)node)->doc);
    xmlNsPtr ns = ((xmlNodePtr)node)->ns;
    while (ns != NULL) {
        xmlXPathRegisterNs(context, ns->prefix, ns->href);
        ns = ns->next;
    }
    xmlXPathObjectPtr evalResult = xmlXPathNodeEval(node, xpath, context);

    xmlNodeSetPtr nodes = evalResult->nodesetval;
    int count = nodes ? nodes->nodeNr : 0;

    CFMutableArrayRef results = CFArrayCreateMutable(NULL, count, NULL);
    for (int i = 0; i < count; i++) {
        CFArrayAppendValue(results, nodes->nodeTab[i]);
    }

    xmlXPathFreeContext(context);
    xmlXPathFreeObject(evalResult);

    return results;
}

CFStringRef _Nullable _XMLCopyPathForNode(_XMLNodePtr node) {
    xmlChar* path = xmlGetNodePath(node);
    CFStringRef result = CFStringCreateWithCString(NULL, (const char*)path, kCFStringEncodingUTF8);
    xmlFree(path);
    return result;
}



static inline int _compareNamespacePrefix(const xmlChar* prefix1, const xmlChar* prefix2) {
    if (prefix1 == NULL) {
        if (prefix2 == NULL) return 0;
        return -1;
    } else {
        if (prefix2 == NULL) return 1;
        return xmlStrcmp(prefix1, prefix2);
    }
}

static inline xmlNsPtr _searchNamespace(xmlNodePtr nodePtr, const xmlChar* prefix) {
    while (nodePtr != NULL) {
        xmlNsPtr ns = nodePtr->nsDef;
        while (ns != NULL) {
            if (_compareNamespacePrefix(prefix, ns->prefix) == 0) {
                return ns;
            }
            ns = ns->next;
        }
        nodePtr = nodePtr->parent;
    }
    return NULL;
}

void _XMLCompletePropURI(_XMLNodePtr propertyNode, _XMLNodePtr node) {
    xmlNodePtr propNodePtr = (xmlNodePtr)propertyNode;
    xmlNodePtr nodePtr = (xmlNodePtr)node;
    if (propNodePtr->type != XML_ATTRIBUTE_NODE || nodePtr->type != XML_ELEMENT_NODE) {
        return;
    }
    if (propNodePtr->ns != NULL
        && propNodePtr->ns->href == NULL
        && propNodePtr->ns->prefix != NULL) {
        xmlNsPtr ns = _searchNamespace(nodePtr, propNodePtr->ns->prefix);
        if (ns != NULL && ns->href != NULL) {
            propNodePtr->ns->href = xmlStrdup(ns->href);
        }
    }
}

_XMLNodePtr _XMLNodeHasProp(_XMLNodePtr node, const unsigned char* propertyName, const unsigned char* uri) {
    xmlNodePtr nodePtr = (xmlNodePtr)node;
    xmlChar* prefix = NULL;
    xmlChar* localName = xmlSplitQName2(propertyName, &prefix);

    if (!uri) {
        xmlNsPtr ns = _searchNamespace(nodePtr, prefix);
        uri = ns ? ns->href : NULL;
    }
    _XMLNodePtr result;
    result = xmlHasNsProp(node, localName ? localName : propertyName, uri);

    if (localName) {
        xmlFree(localName);
    }
    if (prefix) {
        xmlFree(prefix);
    }

    return result;
}


void _XMLNodeSetPrivateData(_XMLNodePtr node, void* data) {
    if (!node) {
        return;
    }

    ((xmlNodePtr)node)->_private = data;
}

void* _Nullable  _XMLNodeGetPrivateData(_XMLNodePtr node) {
    return ((xmlNodePtr)node)->_private;
}



CFStringRef _Nullable _XMLNodeCopyName(_XMLNodePtr node) {
    xmlNodePtr xmlNode = (xmlNodePtr)node;

    xmlChar* qName = _getQName(xmlNode);

    if (qName != NULL) {
        CFStringRef result = CFStringCreateWithCString(NULL, (const char*)qName, kCFStringEncodingUTF8);
        if (qName != xmlNode->name) {
            xmlFree(qName);
        }
        return result;
    } else {
        return NULL;
    }
}

void _XMLNodeForceSetName(_XMLNodePtr node, const char* _Nullable name) {
    xmlNodePtr xmlNode = (xmlNodePtr)node;
    if (xmlNode->name) xmlFree((xmlChar*) xmlNode->name);
    xmlNode->name = xmlStrdup((xmlChar*) name);
}

void _XMLNodeSetName(_XMLNodePtr node, const char* name) {
    xmlNodeSetName(node, (const xmlChar*)name);
}

Boolean _XMLNodeNameEqual(_XMLNodePtr node, const char* name) {
    return (xmlStrcmp(((xmlNodePtr)node)->name, (xmlChar*)name) == 0) ? true : false;
}

CFStringRef _XMLCopyEntityContent(_XMLEntityPtr entity) {
    const xmlChar* content = ((xmlEntityPtr)entity)->content;
    if (!content) {
        return NULL;
    }

    CFIndex length = ((xmlEntityPtr)entity)->length;
    CFStringRef result = CFStringCreateWithBytes(NULL, content, length, kCFStringEncodingUTF8, false);

    return result;
}

// Namespaces
_XMLNodePtr _Nonnull * _Nullable _XMLNamespaces(_XMLNodePtr node, CFIndex* count) {
    *count = 0;
    xmlNs* ns = ((xmlNode*)node)->nsDef;
    while (ns != NULL) {
        (*count)++;
        ns = ns->next;
    }

    _XMLNodePtr* result = calloc(*count, sizeof(_XMLNodePtr));
    ns = ((xmlNode*)node)->nsDef;
    for (int i = 0; i < *count; i++) {
        xmlNode* temp = xmlNewNode(ns, (unsigned char *)"");

        temp->type = _kXMLTypeNamespace;
        result[i] = temp;
        ns = ns->next;
    }
    return result;
}

static inline void _removeAllNamespaces(xmlNodePtr node);
static inline void _removeAllNamespaces(xmlNodePtr node) {
    xmlNsPtr ns = node->nsDef;
    if (ns != NULL) {
        xmlFreeNsList(ns);
        node->nsDef = NULL;
    }
}

void _XMLSetNamespaces(_XMLNodePtr node, _XMLNodePtr _Nullable * _Nullable nodes, CFIndex count) {
    _removeAllNamespaces(node);

    if (nodes == NULL || count == 0) {
        return;
    }

    xmlNodePtr nsNode = (xmlNodePtr)nodes[0];
    ((xmlNodePtr)node)->nsDef = xmlCopyNamespace(nsNode->ns);
    xmlNsPtr currNs = ((xmlNodePtr)node)->nsDef;
    for (CFIndex i = 1; i < count; i++) {
        currNs->next = xmlCopyNamespace(((xmlNodePtr)nodes[i])->ns);
        currNs = currNs->next;
    }
}

CFStringRef _Nullable _XMLNamespaceCopyValue(_XMLNodePtr node) {
    xmlNsPtr ns = ((xmlNode*)node)->ns;

    if (ns->href == NULL) {
        return NULL;
    }

    return CFStringCreateWithCString(NULL, (const char*)ns->href, kCFStringEncodingUTF8);
}

void _XMLNamespaceSetPrefix(_XMLNodePtr node, const char* prefix, int64_t length) {
    xmlNsPtr ns = ((xmlNodePtr)node)->ns;

    ns->prefix = xmlStrndup(_getNamespacePrefix(prefix), length);
}

CFStringRef _XMLNodeCopyContent(_XMLNodePtr node) {
    switch (((xmlNodePtr)node)->type) {
        case XML_ELEMENT_DECL:
        {
            char* buffer = calloc(2048, 1);
            xmlSnprintfElementContent(buffer, 2047, ((xmlElementPtr)node)->content, 1);
            CFStringRef result = CFStringCreateWithCString(NULL, buffer, kCFStringEncodingUTF8);
            free(buffer);
            return result;
        }

        default:
        {
            xmlChar* content = xmlNodeGetContent(node);
            if (content == NULL) {
                return NULL;
            }
            CFStringRef result = CFStringCreateWithCString(NULL, (const char*)content, kCFStringEncodingUTF8);
            xmlFree(content);

            return result;
        }
    }
}

void _XMLNamespaceSetValue(_XMLNodePtr node, const char* value, int64_t length) {
    xmlNsPtr ns = ((xmlNodePtr)node)->ns;
    ns->href = xmlStrndup((const xmlChar*)value, length);
}

void _XMLAddNamespace(_XMLNodePtr node, _XMLNodePtr nsNode) {
    xmlNodePtr nodePtr = (xmlNodePtr)node;
    xmlNsPtr ns = xmlCopyNamespace(((xmlNodePtr)nsNode)->ns);
    ns->context = nodePtr->doc;

    xmlNsPtr currNs = nodePtr->nsDef;
    if (currNs == NULL) {
        nodePtr->nsDef = ns;
        return;
    }

    while(currNs->next != NULL) {
        currNs = currNs->next;
    }

    currNs->next = ns;
}

void _XMLRemoveNamespace(_XMLNodePtr node, const char* prefix) {
    xmlNodePtr nodePtr = (xmlNodePtr)node;
    xmlNsPtr ns = nodePtr->nsDef;
    const xmlChar* prefixForLibxml2 = _getNamespacePrefix(prefix);
    if (ns != NULL && _compareNamespacePrefix(prefixForLibxml2, ns->prefix) == 0) {
        nodePtr->nsDef = ns->next;
        xmlFreeNs(ns);
        return;
    }

    while (ns->next != NULL) {
        if (_compareNamespacePrefix(ns->next->prefix, prefixForLibxml2) == 0) {
            xmlNsPtr next = ns->next;
            ns->next = ns->next->next;
            xmlFreeNs(next);
            return;
        }

        ns = ns->next;
    }
}

void _XMLFreeNode(_XMLNodePtr node) {
    if (!node) {
        return;
    }

    switch (((xmlNodePtr)node)->type) {
        case XML_ENTITY_DECL:
            if (((xmlEntityPtr)node)->etype == XML_INTERNAL_PREDEFINED_ENTITY) {
                // predefined entity nodes are statically declared in libxml2 and can't be free'd
                return;
            }

        case XML_NOTATION_NODE:
            xmlFree(((_XMLNotation*)node)->notation);
            free(node);
            return;

        case XML_ATTRIBUTE_DECL:
        {
            // xmlFreeNode doesn't take into account peculiarities of xmlAttributePtr, such
            // as not having a content field. So we need to handle freeing it the way libxml2 would if we were
            // behaving as it expected us to.
            xmlAttributePtr attribute = (xmlAttributePtr)node;
            xmlDictPtr dict = attribute->doc ? attribute->doc->dict : NULL;
            xmlUnlinkNode(node);
            if (attribute->tree != NULL) {
                xmlFreeEnumeration(attribute->tree);
            }
            if (dict) {
                if (!xmlDictOwns(dict, attribute->elem)) {
                    xmlFree((xmlChar*)attribute->elem);
                }
                if (!xmlDictOwns(dict, attribute->name)) {
                    xmlFree((xmlChar*)attribute->name);
                }
                if (!xmlDictOwns(dict, attribute->prefix)) {
                    xmlFree((xmlChar*)attribute->prefix);
                }
                if (!xmlDictOwns(dict, attribute->defaultValue)) {
                    xmlFree((xmlChar*)attribute->defaultValue);
                }
            } else {
                xmlFree((xmlChar*)attribute->elem);
                xmlFree((xmlChar*)attribute->name);
                xmlFree((xmlChar*)attribute->prefix);
                xmlFree((xmlChar*)attribute->defaultValue);
            }
            xmlFree(attribute);
            return;
        }

        default:
            // we first need to check if this node is one of our custom
            // namespace nodes, which don't actually exist in libxml2
            if (((xmlNodePtr)node)->type == _kXMLTypeNamespace) {
                // resetting its type to XML_ELEMENT_NODE will cause the enclosed namespace
                // to be properly freed by libxml2
                ((xmlNodePtr)node)->type = XML_ELEMENT_NODE;
            }
            xmlFreeNode(node);
    }
}

void _XMLFreeDocument(_XMLDocPtr doc) {
    xmlFreeDoc(doc);
}

void _XMLFreeDTD(_XMLDTDPtr dtd) {
    xmlFreeDtd(dtd);
}

void _XMLFreeProperty(_XMLNodePtr prop) {
    xmlFreeProp(prop);
}

const char *_XMLSplitQualifiedName(const char *_Nonnull qname) {
    int len = 0;
    return (const char *)xmlSplitQName3((const xmlChar *)qname, &len);
}

bool _XMLGetLengthOfPrefixInQualifiedName(const char *_Nonnull qname, size_t *length) {
    int len = 0;
    if (xmlSplitQName3((const xmlChar *)qname, &len) != NULL) {
        *length = len;
        return true;
    } else {
        return false;
    }
}

void _XMLNodeSetContent(_XMLNodePtr node, const unsigned char* _Nullable  content) {
    // So handling set content on XML_ELEMENT_DECL is listed as a TODO !!! in libxml2's source code.
    // that means we have to do it ourselves.
    switch (((xmlNodePtr)node)->type) {
        case XML_ELEMENT_DECL:
        {
            xmlElementPtr element = (xmlElementPtr)node;
            if (content == NULL) {
                xmlFreeDocElementContent(element->doc, element->content);
                element->content = NULL;
                return;
            }

            // rather than writing custom code to parse the new content into the correct
            // xmlElementContent structures, let's leverage what we've already got.
            CFMutableStringRef xmlString = CFStringCreateMutable(NULL, 0);
            CFStringAppend(xmlString, CFStringCreateWithCString(NULL, "<!ELEMENT ", kCFStringEncodingUTF8));
            CFStringAppendCString(xmlString, (const char*)element->name, kCFStringEncodingUTF8);
            CFStringAppend(xmlString, CFStringCreateWithCString(NULL, " ", kCFStringEncodingUTF8));
            CFStringAppendCString(xmlString, (const char*)content, kCFStringEncodingUTF8);
            CFStringAppend(xmlString, CFStringCreateWithCString(NULL, ">", kCFStringEncodingUTF8));

            size_t bufferSize = CFStringGetMaximumSizeForEncoding(CFStringGetLength(xmlString), kCFStringEncodingUTF8) + 1;
            char* buffer = calloc(bufferSize, 1);
            CFStringGetCString(xmlString, buffer, bufferSize, kCFStringEncodingUTF8);
            xmlElementPtr resultNode = _XMLParseDTDNode((const xmlChar*)buffer);

            if (resultNode) {
                xmlFreeDocElementContent(element->doc, element->content);
                _XMLFreeNode(element->attributes);
                xmlRegFreeRegexp(element->contModel);

                element->type = resultNode->type;
                element->etype = resultNode->etype;
                element->content = resultNode->content;
                element->attributes = resultNode->attributes;
                element->contModel = resultNode->contModel;

                resultNode->content = NULL;
                resultNode->attributes = NULL;
                resultNode->contModel = NULL;
                _XMLFreeNode(resultNode);
            }

            return;
        }

        default:
            if (content == NULL) {
                xmlNodeSetContent(node, nil);
                return;
            }

            xmlNodeSetContent(node, content);
    }
}

_XMLDocPtr _XMLNodeGetDocument(_XMLNodePtr node) {
    return ((xmlNodePtr)node)->doc;
}

CFStringRef _XMLEncodeEntities(_XMLDocPtr doc, const unsigned char* string) {
    if (!string) {
        return NULL;
    }

    const xmlChar* stringResult = xmlEncodeEntitiesReentrant(doc, string);

    CFStringRef result = CFStringCreateWithCString(NULL, (const char*)stringResult, kCFStringEncodingUTF8);

    xmlFree((xmlChar*)stringResult);

    return result;
}

CFStringRef _XMLNodeCopyPrefix(_XMLNodePtr node) {
    xmlChar* result = NULL;
    xmlChar* unused = xmlSplitQName2(_getQName((xmlNodePtr)node), &result);

    CFStringRef resultString = CFStringCreateWithCString(NULL, (const char*)result, kCFStringEncodingUTF8);
    xmlFree(result);
    xmlFree(unused);

    return resultString;
}

void _XMLValidityErrorHandler(void* ctxt, const char* msg, ...);
void _XMLValidityErrorHandler(void* ctxt, const char* msg, ...) {
    char* formattedMessage = calloc(1, 1024);

    va_list args;
    va_start(args, msg);
    vsprintf(formattedMessage, msg, args);
    va_end(args);

    CFStringRef message = CFStringCreateWithCString(NULL, formattedMessage, kCFStringEncodingUTF8);
    CFStringAppend(ctxt, message);
    CFRelease(message);
    free(formattedMessage);
}

bool _XMLDocValidate(_XMLDocPtr doc, CFErrorRef _Nullable * error) {
    CFMutableStringRef errorMessage = CFStringCreateMutable(NULL, 0);

    xmlValidCtxtPtr ctxt = xmlNewValidCtxt();
    ctxt->error = &_XMLValidityErrorHandler;
    ctxt->userData = errorMessage;

    int result = xmlValidateDocument(ctxt, doc);

    xmlFreeValidCtxt(ctxt);

    if (result == 0 && error != NULL) {
        CFMutableDictionaryRef userInfo = CFDictionaryCreateMutable(NULL, 1, &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFDictionarySetValue(userInfo, kCFErrorLocalizedDescriptionKey, errorMessage);

        *error = CFErrorCreate(NULL, CFStringCreateWithCString(NULL, "NSXMLParserErrorDomain", kCFStringEncodingUTF8), 0, userInfo);

        CFRelease(userInfo);
    }

    CFRelease(errorMessage);

    return result != 0;
}

_XMLDTDPtr _XMLNewDTD(_XMLDocPtr doc, const unsigned char* name, const unsigned char* publicID, const unsigned char* systemID) {
    return xmlNewDtd(doc, name, publicID, systemID);
}

void _XMLNotationScanner(void* payload, void* data, xmlChar* name) {
    xmlNotationPtr notation = (xmlNotationPtr)payload;
    _XMLNotation* node = (_XMLNotation*)data;
    node->type = XML_NOTATION_NODE;
    node->name = notation->name;
    node->notation = notation;
}

_XMLNodePtr _XMLNodeProperties(_XMLNodePtr node) {
    return ((xmlNodePtr)node)->properties;
}

CFIndex _XMLNodeGetType(_XMLNodePtr node) {
    if (!node) {
        return _kXMLTypeInvalid;
    }
    return ((xmlNodePtr)node)->type;
}

_XMLNodePtr _XMLNodeGetFirstChild(_XMLNodePtr node) {
    return ((xmlNodePtr)node)->children;
}

_XMLDTDPtr _Nullable _XMLParseDTD(const unsigned char* URL) {
    return xmlParseDTD(NULL, URL);
}

_XMLDTDPtr _Nullable _XMLParseDTDFromData(CFDataRef data, CFErrorRef _Nullable * error) {
    xmlParserInputBufferPtr inBuffer = xmlParserInputBufferCreateMem((const char*)CFDataGetBytePtr(data), CFDataGetLength(data), XML_CHAR_ENCODING_UTF8);

    xmlSAXHandler handler;
    handler.error = &_XMLValidityErrorHandler;
    CFMutableStringRef errorMessage = CFStringCreateMutable(NULL, 0);
    handler._private = errorMessage;

    xmlDtdPtr dtd = xmlIOParseDTD(NULL, inBuffer, XML_CHAR_ENCODING_UTF8);

    if (dtd == NULL && error != NULL) {
        CFMutableDictionaryRef userInfo = CFDictionaryCreateMutable(NULL, 1, &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFDictionarySetValue(userInfo, (void *)kCFErrorLocalizedDescriptionKey, (void *)errorMessage);

        *error = CFErrorCreate(NULL, CFStringCreateWithCString(NULL, "NSXMLParserErrorDomain", kCFStringEncodingUTF8), 0, userInfo);

        CFRelease(userInfo);
    }
    CFRelease(errorMessage);

    return dtd;
}

_XMLDTDNodePtr _XMLParseDTDNode(const unsigned char* xmlString) {
    CFDataRef data = CFDataCreateWithBytesNoCopy(NULL, xmlString, xmlStrlen(xmlString), (kCFAllocatorNull));
    xmlDtdPtr dtd = _XMLParseDTDFromData(data, NULL);
    CFRelease(data);

    if (dtd == NULL) {
        return NULL;
    }

    xmlNodePtr node = dtd->children;
    if (node != NULL) {
        xmlUnlinkNode(node);
    } else if (dtd->notations) {
        node = (xmlNodePtr)calloc(1, sizeof(_XMLNotation));
        xmlHashScan((xmlNotationTablePtr)dtd->notations, &_XMLNotationScanner, (void*)node);
    }

    return node;
}

CFStringRef _Nullable _XMLDTDCopyExternalID(_XMLDTDPtr dtd) {
    const unsigned char* externalID = ((xmlDtdPtr)dtd)->ExternalID;
    if (externalID) {
        return CFStringCreateWithCString(NULL, (const char*)externalID, kCFStringEncodingUTF8);
    }

    return NULL;
}

void _XMLDTDSetExternalID(_XMLDTDPtr dtd, const unsigned char* externalID) {
    xmlDtdPtr dtdPtr = (xmlDtdPtr)dtd;
    if (dtdPtr->ExternalID) {
        xmlDictPtr dict = dtdPtr->doc ? dtdPtr->doc->dict : NULL;
        if (dict) {
            if (!xmlDictOwns(dict, dtdPtr->ExternalID)) {
                xmlFree((xmlChar*)dtdPtr->ExternalID);
            }
        } else {
            xmlFree((xmlChar*)dtdPtr->ExternalID);
        }
    }

    dtdPtr->ExternalID = xmlStrdup(externalID);
}

CFStringRef _Nullable _XMLDTDCopySystemID(_XMLDTDPtr dtd) {
    const unsigned char* systemID = ((xmlDtdPtr)dtd)->SystemID;
    if (systemID) {
        return CFStringCreateWithCString(NULL, (const char*)systemID, kCFStringEncodingUTF8);
    }

    return NULL;
}

void _XMLDTDSetSystemID(_XMLDTDPtr dtd, const unsigned char* systemID) {
    xmlDtdPtr dtdPtr = (xmlDtdPtr)dtd;

    if (dtdPtr->SystemID) {
        xmlDictPtr dict = dtdPtr->doc ? dtdPtr->doc->dict : NULL;
        if (dict) {
            if (!xmlDictOwns(dict, dtdPtr->SystemID)) {
                xmlFree((xmlChar*)dtdPtr->SystemID);
            }
        } else {
            xmlFree((xmlChar*)dtdPtr->SystemID);
        }
    }

    dtdPtr->SystemID = xmlStrdup(systemID);
}

_XMLDTDNodePtr _Nullable _XMLDTDGetElementDesc(_XMLDTDPtr dtd, const unsigned char* name) {
    return xmlGetDtdElementDesc(dtd, name);
}

_XMLDTDNodePtr _Nullable _XMLDTDGetAttributeDesc(_XMLDTDPtr dtd, const unsigned char* elementName, const unsigned char* name) {
    return xmlGetDtdAttrDesc(dtd, elementName, name);
}

_XMLDTDNodePtr _Nullable _XMLDTDGetNotationDesc(_XMLDTDPtr dtd, const unsigned char* name) {
    xmlNotationPtr notation = xmlGetDtdNotationDesc(dtd, name);
    _XMLNotation *notationPtr = calloc(sizeof(_XMLNotation), 1);
    notationPtr->type = XML_NOTATION_NODE;
    notationPtr->notation = notation;
    notationPtr->parent = dtd;
    notationPtr->doc = ((xmlDtdPtr)dtd)->doc;
    notationPtr->name = notation->name;

    return notationPtr;
}

_XMLDTDNodePtr _Nullable _XMLDTDGetEntityDesc(_XMLDTDPtr dtd, const unsigned char* name) {
    xmlDocPtr doc = ((xmlDtdPtr)dtd)->doc;
    bool createdDoc = false;
    if (doc == NULL) {
        doc = xmlNewDoc((const xmlChar*)"1.0");
        doc->extSubset = dtd;
        ((xmlDtdPtr)dtd)->doc = doc;
        createdDoc = true;
    }

    xmlEntityPtr node = xmlGetDtdEntity(doc, name);

    if (!node) {
        node = xmlGetParameterEntity(doc, name);
    }

    if (createdDoc) {
        doc->extSubset = NULL;
        ((xmlDtdPtr)dtd)->doc = NULL;
        xmlFreeDoc(doc);
    }

    return node;
}

_XMLDTDNodePtr _Nullable _XMLDTDGetPredefinedEntity(const unsigned char* name) {
    return xmlGetPredefinedEntity(name);
}

CFIndex _XMLDTDElementNodeGetType(_XMLDTDNodePtr node) {
    return ((xmlElementPtr)node)->etype;
}

CFIndex _XMLDTDEntityNodeGetType(_XMLDTDNodePtr node) {
    return ((xmlEntityPtr)node)->etype;
}

CFIndex _XMLDTDAttributeNodeGetType(_XMLDTDNodePtr node) {
    return ((xmlAttributePtr)node)->atype;
}

CFStringRef _Nullable _XMLDTDNodeCopySystemID(_XMLDTDNodePtr node) {
    switch (((xmlNodePtr)node)->type) {
        case XML_ENTITY_DECL:
            return CFStringCreateWithCString(NULL, (const char*)((xmlEntityPtr)node)->SystemID, kCFStringEncodingUTF8);

        case XML_NOTATION_NODE:
            return CFStringCreateWithCString(NULL, (const char*)((_XMLNotation*)node)->notation->SystemID, kCFStringEncodingUTF8);

        default:
            return NULL;
    }
}

void _XMLDTDNodeSetSystemID(_XMLDTDNodePtr node, const unsigned char* systemID) {
    switch (((xmlNodePtr)node)->type) {
        case XML_ENTITY_DECL:
        {
            xmlEntityPtr entity = (xmlEntityPtr)node;
            xmlDictPtr dict = entity->doc ? entity->doc->dict : NULL;
            if (dict) {
                if (!xmlDictOwns(dict, entity->SystemID)) {
                    xmlFree((xmlChar*)entity->SystemID);
                }
            } else {
                xmlFree((xmlChar*)entity->SystemID);
            }
            entity->SystemID = systemID ? xmlStrdup(systemID) : NULL;
            return;
        }
        case XML_NOTATION_NODE:
        {
            xmlNotationPtr notation = ((_XMLNotation*)node)->notation;
            xmlFree((xmlChar*)notation->SystemID);
            notation->SystemID = systemID ? xmlStrdup(systemID) : NULL;
            return;
        }

        default:
            return;
    }
}

CFStringRef _Nullable _XMLDTDNodeCopyPublicID(_XMLDTDNodePtr node) {
    switch (((xmlNodePtr)node)->type) {
        case XML_ENTITY_DECL:
            return CFStringCreateWithCString(NULL, (const char*)((xmlEntityPtr)node)->ExternalID, kCFStringEncodingUTF8);

        case XML_NOTATION_NODE:
            return CFStringCreateWithCString(NULL, (const char*)((_XMLNotation*)node)->notation->PublicID, kCFStringEncodingUTF8);

        default:
            return NULL;
    }
}

void _XMLDTDNodeSetPublicID(_XMLDTDNodePtr node, const unsigned char* publicID) {
    switch (((xmlNodePtr)node)->type) {
        case XML_ENTITY_DECL:
        {
            xmlEntityPtr entity = (xmlEntityPtr)node;
            xmlDictPtr dict = entity->doc ? entity->doc->dict : NULL;
            if (dict) {
                if (!xmlDictOwns(dict, entity->ExternalID)) {
                    xmlFree((xmlChar*)entity->ExternalID);
                }
            } else {
                xmlFree((xmlChar*)entity->ExternalID);
            }
            entity->ExternalID = publicID ? xmlStrdup(publicID) : NULL;
            return;
        }
        case XML_NOTATION_NODE:
        {
            xmlNotationPtr notation = ((_XMLNotation*)node)->notation;
            xmlFree((xmlChar*)notation->PublicID);
            notation->PublicID = publicID ? xmlStrdup(publicID) : NULL;
            return;
        }

        default:
            return;
    }
}

