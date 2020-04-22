/*
 * Copyright (C) 2019-present Alibaba Inc. All rights reserved.
 * Author: Kraken Team.
 */
import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:kraken/foundation.dart';
import 'package:kraken/rendering.dart';
import 'package:kraken/style.dart';

/// RenderDecoratedBox impls styles of
/// - background
/// - border
mixin RenderDecoratedBoxMixin on BackgroundImageMixin {
  RenderDecoratedBox renderDecoratedBox;
  RenderMargin renderBorderHolder;
  TransitionDecoration oldDecoration;
  Padding oldBorderPadding;

  RenderObject initRenderDecoratedBox(
      RenderObject renderObject, StyleDeclaration style, int targetId) {
    oldDecoration = getTransitionDecoration(style);
    EdgeInsets margin = oldDecoration.getBorderEdgeInsets();
    // Flutter Border width is inside the element
    // but w3c border is outside the element
    // so use margin to fix it.
    renderBorderHolder = RenderMargin(
      margin: margin,
      child: renderObject,
    );
    return renderDecoratedBox = RenderGradient(
      targetId: targetId,
      decoration: oldDecoration.toBoxDecoration(),
      child: renderBorderHolder,
    );
  }

  void updateRenderDecoratedBox(
      StyleDeclaration style, Map<String, Transition> transitionMap) {
    TransitionDecoration newDecoration = getTransitionDecoration(style);
    if (transitionMap != null) {
      Transition backgroundColorTransition = getTransition(
          transitionMap, BACKGROUND_COLOR);
      // border color and width transition add inorder left top right bottom
      List<Transition> borderColorTransitionsLTRB = [
        getTransition(transitionMap, 'border-left-color',
            parentProperty: 'border-color'),
        getTransition(transitionMap, 'border-top-color',
            parentProperty: 'border-color'),
        getTransition(transitionMap, 'border-right-color',
            parentProperty: 'border-color'),
        getTransition(transitionMap, 'border-bottom-color',
            parentProperty: 'border-color')
      ];
      List<Transition> borderWidthTransitionsLTRB = [
        getTransition(transitionMap, 'border-left-width',
            parentProperty: 'border-width'),
        getTransition(transitionMap, 'border-top-width',
            parentProperty: 'border-width'),
        getTransition(transitionMap, 'border-right-width',
            parentProperty: 'border-width'),
        getTransition(transitionMap, 'border-bottom-width',
            parentProperty: 'border-width')
      ];

      // border radius transition add inorder topLeft topRight bottomLeft
      // bottomRight
      List<Transition> borderRadiusTransitionTLTRBLBR = [
        getTransition(transitionMap, 'border-top-left-radius',
            parentProperty: 'border-radius'),
        getTransition(transitionMap, 'border-top-right-radius',
            parentProperty: 'border-radius'),
        getTransition(transitionMap, 'border-bottom-left-radius',
            parentProperty: 'border-radius'),
        getTransition(transitionMap, 'border-bottom-right-radius',
            parentProperty: 'border-radius')
      ];
      if (backgroundColorTransition != null ||
          borderWidthTransitionsLTRB.isNotEmpty ||
          borderColorTransitionsLTRB.isNotEmpty ||
          borderRadiusTransitionTLTRBLBR.isNotEmpty) {
        TransitionDecoration progressDecoration = oldDecoration.clone();
        TransitionDecoration baseDecoration = oldDecoration.clone();

        // background color transition
        addColorProcessListener(
            backgroundColorTransition, newDecoration, oldDecoration,
            progressDecoration, baseDecoration, progressDecoration);

        // side read inorder left top right bottom
        // radius read inorder topLeft topRight bottomLeft bottomRight
        for (int i = 0; i < 4; i++) {

          // add border color transition
          addColorProcessListener(
              borderColorTransitionsLTRB[i], newDecoration.borderSidesLTRB[i],
              oldDecoration.borderSidesLTRB[i], progressDecoration.borderSidesLTRB[i],
              baseDecoration.borderSidesLTRB[i], progressDecoration);

          addWidthAndRadiusProcessListener(
              borderWidthTransitionsLTRB[i],
              borderRadiusTransitionTLTRBLBR[i],
              i,
              newDecoration,
              oldDecoration,
              baseDecoration,
              progressDecoration);
        }
      } else {
        renderDecoratedBox.decoration = newDecoration.toBoxDecoration();
        _updateBorderInsets(newDecoration.getBorderEdgeInsets());
      }
    } else {
      renderDecoratedBox.decoration = newDecoration.toBoxDecoration();
      // Update can not trigger performlayout.
      // Gradient need trigger performlayout to recaculate the alignment
      // when linearAngle not null (other situation doesn't need).
      if (linearAngle != null) {
        renderDecoratedBox.markNeedsLayout();
      }
      _updateBorderInsets(newDecoration.getBorderEdgeInsets());
    }
    oldDecoration = newDecoration;
  }

  // add color relate transition listener
  void addColorProcessListener(Transition transition,
      TransitionColorMixin newColor, TransitionColorMixin oldColor,
      TransitionColorMixin processColor, TransitionColorMixin baseColor,
      TransitionDecoration processDecoration) {
    if (transition != null) {
      int alphaDiff = newColor.color.alpha - oldColor.color.alpha;
      int redDiff = newColor.color.red - oldColor.color.red;
      int greenDiff = newColor.color.green - oldColor.color.green;
      int blueDiff = newColor.color.blue - oldColor.color.blue;
      transition.addProgressListener((progress) {
        processColor.color = processColor.color.withAlpha(
            (alphaDiff * progress).toInt() + baseColor.color.alpha);
        processColor.color = processColor.color.withRed(
            (redDiff * progress).toInt() + baseColor.color.red);
        processColor.color = processColor.color.withBlue(
            (blueDiff * progress).toInt() + baseColor.color.blue);
        processColor.color = processColor.color.withGreen(
            (greenDiff * progress).toInt() + baseColor.color.green);
        renderDecoratedBox.decoration = processDecoration.toBoxDecoration();
      });
    }
  }

  // add width and radius relate transition listener
  void addWidthAndRadiusProcessListener(Transition widthTransition,
      Transition radiusTransition, int index,
      TransitionDecoration newDecoration, TransitionDecoration oldDecoration,
      TransitionDecoration baseDecoration,
      TransitionDecoration processDecoration) {
    if (widthTransition != null) {
      double widthDiff = newDecoration.borderSidesLTRB[index].borderWidth
          - oldDecoration.borderSidesLTRB[index].borderWidth;
      widthTransition.addProgressListener((progress) {
        processDecoration.borderSidesLTRB[index].borderWidth =
            widthDiff * progress +
                baseDecoration.borderSidesLTRB[index].borderWidth;
        renderDecoratedBox.decoration = processDecoration.toBoxDecoration();
        _updateBorderInsets(processDecoration.getBorderEdgeInsets());
      });
    }

    if (radiusTransition != null) {
      double radiusDiff = newDecoration.borderRadiusTLTRBLBR[index]
          - oldDecoration.borderRadiusTLTRBLBR[index];
      radiusTransition.addProgressListener((progress) {
        processDecoration.borderRadiusTLTRBLBR[index] =
            radiusDiff * progress +
                baseDecoration.borderRadiusTLTRBLBR[index];
        renderDecoratedBox.decoration = processDecoration.toBoxDecoration();
      });
    }
  }

  Transition getTransition(Map<String, Transition> transitionMap,
      String property, {String parentProperty}) {
    if (transitionMap.containsKey(property)) {
      return transitionMap[property];
    } else if (parentProperty?.isNotEmpty != null &&
        transitionMap.containsKey(parentProperty)) {
      return transitionMap[parentProperty];
    } else if (transitionMap.containsKey('all')) {
      return transitionMap['all'];
    }
    return null;
  }

  void _updateBorderInsets(EdgeInsets insets) {
    renderBorderHolder.margin = insets;
  }

  /// Shorted border property:
  ///   border：<line-width> || <line-style> || <color>
  ///   (<line-width> = <length> | thin | medium | thick), support length now.
  /// Seperated properties:
  ///   borderWidth: <line-width>{1,4}
  ///   borderStyle: none | hidden | dotted | dashed | solid | double | groove | ridge | inset | outset
  ///     (PS. Only support solid now.)
  ///   borderColor: <color>
  TransitionDecoration getTransitionDecoration(StyleDeclaration style) {
    DecorationImage decorationImage;
    Gradient gradient;
    if (background[BACKGROUND_ATTACHMENT] == ''
        || background[BACKGROUND_ATTACHMENT] == 'scroll'
            && background.containsKey(BACKGROUND_IMAGE)) {
      Map<String, Method> methods = Method.parseMethod(background[BACKGROUND_IMAGE]);
      for (Method method in methods?.values) {
        if (method.name == 'url') {
          String url = method.args.length > 0 ? method.args[0] : '';
          if (url != null && url.isNotEmpty) {
            decorationImage = getBackgroundImage(url);
          }
        } else {
          gradient = getBackgroundGradient(method);
        }
      }
    }

    Color color = getBackgroundColor(style);
    TransitionBorderSide leftSide = getBorderSideByStyle(style, 'Left');
    TransitionBorderSide topSide = getBorderSideByStyle(style, 'Top');
    TransitionBorderSide rightSide = getBorderSideByStyle(style, 'Right');
    TransitionBorderSide bottomSide = getBorderSideByStyle(style, 'Bottom');

    // border radius add inorder topLeft topRight bottomLeft bottomRight
    List<double> borderRadiusTLTRBLBR = [
      getBorderRadius(style, 'borderTopLeftRadius'),
      getBorderRadius(style, 'borderTopRightRadius'),
      getBorderRadius(style, 'borderBottomLeftRadius'),
      getBorderRadius(style, 'borderBottomRightRadius')
    ];
    return TransitionDecoration(
        color?.alpha,
        color?.red,
        color?.green,
        color?.blue,
        leftSide,
        topSide,
        rightSide,
        bottomSide,
        decorationImage,
        getBoxShadow(style),
        borderRadiusTLTRBLBR,
        gradient);
  }

  /// Tip: inset not supported.
  static RegExp commaRegExp = RegExp(r',');
  List<BoxShadow> getBoxShadow(StyleDeclaration style) {
    List<BoxShadow> boxShadow = [];
    if (style.contains('boxShadow')) {
      String processedValue =
          WebColor.preprocessCSSPropertyWithRGBAColor(style['boxShadow']);
      List<String> rawShadows = processedValue.split(commaRegExp);
      for (String rawShadow in rawShadows) {
        List<String> shadowDefinitions = rawShadow.trim().split(spaceRegExp);
        if (shadowDefinitions.length > 2) {
          double offsetX = Length.toDisplayPortValue(shadowDefinitions[0]);
          double offsetY = Length.toDisplayPortValue(shadowDefinitions[1]);
          double blurRadius = shadowDefinitions.length > 3
              ? Length.toDisplayPortValue(shadowDefinitions[2])
              : 0.0;
          double spreadRadius = shadowDefinitions.length > 4
              ? Length.toDisplayPortValue(shadowDefinitions[3])
              : 0.0;

          Color color = WebColor.generate(shadowDefinitions.last);
          if (color != null) {
            boxShadow.add(BoxShadow(
              offset: Offset(offsetX, offsetY),
              blurRadius: blurRadius,
              spreadRadius: spreadRadius,
              color: color,
            ));
          }
        }
      }

      // Tips only debug.
      if (!PRODUCTION && boxShadow.isEmpty) {
        print('[Warning] Wrong style format with boxShadow: ${style['boxShadow']}');
        print('    Correct syntax: inset? && <length>{2,4} && <color>?');
      }
    }
    return boxShadow;
  }

  double getBorderRadius(StyleDeclaration style, String side) {
    if (style.contains(side)) {
      return Length.toDisplayPortValue(style[side]);
    } else if (style.contains('borderRadius')) {
      return Length.toDisplayPortValue(style['borderRadius']);
    }
    return 0.0;
  }

  Color getBackgroundColor(StyleDeclaration style) {
    Color backgroundColor = WebColor.transparent;
    if (background.containsKey(BACKGROUND_COLOR)) {
      backgroundColor = WebColor.generate(background[BACKGROUND_COLOR]);
    }
    return backgroundColor;
  }

  static RegExp spaceRegExp = RegExp(r' ');
  List<String> getShorttedProperties(String input) {
    assert(input != null);
    return input.trim().split(spaceRegExp);
  }

  // border default width 3.0
  static double defaultBorderLineWidth = 3.0;
  static BorderStyle defaultBorderStyle = BorderStyle.none;
  static Color defaultBorderColor = WebColor.transparent;

  BorderStyle getBorderStyle(String input) {
    BorderStyle borderStyle;
    switch (input) {
      case 'solid':
        borderStyle = BorderStyle.solid;
        break;
      default:
        borderStyle = BorderStyle.none;
        break;
    }
    return borderStyle;
  }
  // TODO: Shortted order in web not keep in same order
  Map _getShorttedInfoFromString(String input) {
    List<String> splittedBorder = getShorttedProperties(input);

    double width = splittedBorder.length > 0
      ? Length.toDisplayPortValue(splittedBorder[0])
      : null;

    BorderStyle style = splittedBorder.length > 1
      ? getBorderStyle(splittedBorder[1])
      : null;

    Color color = splittedBorder.length > 2
      ? WebColor.generate(splittedBorder[2])
      : null;

    return {
      'Color': color,
      'Style': style,
      'Width': width
    };
  }

  // TODO: shorthand format like `borderColor: 'red yellow green blue'` should full support
  TransitionBorderSide getBorderSideByStyle(StyleDeclaration style, String side) {
    TransitionBorderSide borderSide = TransitionBorderSide(0, 0, 0, 0, defaultBorderLineWidth, defaultBorderStyle);
    final String borderName = 'border';
    final String borderSideName = borderName + side; // eg. borderLeft/borderRight
    // Same with the key in shortted info map
    final String widthName = 'Width';
    final String styleName = 'Style';
    final String colorName = 'Color';
    Map borderShorttedInfo;
    Map borderSideShorttedInfo;
    if (style.contains(borderName)){
      borderShorttedInfo = _getShorttedInfoFromString(style[borderName]);
    }

    if (style.contains(borderSideName)) {
      borderSideShorttedInfo = _getShorttedInfoFromString(style[borderSideName]);
    }

    // Set border style
    final String borderSideStyleName = borderSideName + styleName; // eg. borderLeftStyle/borderRightStyle
    final String borderStyleName = borderName + styleName; // borderStyle
    if (style.contains(borderSideStyleName)) {
      borderSide.borderStyle = getBorderStyle(style[borderSideStyleName]);
    } else if (borderSideShorttedInfo != null && borderSideShorttedInfo[styleName] != null) {
      borderSide.borderStyle = borderSideShorttedInfo[styleName];
    } else if (style.contains(borderStyleName)) {
      borderSide.borderStyle = getBorderStyle(style[borderStyleName]);
    } else if (borderShorttedInfo != null && borderShorttedInfo[styleName] != null) {
      borderSide.borderStyle = borderShorttedInfo[styleName];
    }

    // border width should be zero when style is none
    if (borderSide.borderStyle == BorderStyle.none) {
      borderSide.borderWidth = 0.0;
    } else {
      // Set border width
      final String borderSideWidthName = borderSideName + widthName; // eg. borderLeftWidth/borderRightWidth
      final String borderWidthName = borderName + widthName; // borderWidth
      if (style.contains(borderSideWidthName) &&
          (style[borderSideWidthName] as String).isNotEmpty) {
        borderSide.borderWidth = Length.toDisplayPortValue(style[borderSideWidthName]);
      } else if (borderSideShorttedInfo != null && borderSideShorttedInfo[widthName] != null) { // eg. borderLeft: 'solid 1px black'
        borderSide.borderWidth = borderSideShorttedInfo[widthName];
      } else if (style.contains(borderWidthName)) {
        borderSide.borderWidth = Length.toDisplayPortValue(style[borderWidthName]);
      } else if (borderShorttedInfo != null && borderShorttedInfo[widthName] != null) { // eg. border: 'solid 2px red'
        borderSide.borderWidth = borderShorttedInfo[widthName];
      }
    }

    // Set border color
    Color borderColor;
    final String borderSideColorName = borderSideName + colorName; // eg. borderLeftColor/borderRightColor
    final String borderColorName = borderName + colorName; // borderColor
    if (style.contains(borderSideColorName)) {
      borderColor = WebColor.generate(style[borderSideColorName]);
    } else if (borderSideShorttedInfo != null && borderSideShorttedInfo[colorName] != null) {
      borderColor = borderSideShorttedInfo[colorName];
    } else if (style.contains(borderColorName)) {
      borderColor = WebColor.generate(style[borderColorName]);
    } else if (borderShorttedInfo != null && borderShorttedInfo[colorName] != null) {
      borderColor = borderShorttedInfo[colorName];
    }

    if (borderColor != null) {
      borderSide.color = borderSide.color.withAlpha(borderColor.alpha);
      borderSide.color = borderSide.color.withRed(borderColor.red);
      borderSide.color = borderSide.color.withGreen(borderColor.green);
      borderSide.color = borderSide.color.withBlue(borderColor.blue);
    }

    return borderSide;
  }
}

