import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';


void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => WorkflowModel(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dynamic Workflow',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[200],
      ),
      home: const WorkflowPage(),
    );
  }
}

// ---------------- Dados ----------------

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
  final String title;
  final String subtitle;
  final String type; // "trigger", "action", "paths", "path", "delay", "email", "webhook"
  List<String> childrenIds;

  WorkflowBlock({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    List<String>? childrenIds,
  }) : childrenIds = childrenIds ?? [];

  WorkflowBlock copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? type,
    List<String>? childrenIds,
  }) {
    return WorkflowBlock(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      type: type ?? this.type,
      childrenIds: childrenIds ?? this.childrenIds,
    );
  }
}

// ---------------- Modelo ----------------

class WorkflowModel extends ChangeNotifier {
  final List<WorkflowBlock> _blocks = [
    WorkflowBlock(
      id: 'start',
      title: 'Trigger',
      subtitle: 'Início do fluxo',
      type: 'trigger',
    ),
  ];

  List<WorkflowBlock> get blocks => _blocks;

  WorkflowBlock? getBlockById(String id) {
    try {
      return _blocks.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }

  void removeBlock(String id) {
    _blocks.removeWhere((b) => b.id == id);
    notifyListeners();
  }

  void reorderBlock(String targetId, String draggedId) {
    final draggedBlock = getBlockById(draggedId);
    if (draggedBlock == null) return;

    _blocks.removeWhere((b) => b.id == draggedId);

    final target = getBlockById(targetId);
    if (target == null) return;

    final index = _blocks.indexOf(target);
    _blocks.insert(index + 1, draggedBlock);

    notifyListeners();
  }

  void addBlockAfter(String parentId, String title, String type, {String subtitle = 'Adicionado dinamicamente'}) {
    final parentIndex = _blocks.indexWhere((b) => b.id == parentId);
    if (parentIndex == -1) return;

    final newBlock = WorkflowBlock(
      id: uuid.v4(),
      title: title,
      subtitle: subtitle,
      type: type,
    );

    _blocks.insert(parentIndex + 1, newBlock);
    notifyListeners();
  }

  void addPathsAfter(String parentId) {
    final parentIndex = _blocks.indexWhere((b) => b.id == parentId);
    if (parentIndex == -1) return;

    final pathsBlockId = uuid.v4();
    final pathAId = uuid.v4();
    final pathBId = uuid.v4();

    final pathsBlock = WorkflowBlock(
      id: pathsBlockId,
      title: 'Caminhos',
      subtitle: 'Divida em múltiplos caminhos',
      type: 'paths',
      childrenIds: [pathAId, pathBId],
    );

    final pathA = WorkflowBlock(
      id: pathAId,
      title: 'Caminho A',
      subtitle: 'Filho A',
      type: 'path',
    );

    final pathB = WorkflowBlock(
      id: pathBId,
      title: 'Caminho B',
      subtitle: 'Filho B',
      type: 'path',
    );

    _blocks.insertAll(parentIndex + 1, [pathsBlock, pathA, pathB]);
    notifyListeners();
  }

  void addAnotherPath(String pathsBlockId) {
    final pathsBlock = getBlockById(pathsBlockId);
    if (pathsBlock == null) return;

    final newPathId = uuid.v4();
    final newPathBlock = WorkflowBlock(
      id: newPathId,
      title: 'Caminho ${String.fromCharCode(65 + pathsBlock.childrenIds.length)}',
      subtitle: 'Novo Caminho',
      type: 'path',
    );

    pathsBlock.childrenIds.add(newPathId);

    final pathsBlockIndex = _blocks.indexOf(pathsBlock);
    _blocks.insert(pathsBlockIndex + pathsBlock.childrenIds.length, newPathBlock);

    notifyListeners();
  }

  void renameBlock(String blockId, String newTitle) {
    final index = _blocks.indexWhere((b) => b.id == blockId);
    if (index != -1) {
      final oldBlock = _blocks[index];
      _blocks[index] = oldBlock.copyWith(title: newTitle);
      notifyListeners();
    }
  }

  void duplicateBlock(String blockId) {
    final originalBlock = getBlockById(blockId);
    if (originalBlock == null) return;

    final newBlock = WorkflowBlock(
      id: uuid.v4(),
      title: '${originalBlock.title} (Cópia)',
      subtitle: originalBlock.subtitle,
      type: originalBlock.type,
      childrenIds: [...originalBlock.childrenIds],
    );

    final originalIndex = _blocks.indexOf(originalBlock);
    _blocks.insert(originalIndex + 1, newBlock);
    notifyListeners();
  }
}

// ---------------- UI ----------------

class WorkflowPage extends StatefulWidget {
  const WorkflowPage({super.key});

