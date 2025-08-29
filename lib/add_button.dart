import 'package:flutter/material.dart';

// ---------------- Botão Adicionar ----------------

class AddButton extends StatelessWidget {
  final String parentBlockId;
  final Function(String, String) onBlockDropped;
  final Function(String) onAddBlock;

  const AddButton({
    super.key,
    required this.parentBlockId,
    required this.onBlockDropped,
    required this.onAddBlock,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAccept: (data) => data != null,
      onAccept: (draggedId) {
        onBlockDropped(parentBlockId, draggedId);
      },
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: () {
            onAddBlock(parentBlockId);
          },
          child: CircleAvatar(
            radius: 20,
            backgroundColor: candidateData.isNotEmpty ? Colors.blue[300] : Colors.green[300],
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }
}