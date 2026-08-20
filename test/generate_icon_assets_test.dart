import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Generate Icon Assets for flutter_launcher_icons', () async {
    final rawBytes = await File('assets/images/aero_mascot.png').readAsBytes();
    final codec = await ui.instantiateImageCodec(rawBytes);
    final frameInfo = await codec.getNextFrame();
    final mascotImage = frameInfo.image;

    const canvasSize = 1024.0;

    // 1. Generate Full Flat Icon (for iOS & legacy Android with #0A0A0A background)
    final recorderFull = ui.PictureRecorder();
    final canvasFull = Canvas(recorderFull, const Rect.fromLTWH(0, 0, canvasSize, canvasSize));

    // Fill background
    final bgPaint = Paint()..color = const Color(0xFF0A0A0A);
    canvasFull.drawRect(const Rect.fromLTWH(0, 0, canvasSize, canvasSize), bgPaint);

    // Center mascot with ~16% margin (target dimension ~680px)
    const targetSizeFull = 700.0;
    final scaleFull = targetSizeFull / (mascotImage.width > mascotImage.height ? mascotImage.width : mascotImage.height);
    final drawWFull = mascotImage.width * scaleFull;
    final drawHFull = mascotImage.height * scaleFull;
    final dxFull = (canvasSize - drawWFull) / 2;
    final dyFull = (canvasSize - drawHFull) / 2;

    canvasFull.drawImageRect(
      mascotImage,
      Rect.fromLTWH(0, 0, mascotImage.width.toDouble(), mascotImage.height.toDouble()),
      Rect.fromLTWH(dxFull, dyFull, drawWFull, drawHFull),
      Paint()..filterQuality = FilterQuality.high,
    );

    final pictureFull = recorderFull.endRecording();
    final imgFull = await pictureFull.toImage(canvasSize.toInt(), canvasSize.toInt());
    final pngDataFull = await imgFull.toByteData(format: ui.ImageByteFormat.png);
    await File('assets/images/aero_icon_full.png').writeAsBytes(pngDataFull!.buffer.asUint8List());

    // 2. Generate Adaptive Icon Foreground (transparent 1024x1024 with bird strictly inside the 66% inner circle safe zone ~600px)
    final recorderForeground = ui.PictureRecorder();
    final canvasForeground = Canvas(recorderForeground, const Rect.fromLTWH(0, 0, canvasSize, canvasSize));

    const targetSizeForeground = 580.0;
    final scaleForeground = targetSizeForeground / (mascotImage.width > mascotImage.height ? mascotImage.width : mascotImage.height);
    final drawWForeground = mascotImage.width * scaleForeground;
    final drawHForeground = mascotImage.height * scaleForeground;
    final dxForeground = (canvasSize - drawWForeground) / 2;
    final dyForeground = (canvasSize - drawHForeground) / 2;

    canvasForeground.drawImageRect(
      mascotImage,
      Rect.fromLTWH(0, 0, mascotImage.width.toDouble(), mascotImage.height.toDouble()),
      Rect.fromLTWH(dxForeground, dyForeground, drawWForeground, drawHForeground),
      Paint()..filterQuality = FilterQuality.high,
    );

    final pictureForeground = recorderForeground.endRecording();
    final imgForeground = await pictureForeground.toImage(canvasSize.toInt(), canvasSize.toInt());
    final pngDataForeground = await imgForeground.toByteData(format: ui.ImageByteFormat.png);
    await File('assets/images/aero_mascot_foreground.png').writeAsBytes(pngDataForeground!.buffer.asUint8List());

    expect(File('assets/images/aero_icon_full.png').existsSync(), isTrue);
    expect(File('assets/images/aero_mascot_foreground.png').existsSync(), isTrue);
  });
}
