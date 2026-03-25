import 'package:flutter_riverpod/flutter_riverpod.dart';

enum InventoryStatus { pending, accepted, short, over }

class DailyInventory {
  final int assignedAid;
  final int? receivedAid;
  final int returnedAid;
  final InventoryStatus status;

  DailyInventory({
    this.assignedAid = 100, // Mock NGO Assignment
    this.receivedAid,
    this.returnedAid = 0,
    this.status = InventoryStatus.pending,
  });

  DailyInventory copyWith({
    int? assignedAid,
    int? receivedAid,
    int? returnedAid,
    InventoryStatus? status,
  }) {
    return DailyInventory(
      assignedAid: assignedAid ?? this.assignedAid,
      receivedAid: receivedAid ?? this.receivedAid,
      returnedAid: returnedAid ?? this.returnedAid,
      status: status ?? this.status,
    );
  }
}

class InventoryNotifier extends StateNotifier<DailyInventory> {
  InventoryNotifier() : super(DailyInventory());

  void acceptAll() {
    state = state.copyWith(
      receivedAid: state.assignedAid,
      status: InventoryStatus.accepted,
    );
  }

  void reportDiscrepancy(int actualReceived, InventoryStatus newStatus) {
    state = state.copyWith(
      receivedAid: actualReceived,
      status: newStatus,
    );
  }

  void recordReturn(int amount) {
    state = state.copyWith(returnedAid: amount);
  }
}

final inventoryProvider = StateNotifierProvider<InventoryNotifier, DailyInventory>((ref) {
  return InventoryNotifier();
});
