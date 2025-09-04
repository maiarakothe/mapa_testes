import 'package:flutter/material.dart';
import 'package:mapa_testes/workflow_model.dart';
import 'package:provider/provider.dart';
import 'data.dart';
import 'main.dart';

// ---------------- Botão Adicionar ----------------

class AddButton extends StatefulWidget {
  final String parentBlockId;
  final int insertIndex;
  final Function(String parentId, String draggedId, int insertIndex)
      onBlockDropped;
  final Function(String parentId, int insertIndex) onAddBlock;

  const AddButton({
    super.key,
    required this.parentBlockId,
    required this.insertIndex,
    required this.onBlockDropped,
    required this.onAddBlock,
  });

  @override
  State<AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<AddButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<WorkflowModel>(context, listen: false);

    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        setState(() {
          _isHovering = false;
        });
        widget.onBlockDropped(
            widget.parentBlockId, details.data, widget.insertIndex);
      },
      onWillAcceptWithDetails: (data) {
        setState(() {
          _isHovering = true;
        });
        return true;
      },
      onLeave: (data) {
        setState(() {
          _isHovering = false;
        });
      },
      builder: (context, candidateData, rejectedData) {
        final isDraggingOver = candidateData.isNotEmpty;

        // Se um bloco está sendo arrastado por cima, mostra um bloco fantasma
        if (isDraggingOver) {
          final draggedId = candidateData.first;
          final draggedBlock =
              model.findBlockAndParent(draggedId!, model.rootBlock)?.block;

          if (draggedBlock != null) {
            final blockColor = blockColors[draggedBlock.type] ?? Colors.grey;
            return Opacity(
              opacity: 0.15,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 290,
                    height: 95,
                    margin: const EdgeInsets.symmetric(vertical: 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: blockColor, width: 2),
                    ),
                  ),
                  Icon(
                    Icons.check_circle_outline,
                    color: blockColor,
                    size: 48,
                  ),
                ],
              ),
            );
          }
        }
        return MouseRegion(
          onEnter: (event) {
            setState(() {
              _isHovering = true;
            });
          },
          onExit: (event) {
            setState(() {
              _isHovering = false;
            });
          },
          child: Tooltip(
            message: 'Adicionar passo',
            child: GestureDetector(
              onTap: () {
                widget.onAddBlock(widget.parentBlockId, widget.insertIndex);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeIn,
                margin: const EdgeInsets.symmetric(vertical: 5),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _isHovering
                      ? DefaultColors.primary
                      : DefaultColors.secondary,
                  borderRadius: BorderRadius.circular(_isHovering ? 12 : 20),
                  boxShadow: [
                    BoxShadow(
                      color: _isHovering
                          // ignore: deprecated_member_use
                          ? DefaultColors.primary.withOpacity(0.4)
                          : Colors.transparent,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
