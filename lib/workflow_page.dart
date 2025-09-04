import 'package:flutter/material.dart';
import 'package:mapa_testes/workflow_model.dart';
import 'package:provider/provider.dart';

import 'add_button.dart';
import 'block_widget.dart';
import 'connection_line.dart';
import 'data.dart';
import 'main.dart';

// ---------------- UI ----------------

class WorkflowPage extends StatefulWidget {
  const WorkflowPage({super.key});

  @override
  State<WorkflowPage> createState() => _WorkflowPageState();
}

class _WorkflowPageState extends State<WorkflowPage> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocos Dinâmicos',
            style: TextStyle(color: Colors.white)),
        backgroundColor: DefaultColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in, color: Colors.white),
            onPressed: _zoomIn,
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out, color: Colors.white),
            onPressed: _zoomOut,
          ),
        ],
      ),
      body: Consumer<WorkflowModel>(
        builder: (context, model, _) {
          return InteractiveViewer(
            scaleEnabled: true,
            panEnabled: true,
            transformationController: _transformationController,
            constrained: false,
            boundaryMargin: const EdgeInsets.all(100),
            minScale: 0.1,
            maxScale: 2.0,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width,
              ),
              child: IntrinsicWidth(
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      children: _buildLayout(
                        context,
                        model.rootBlock,
                        allowLeafFenda: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    final Matrix4 currentMatrix = _transformationController.value;
    final double scale = currentMatrix.storage[0];
    final double newScale = (scale * 1.2).clamp(0.1, 2.0);
    _transformationController.value = Matrix4.identity()..scale(newScale);
  }

  void _zoomOut() {
    final Matrix4 currentMatrix = _transformationController.value;
    final double scale = currentMatrix.storage[0];
    final double newScale = (scale / 1.2).clamp(0.1, 2.0);
    _transformationController.value = Matrix4.identity()..scale(newScale);
  }

  // Função recursiva para construir o layout
  List<Widget> _buildLayout(BuildContext context, WorkflowBlock block,
      {bool allowLeafFenda = false}) {
    final List<Widget> widgets = [];
    final model = Provider.of<WorkflowModel>(context, listen: false);

    widgets.add(BlockWidget(
      block: block,
      onRenameBlock: (blockToRename) =>
          _showRenameDialog(context, blockToRename),
      onBlockDropped: (targetId, draggedId) =>
          model.reorderBlock(targetId, draggedId),
      onRemoveBlock: (id) => model.removeBlock(id),
      onDuplicateBlock: (id) => model.duplicateBlock(id),
    ));

    // 'paths'
    if (block.type == 'paths') {
      widgets.add(const ConnectionLine());

      widgets.add(
        Center(
          child: AddButton(
            parentBlockId: block.id,
            insertIndex: block.children.length,
            onAddBlock: (parentId, insertIndex) {
              model.addAnotherPath(parentId);
            },
            onBlockDropped: (parentId, draggedId, insertIndex) {
              model.moveBlockTo(parentId, draggedId, insertIndex);
            },
          ),
        ),
      );

      widgets.add(const ConnectionLine());

      widgets.add(
        SizedBox(
          height: 50,
          child: CustomPaint(
            painter: BranchingLinePainter(numChildren: block.children.length),
            child: Container(),
          ),
        ),
      );

      widgets.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: block.children.map((childBlock) {
            return Expanded(
              child: Column(
                children: [
                  // Renderiza o próprio caminho das fendas
                  ..._buildLayout(context, childBlock, allowLeafFenda: true),
                ],
              ),
            );
          }).toList(),
        ),
      );

      return widgets;
    }

    final children = block.children;

    // Linha do bloco atual para a área dos filhos
    widgets.add(const ConnectionLine());

    // Sem filhos: mostra a fenda de folha somente se permitido
    if (children.isEmpty) {
      if (allowLeafFenda) {
        widgets.add(
          AddButton(
            parentBlockId: block.id,
            insertIndex: 0,
            onAddBlock: (parentId, insertIndex) =>
                _showAddBlockDialog(context, parentId, insertIndex),
            onBlockDropped: (parentId, draggedId, insertIndex) =>
                model.moveBlockTo(parentId, draggedId, insertIndex),
          ),
        );
      }
      return widgets;
    }

    // Com filhos: para cada filho, renderizar:
    //  AddButton(i) -> ConnectionLine -> child[i] -> ConnectionLine
    for (int i = 0; i < children.length; i++) {
      // Fenda do pai ANTES do filho i
      widgets.add(
        AddButton(
          parentBlockId: block.id,
          insertIndex: i,
          onAddBlock: (parentId, insertIndex) =>
              _showAddBlockDialog(context, parentId, insertIndex),
          onBlockDropped: (parentId, draggedId, insertIndex) =>
              model.moveBlockTo(parentId, draggedId, insertIndex),
        ),
      );

      // Linha da fenda até o filho
      widgets.add(const ConnectionLine());

      widgets.addAll(
        _buildLayout(context, children[i],
            allowLeafFenda: children[i].type == 'paths' ? false : false),
      );

      if (children[i].type != 'paths') {
        widgets.add(const ConnectionLine());
      }
    }

    // Fenda final (após o último filho)
    if (children.isEmpty || children.last.type != 'paths') {
      widgets.add(
        AddButton(
          parentBlockId: block.id,
          insertIndex: children.length,
          onAddBlock: (parentId, insertIndex) =>
              _showAddBlockDialog(context, parentId, insertIndex),
          onBlockDropped: (parentId, draggedId, insertIndex) =>
              model.moveBlockTo(parentId, draggedId, insertIndex),
        ),
      );
    }

    return widgets;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showAddBlockDialog(
      BuildContext context, String parentId, int insertIndex) {
    final model = Provider.of<WorkflowModel>(context, listen: false);
    final parentBlock =
        model.findBlockAndParent(parentId, model.rootBlock)?.block;

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
                  leading: const Icon(Icons.subdirectory_arrow_right,
                      color: Colors.purple),
                  title: const Text('Adicionar Caminho ao Lado'),
                  onTap: () {
                    model.addAnotherPath(parentId);
                    Navigator.of(dialogContext).pop();
                    _showSnackBar('Novo caminho adicionado ao lado!');
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
                    model.addBlockAsChild(parentId, 'Nova Ação', 'action',
                        insertIndex: insertIndex);
                    Navigator.pop(context);
                    _showSnackBar('Bloco "Nova Ação" adicionado!');
                  },
                ),
                ListTile(
                  leading: Icon(blockIcons['paths']),
                  title: const Text('Caminho'),
                  onTap: () {
                    model.addPaths(parentId, insertIndex: insertIndex);
                    Navigator.pop(context);
                    _showSnackBar('Bloco "Caminhos" adicionado!');
                  },
                ),
                ListTile(
                  leading: Icon(blockIcons['delay']),
                  title: const Text('Atraso'),
                  onTap: () {
                    model.addBlockAsChild(parentId, 'Atraso', 'delay',
                        insertIndex: insertIndex);
                    Navigator.pop(context);
                    _showSnackBar('Bloco "Atraso" adicionado!');
                  },
                ),
                ListTile(
                  leading: Icon(blockIcons['email']),
                  title: const Text('E-mail'),
                  onTap: () {
                    model.addBlockAsChild(parentId, 'Enviar E-mail', 'email',
                        insertIndex: insertIndex);
                    Navigator.pop(context);
                    _showSnackBar('Bloco "Enviar E-mail" adicionado!');
                  },
                ),
                ListTile(
                  leading: Icon(blockIcons['webhook']),
                  title: const Text('Webhook'),
                  onTap: () {
                    model.addBlockAsChild(
                        parentId, 'Disparar Webhook', 'webhook',
                        insertIndex: insertIndex);
                    Navigator.pop(context);
                    _showSnackBar('Bloco "Disparar Webhook" adicionado!');
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
