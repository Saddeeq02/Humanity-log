import 'package:flutter_riverpod/flutter_riverpod.dart';

enum InventoryStatus { pending, accepted, short, over }

class DailyInventory {
  final String? assignmentId; // Added to track current mission
  final int assignedAid;
  final int? receivedAid;
  final int returnedAid;
  final InventoryStatus status;

  DailyInventory({
    this.assignmentId,
    this.assignedAid = 0,
    this.receivedAid,
    this.returnedAid = 0,
    this.status = InventoryStatus.pending,
  });

  DailyInventory copyWith({
    String? assignmentId,
    int? assignedAid,
    int? receivedAid,
    int? returnedAid,
    InventoryStatus? status,
  }) {
    return DailyInventory(
      assignmentId: assignmentId ?? this.assignmentId,
      assignedAid: assignedAid ?? this.assignedAid,
      receivedAid: receivedAid ?? this.receivedAid,
      returnedAid: returnedAid ?? this.returnedAid,
      status: status ?? this.status,
    );
  }
}

class InventoryNotifier extends StateNotifier<DailyInventory> {
  InventoryNotifier() : super(DailyInventory());

  void updateFromAssignment(String id, int totalAllocated) {
    state = state.copyWith(assignmentId: id, assignedAid: totalAllocated);
  }

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
