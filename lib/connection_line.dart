import 'package:flutter/material.dart';

// ---------------- Linhas ----------------

class ConnectionLine extends StatelessWidget {
  const ConnectionLine({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: CustomPaint(
        painter: StraightLinePainter(),
        size: const Size(double.infinity, 50),
      ),
    );
  }
}

class StraightLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class BranchingLinePainter extends CustomPainter {
  final int numChildren;
  BranchingLinePainter({required this.numChildren});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final path = Path();
    // Desenha a linha vertical que sai do bloco pai
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width / 2, size.height / 2);

    // Linha horizontal que conecta os caminhos
    path.moveTo(0, size.height / 2);
    path.lineTo(size.width, size.height / 2);

    // Linhas verticais que descem para cada caminho
    final double spacing = size.width / (numChildren + 1);
    for (int i = 0; i < numChildren; i++) {
      final x = spacing * (i + 1);
      path.moveTo(x, size.height / 2);
      path.lineTo(x, size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}