mixin TransitionColorMixin {
  Color color;

  void initColor(Color color) {
    this.color = color;
  }
}

class TransitionBorderSide with TransitionColorMixin {
  double borderWidth;
  BorderStyle borderStyle;

  TransitionBorderSide(borderAlpha, borderRed, borderGreen, borderBlue,
      this.borderWidth, this.borderStyle) {
    initColor(Color.fromARGB(
        borderAlpha, borderRed, borderGreen, borderBlue));
  }

  TransitionBorderSide clone() {
    return TransitionBorderSide(color.alpha, color.red,
        color.green, color.blue, this.borderWidth, this.borderStyle);
  }

  BorderSide toBorderSide() {
    return BorderSide(
        color: color,
        width: borderWidth,
        style: borderStyle);
  }
}

class TransitionDecoration with TransitionColorMixin {
  // radius inorder topLeft topRight bottomLeft bottomRight
  List<double> borderRadiusTLTRBLBR;
  // side inorder left top right bottom
  List<TransitionBorderSide> borderSidesLTRB;
  DecorationImage image;
  List<BoxShadow> boxShadow;
  Gradient gradient;

  TransitionDecoration(
      alpha,
      red,
      green,
      blue,
      borderLeftSide,
      borderTopSide,
      borderRightSide,
      borderBottomSide,
      this.image,
      this.boxShadow,
      this.borderRadiusTLTRBLBR,
      this.gradient) {
    initColor(Color.fromARGB(alpha, red, green, blue));
    // side add inorder left top right bottom
    borderSidesLTRB = [
      borderLeftSide,
      borderTopSide,
      borderRightSide,
      borderBottomSide,
    ];
  }

