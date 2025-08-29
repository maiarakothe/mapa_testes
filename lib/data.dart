import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

// Mapa de cores para cada tipo de bloco
const Map<String, Color> blockColors = {
  'trigger': Colors.orange,
  'action': Colors.blue,
  'paths': Colors.purple,
  'path': Colors.purple,
  'delay': Colors.green,
  'email': Colors.red,
  'webhook': Colors.teal,
};

// Mapa de ícones para cada tipo de bloco
const Map<String, IconData> blockIcons = {
  'trigger': Icons.flash_on,
  'action': Icons.settings,
  'paths': Icons.call_split,
  'path': Icons.subdirectory_arrow_right,
  'delay': Icons.schedule,
  'email': Icons.email,
  'webhook': Icons.http,
};

class WorkflowBlock {
  final String id;
  String title;
  String subtitle;
  final String type;
  List<WorkflowBlock> children;

  WorkflowBlock({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    List<WorkflowBlock>? children,
  }) : children = children ?? [];
}

// Classe auxiliar para encontrar um bloco e seu pai na árvore
class BlockLocation {
  final WorkflowBlock? parent;
  final WorkflowBlock block;
  final int index;

  BlockLocation({required this.block, this.parent, required this.index});
}