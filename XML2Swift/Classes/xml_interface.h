//
//  xml_interface.h
//  XML2Swift
//
//  Created by igork on 9/8/19.
//

#ifndef xml_interface_h
#define xml_interface_h

#include <stdio.h>
#include <stdint.h>
#include <sys/types.h>
#include <stdbool.h>
#include <libxml/globals.h>
#include <libxml/xmlerror.h>
#include <libxml/parser.h>
#include <libxml/parserInternals.h>
#include <libxml/tree.h>
#include <libxml/xmlmemory.h>
#include <libxml/xmlsave.h>
#include <libxml/xpath.h>
#include <libxml/xpathInternals.h>
#include <libxml/dict.h>
#include <CoreFoundation/CoreFoundation.h>

extern CFIndex _kXMLInterfaceRecover;
extern CFIndex _kXMLInterfaceNoEnt;
extern CFIndex _kXMLInterfaceDTDLoad;
extern CFIndex _kXMLInterfaceDTDAttr;
extern CFIndex _kXMLInterfaceDTDValid;
extern CFIndex _kXMLInterfaceNoError;
extern CFIndex _kXMLInterfaceNoWarning;
extern CFIndex _kXMLInterfacePedantic;
extern CFIndex _kXMLInterfaceNoBlanks;
extern CFIndex _kXMLInterfaceSAX1;
extern CFIndex _kXMLInterfaceXInclude;
extern CFIndex _kXMLInterfaceNoNet;
extern CFIndex _kXMLInterfaceNoDict;
extern CFIndex _kXMLInterfaceNSClean;
extern CFIndex _kXMLInterfaceNoCdata;
extern CFIndex _kXMLInterfaceNoXIncnode;
extern CFIndex _kXMLInterfaceCompact;
extern CFIndex _kXMLInterfaceOld10;
extern CFIndex _kXMLInterfaceNoBasefix;
extern CFIndex _kXMLInterfaceHuge;
extern CFIndex _kXMLInterfaceOldsax;
extern CFIndex _kXMLInterfaceIgnoreEnc;
extern CFIndex _kXMLInterfaceBigLines;

extern CFIndex _kXMLTypeInvalid;
extern CFIndex _kXMLTypeDocument;
extern CFIndex _kXMLTypeElement;
extern CFIndex _kXMLTypeAttribute;
extern CFIndex _kXMLTypeProcessingInstruction;
extern CFIndex _kXMLTypeComment;
extern CFIndex _kXMLTypeText;
extern CFIndex _kXMLTypeCDataSection;
extern CFIndex _kXMLTypeDTD;
extern CFIndex _kXMLDocTypeHTML;
extern CFIndex _kXMLTypeNamespace;

extern CFIndex _kXMLDTDNodeTypeEntity;
extern CFIndex _kXMLDTDNodeTypeAttribute;
extern CFIndex _kXMLDTDNodeTypeElement;
extern CFIndex _kXMLDTDNodeTypeNotation;

extern CFIndex _kXMLDTDNodeElementTypeUndefined;
extern CFIndex _kXMLDTDNodeElementTypeEmpty;
extern CFIndex _kXMLDTDNodeElementTypeAny;
extern CFIndex _kXMLDTDNodeElementTypeMixed;
extern CFIndex _kXMLDTDNodeElementTypeElement;

extern CFIndex _kXMLDTDNodeEntityTypeInternalGeneral;
extern CFIndex _kXMLDTDNodeEntityTypeExternalGeneralParsed;
extern CFIndex _kXMLDTDNodeEntityTypeExternalGeneralUnparsed;
extern CFIndex _kXMLDTDNodeEntityTypeInternalParameter;
extern CFIndex _kXMLDTDNodeEntityTypeExternalParameter;
extern CFIndex _kXMLDTDNodeEntityTypeInternalPredefined;

extern CFIndex _kXMLDTDNodeAttributeTypeCData;
extern CFIndex _kXMLDTDNodeAttributeTypeID;
extern CFIndex _kXMLDTDNodeAttributeTypeIDRef;
extern CFIndex _kXMLDTDNodeAttributeTypeIDRefs;
extern CFIndex _kXMLDTDNodeAttributeTypeEntity;
extern CFIndex _kXMLDTDNodeAttributeTypeEntities;
extern CFIndex _kXMLDTDNodeAttributeTypeNMToken;
extern CFIndex _kXMLDTDNodeAttributeTypeNMTokens;
extern CFIndex _kXMLDTDNodeAttributeTypeEnumeration;
extern CFIndex _kXMLDTDNodeAttributeTypeNotation;

typedef void* _XMLNodePtr;
typedef void* _XMLDocPtr;
typedef void* _XMLNamespacePtr;
typedef void* _XMLEntityPtr;
typedef void* _XMLDTDPtr;
typedef void* _XMLDTDNodePtr;

_XMLDTDNodePtr _Nullable _XMLDTDNewElementDesc(_XMLDTDPtr dtd, const unsigned char* name);

