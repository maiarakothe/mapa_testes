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
  final TransformationController _transformationController = TransformationController();

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
            // pega a largura e altura total, porém o bloco sempre fica colado no lado esquerdo
            // child: IntrinsicWidth(
            //   child: IntrinsicHeight(
            //     child: Column( crossAxisAlignment: CrossAxisAlignment.center,
            //       children: _buildLayout(context, model.rootBlock),
            //     ),
            //   ),
            // ),
            child: SizedBox(
             // colocada uma largura fixa por enquanto
              width: 3000,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: _buildLayout(context, model.rootBlock),
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
    _transformationController.value = Matrix4.identity()
      ..scale(newScale);
  }

  void _zoomOut() {
    final Matrix4 currentMatrix = _transformationController.value;
    final double scale = currentMatrix.storage[0];
    final double newScale = (scale / 1.2).clamp(0.1, 2.0);
    _transformationController.value = Matrix4.identity()
      ..scale(newScale);
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
        // Se for um bloco 'paths', renderiza os filhos em uma Row
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
                  children: _buildLayout(context, childBlock),
                ),
              );
            }).toList(),
          ),
        );
      } else {
        // Para outros blocos, renderiza os filhos em uma Column
        widgets.add(const ConnectionLine());
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