/*
 * Copyright (C) 2019 Alibaba Inc. All rights reserved.
 * Author: Kraken Team.
 */

#include "console.h"
#include "foundation/logging.h"
#include <sstream>

// #define ENABLE_LOGFILE

#ifdef ENABLE_LOGFILE
#include <fstream>
#endif // ENABLE_LOGFILE

namespace kraken::binding::jsc {
namespace {

#ifdef ENABLE_LOGFILE
std::ofstream logFile { "console.log", std::ofstream::trunc };
#endif // ENABLE_LOGFILE

JSValueRef print(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount,
                 const JSValueRef arguments[], JSValueRef *exception) {
  std::stringstream stream;
  const JSValueRef &log = arguments[0];
  if (JSValueIsString(ctx, log)) {
    JSStringRef str = JSValueToStringCopy(ctx, log, nullptr);
    int32_t length = JSStringGetMaximumUTF8CStringSize(str);
    char *buffer = new char[length];
    JSStringGetUTF8CString(str, buffer, length);
    JSStringRelease(str);
    stream << buffer;
#ifdef ENABLE_LOGFILE
    logFile << stream.str()<< std::endl;
#endif // #ifdef ENABLE_LOGFILE
    free(buffer);
  } else {
    KRAKEN_LOG(ERROR) << "Failed to execute 'print': log must be string.";
    return JSValueMakeUndefined(ctx);
  }

  auto context = static_cast<JSContext *>(JSObjectGetPrivate(function));

  std::string logLevel = "info";
  const JSValueRef &level = arguments[1];
  if (JSValueIsString(ctx, level)) {
    logLevel = std::move(JSStringToStdString(JSValueToStringCopy(ctx, level, nullptr)));
  }

  foundation::printLog(context->getContextId(), stream, logLevel, JSContextGetGlobalContext(ctx));

  return JSValueMakeUndefined(ctx);
}

} // namespace

////////////////

void bindConsole(std::unique_ptr<JSContext> &context) {
  JSC_GLOBAL_BINDING_FUNCTION(context, "__kraken_print__", print);
}

} // namespace kraken::binding::jsc
