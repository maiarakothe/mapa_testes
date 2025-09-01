import 'package:flutter/material.dart';

import 'data.dart';

// ---------------- Modelo ----------------

class WorkflowModel extends ChangeNotifier {
  final WorkflowBlock _rootBlock = WorkflowBlock(
    id: 'start',
    title: 'Trigger',
    subtitle: 'Início do fluxo',
    type: 'trigger',
  );

  WorkflowBlock get rootBlock => _rootBlock;

  BlockLocation? findBlockAndParent(String id, WorkflowBlock? startNode,
      {WorkflowBlock? parent}) {
    if (startNode == null) return null;
    if (startNode.id == id) {
      return BlockLocation(
          block: startNode,
          parent: parent,
          index: parent?.children.indexOf(startNode) ?? 0);
    }
    for (int i = 0; i < startNode.children.length; i++) {
      final found =
          findBlockAndParent(id, startNode.children[i], parent: startNode);
      if (found != null) return found;
    }
    return null;
  }

  void addBlockAsChild(String parentId, String title, String type,
      {String subtitle = 'Adicionado dinamicamente', int? insertIndex}) {
    final parentBlock = findBlockAndParent(parentId, _rootBlock)?.block;
    if (parentBlock == null) return;

    if (parentBlock.type == 'paths' && type != 'path') {
      return;
    }

    final newBlock = WorkflowBlock(
      id: uuid.v4(),
      title: title,
      subtitle: subtitle,
      type: type,
    );

    final idx = (insertIndex == null)
        ? parentBlock.children.length
        : insertIndex.clamp(0, parentBlock.children.length);

    parentBlock.children.insert(idx, newBlock);
    notifyListeners();
  }

  // Mover bloco arrastado para um parent específico, em um índice específico
  void moveBlockTo(String parentId, String draggedId, int insertIndex) {
    final draggedLocation = findBlockAndParent(draggedId, _rootBlock);
    if (draggedLocation == null || draggedLocation.parent == null) return;

    final newParent = findBlockAndParent(parentId, _rootBlock)?.block;
    if (newParent == null) {
      return;
    }

    final draggedBlock = draggedLocation.block;
    final oldParent = draggedLocation.parent!;
    int oldIndex = oldParent.children.indexOf(draggedBlock);

    if (draggedBlock.type == 'path' && newParent.type != 'paths') {
      return;
    }
    if (newParent.type == 'paths' && draggedBlock.type != 'path') {
      return;
    }

    oldParent.children.removeAt(oldIndex);

    int targetIndex = insertIndex;
    if (oldParent.id == newParent.id && oldIndex < insertIndex) {
      targetIndex = insertIndex - 1;
    }

    targetIndex = targetIndex.clamp(0, newParent.children.length);
    newParent.children.insert(targetIndex, draggedBlock);
    notifyListeners();
  }

  void addPaths(String parentId, {int? insertIndex}) {
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

    pathsBlock.children.addAll([pathA, pathB]);

    final idx = (insertIndex == null)
        ? parentBlock.children.length
        : insertIndex.clamp(0, parentBlock.children.length);

    parentBlock.children.insert(idx, pathsBlock);
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
    if (draggedLocation.parent == null) {
      return; // Não permite reordenar o bloco raiz
    }

    final draggedBlock = draggedLocation.block;
    final draggedParent = draggedLocation.parent!;
    final draggedIndex = draggedParent.children.indexOf(draggedBlock);
    final newParent = targetLocation.parent ?? _rootBlock;

    // Impede o movimento de um 'caminho' para fora de um 'caminhoS'
    if (draggedBlock.type == 'path' && newParent.type != 'paths') {
      return;
    }

    //  Impede que um bloco que NÃO seja 'caminho' se torne filho de um 'caminhoS'
    if (newParent.type == 'paths' && draggedBlock.type != 'path') {
      return;
    }

    // Remove o bloco arrastado da sua posição original
    draggedParent.children.removeAt(draggedIndex);

    // Adiciona o bloco arrastado na nova posição
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

    if (location.block.type == 'paths') {
      location.parent!.children.remove(location.block);
    } else {
      final parentChildren = location.parent!.children;
      final blockToRemove = location.block;
      final index = parentChildren.indexOf(blockToRemove);

      parentChildren.removeAt(index);
      if (blockToRemove.children.isNotEmpty) {
        parentChildren.insertAll(index, blockToRemove.children);
      }
    }

    notifyListeners();
  }

  void renameBlock(String id, String newTitle) {
    final block = findBlockAndParent(id, _rootBlock)?.block;
    if (block == null) return;

    block.title = newTitle;
    notifyListeners();
  }
}
