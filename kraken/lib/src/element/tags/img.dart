/*
 * Copyright (C) 2019 Alibaba Inc. All rights reserved.
 * Author: Kraken Team.
 */

import 'package:flutter/rendering.dart';
import 'package:kraken/element.dart';
import 'package:kraken/rendering.dart';
import 'package:kraken/style.dart';

const String IMAGE = 'IMG';

class ImgElement extends Element {
  ImageProvider image;
  RenderDecoratedBox imageBox;
  RenderConstrainedBox imageConstrainedBox;
  ImageStream imageStream;
  ImageStreamListener imageListener;

  ImgElement(int nodeId, Map<String, dynamic> props, List<String> events)
      : super(
            nodeId: nodeId,
            defaultDisplay: 'inline',
            tagName: IMAGE,
            properties: props,
            events: events) {
    addImgBox();
  }

  void addImgBox() {
    String url = _getFormattedSourceURL(properties['src']);
    if (url.isNotEmpty) {
      image = NetworkImage(url);
      _constructImageChild();
    }
  }

  void removeImgBox() {
    renderLayoutElement.removeAll();
  }

  void _constructImageChild() {
    imageBox = getRenderDecoratedBox(style, image);
    imageConstrainedBox = getRenderConstraintedBox(imageBox);

    if (!determinBothWidthAndHeight) {
      imageStream = image.resolve(imageBox.configuration);
      imageListener = ImageStreamListener(resizeAfterImageLoaded);
      imageStream.addListener(imageListener);
    }

    if (childNodes.isEmpty) {
      addChild(imageConstrainedBox);
    }
  }

  bool get determinBothWidthAndHeight {
    return style.contains('width') && style.contains('height');
  }

  String _getFormattedSourceURL(String url) {
    if (url == null) url = '';
    if (url.startsWith('//')) return 'https:' + url;
    return url;
  }

  void resizeAfterImageLoaded(ImageInfo imageInfo, bool synchronousCall) {
    imageStream.removeListener(imageListener);

    BoxConstraints constraints;
    double realWidth = imageInfo.image.width + 0.0;
    double realHeight = imageInfo.image.height + 0.0;
    double width = 0.0;
    double height = 0.0;
    bool containWidth = style.contains('width');
    bool containHeight = style.contains('height');
    if (!containWidth && !containHeight) {
      constraints = BoxConstraints.tightFor(
        width: realWidth,
        height: realHeight,
      );
    } else {
      if (containWidth) {
        width = getDisplayPortedLength(style['width']);
        height = width * realHeight / realWidth;
      } else if (containHeight) {
        height = getDisplayPortedLength(style['height']);
        width = height * realWidth / realHeight;
      }
      constraints = BoxConstraints.tightFor(
        width: width,
        height: height,
      );
    }

    imageConstrainedBox.additionalConstraints = constraints;
  }

  BoxConstraints getBoxConstraintsFromStyle(Style style) {
    double width = getDisplayPortedLength(style['width']);
    double height = getDisplayPortedLength(style['height']);
    return BoxConstraints.tightFor(width: width, height: height);
  }

  RenderConstrainedBox getRenderConstraintedBox(RenderBox child) {
    return KrakenRenderConstrainedBox(
      additionalConstraints: getBoxConstraintsFromStyle(style),
      child: child,
    );
  }

  BoxFit _getBoxFit(Style style) {
    String fit = style['objectFit'];
    switch (fit) {
      case 'contain':
        return BoxFit.contain;

      case 'cover':
        return BoxFit.cover;

      case 'none':
        return BoxFit.none;

      case 'scaleDown':
      case 'scale-down':
        return BoxFit.scaleDown;

      case 'fitWidth':
      case 'fit-width':
        return BoxFit.fitWidth;

      case 'fitHeight':
      case 'fit-height':
        return BoxFit.fitHeight;

      case 'fill':
      default:
        return BoxFit.fill;
    }
  }

  RenderDecoratedBox getRenderDecoratedBox(Style style, ImageProvider image) {
    BoxFit fit = _getBoxFit(style);
    return RenderDecoratedBox(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: image,
          fit: fit,
        ),
      ),
      position: DecorationPosition.foreground,
    );
  }

  @override
  void removeProperty(String key) {
    super.removeProperty(key);
    if (key == 'src') {
      image = null;
      imageBox = null;
      imageConstrainedBox.child = null;
    }
  }

  @override
  void setProperty(String key, dynamic value) {
    super.setProperty(key, value);
    if (key == 'src' ||
      key == '.style.width' ||
      key == '.style.height'
    ) {
      removeImgBox();
      addImgBox();
    }
  }
}
