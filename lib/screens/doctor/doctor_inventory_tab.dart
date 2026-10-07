import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';

class DoctorInventoryTab extends StatefulWidget {
  final AppState state;

  const DoctorInventoryTab({super.key, required this.state});

  @override
  State<DoctorInventoryTab> createState() => _DoctorInventoryTabState();
}

class _DoctorInventoryTabState extends State<DoctorInventoryTab> {
  String _selectedCategory = 'Todos';
  final List<String> _categories = [
    'Todos',
    'Anestésicos',
    'Restauración',
    'Descartables',
    'Ortodoncia',
    'Impresión',
  ];

  @override
  Widget build(BuildContext context) {
    final items = _selectedCategory == 'Todos'
        ? widget.state.inventory
        : widget.state.inventory
            .where((i) => i.category == _selectedCategory)
            .toList();

    final lowStockCount =
        widget.state.inventory.where((i) => i.isLowStock).length;

    final dateFormat = DateFormat('MM/yy');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Inventario',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Insumos y Material Dental',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  // Critical items pill
                  if (lowStockCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warningBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.warningOrange.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 15,
                            color: AppTheme.warningOrange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$lowStockCount stock bajo',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),

              // Categories Carousel
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = cat == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryBlue
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryBlue
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : AppTheme.softShadow,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),

              // Supplies List
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: AppTheme.softShadow,
                        border: Border.all(
                          color: item.isLowStock
                              ? AppTheme.warningOrange.withValues(alpha: 0.5)
                              : Colors.grey.shade100,
                          width: item.isLowStock ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              if (item.isLowStock)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.warningBg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Reabastecer',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.warningOrange,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.category} • Lote: ${item.batch} • Vence: ${dateFormat.format(item.expiryDate)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '${item.currentStock}',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: item.isLowStock
                                              ? AppTheme.warningOrange
                                              : AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        item.unit,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Mínimo recomendado: ${item.minStock}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton.filledTonal(
                                    onPressed: () {
                                      widget.state.updateStock(item.id, -1);
                                    },
                                    icon: const Icon(Icons.remove_rounded),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.grey.shade100,
                                      foregroundColor: AppTheme.textPrimary,
                                      padding: const EdgeInsets.all(8),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton.filledTonal(
                                    onPressed: () {
                                      widget.state.updateStock(item.id, 1);
                                    },
                                    icon: const Icon(Icons.add_rounded),
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppTheme.primaryBlue
                                          .withValues(alpha: 0.1),
                                      foregroundColor: AppTheme.primaryBlue,
                                      padding: const EdgeInsets.all(8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