  TransitionDecoration clone() {
    return TransitionDecoration(
        color.alpha,
        color.red,
        color.green,
        color.blue,
        // side read inorder left top right bottom
        this.borderSidesLTRB[0].clone(),
        this.borderSidesLTRB[1].clone(),
        this.borderSidesLTRB[2].clone(),
        this.borderSidesLTRB[3].clone(),
        this.image,
        this.boxShadow,
        // radius read inorder topLeft topRight bottomLeft bottomRight
        List.of(this.borderRadiusTLTRBLBR),
        this.gradient);
  }

  BoxDecoration toBoxDecoration() {
    if (gradient != null) {
      color = null;
    }
    // side read inorder left top right bottom
    Border border = Border(
        left: borderSidesLTRB[0].toBorderSide(),
        top: borderSidesLTRB[1].toBorderSide(),
        right: borderSidesLTRB[2].toBorderSide(),
        bottom: borderSidesLTRB[3].toBorderSide());
    BorderRadius borderRadius;

    // flutter border limit, when border is not uniform, should set borderRadius
    if (border.isUniform) {
      // radius read inorder topLeft topRight bottomLeft bottomRight
      borderRadius = BorderRadius.only(
        topLeft: Radius.circular(borderRadiusTLTRBLBR[0]),
        topRight: Radius.circular(borderRadiusTLTRBLBR[1]),
        bottomLeft: Radius.circular(borderRadiusTLTRBLBR[2]),
        bottomRight: Radius.circular(borderRadiusTLTRBLBR[3])
      );
    }

    return BoxDecoration(
        color: color,
        image: image,
        border: border,
        borderRadius: borderRadius,
        boxShadow: boxShadow,
        gradient: gradient);
  }

  EdgeInsets getBorderEdgeInsets() {
    // side read inorder left top right bottom
    return EdgeInsets.fromLTRB(
        borderSidesLTRB[0].borderWidth,
        borderSidesLTRB[1].borderWidth,
        borderSidesLTRB[2].borderWidth,
        borderSidesLTRB[3].borderWidth);
  }
}
