import 'dart:math';
import 'dart:typed_data';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart' as flutter;
import 'package:path/path.dart' as path;
import 'package:image/image.dart';

///Check if [firstImg] and [secondImg] have the same width and height
bool haveSameSize(Image firstImg, Image secondImg) {
  if (firstImg.width != secondImg.width || firstImg.height != secondImg.height) {
    return false;
  }
  return true;
}

///Returns a red color only if two RGB pixels are different
int selectColor(firstPixel, secondPixel, diffAtPixel) {
  var fRed = getRed(firstPixel);
  var fGreen = getGreen(firstPixel);
  var fBlue = getBlue(firstPixel);
  var sRed = getRed(secondPixel);
  var sGreen = getGreen(secondPixel);
  var sBlue = getBlue(secondPixel);

  if (diffAtPixel == 0) return Color.fromRgba(fRed, fGreen, fBlue, 50);
  if (fRed == 0 && fGreen == 0 && fBlue == 0) return Color.fromRgba(sRed, sGreen, sBlue, 50);
  if (sRed == 0 && sGreen == 0 && sBlue == 0) return Color.fromRgba(fRed, fGreen, fBlue, 50);

  int alpha, red, green, blue;

  alpha = 255;
  red = 255;
  green = 0;
  blue = 0;

  return Color.fromRgba(red, green, blue, alpha);
}

num diffBetweenPixels(firstPixel, secondPixel, ignoreAlpha) {
  var fRed = getRed(firstPixel);
  var fGreen = getGreen(firstPixel);
  var fBlue = getBlue(firstPixel);
  var fAlpha = getAlpha(firstPixel);
  var sRed = getRed(secondPixel);
  var sGreen = getGreen(secondPixel);
  var sBlue = getBlue(secondPixel);
  var sAlpha = getAlpha(secondPixel);

  num diff = (fRed - sRed).abs() + (fGreen - sGreen).abs() + (fBlue - sBlue).abs();

  if (ignoreAlpha) {
    diff = (diff / 255) / 3;
  } else {
    diff += (fAlpha - sAlpha).abs();
    diff = (diff / 255) / 4;
  }

  return diff;
}

