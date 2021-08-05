/*
 * Copyright (C) 2021 Alibaba Inc. All rights reserved.
 * Author: Kraken Team.
 */

#include "gtest/gtest.h"
#include "event_target.h"
#include "bridge_qjs.h"

TEST(Node, appendChild) {
  bool static errorCalled = false;
  bool static logCalled = false;
  kraken::JSBridge::consoleMessageHandler = [](void *ctx, const std::string &message, int logLevel) {
    EXPECT_STREQ(message.c_str(), "true true true");
    logCalled = true;
  };
  auto *bridge = new kraken::JSBridge(0, [](int32_t contextId, const char* errmsg) {
    errorCalled = true;
  });
  auto &context = bridge->getContext();
  const char* code = "let div = document.createElement('div');"
                     "document.body.appendChild(div);"
                     "console.log(document.body.firstChild === div, document.body.lastChild === div, div.parentNode === document.body);";
  bridge->evaluateScript(code, strlen(code), "vm://", 0);
  delete bridge;
  EXPECT_EQ(errorCalled, false);
  EXPECT_EQ(logCalled, true);
}

TEST(Node, childNodes) {
  bool static errorCalled = false;
  bool static logCalled = false;
  kraken::JSBridge::consoleMessageHandler = [](void *ctx, const std::string &message, int logLevel) {
    EXPECT_STREQ(message.c_str(), "true true true true");
    logCalled = true;
  };
  auto *bridge = new kraken::JSBridge(0, [](int32_t contextId, const char* errmsg) {
    errorCalled = true;
  });
  auto &context = bridge->getContext();
  const char* code = "let div1 = document.createElement('div');"
                     "let div2 = document.createElement('div');"
                     "document.body.appendChild(div1);"
                     "document.body.appendChild(div2);"
                     "console.log("
                        "document.body.childNodes[0] === div1,"
                        "document.body.childNodes[1] === div2,"
                        "div1.nextSibling === div2,"
                        "div2.previousSibling === div1)";
  bridge->evaluateScript(code, strlen(code), "vm://", 0);
  delete bridge;
  EXPECT_EQ(errorCalled, false);
  EXPECT_EQ(logCalled, true);
}

TEST(Node, textContent) {
  bool static errorCalled = false;
  bool static logCalled = false;
  kraken::JSBridge::consoleMessageHandler = [](void *ctx, const std::string &message, int logLevel) {
    EXPECT_STREQ(message.c_str(), "1234helloworld");
    logCalled = true;
  };
  auto *bridge = new kraken::JSBridge(0, [](int32_t contextId, const char* errmsg) {
    errorCalled = true;
  });
  auto &context = bridge->getContext();
  const char* code = "let text1 = document.createTextNode('1234');"
                     "let text2 = document.createTextNode('helloworld');"
                     "let div = document.createElement('div');"
                     "div.appendChild(text1);"
                     "div.appendChild(text2);"
                     "console.log(div.textContent)";
  bridge->evaluateScript(code, strlen(code), "vm://", 0);
  delete bridge;
  EXPECT_EQ(errorCalled, false);
  EXPECT_EQ(logCalled, true);
}

TEST(Node, ensureDetached) {
  bool static errorCalled = false;
  bool static logCalled = false;
  kraken::JSBridge::consoleMessageHandler = [](void *ctx, const std::string &message, int logLevel) {
    EXPECT_STREQ(message.c_str(), "true true");
    logCalled = true;
  };
  auto *bridge = new kraken::JSBridge(0, [](int32_t contextId, const char* errmsg) {
    errorCalled = true;
  });
  auto &context = bridge->getContext();
  const char* code = "let div = document.createElement('div');"
                     "document.body.appendChild(div);"
                     "let container = document.createElement('div');"
                     "container.appendChild(div);"
                     "document.body.appendChild(container);"
                     "console.log(document.body.firstChild === container, container.firstChild === div);";
  bridge->evaluateScript(code, strlen(code), "vm://", 0);
  delete bridge;
  EXPECT_EQ(errorCalled, false);
  EXPECT_EQ(logCalled, true);
}


TEST(Node, replaceBody) {
  bool static errorCalled = false;
  bool static logCalled = false;
  kraken::JSBridge::consoleMessageHandler = [](void *ctx, const std::string &message, int logLevel) {
    logCalled = true;
  };
  auto *bridge = new kraken::JSBridge(0, [](int32_t contextId, const char* errmsg) {
    KRAKEN_LOG(VERBOSE) << errmsg;
    errorCalled = true;
  });
  auto &context = bridge->getContext();
  const char* code = "document.body = document.createElement('body');";
  bridge->evaluateScript(code, strlen(code), "vm://", 0);
  delete bridge;
  EXPECT_EQ(errorCalled, false);
}