void _XMLUnlinkNode(_XMLNodePtr node);
_XMLNodePtr _XMLNodeGetPrevSibling(_XMLNodePtr node);
_XMLNodePtr _XMLNodeGetNextSibling(_XMLNodePtr node);
_XMLNodePtr _XMLNodeGetParent(_XMLNodePtr node);
bool _XMLDocStandalone(_XMLDocPtr doc);
void _XMLDocSetStandalone(_XMLDocPtr doc, bool standalone);


_XMLNodePtr _XMLDocRootElement(_XMLDocPtr doc);
void _XMLDocSetRootElement(_XMLDocPtr doc, _XMLNodePtr node);
CFStringRef _XMLDocCopyCharacterEncoding(_XMLDocPtr doc);
void _XMLDocSetCharacterEncoding(_XMLDocPtr doc,  const unsigned char* _Nullable  encoding);
CFStringRef _XMLDocCopyVersion(_XMLDocPtr doc);
void _XMLDocSetVersion(_XMLDocPtr doc, const unsigned char* version);
int _XMLDocProperties(_XMLDocPtr doc);
void _XMLDocSetProperties(_XMLDocPtr doc, int newProperties);
_XMLDTDPtr _Nullable _XMLDocDTD(_XMLDocPtr doc);
void _XMLDocSetDTD(_XMLDocPtr doc, _XMLDTDPtr _Nullable dtd);
CFIndex _XMLNodeGetElementChildCount(_XMLNodePtr node);
void _XMLNodeAddChild(_XMLNodePtr node, _XMLNodePtr child);
void _XMLNodeAddPrevSibling(_XMLNodePtr node, _XMLNodePtr prevSibling);
void _XMLNodeAddNextSibling(_XMLNodePtr node, _XMLNodePtr nextSibling);
void _XMLNodeReplaceNode(_XMLNodePtr node, _XMLNodePtr replacement);

_XMLDocPtr _XMLNewDoc(const unsigned char* version);
_XMLNodePtr _XMLNewProcessingInstruction(const unsigned char* name, const unsigned char* value);
_XMLNodePtr _XMLNewNode(_XMLNamespacePtr namespace, const char* name);
_XMLNodePtr _XMLCopyNode(_XMLNodePtr node, bool recursive);
_XMLNodePtr _XMLNewTextNode(const unsigned char* value);
_XMLNodePtr _XMLNewComment(const unsigned char* value);
_XMLNodePtr _Nonnull _XMLNewProperty(_XMLNodePtr node, const unsigned char* name, const unsigned char* uri, const unsigned char* value);
const char* _XMLNodeCopyURI(_XMLNodePtr node);
void _XMLNodeSetURI(_XMLNodePtr node, const unsigned char* URI);
bool _XMLDocValidate(_XMLDocPtr doc, CFErrorRef _Nullable * error);
_XMLDTDPtr _XMLNewDTD(_XMLDocPtr doc, const unsigned char* name, const unsigned char* publicID, const unsigned char* systemID);
_XMLDocPtr _XMLDocPtrFromDataWithOptions(CFDataRef data, unsigned int options);
CFStringRef _XMLNodeCopyLocalName(_XMLNodePtr node);
CFStringRef _Nullable _XMLNamespaceCopyPrefix(_XMLNodePtr node);
_XMLNodePtr _XMLNewNamespace(const char* name, const char* stringValue);
CFStringRef _XMLCopyStringWithOptions(_XMLNodePtr node, uint32_t options);


static inline int _compareNamespacePrefix(const xmlChar* prefix1, const xmlChar* prefix2);
static inline xmlNsPtr _searchNamespace(xmlNodePtr nodePtr, const xmlChar* prefix);
void _XMLCompletePropURI(_XMLNodePtr propertyNode, _XMLNodePtr node);
_XMLNodePtr _XMLNodeHasProp(_XMLNodePtr node, const unsigned char* propertyName, const unsigned char* uri);
void _XMLNodeSetPrivateData(_XMLNodePtr node, void* data);
CFArrayRef _XMLNodesForXPath(_XMLNodePtr node, const unsigned char* xpath);
CFStringRef _Nullable _XMLCopyPathForNode(_XMLNodePtr node);
void* _Nullable  _XMLNodeGetPrivateData(_XMLNodePtr node);
CFStringRef _Nullable _XMLNodeCopyName(_XMLNodePtr node);

