class InventoryItem {
  final String id;
  final String name;
  final String category;
  int currentStock;
  final int minStock;
  final String unit;
  final String batch;
  final DateTime expiryDate;

  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.currentStock,
    required this.minStock,
    required this.unit,
    required this.batch,
    required this.expiryDate,
  });

  bool get isLowStock => currentStock <= minStock;
  bool get isCritical => currentStock <= (minStock * 0.5);
}
