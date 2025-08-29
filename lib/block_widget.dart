import 'package:flutter/material.dart';

import 'data.dart';

// ---------------- Bloco ----------------

class BlockWidget extends StatelessWidget {
  final WorkflowBlock block;
  final Function(String targetId, String draggedId) onBlockDropped;
  final Function(WorkflowBlock) onRenameBlock;
  final Function(String) onRemoveBlock;
  final double width;

  const BlockWidget({
    super.key,
    required this.block,
    required this.onBlockDropped,
    required this.onRenameBlock,
    required this.onRemoveBlock,
    this.width = 220,
  });

  @override
  Widget build(BuildContext context) {
    final blockColor = blockColors[block.type] ?? Colors.grey;
    final blockIcon = blockIcons[block.type] ?? Icons.block;

    return Draggable<String>(
      data: block.id,
      feedback: Material(
        child: Opacity(
          opacity: 0.7,
          child: _buildBlock(context, blockColor, blockIcon),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: _buildBlock(context, blockColor, blockIcon)),
      child: DragTarget<String>(
        onWillAccept: (data) => data != block.id,
        onAccept: (dragged) => onBlockDropped(block.id, dragged),
        builder: (context, candidate, rejected) => _buildBlock(context, blockColor, blockIcon, highlight: candidate.isNotEmpty),
      ),
    );
  }

  Widget _buildBlock(BuildContext context, Color color, IconData icon, {bool highlight = false}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: highlight ? Colors.blue : Colors.grey, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 24, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    block.title,
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (String value) {
                  if (value == 'rename') {
                    onRenameBlock(block);
                  } else if (value == 'duplicate') {
                    // Lógica para duplicar
                  } else if (value == 'delete') {
                    onRemoveBlock(block.id);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'rename',
                    child: Text('Renomear'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'duplicate',
                    child: Text('Duplicar'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Deletar'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(block.subtitle),
        ],
      ),
    );
  }
}