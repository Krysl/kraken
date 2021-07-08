/*
 * Copyright (C) 2021 Alibaba Inc. All rights reserved.
 * Author: Kraken Team.
 */

#include "node.h"
#include "kraken_bridge.h"

namespace kraken::binding::qjs {

JSValue Node::constructor(QjsContext *ctx, JSValue func_obj, JSValue this_val, int argc, JSValue *argv) {
  return JS_ThrowTypeError(ctx, "Illegal constructor");
}
JSValue Node::cloneNode(QjsContext *ctx, JSValue this_val, int argc, JSValue *argv) {
  auto selfInstance = static_cast<NodeInstance *>(JS_GetOpaque(this_val, kHostClassInstanceClassId));

  JSValue deepValue;
  if (argc < 1) {
    deepValue = JS_NewBool(ctx, false);
  } else {
    deepValue = argv[0];
  }
//
  if (!JS_IsBool(deepValue)) {
    return JS_ThrowTypeError(ctx, "Failed to cloneNode: deep should be a Boolean.");
  }
  bool deep = JS_ToBool(ctx, deepValue);

  if (selfInstance->nodeType == NodeType::ELEMENT_NODE) {
//    auto element = static_cast<ElementInstance *>(selfInstance);
//
//    JSValueRef rootElementRef = copyNodeValue(ctx, static_cast<NodeInstance *>(element));
//    JSObjectRef rootNodeObjectRef = JSValueToObject(ctx, rootElementRef, nullptr);
//    auto rootNodeInstance = static_cast<NodeInstance *>(JSObjectGetPrivate(rootNodeObjectRef));
//
//    if (deepBooleanRef) {
//      traverseCloneNode(ctx, static_cast<ElementInstance *>(element), static_cast<ElementInstance *>(rootNodeInstance));
//    }
//
//    return rootNodeInstance->object;
  } else if (selfInstance->nodeType == NodeType::TEXT_NODE) {
//    auto textNode = static_cast<JSTextNode::TextNodeInstance *>(selfInstance);
//    JSValueRef newTextNodeRef = copyNodeValue(ctx, static_cast<NodeInstance *>(textNode));
//    JSObjectRef newTextNodeObjectRef = JSValueToObject(ctx, newTextNodeRef, nullptr);
//    auto newTextNodeObjectInstance = static_cast<NodeInstance *>(JSObjectGetPrivate(newTextNodeObjectRef));
//
//    return newTextNodeObjectInstance->object;
  } else {
    return JS_NULL;
  }
  return JS_NULL;
}
JSValue Node::appendChild(QjsContext *ctx, JSValue this_val, int argc, JSValue *argv) {
  if (argc != 1) {
    return JS_ThrowTypeError(ctx, "Failed to execute 'appendChild' on 'Node': first argument is required.");
  }

  auto selfInstance = static_cast<NodeInstance *>(JS_GetOpaque(this_val, kHostClassInstanceClassId));
  if (selfInstance == nullptr) return JS_ThrowTypeError(ctx, "this object is not a instance of Node.");
  JSValue &nodeValue = argv[0];

  if (!JS_IsObject(nodeValue)) {
    return JS_ThrowTypeError(ctx, "Failed to execute 'appendChild' on 'Node': first arguments should be an Node type.");
  }

  auto *nodeInstance = static_cast<NodeInstance *>(JS_GetOpaque(nodeValue, kHostClassInstanceClassId));

  if (nodeInstance == nullptr || nodeInstance->document() != selfInstance->document()) {
    return JS_ThrowTypeError(ctx, "Failed to execute 'appendChild' on 'Node': first arguments should be an Node type.");
  }

  if (nodeInstance->eventTargetId == HTML_TARGET_ID || nodeInstance == selfInstance) {
    return JS_ThrowTypeError(ctx, "Failed to execute 'appendChild' on 'Node': The new child element contains the parent.");
  }

  selfInstance->internalAppendChild(nodeInstance);
  return nodeInstance->instanceObject;
}
JSValue Node::remove(QjsContext *ctx, JSValue this_val, int argc, JSValue *argv) {
  auto selfInstance = static_cast<NodeInstance *>(JS_GetOpaque(this_val, kHostClassInstanceClassId));
  selfInstance->internalRemove();
  return JS_UNDEFINED;
}
JSValue Node::removeChild(QjsContext *ctx, JSValue this_val, int argc, JSValue *argv) {
  if (argc < 1) {
    return JS_ThrowTypeError(ctx, "Uncaught TypeError: Failed to execute 'removeChild' on 'Node': 1 arguments required");
  }

  JSValue &nodeValue = argv[0];

  if (!JS_IsObject(nodeValue)) {
    return JS_ThrowTypeError(ctx, "Uncaught TypeError: Failed to execute 'removeChild' on 'Node': 1st arguments is not object");
  }

  auto selfInstance = static_cast<NodeInstance *>(JS_GetOpaque(this_val, kHostClassInstanceClassId));
  auto nodeInstance = static_cast<NodeInstance *>(JS_GetOpaque(nodeValue, kHostClassInstanceClassId));

  if (nodeInstance == nullptr || nodeInstance->document() != selfInstance->document()) {
    return JS_ThrowTypeError(ctx, "Failed to execute 'removeChild' on 'Node': 1st arguments is not a Node object.");
  }

  auto removedNode = selfInstance->internalRemoveChild(nodeInstance);
  return removedNode->instanceObject;
}
JSValue Node::insertBefore(QjsContext *ctx, JSValue this_val, int argc, JSValue *argv) {
  if (argc < 2) {
    return JS_ThrowTypeError(ctx, "Failed to execute 'insertBefore' on 'Node': 2 arguments is required.");
  }

  JSValue &nodeValue = argv[0];
  JSValue &referenceNodeValue = argv[1];

  if (!JS_IsObject(nodeValue)) {
    return JS_ThrowTypeError(ctx, "Failed to execute 'insertBefore' on 'Node': the node element is not object.");
  }

  NodeInstance *referenceInstance = nullptr;

  if (JS_IsObject(referenceNodeValue)) {
    referenceInstance = static_cast<NodeInstance *>(JS_GetOpaque(referenceNodeValue, kHostClassInstanceClassId));
  } else if (!JS_IsNull(referenceNodeValue)) {
    return JS_ThrowTypeError(ctx, "TypeError: Failed to execute 'insertBefore' on 'Node': parameter 2 is not of type 'Node'");
  }

  auto selfInstance = static_cast<NodeInstance *>(JS_GetOpaque(this_val, kHostClassInstanceClassId));
  auto nodeInstance = static_cast<NodeInstance *>(JS_GetOpaque(nodeValue, kHostClassInstanceClassId));

  if (nodeInstance == nullptr || nodeInstance->document() != selfInstance->document()) {
    return JS_ThrowTypeError(ctx, "Failed to execute 'insertBefore' on 'Node': parameter 1 is not of type 'Node'");
  }

  return selfInstance->internalInsertBefore(nodeInstance, referenceInstance);
}
JSValue Node::replaceChild(QjsContext *ctx, JSValue this_val, int argc, JSValue *argv) {
  if (argc < 2) {
    return JS_ThrowTypeError(ctx, "Uncaught TypeError: Failed to execute 'replaceChild' on 'Node': 2 arguments required");
  }

  JSValue &newChildValue = argv[0];
  JSValue &oldChildValue = argv[1];

  if (!JS_IsObject(newChildValue)) {
    return JS_ThrowTypeError(ctx, "Uncaught TypeError: Failed to execute 'replaceChild' on 'Node': 1 arguments is not object");
  }

  if (!JS_IsObject(oldChildValue)) {
    return JS_ThrowTypeError(ctx, "Uncaught TypeError: Failed to execute 'replaceChild' on 'Node': 2 arguments is not object.");
  }

  auto selfInstance = static_cast<NodeInstance *>(JS_GetOpaque(this_val, kHostClassInstanceClassId));
  auto newChildInstance = static_cast<NodeInstance *>(JS_GetOpaque(newChildValue, kHostClassInstanceClassId));
  auto oldChildInstance = static_cast<NodeInstance *>(JS_GetOpaque(oldChildValue, kHostClassInstanceClassId));

  if (oldChildInstance == nullptr || oldChildInstance->parentNode != selfInstance ||
      oldChildInstance->document() != selfInstance->document()) {
    return JS_ThrowTypeError(ctx,
                 "Failed to execute 'replaceChild' on 'Node': The node to be replaced is not a child of this node.");
  }

  if (newChildInstance == nullptr || newChildInstance->document() != selfInstance->document()) {
    return JS_ThrowTypeError(ctx, "Failed to execute 'replaceChild' on 'Node': The new node is not a type of node.");
  }

  return selfInstance->internalReplaceChild(newChildInstance, oldChildInstance);
}

void Node::traverseCloneNode(QjsContext *ctx, NodeInstance *element, NodeInstance *parentElement) {
  for (auto iter : element->childNodes) {
    JSValue newNode = copyNodeValue(ctx, static_cast<NodeInstance *>(iter));
    auto newNodeInstance = static_cast<NodeInstance *>(JS_GetOpaque(newNode, kHostClassInstanceClassId));
    parentElement->internalAppendChild(newNodeInstance);
    // element node needs recursive child nodes.
    if (iter->nodeType == NodeType::ELEMENT_NODE) {
//      traverseCloneNode(ctx, static_cast<ElementInstance *>(iter), static_cast<ElementInstance *>(newNodeInstance));
    }
  }
}

JSValue Node::copyNodeValue(QjsContext *ctx, NodeInstance *element) {
//  if (node->nodeType == NodeType::ELEMENT_NODE) {
//    ElementInstance *element = reinterpret_cast<ElementInstance *>(node);
//
//    /* createElement */
//    std::string tagName = element->getRegisteredTagName();
//    auto newElement = JSElement::buildElementInstance(element->document()->context, tagName);
//
//    /* copy attributes */
//    JSStringHolder attributesStringHolder = JSStringHolder(element->document()->context, "attributes");
//    JSValueRef attributeValueRef =
//        JSObjectGetProperty(ctx, element->object, attributesStringHolder.getString(), nullptr);
//    JSObjectRef attributeObjectRef = JSValueToObject(ctx, attributeValueRef, nullptr);
//    auto mAttributes = reinterpret_cast<JSElementAttributes *>(JSObjectGetPrivate(attributeObjectRef));
//
//    std::map<std::string, JSValueRef> &attributesMap = mAttributes->getAttributesMap();
//    std::vector<JSValueRef> &attributesVector = mAttributes->getAttributesVector();
//
//    (*newElement->getAttributes())->setAttributesMap(attributesMap);
//    (*newElement->getAttributes())->setAttributesVector(attributesVector);
//
//    /* copy style */
//    newElement->setStyle(element->getStyle());
//
//    std::string newNodeEventTargetId = std::to_string(newElement->eventTargetId);
//
//    NativeString args_01{};
//    buildUICommandArgs(newNodeEventTargetId, args_01);
//
//    foundation::UICommandBuffer::instance(newElement->contextId)
//        ->addCommand(element->eventTargetId, UICommand::cloneNode, args_01, nullptr);
//
//    return newElement->object;
//  } else if (node->nodeType == TEXT_NODE) {
//    JSTextNode::TextNodeInstance *textNode = reinterpret_cast<JSTextNode::TextNodeInstance *>(node);
//
//    std::string content = textNode->internalGetTextContent();
//    auto newTextNodeInstance = new JSTextNode::TextNodeInstance(JSTextNode::instance(textNode->document()->context),
//                                                                JSStringCreateWithUTF8CString(content.c_str()));
//    return newTextNodeInstance->object;
//  }
//
//  return nullptr;
  return JS_NULL;
}

PROP_GETTER(Node, isConnected)(QjsContext *ctx, JSValue this_val, int argc, JSValue *argv) {
  auto *nodeInstance = static_cast<NodeInstance *>(JS_GetOpaque(this_val, kHostClassInstanceClassId));
  return JS_NewBool(ctx, nodeInstance->isConnected());
}
PROP_SETTER(Node, isConnected)(QjsContext *ctx, JSValue this_val, int argc, JSValue *argv) {
  return JS_NULL;
}

PROP_GETTER(Node, ownerDocument)(QjsContext *ctx, JSValue this_val, int argc, JSValue *argv) {
  auto *nodeInstance = static_cast<NodeInstance *>(JS_GetOpaque(this_val, kHostClassInstanceClassId));
//  return nodeInstance->m_document->instanceObject;
  return JS_NULL;
}
PROP_SETTER(Node, ownerDocument)(QjsContext *ctx, JSValue this_val, int argc, JSValue *argv) {
  return JS_NULL;
}

PROP_GETTER(Node, firstChild)(QjsContext *ctx, JSValue this_val, int argc, JSValue *argv) {
  auto *nodeInstance = static_cast<NodeInstance *>(JS_GetOpaque(this_val, kHostClassInstanceClassId));
  auto *instance = nodeInstance->firstChild();
  return instance != nullptr ? instance->instanceObject : JS_NULL;
}
PROP_SETTER(Node, firstChild)(QjsContext *ctx, JSValue this_val, int argc, JSValue *argv) {
  return JS_NULL;
}

PROP_GETTER(Node, lastChild)(QjsContext *ctx, JSValue this_val, int argc, JSValue *argv) {
  auto *nodeInstance = static_cast<NodeInstance *>(JS_GetOpaque(this_val, kHostClassInstanceClassId));
  auto *instance = nodeInstance->lastChild();
  return instance != nullptr ? instance->instanceObject : JS_NULL;
}
PROP_SETTER(Node, lastChild)(QjsContext *ctx, JSValue this_val, int argc, JSValue *argv) {
  return JS_NULL;
}

PROP_GETTER(Node, parentNode)(QjsContext *ctx, JSValue this_val, int argc, JSValue *argv) {
  auto *nodeInstance = static_cast<NodeInstance *>(JS_GetOpaque(this_val, kHostClassInstanceClassId));
  if (nodeInstance->parentNode == nullptr) return JS_NULL;
  return nodeInstance->parentNode->instanceObject;
}
PROP_SETTER(Node, parentNode)(QjsContext *ctx, JSValue this_val, int argc, JSValue *argv) {
  return JS_NULL;
}

PROP_GETTER(Node, childNodes)(QjsContext *ctx, JSValue this_val, int argc, JSValue *argv) {
  auto *nodeInstance = static_cast<NodeInstance *>(JS_GetOpaque(this_val, kHostClassInstanceClassId));
  JSValue arrayObject = JS_NewArray(ctx);
  size_t len = nodeInstance->childNodes.size();
  for (int i = 0; i < len; i ++) {
    JS_SetPropertyUint32(ctx, arrayObject, i, nodeInstance->childNodes[i]->instanceObject);
  }
  return arrayObject;
}
PROP_SETTER(Node, childNodes)(QjsContext *ctx, JSValue this_val, int argc, JSValue *argv) {
  return JS_NULL;
}

PROP_GETTER(Node, previousSibling)(QjsContext *ctx, JSValue this_val, int argc, JSValue *argv) {
  auto *nodeInstance = static_cast<NodeInstance *>(JS_GetOpaque(this_val, kHostClassInstanceClassId));
  auto *instance = nodeInstance->previousSibling();
  return instance != nullptr ? instance->instanceObject : JS_NULL;
}
PROP_SETTER(Node, previousSibling)(QjsContext *ctx, JSValue this_val, int argc, JSValue *argv) {
  return JS_NULL;
}

PROP_GETTER(Node, nextSibling)(QjsContext *ctx, JSValue this_val, int argc, JSValue *argv) {
  auto *nodeInstance = static_cast<NodeInstance *>(JS_GetOpaque(this_val, kHostClassInstanceClassId));
  auto *instance = nodeInstance->nextSibling();
  return instance != nullptr ? instance->instanceObject : JS_NULL;
}
PROP_SETTER(Node, nextSibling)(QjsContext *ctx, JSValue this_val, int argc, JSValue *argv) {
  return JS_NULL;
}

PROP_GETTER(Node, nodeType)(QjsContext *ctx, JSValue this_val, int argc, JSValue *argv) {
  auto *nodeInstance = static_cast<NodeInstance *>(JS_GetOpaque(this_val, kHostClassInstanceClassId));
  return JS_NewUint32(ctx, nodeInstance->nodeType);
}
PROP_SETTER(Node, nodeType)(QjsContext *ctx, JSValue this_val, int argc, JSValue *argv) {
  return JS_NULL;
}

PROP_GETTER(Node, textContent)(QjsContext *ctx, JSValue this_val, int argc, JSValue *argv) {
  auto *nodeInstance = static_cast<NodeInstance *>(JS_GetOpaque(this_val, kHostClassInstanceClassId));
  std::string textContent = nodeInstance->internalGetTextContent();
  return JS_NewString(ctx, textContent.c_str());
}
PROP_SETTER(Node, textContent)(QjsContext *ctx, JSValue this_val, int argc, JSValue *argv) {
  auto *nodeInstance = static_cast<NodeInstance *>(JS_GetOpaque(this_val, kHostClassInstanceClassId));
  nodeInstance->internalSetTextContent(argv[0]);
  return JS_NULL;
}

bool NodeInstance::isConnected() {
  bool _isConnected = eventTargetId == HTML_TARGET_ID;
  auto parent = parentNode;

  while (parent != nullptr && !_isConnected) {
    _isConnected = parent->eventTargetId == HTML_TARGET_ID;
    parent = parent->parentNode;
  }

  return _isConnected;
}
DocumentInstance *NodeInstance::ownerDocument() {
  if (nodeType == NodeType::DOCUMENT_NODE) {
    return nullptr;
  }

  return document();
}
NodeInstance *NodeInstance::firstChild() {
  if (childNodes.empty()) {
    return nullptr;
  }
  return childNodes.front();
}
NodeInstance *NodeInstance::lastChild() {
  if (childNodes.empty()) {
    return nullptr;
  }
  return childNodes.back();
}
NodeInstance *NodeInstance::previousSibling() {
  if (parentNode == nullptr) return nullptr;

  auto &&parentChildNodes = parentNode->childNodes;
  auto it = std::find(parentChildNodes.begin(), parentChildNodes.end(), this);

  if (parentChildNodes.size() < 2) {
    return nullptr;
  }

  if (it != parentChildNodes.begin()) {
    return *(it - 1);
  }

  return nullptr;
}
NodeInstance *NodeInstance::nextSibling() {
  if (parentNode == nullptr) return nullptr;

  auto &&parentChildNodes = parentNode->childNodes;
  auto it = std::find(parentChildNodes.begin(), parentChildNodes.end(), this);

  if ((it + 1) != parentChildNodes.end()) {
    return *(it + 1);
  }

  return nullptr;
}
void NodeInstance::internalAppendChild(NodeInstance *node) {
  ensureDetached(node);
  childNodes.emplace_back(node);
  node->parentNode = this;
  node->refer();

  node->_notifyNodeInsert(this);

  std::string nodeEventTargetId = std::to_string(node->eventTargetId);
  std::string position = std::string("beforeend");

  std::u16string u16NodeEventTargetId;
  std::u16string u16Position;

  fromUTF8(nodeEventTargetId, u16NodeEventTargetId);
  fromUTF8(position, u16Position);

  NativeString args_01{};
  NativeString args_02{};
  buildUICommandArgs(m_ctx, u16NodeEventTargetId, u16Position, args_01, args_02);

  foundation::UICommandBuffer::instance(m_context->getContextId())
      ->addCommand(eventTargetId, UICommand::insertAdjacentNode, args_01, args_02, nullptr);
}
void NodeInstance::internalRemove() {
  if (parentNode == nullptr) return;
  parentNode->internalRemoveChild(this);
}
NodeInstance *NodeInstance::internalRemoveChild(NodeInstance *node) {
  auto it = std::find(childNodes.begin(), childNodes.end(), node);

  if (it != childNodes.end()) {
    childNodes.erase(it);
    node->parentNode = nullptr;
    node->unrefer();
    node->_notifyNodeRemoved(this);
    foundation::UICommandBuffer::instance(node->m_context->getContextId())
        ->addCommand(node->eventTargetId, UICommand::removeNode, nullptr);
  }

  return node;
}
JSValue NodeInstance::internalInsertBefore(NodeInstance *node, NodeInstance *referenceNode) {
  if (referenceNode == nullptr) {
    internalAppendChild(node);
  } else {
    if (referenceNode->parentNode != this) {
      return JS_ThrowTypeError(
          m_ctx,
          "Uncaught TypeError: Failed to execute 'insertBefore' on 'Node': reference node is not a child of this node.");
    }

    ensureDetached(node);
    auto parent = referenceNode->parentNode;
    if (parent != nullptr) {
      auto &&parentChildNodes = parent->childNodes;
      auto it = std::find(parentChildNodes.begin(), parentChildNodes.end(), referenceNode);

      if (it == parentChildNodes.end()) {
        return JS_ThrowTypeError(m_ctx, "Failed to execute 'insertBefore' on 'Node': reference node is not a child of this node.");
      }

      parentChildNodes.insert(it, node);
      node->parentNode = parent;
      node->refer();
      node->_notifyNodeInsert(parent);

      std::string nodeEventTargetId = std::to_string(node->eventTargetId);
      std::string position = std::string("beforebegin");

      std::u16string u16NodeEventTargetId;
      std::u16string u16Position;

      fromUTF8(nodeEventTargetId, u16NodeEventTargetId);
      fromUTF8(position, u16Position);

      NativeString args_01{};
      NativeString args_02{};
      buildUICommandArgs(m_ctx, u16NodeEventTargetId, u16Position, args_01, args_02);

      foundation::UICommandBuffer::instance(m_context->getContextId())
          ->addCommand(referenceNode->eventTargetId, UICommand::insertAdjacentNode, args_01, args_02, nullptr);
    }
  }

  return JS_NULL;
}
std::string NodeInstance::internalGetTextContent() {
  return "";
}
void NodeInstance::internalSetTextContent(JSValue content) {}
JSValue NodeInstance::internalReplaceChild(NodeInstance *newChild, NodeInstance *oldChild) {
  ensureDetached(newChild);
  assert_m(newChild->parentNode == nullptr, "ReplaceChild Error: newChild was not detached.");
  oldChild->parentNode = nullptr;
  oldChild->unrefer();

  auto childIndex = std::find(childNodes.begin(), childNodes.end(), oldChild);
  if (childIndex == childNodes.end()) {
    return JS_ThrowTypeError(m_ctx, "Failed to execute 'replaceChild' on 'Node': old child is not exist on childNodes.");
  }

  newChild->parentNode = this;
  childNodes.erase(childIndex);
  childNodes.insert(childIndex, newChild);
  newChild->refer();

  oldChild->_notifyNodeRemoved(this);
  newChild->_notifyNodeInsert(this);

  std::string newChildEventTargetId = std::to_string(newChild->eventTargetId);
  std::string position = std::string("afterend");

  std::u16string u16NodeEventTargetId;
  std::u16string u16Position;

  fromUTF8(newChildEventTargetId, u16NodeEventTargetId);
  fromUTF8(position, u16Position);

  NativeString args_01{};
  NativeString args_02{};

  buildUICommandArgs(m_ctx, u16NodeEventTargetId, u16Position, args_01, args_02);

  foundation::UICommandBuffer::instance(m_context->getContextId())
      ->addCommand(oldChild->eventTargetId, UICommand::insertAdjacentNode, args_01, args_02, nullptr);

  foundation::UICommandBuffer::instance(m_context->getContextId())
      ->addCommand(oldChild->eventTargetId, UICommand::removeNode, nullptr);

  return oldChild->instanceObject;
}
void NodeInstance::refer() {
  JS_DupValue(m_ctx, instanceObject);
}
void NodeInstance::unrefer() {
  JS_FreeValue(m_ctx, instanceObject);
}
void NodeInstance::_notifyNodeRemoved(NodeInstance *node) {}
void NodeInstance::_notifyNodeInsert(NodeInstance *node) {}
void NodeInstance::ensureDetached(NodeInstance *node) {
  if (node->parentNode != nullptr) {
    auto it = std::find(node->parentNode->childNodes.begin(), node->parentNode->childNodes.end(), node);
    if (it != node->parentNode->childNodes.end()) {
      node->_notifyNodeRemoved(node->parentNode);
      node->parentNode->childNodes.erase(it);
      node->parentNode = nullptr;
      node->unrefer();
    }
  }
}

} // namespace kraken::binding::qjs