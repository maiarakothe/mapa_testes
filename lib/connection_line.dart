import 'package:flutter/material.dart';
import 'main.dart';

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
      ..color = DefaultColors.primary
      ..strokeWidth = 2 // Linha mais fina
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
    // Adicionado para não desenhar linhas desnecessárias
    if (numChildren <= 1) return;

    final paint = Paint()
      ..color = DefaultColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path();
    
    final double childColumnWidth = size.width / numChildren;
    final double firstChildX = childColumnWidth / 2;
    final double lastChildX = size.width - (childColumnWidth / 2);

    // Desenha a linha vertical que sai do bloco pai
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width / 2, size.height / 2);

    // Linha horizontal vai apenas do primeiro ao último filho
    path.moveTo(firstChildX, size.height / 2);
    path.lineTo(lastChildX, size.height / 2);

    // Linhas verticais que descem para cada caminho
    for (int i = 0; i < numChildren; i++) {
      final x = firstChildX + (i * childColumnWidth);
      path.moveTo(x, size.height / 2);
      path.lineTo(x, size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return oldDelegate is! BranchingLinePainter || oldDelegate.numChildren != numChildren;
  }
}