import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

Future<Uint8List> generatePastelarioLogo({required int size}) async {
  final recorder = ui.PictureRecorder();
  final canvas =
      Canvas(recorder, Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()));

  // Background preto
  canvas.drawRect(
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    Paint()..color = Colors.black,
  );

  // Proporções
  final pastelSize = size * 0.41; // 212/512
  final pastelX = (size - pastelSize) / 2; // Centralizado
  final pastelY = size * 0.195; // 100/512

  // Quadrado amarelo principal (pastel)
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(pastelX, pastelY, pastelSize, pastelSize),
      Radius.circular(size * 0.02),
    ),
    Paint()..color = Color(0xFFFFD700),
  );

  // Triângulo do topo esquerdo
  final trianglePaint = Paint()..color = Color(0xFFFFD700);
  final trianglePath = Path();
  trianglePath.moveTo(pastelX, pastelY - size * 0.078); // 80/512
  trianglePath.lineTo(pastelX + size * 0.078, pastelY - size * 0.156); // 50
  trianglePath.lineTo(pastelX + size * 0.078, pastelY - size * 0.078); // 110
  trianglePath.close();
  canvas.drawPath(trianglePath, trianglePaint);

  // Barra horizontal do topo
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(
        pastelX + size * 0.098, // 50/512
        pastelY - size * 0.215, // 20
        size * 0.293, // 150
        size * 0.098, // 50
      ),
      Radius.circular(size * 0.01),
    ),
    Paint()..color = Color(0xFFFFD700),
  );

  // Olhos
  final eyePaint = Paint()
    ..color = Colors.black
    ..strokeWidth = size * 0.0234 // 12
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  // Olho esquerdo
  canvas.drawArc(
    Rect.fromCircle(
      center: Offset(pastelX + size * 0.195, pastelY + size * 0.195),
      radius: size * 0.039, // 20
    ),
    0,
    3.14159,
    false,
    eyePaint,
  );

  // Olho direito
  canvas.drawArc(
    Rect.fromCircle(
      center:
          Offset(pastelX + pastelSize - size * 0.117, pastelY + size * 0.195),
      radius: size * 0.039,
    ),
    0,
    3.14159,
    false,
    eyePaint,
  );

  // Boca
  final mouthPath = Path();
  final mouthStartX = pastelX + size * 0.117; // 60
  final mouthEndX = pastelX + pastelSize - size * 0.117;
  final mouthY = pastelY + size * 0.293; // 150
  mouthPath.moveTo(mouthStartX, mouthY);
  mouthPath.quadraticBezierTo(
      size / 2, mouthY + size * 0.059, mouthEndX, mouthY);
  canvas.drawPath(mouthPath, eyePaint);

  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}
