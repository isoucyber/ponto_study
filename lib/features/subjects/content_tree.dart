import '../../core/database/database.dart';

// ============================================================
// ARQUIVO: lib/features/subjects/content_tree.dart
// FUNÇÃO: Transforma a lista "plana" de itens do banco em árvore:
//         ordem de exibição, profundidade de cada item e descendentes.
//         Não acessa o banco (é testado em test/content_tree_test.dart).
// ============================================================

/// Um item da árvore pronto para exibir.
class TreeEntry {
  final ContentNode node;
  final int depth;
  final bool hasChildren;
  const TreeEntry(this.node, this.depth, this.hasChildren);
}

/// Nome do nível conforme a profundidade.
String levelLabel(int depth) {
  switch (depth) {
    case 0:
      return 'Assunto';
    case 1:
      return 'Tópico';
    default:
      return 'Subtópico';
  }
}

/// Lista na ordem de exibição (pai, depois filhos), respeitando a
/// posição definida pelo usuário. Itens em [collapsed] escondem os filhos.
List<TreeEntry> flattenTree(List<ContentNode> nodes,
    {Set<int> collapsed = const {}}) {
  final byParent = <int?, List<ContentNode>>{};
  for (final n in nodes) {
    byParent.putIfAbsent(n.parentId, () => []).add(n);
  }
  for (final list in byParent.values) {
    list.sort((a, b) {
      final c = a.position.compareTo(b.position);
      return c != 0 ? c : a.id.compareTo(b.id);
    });
  }
  final result = <TreeEntry>[];
  final visited = <int>{};

  void visit(int? parentId, int depth) {
    for (final n in byParent[parentId] ?? const <ContentNode>[]) {
      if (!visited.add(n.id)) continue; // proteção contra ciclos
      final children = byParent[n.id] ?? const [];
      result.add(TreeEntry(n, depth, children.isNotEmpty));
      if (!collapsed.contains(n.id)) visit(n.id, depth + 1);
    }
  }

  visit(null, 0);
  return result;
}

/// Ids de todos os descendentes (filhos, netos...) de [id].
Set<int> descendantIds(List<ContentNode> nodes, int id) {
  final result = <int>{};
  var frontier = [id];
  while (frontier.isNotEmpty) {
    final next = <int>[];
    for (final n in nodes) {
      if (n.parentId != null &&
          frontier.contains(n.parentId) &&
          result.add(n.id)) {
        next.add(n.id);
      }
    }
    frontier = next;
  }
  return result;
}

/// Caminho legível: "Estruturas de repetição › for › for aninhado".
String nodePath(List<ContentNode> nodes, int id) {
  final byId = {for (final n in nodes) n.id: n};
  final parts = <String>[];
  int? current = id;
  var guard = 0;
  while (current != null && guard++ < 50) {
    final n = byId[current];
    if (n == null) break;
    parts.insert(0, n.name);
    current = n.parentId;
  }
  return parts.join(' › ');
}