  @override
  State<WorkflowPage> createState() => _WorkflowPageState();
}

class _WorkflowPageState extends State<WorkflowPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _workflowKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workflow Dinâmico')),
      body: Stack(
        children: [
          Consumer<WorkflowModel>(
            builder: (context, model, _) {
              return SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  key: _workflowKey,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: _buildLayout(context, model),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildLayout(BuildContext context, WorkflowModel model) {
    final List<Widget> workflowWidgets = [];
    int i = 0;
    while (i < model.blocks.length) {
      final block = model.blocks[i];

      if (block.type == 'paths') {
        final pathsParentBlock = block;

        // Botão para adicionar caminhos, posicionado acima da ramificação
        workflowWidgets.add(const ConnectionLine());
        workflowWidgets.add(
          AddButton(
            parentBlockId: pathsParentBlock.id,
            onBlockDropped: (parentId, draggedId) => model.reorderBlock(parentId, draggedId),
            onAddBlock: (parentId) => _showAddBlockDialog(context, parentId),
          ),
        );
        workflowWidgets.add(const ConnectionLine(isBranching: true));

        final List<Widget> pathColumns = [];
        for (int j = 0; j < pathsParentBlock.childrenIds.length; j++) {
          final pathBlockId = pathsParentBlock.childrenIds[j];
          final pathBlock = model.getBlockById(pathBlockId);
          if (pathBlock == null) continue;

          pathColumns.add(
            Expanded(
              child: Column(
                children: [
                  BlockWidget(
                    block: pathBlock,
                    onBlockDropped: (targetId, draggedId) => model.reorderBlock(targetId, draggedId),
                    onRenameBlock: (blockToRename) => _showRenameDialog(context, blockToRename),
                  ),
                  const ConnectionLine(),
                  AddButton(
                    parentBlockId: pathBlock.id,
                    onBlockDropped: (parentId, draggedId) => model.reorderBlock(parentId, draggedId),
                    onAddBlock: (parentId) => _showAddBlockDialog(context, parentId),
                  ),
                ],
              ),
            ),
          );
        }

        workflowWidgets.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: pathColumns,
          ),
        );

        i += pathsParentBlock.childrenIds.length;
      } else {
        workflowWidgets.add(
          BlockWidget(
            block: block,
            onBlockDropped: (targetId, draggedId) => model.reorderBlock(targetId, draggedId),
            onRenameBlock: (blockToRename) => _showRenameDialog(context, blockToRename),
          ),
        );
        workflowWidgets.add(const ConnectionLine());
        workflowWidgets.add(
          AddButton(
            parentBlockId: block.id,
            onBlockDropped: (parentId, draggedId) => model.reorderBlock(parentId, draggedId),
            onAddBlock: (parentId) => _showAddBlockDialog(context, parentId),
          ),
        );
      }
      i++;
    }
    return workflowWidgets;
  }

  void _showAddBlockDialog(BuildContext context, String parentId) {
    final model = Provider.of<WorkflowModel>(context, listen: false);
    final parentBlock = model.getBlockById(parentId);

    if (parentBlock?.type == 'paths') {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Adicionar Novo Caminho'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  title: const Text('Adicionar Caminho ao Lado'),
                  onTap: () {
                    model.addAnotherPath(parentId);
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            ),
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Adicionar'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(blockIcons['action']),
                  title: const Text('Ação'),
                  onTap: () {
                    model.addBlockAfter(parentId, 'Nova Ação', 'action');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(blockIcons['paths']),
                  title: const Text('Caminho'),
                  onTap: () {
                    model.addPathsAfter(parentId);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(blockIcons['delay']),
                  title: const Text('Atraso'),
                  onTap: () {
                    model.addBlockAfter(parentId, 'Atraso', 'delay');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(blockIcons['email']),
                  title: const Text('E-mail'),
                  onTap: () {
                    model.addBlockAfter(parentId, 'Enviar E-mail', 'email');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(blockIcons['webhook']),
                  title: const Text('Webhook'),
                  onTap: () {
                    model.addBlockAfter(parentId, 'Disparar Webhook', 'webhook');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        },
      );
    }
  }

  void _showRenameDialog(BuildContext context, WorkflowBlock block) {
    final model = Provider.of<WorkflowModel>(context, listen: false);
    final controller = TextEditingController(text: block.title);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Renomear Bloco'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Novo Título'),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Renomear'),
              onPressed: () {
                model.renameBlock(block.id, controller.text);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

// ---------------- Bloco ----------------

class BlockWidget extends StatelessWidget {
  final WorkflowBlock block;
  final Function(String targetId, String draggedId) onBlockDropped;
  final Function(WorkflowBlock) onRenameBlock;
  final double width;

  const BlockWidget({
    super.key,
    required this.block,
    required this.onBlockDropped,
    required this.onRenameBlock,
    this.width = 220,
  });

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<WorkflowModel>(context, listen: false);
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
    final model = Provider.of<WorkflowModel>(context, listen: false);

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
                    model.duplicateBlock(block.id);
                  } else if (value == 'delete') {
                    model.removeBlock(block.id);
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

// ---------------- Linha ----------------

class ConnectionLine extends StatelessWidget {
  final double height;
  final bool isBranching;

  const ConnectionLine({
    super.key,
    this.height = 50,
    this.isBranching = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: isBranching ? BranchingLinePainter() : StraightLinePainter(),
        size: Size(double.infinity, height),
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
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width / 2, size.height / 2);
    path.lineTo(0, size.height / 2);
    path.lineTo(size.width, size.height / 2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

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