final bool isWindows = Platform.isWindows;
const bool debugON = false;
num maxh = 0, maxs = 0, maxl = 0, maxa = 0;
num diffBetweenPixelsWin(int firstPixel, int secondPixel, bool ignoreAlpha, Image img, int i, int j) {
  var fRed = getRed(firstPixel);
  var fGreen = getGreen(firstPixel);
  var fBlue = getBlue(firstPixel);
  var fAlpha = getAlpha(firstPixel);
  var sRed = getRed(secondPixel);
  var sGreen = getGreen(secondPixel);
  var sBlue = getBlue(secondPixel);
  var sAlpha = getAlpha(secondPixel);

  final fHSL = flutter.HSLColor.fromColor(flutter.Color.fromARGB(fAlpha, fRed, fGreen, fBlue));
  final sHSL = flutter.HSLColor.fromColor(flutter.Color.fromARGB(sAlpha, sRed, sGreen, sBlue));

  num dh = (fHSL.hue - sHSL.hue).abs() / 360;
  num ds = (fHSL.saturation - sHSL.saturation).abs();
  num dl = (fHSL.lightness - sHSL.lightness).abs();
  num da = (fHSL.alpha - sHSL.alpha).abs();

  flutter.HSLColor backgroundHSL;
  num dh2 = 0, ds2 = 0, dl2 = 0, da2 = 0;
  const dh_max = 0.3;
  const ds_max = 0.5;
  const dl_max = 0.3;

  if ((dh > dh_max) || (ds > ds_max) || (dl > dl_max)) {
    backgroundHSL = backgroundColor(img, i, j, sHSL);
    if (dh > 0) {
      dh2 = (sHSL.hue - backgroundHSL.hue).abs() / 360;
      dh = min(dh, dh2);
      // print('hue ${fHSL.hue} ${sHSL.hue} ${backgroundColor}');
    }
    if (ds > 0) {
      ds2 = (sHSL.saturation - backgroundHSL.saturation).abs();
      ds = min(ds, ds2);
    }
    if (dl > 0) {
      dl2 = (sHSL.saturation - backgroundHSL.saturation).abs();
      dl = min(dl, dl2);
    }

    if ((dh > dh_max) || (ds > ds_max) || (dl > dl_max)) {
      var bc = backgroundHSL.toColor();
      // if (bc.red == 255 && bc.green == 255 && bc.blue == 255)
      //   backgroundColor(img, i, j, sHSL, true);
      // print(
      //     '($i,$j) dh=${dh.toStringAsPrecision(3)}, ' + //
      //     'ds=${ds.toStringAsPrecision(3)}, ' +         //
      //     'dl=${dl.toStringAsPrecision(3)}, ' +         //
      //     'da=${da.toStringAsPrecision(3)}' +           //
      //     '\t${maxh.toStringAsPrecision(3)},${maxs.toStringAsPrecision(3)},${maxl.toStringAsPrecision(3)},${maxa.toStringAsPrecision(3)}'
      //     + //
      //     '\n\tf:$fRed,$fGreen,$fBlue,$fAlpha' + //
      //     '\n\ts:$sRed,$sGreen,$sBlue,$sAlpha' +
      //     '\n\tb:${bc.red},${bc.green},${bc.blue},${bc.alpha}');
    }
  }
  if (debugON) {
    if (dh > maxh) maxh = dh;
    if (ds > maxs) maxs = ds;
    if (dl > maxl) maxl = dl;
    if (da > maxa) maxa = da;
  }
  dh = (dh <= dh_max) ? 0 : 1;
  ds = (ds <= ds_max) ? 0 : 1;
  dl = (dl <= dl_max) ? 0 : 1;
  da = (da <= 0.1) ? 0 : 1;
  num diff = dh + ds + dl;
  if (ignoreAlpha) {
    diff /= 3;
  } else {
    diff += da;
    diff /= 4;
  }

  return diff;
}

flutter.HSLColor backgroundColor(Image img, int i, int j, flutter.HSLColor forground, [bool debug = false]) {
  const searchradius = 2;
  int iMin = i - searchradius;
  int iMax = i + searchradius;
  int jMin = j - searchradius;
  int jMax = j + searchradius;
  if (iMin < 0) iMin = 0;
  if (iMax > img.width - 1) iMax = img.width - 1;
  if (jMin < 0) jMin = 0;
  if (jMax > img.height - 1) jMax = img.height - 1;
  int count = 0;
  int aSum = 0, rSum = 0, gSum = 0, bSum = 0;
  int pix;
  int a = 0, r = 0, g = 0, b = 0;
  StringBuffer sb = new StringBuffer();

  for (int y = jMin; y < jMax; y++) {
    if (debug) sb.write('\n($y):');
    for (int x = iMin; x < iMax; x++) {
      pix = img.getPixel(x, y);
      a = getAlpha(pix);
      r = getRed(pix);
      g = getGreen(pix);
      b = getBlue(pix);
      // var hsl = flutter.HSLColor.fromColor(flutter.Color.fromARGB(a, r, g, b));
      // var dh = (hsl.hue - forground.hue).abs() / 360;
      // var ds = (hsl.saturation - forground.saturation).abs();
      // var dl = (hsl.lightness - forground.lightness).abs();
      // var diff = dh + ds + dl;
      if (debug) sb.write('($r,$g,$b,$a) ');
      // sb.write('($r,$g,$b,$a)$dh`$ds`$dl ');
      // if (diff > 0.2) {
      aSum += a;
      rSum += r;
      gSum += g;
      bSum += b;
      count++;
      // }
    }
    if (debug) sb.write('\n');
  }
  if (debug) print(sb.toString());
  if (count == 0) {
    print('count =0');
    if (debug == false) backgroundColor(img, i, j, forground, true);
    return flutter.HSLColor.fromAHSL(1, 0, 0, 1);
  }
  aSum = (aSum / count).floor();
  rSum = (rSum / count).floor();
  gSum = (gSum / count).floor();
  bSum = (bSum / count).floor();
  return flutter.HSLColor.fromColor(flutter.Color.fromARGB(aSum, rSum, gSum, bSum));
}

