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

// ---------------- Modelo ----------------

class WorkflowModel extends ChangeNotifier {
  final WorkflowBlock _rootBlock = WorkflowBlock(
    id: 'start',
    title: 'Trigger',
    subtitle: 'Início do fluxo',
    type: 'trigger',
  );

  WorkflowBlock get rootBlock => _rootBlock;

  BlockLocation? findBlockAndParent(String id, WorkflowBlock? startNode, {WorkflowBlock? parent}) {
    if (startNode == null) return null;
    if (startNode.id == id) {
      return BlockLocation(block: startNode, parent: parent, index: parent?.children.indexOf(startNode) ?? 0);
    }
    for (int i = 0; i < startNode.children.length; i++) {
      final found = findBlockAndParent(id, startNode.children[i], parent: startNode);
      if (found != null) return found;
    }
    return null;
  }

  void addBlockAsChild(String parentId, String title, String type, {String subtitle = 'Adicionado dinamicamente'}) {
    final parentBlock = findBlockAndParent(parentId, _rootBlock)?.block;
    if (parentBlock == null) return;

    final newBlock = WorkflowBlock(
      id: uuid.v4(),
      title: title,
      subtitle: subtitle,
      type: type,
    );

    parentBlock.children.add(newBlock);
    notifyListeners();
  }

  void addPaths(String parentId) {
    final parentBlock = findBlockAndParent(parentId, _rootBlock)?.block;
    if (parentBlock == null) return;

    final pathsBlock = WorkflowBlock(
      id: uuid.v4(),
      title: 'Caminhos',
      subtitle: 'Divida em múltiplos caminhos',
      type: 'paths',
    );

    final pathA = WorkflowBlock(
      id: uuid.v4(),
      title: 'Caminho A',
      subtitle: 'Filho A',
      type: 'path',
    );

    final pathB = WorkflowBlock(
      id: uuid.v4(),
      title: 'Caminho B',
      subtitle: 'Filho B',
      type: 'path',
    );

    pathsBlock.children.add(pathA);
    pathsBlock.children.add(pathB);

    parentBlock.children.add(pathsBlock);
    notifyListeners();
  }

  void addAnotherPath(String pathsBlockId) {
    final pathsBlock = findBlockAndParent(pathsBlockId, _rootBlock)?.block;
    if (pathsBlock == null) return;

    final newPathBlock = WorkflowBlock(
      id: uuid.v4(),
      title: 'Caminho ${String.fromCharCode(65 + pathsBlock.children.length)}',
      subtitle: 'Novo Caminho',
      type: 'path',
    );

    pathsBlock.children.add(newPathBlock);
    notifyListeners();
  }

  void reorderBlock(String targetId, String draggedId) {
    if (targetId == draggedId) return;

    final draggedLocation = findBlockAndParent(draggedId, _rootBlock);
    final targetLocation = findBlockAndParent(targetId, _rootBlock);

    if (draggedLocation == null || targetLocation == null) return;
    if (draggedLocation.parent == null) return; // Não permite reordenar o bloco raiz

    final draggedBlock = draggedLocation.block;
    final draggedParent = draggedLocation.parent!;
    final draggedIndex = draggedParent.children.indexOf(draggedBlock);

    // Remove o bloco arrastado da sua posição original
    draggedParent.children.removeAt(draggedIndex);

    // Adiciona o bloco arrastado na nova posição
    final newParent = targetLocation.parent ?? _rootBlock;
    final newIndex = newParent.children.indexOf(targetLocation.block);

    // Adicionar a lógica para o caso de o target ser o 'paths'
    if (newParent.type == 'paths') {
      newParent.children.insert(newIndex + 1, draggedBlock);
    } else {
      // Caso de o target ser um bloco normal
      newParent.children.insert(newIndex + 1, draggedBlock);
    }

    notifyListeners();
  }

  void removeBlock(String id) {
    final location = findBlockAndParent(id, _rootBlock);
    if (location == null || location.parent == null) return;

    location.parent!.children.remove(location.block);
    notifyListeners();
  }

  void renameBlock(String id, String newTitle) {
    final block = findBlockAndParent(id, _rootBlock)?.block;
    if (block == null) return;

    block.title = newTitle;
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: _buildLayout(context, model.rootBlock),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Função recursiva para construir o layout
  List<Widget> _buildLayout(BuildContext context, WorkflowBlock block) {
    final List<Widget> widgets = [];
    final model = Provider.of<WorkflowModel>(context, listen: false);

    widgets.add(BlockWidget(
      block: block,
      onRenameBlock: (blockToRename) => _showRenameDialog(context, blockToRename),
      onBlockDropped: (targetId, draggedId) => model.reorderBlock(targetId, draggedId),
      onRemoveBlock: (id) => model.removeBlock(id),
    ));

    // Renderiza a linha de conexão e o botão de adicionar
    widgets.add(const ConnectionLine());
    widgets.add(
      AddButton(
        parentBlockId: block.id,
        onAddBlock: (parentId) => _showAddBlockDialog(context, parentId),
        onBlockDropped: (parentId, draggedId) => model.reorderBlock(parentId, draggedId),
      ),
    );

    // Renderiza os filhos
    if (block.children.isNotEmpty) {
      if (block.type == 'paths') {
        widgets.add(const ConnectionLine(isBranching: true));
        // Se for um bloco 'paths', renderiza os filhos em uma Row
        widgets.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: block.children.map((childBlock) {
              return Expanded(
                child: Column(
                  children: _buildLayout(context, childBlock),
                ),
              );
            }).toList(),
          ),
        );
      } else {
        // Para outros blocos, renderiza os filhos em uma Column
        for (var childBlock in block.children) {
          widgets.addAll(_buildLayout(context, childBlock));
        }
      }
    }
    return widgets;
  }

  void _showAddBlockDialog(BuildContext context, String parentId) {
    final model = Provider.of<WorkflowModel>(context, listen: false);
    final parentBlock = model.findBlockAndParent(parentId, model.rootBlock)?.block;

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
                  leading: const Icon(Icons.subdirectory_arrow_right, color: Colors.purple),
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
                    model.addBlockAsChild(parentId, 'Nova Ação', 'action');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(blockIcons['paths']),
                  title: const Text('Caminho'),
                  onTap: () {
                    model.addPaths(parentId);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(blockIcons['delay']),
                  title: const Text('Atraso'),
                  onTap: () {
                    model.addBlockAsChild(parentId, 'Atraso', 'delay');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(blockIcons['email']),
                  title: const Text('E-mail'),
                  onTap: () {
                    model.addBlockAsChild(parentId, 'Enviar E-mail', 'email');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(blockIcons['webhook']),
                  title: const Text('Webhook'),
                  onTap: () {
                    model.addBlockAsChild(parentId, 'Disparar Webhook', 'webhook');
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
                    //model.duplicateBlock(block.id);
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