import 'package:flutter/material.dart';
import 'main.dart';

// ---------------- Botão Adicionar ----------------

class AddButton extends StatefulWidget {
  final String parentBlockId;
  final int insertIndex;
  final Function(String parentId, String draggedId, int insertIndex) onBlockDropped;
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
    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        widget.onBlockDropped(widget.parentBlockId, details.data, widget.insertIndex);
      },
      builder: (context, candidateData, rejectedData) {
        final isDraggingOver = candidateData.isNotEmpty;
        final isInteractive = isDraggingOver || _isHovering;
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
                margin: const EdgeInsets.symmetric(vertical: 0),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isInteractive
                      ? DefaultColors.primary : DefaultColors.secondary,
                  borderRadius: BorderRadius.circular(isInteractive ? 12 : 20),
                  boxShadow: [
                    BoxShadow(
                      color: isInteractive
                          // ignore: deprecated_member_use
                          ? (isDraggingOver ? DefaultColors.primary: DefaultColors.secondary).withOpacity(0.4)
                          : Colors.transparent,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ),
        );
      },
    );
  }
}