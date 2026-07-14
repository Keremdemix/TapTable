import '../../features/tables/data/table_models.dart';

extension TableStatusX on TableStatus {
  String get value {
    switch (this) {
      case TableStatus.available:
        return 'Available';
      case TableStatus.occupied:
        return 'Occupied';
      case TableStatus.reserved:
        return 'Reserved';
      case TableStatus.outOfService:
        return 'OutOfService';
    }
  }
}