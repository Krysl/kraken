/*
 * Copyright (C) 2019-present Alibaba Inc. All rights reserved.
 * Author: Kraken Team.
 */

import 'dart:ffi';
import 'package:kraken/bridge.dart';
import 'package:kraken/dom.dart';
import 'package:kraken/kraken.dart';
import 'package:kraken/module.dart';
import 'package:flutter/rendering.dart';

const String ANCHOR = 'A';

class AnchorElement extends Element {
  String? _href;
  String? _target;

  AnchorElement(int targetId, Pointer<NativeEventTarget> nativeEventTargetPtr, ElementManager elementManager)
      : super(targetId, nativeEventTargetPtr, elementManager, tagName: ANCHOR) {
    addEvent(EVENT_CLICK);
  }

  void handleMouseEvent(String eventType, { PointerDownEvent? down, PointerUpEvent? up }) {
    super.handleMouseEvent(eventType, down: down, up: up);

    String? href = _href;
    if (href == null) return;

    Uri uri = Uri.parse(href);
    KrakenController rootController = elementManager.controller.view.rootController;
    String? sourceUrl = rootController.bundleURL;
    String scheme;
    if (!uri.hasScheme) {
      if (sourceUrl != null) {
        Uri sourceUri = Uri.parse(sourceUrl);
        scheme = sourceUri.scheme;
      } else {
        scheme = 'http';
      }
    } else {
      scheme = uri.scheme;
    }
    elementManager.controller.view.handleNavigationAction(sourceUrl, href, _getNavigationType(scheme));
  }

  KrakenNavigationType _getNavigationType(String scheme) {
    switch (scheme) {
      case 'http':
      case 'https':
      case 'file':
        if (_target == null || _target == '_self') {
          return KrakenNavigationType.reload;
        }
    }

    return KrakenNavigationType.navigate;
  }

  @override
  handleJSCall(String method, List argv) {
    switch(method) {
      case 'getHref':
        return _href;
      case 'getTarget':
        return _target;
      default:
        return super.handleJSCall(method, argv);
    }
  }

  @override
  void setProperty(String key, dynamic value) {
    super.setProperty(key, value);
    switch (key) {
      case 'href':
        _href = value;
        break;
      case 'target':
        _target = value;
        break;
      default:
    }
  }
}