bool matchImage(Uint8List imageA, List<int> imageB, String filename) {
  Image a = decodeImage(imageA.toList())!;
  Image b = decodeImage(imageB.toList())!;
  if (!haveSameSize(a, b)) {
    return false;
  }

  var width = a.width;
  var height = b.height;
  var diff = 0.0;

  if (debugON) maxh = maxs = maxl = maxa = 0;

  //Create an image to show the differences
  var diffImg = Image(width, height);

  // print('${filename} ($width,$height)');
  for (var i = 0; i < width; i++) {
    var diffAtPixel, firstPixel, secondPixel;
    for (var j = 0; j < height; j++) {
      firstPixel = a.getPixel(i, j);
      secondPixel = b.getPixel(i, j);
      diffAtPixel = (!isWindows)
          ? diffBetweenPixels(firstPixel, secondPixel, true)
          : diffBetweenPixelsWin(firstPixel, secondPixel, true, b, i, j);
      diff += diffAtPixel;

      //Shows in red the different pixels and in semitransparent the same ones
      diffImg.setPixel(i, j, selectColor(firstPixel, secondPixel, diffAtPixel));
    }
  }

  // print('${filename} DIFF ${diff}');
  diff /= height * width;

  if (diff > 0) {
    if (!isWindows) {
      final newSnap = File('$filename.diff.png');
      newSnap.writeAsBytesSync(encodePng(diffImg));
    } else {
      final filenameAddCurrent = filename.replaceFirst('snapshots', 'snapshots-diff');
      final dirnameAddCurrent = path.dirname(filenameAddCurrent);
      var dirAddCurrent = Directory(dirnameAddCurrent);
      if (!dirAddCurrent.existsSync()) {
        dirAddCurrent.createSync(recursive: true);
      }
      final newSnap = File('$filenameAddCurrent.png');
      newSnap.writeAsBytesSync(encodePng(diffImg));
    }
  }
  if (isWindows) {
    if ((diff * 10e5) < 20) {
      return true;
    } else {
      print('DIFF * 10e5 = ${(diff * 10e5)}');
      return false;
    }
  }

  return (diff * 10e5) < 20;
}

bool matchFile(List<int> left, List<int> right) {
  if (left.length != right.length) {
    return false;
  }

  for (int i = 0; i < left.length; i++) {
    if (left[i] != right[i]) {
      return false;
    }
  }

  return true;
}

Future<bool> matchImageSnapshot(Uint8List bytes, String filename) async {
  final dirname = path.dirname(filename);
  var dir = Directory(dirname);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  List<int> currentPixels = bytes.toList();
  final snap = File('$filename.png');
  if (snap.existsSync()) {
    Uint8List snapPixels = snap.readAsBytesSync();
    bool match = matchFile(snapPixels, currentPixels);
    if (!match) {
      match = matchImage(snapPixels, currentPixels, filename);
    }
    if (!match) {
      if (!isWindows) {
        final newSnap = File('$filename.current.png');
        newSnap.writeAsBytes(currentPixels);
      } else {
        final dirnameAddCurrent = dirname.replaceFirst('snapshots', 'snapshots-current');
        final filenameAddCurrent = filename.replaceFirst('snapshots', 'snapshots-current');
        var dirAddCurrent = Directory(dirnameAddCurrent);
        if (!dirAddCurrent.existsSync()) {
          dirAddCurrent.createSync(recursive: true);
        }
        final newSnap = File('$filenameAddCurrent.png');
        newSnap.writeAsBytes(currentPixels);
      }
    }
    return match;
  } else {
    await snap.writeAsBytes(currentPixels);
    return true;
  }
}
