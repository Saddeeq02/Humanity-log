import 'package:flutter_riverpod/flutter_riverpod.dart';

enum InventoryStatus { pending, in_progress, accepted, short, over, reconciling, completed, suspended }

class InventoryItemStock {
  final String inventoryId;
  final String name;
  final int assigned;
  final int distributed;
  final int returned;

  InventoryItemStock({
    required this.inventoryId,
    required this.name,
    required this.assigned,
    this.distributed = 0,
    this.returned = 0,
  });

  InventoryItemStock copyWith({
    int? distributed,
    int? returned,
  }) {
    return InventoryItemStock(
      inventoryId: inventoryId,
      name: name,
      assigned: assigned,
      distributed: distributed ?? this.distributed,
      returned: returned ?? this.returned,
    );
  }
}

class DailyInventory {
  final String? assignmentId;
  final List<InventoryItemStock> items;
  final InventoryStatus status;

  DailyInventory({
    this.assignmentId,
    this.items = const [],
    this.status = InventoryStatus.pending,
  });

  DailyInventory copyWith({
    String? assignmentId,
    List<InventoryItemStock>? items,
    InventoryStatus? status,
  }) {
    return DailyInventory(
      assignmentId: assignmentId ?? this.assignmentId,
      items: items ?? this.items,
      status: status ?? this.status,
    );
  }

  int get totalAssigned => items.fold(0, (sum, item) => sum + item.assigned);
  int get totalDistributed => items.fold(0, (sum, item) => sum + item.distributed);
  int get totalReturned => items.fold(0, (sum, item) => sum + item.returned);
}

class InventoryNotifier extends StateNotifier<DailyInventory> {
  InventoryNotifier() : super(DailyInventory());

  void updateFromAssignment(String id, List<dynamic> itemsJson, String statusStr) {
    final List<InventoryItemStock> items = itemsJson.map((item) => InventoryItemStock(
      inventoryId: item['inventory_id'],
      name: item['name'],
      assigned: item['quantity'],
    )).toList();

    InventoryStatus status = InventoryStatus.pending;
    if (statusStr == 'in_progress' || statusStr == 'active') status = InventoryStatus.in_progress;
    if (statusStr == 'accepted') status = InventoryStatus.accepted;
    if (statusStr == 'reconciling') status = InventoryStatus.reconciling;
    if (statusStr == 'completed') status = InventoryStatus.completed;
    if (statusStr == 'suspended') status = InventoryStatus.suspended;

    state = DailyInventory(
      assignmentId: id,
      items: items,
      status: status,
    );
  }

  void acceptAll() {
    state = state.copyWith(status: InventoryStatus.accepted);
  }

  void updateDistributedCount(String inventoryId, int count) {
    state = state.copyWith(
      items: state.items.map((item) => 
        item.inventoryId == inventoryId ? item.copyWith(distributed: count) : item
      ).toList()
    );
  }

  void recordReturn(String inventoryId, int amount) {
    state = state.copyWith(
      items: state.items.map((item) => 
        item.inventoryId == inventoryId ? item.copyWith(returned: amount) : item
      ).toList()
    );
  }
}

final inventoryProvider = StateNotifierProvider<InventoryNotifier, DailyInventory>((ref) {
  return InventoryNotifier();
});
