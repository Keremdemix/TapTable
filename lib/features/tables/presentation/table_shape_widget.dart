import 'dart:math';
import 'package:flutter/material.dart';
import '../data/table_models.dart';
import 'package:tap_table_staff/core/constants/layout_constants.dart';

class TableShapeWidget extends StatelessWidget {
  final int tableNumber;
  final int capacity;
  final TableStatus status;
  final double width;
  final double height;
  final String shape; // 'rectangle' | 'circle'
  final bool isSelected;
  

  const TableShapeWidget({
    super.key,
    required this.tableNumber,
    required this.capacity,
    required this.status,
    required this.width,
    required this.height,
    required this.shape,
    this.isSelected = false,
  });

  Color get _statusColor => switch (status) {
        TableStatus.available => Colors.green,
        TableStatus.occupied => Colors.orange,
        TableStatus.reserved => Colors.blue,
        TableStatus.outOfService => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
    width: width,
    height: height,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          ..._buildChairs(),
          _buildTabletop(),
        ],
      ),
    );
  }

  Widget _buildTabletop() {
    final isCircle = shape == 'circle';
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _statusColor.withValues(alpha: 0.18),
        border: Border.all(color: _statusColor, width: 2.5),
        borderRadius: isCircle ? null : BorderRadius.circular(10),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$tableNumber', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('$capacity kişi', style: const TextStyle(fontSize: 10, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildChairs() {
    final chairs = <Widget>[];
    final chairSize = LayoutConstants.chairSize;
    final centerX = (width) / 2;
    final centerY = (height) / 2;

    if (shape == 'circle') {
      final radius = (width / 2) + 14;
      for (var i = 0; i < capacity; i++) {
        final angle = (2 * pi * i) / capacity;
        chairs.add(Positioned(
          left: centerX + radius * cos(angle) - chairSize / 2,
          top: centerY + radius * sin(angle) - chairSize / 2,
          child: _chair(),
        ));
      }
    } else {
      final topCount = (capacity / 2).ceil();
      final bottomCount = capacity - topCount;

      for (var i = 0; i < topCount; i++) {
        final spacing = width / (topCount + 1);
        chairs.add(Positioned(
          left: spacing * (i + 1) - chairSize / 2,
          top: -10 -chairSize / 2,
          child: _chair(),
        ));
      }
      for (var i = 0; i < bottomCount; i++) {
        final spacing = width / (bottomCount + 1);
        chairs.add(Positioned(
          left: spacing * (i + 1) - chairSize / 2,
          top: 10 + height - (chairSize / 2),
          child: _chair(),
        ));
      }
    }
    return chairs;
  }

  Widget _chair() => Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: Colors.brown.shade300,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.brown.shade600, width: 1),
        ),
      );
}