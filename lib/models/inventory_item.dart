import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory InventoryItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return InventoryItem(
      id: doc.id,
      name: d['name'] ?? '',
      category: d['category'] ?? '',
      currentStock: (d['currentStock'] ?? 0) as int,
      minStock: (d['minStock'] ?? 0) as int,
      unit: d['unit'] ?? '',
      batch: d['batch'] ?? '',
      expiryDate: (d['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'category': category,
    'currentStock': currentStock,
    'minStock': minStock,
    'unit': unit,
    'batch': batch,
    'expiryDate': Timestamp.fromDate(expiryDate),
  };

  bool get isLowStock => currentStock <= minStock;
  bool get isCritical => currentStock <= (minStock * 0.5);
}