void _XMLNodeForceSetName(_XMLNodePtr node, const char* _Nullable name);
void _XMLNodeSetName(_XMLNodePtr node, const char* name);
Boolean _XMLNodeNameEqual(_XMLNodePtr node, const char* name);
CFStringRef _XMLCopyEntityContent(_XMLEntityPtr entity);
_XMLNodePtr _Nonnull * _Nullable _XMLNamespaces(_XMLNodePtr node, CFIndex* count);
void _XMLSetNamespaces(_XMLNodePtr node, _XMLNodePtr _Nullable * _Nullable nodes, CFIndex count);
CFStringRef _Nullable _XMLNamespaceCopyValue(_XMLNodePtr node);
void _XMLNamespaceSetPrefix(_XMLNodePtr node, const char* prefix, int64_t length);
CFStringRef _XMLNodeCopyContent(_XMLNodePtr node);
void _XMLNamespaceSetValue(_XMLNodePtr node, const char* value, int64_t length);
void _XMLAddNamespace(_XMLNodePtr node, _XMLNodePtr nsNode);
void _XMLRemoveNamespace(_XMLNodePtr node, const char* prefix);
void _XMLFreeNode(_XMLNodePtr node);
void _XMLFreeDocument(_XMLDocPtr doc);
void _XMLFreeDTD(_XMLDTDPtr dtd);
void _XMLFreeProperty(_XMLNodePtr prop);
const char *_XMLSplitQualifiedName(const char *_Nonnull qname);
bool _XMLGetLengthOfPrefixInQualifiedName(const char *_Nonnull qname, size_t *length);
void _XMLNodeSetContent(_XMLNodePtr node, const unsigned char* _Nullable  content);
_XMLDocPtr _XMLNodeGetDocument(_XMLNodePtr node);
CFStringRef _XMLEncodeEntities(_XMLDocPtr doc, const unsigned char* string);
CFStringRef _XMLNodeCopyPrefix(_XMLNodePtr node);
_XMLDTDNodePtr _XMLParseDTDNode(const unsigned char* xmlString);

_XMLNodePtr _XMLNodeProperties(_XMLNodePtr node);
CFIndex _XMLNodeGetType(_XMLNodePtr node);
CFIndex _XMLNodeGetElementChildCount(_XMLNodePtr node);
_XMLNodePtr _XMLNodeGetFirstChild(_XMLNodePtr node);
_XMLDTDPtr _Nullable _XMLParseDTD(const unsigned char* URL);
_XMLDTDPtr _Nullable _XMLParseDTDFromData(CFDataRef data, CFErrorRef _Nullable * error);
_XMLDTDNodePtr _XMLParseDTDNode(const unsigned char* xmlString);
CFStringRef _Nullable _XMLDTDCopyExternalID(_XMLDTDPtr dtd);
void _XMLDTDSetExternalID(_XMLDTDPtr dtd, const unsigned char* externalID);
CFStringRef _Nullable _XMLDTDCopySystemID(_XMLDTDPtr dtd);
void _XMLDTDSetSystemID(_XMLDTDPtr dtd, const unsigned char* systemID);
_XMLDTDNodePtr _Nullable _XMLDTDGetElementDesc(_XMLDTDPtr dtd, const unsigned char* name);
_XMLDTDNodePtr _Nullable _XMLDTDGetAttributeDesc(_XMLDTDPtr dtd, const unsigned char* elementName, const unsigned char* name);
_XMLDTDNodePtr _Nullable _XMLDTDGetNotationDesc(_XMLDTDPtr dtd, const unsigned char* name);
_XMLDTDNodePtr _Nullable _XMLDTDGetEntityDesc(_XMLDTDPtr dtd, const unsigned char* name);


_XMLDTDNodePtr _Nullable _XMLDTDGetPredefinedEntity(const unsigned char* name);
CFStringRef _Nullable _XMLDTDCopySystemID(_XMLDTDPtr dtd);
void _XMLDTDSetSystemID(_XMLDTDPtr dtd, const unsigned char* systemID);
_XMLDTDNodePtr _Nullable _XMLDTDGetElementDesc(_XMLDTDPtr dtd, const unsigned char* name);
_XMLDTDNodePtr _Nullable _XMLDTDGetAttributeDesc(_XMLDTDPtr dtd, const unsigned char* elementName, const unsigned char* name);
_XMLDTDNodePtr _Nullable _XMLDTDGetNotationDesc(_XMLDTDPtr dtd, const unsigned char* name);
_XMLDTDNodePtr _Nullable _XMLDTDGetEntityDesc(_XMLDTDPtr dtd, const unsigned char* name);
_XMLDTDNodePtr _Nullable _XMLDTDGetPredefinedEntity(const unsigned char* name);
CFIndex _XMLDTDElementNodeGetType(_XMLDTDNodePtr node);
CFIndex _XMLDTDEntityNodeGetType(_XMLDTDNodePtr node);
CFIndex _XMLDTDAttributeNodeGetType(_XMLDTDNodePtr node);
CFStringRef _Nullable _XMLDTDNodeCopySystemID(_XMLDTDNodePtr node);
void _XMLDTDNodeSetSystemID(_XMLDTDNodePtr node, const unsigned char* systemID);
CFStringRef _Nullable _XMLDTDNodeCopyPublicID(_XMLDTDNodePtr node);
void _XMLDTDNodeSetPublicID(_XMLDTDNodePtr node, const unsigned char* publicID);


#endif /* xml_interface_h */
