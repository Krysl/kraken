/*
 * Copyright (C) 2019-present Alibaba Inc. All rights reserved.
 * Author: Kraken Team.
 */
import 'package:kraken/css.dart';
import 'package:kraken/dom.dart';

const String PRE = 'PRE';

const Map<String, dynamic> _defaultStyle = {
  WHITE_SPACE: 'pre',
};

class PreElement extends Element {
  PreElement(int targetId, ElementManager elementManager)
      : super(targetId, elementManager, tagName: PRE, defaultStyle: _defaultStyle);
}