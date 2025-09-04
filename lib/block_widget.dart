// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import 'data.dart';

// ---------------- Bloco ----------------

class BlockWidget extends StatelessWidget {
  final WorkflowBlock block;
  final Function(String targetId, String draggedId) onBlockDropped;
  final Function(WorkflowBlock) onRenameBlock;
  final Function(String) onRemoveBlock;
  final Function(String) onDuplicateBlock;
  final double width;

  const BlockWidget({
    super.key,
    required this.block,
    required this.onBlockDropped,
    required this.onRenameBlock,
    required this.onRemoveBlock,
    required this.onDuplicateBlock,
    this.width = 220,
  });

  @override
  Widget build(BuildContext context) {
    final blockColor = blockColors[block.type] ?? Colors.grey;
    final blockIcon = blockIcons[block.type] ?? Icons.block;

    return Draggable<String>(
      data: block.id,
      feedback: Opacity(
        opacity: 0.3, // Opacidade do bloco sendo arrastado
        child: Material(
          elevation: 10,
          borderRadius: BorderRadius.circular(16),
          child: _buildBlock(context, blockColor, blockIcon),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.6, // Opacidade do bloco que fica
        child: _buildBlock(context, blockColor, blockIcon),
      ),
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: highlight ? Colors.grey.withOpacity(0.9) : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    block.title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (String value) {
                  if (value == 'rename') {
                    onRenameBlock(block);
                  } else if (value == 'duplicate') {
                    if (block.type != 'paths') {
                      onDuplicateBlock(block.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Bloco "${block.title}" duplicado!'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else if (value == 'delete') {
                    onRemoveBlock(block.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Bloco "${block.title}" removido!'),
                        duration: const Duration(seconds: 2),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                itemBuilder: (BuildContext context) {
                  return <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'rename',
                      child: Text('Renomear'),
                    ),
                    if (block.type != 'paths')
                      const PopupMenuItem<String>(
                        value: 'duplicate',
                        child: Text('Duplicar'),
                      ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Deletar'),
                    ),
                  ];
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            block.subtitle,
            style: const TextStyle(color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}