class DiningArea {
  final String id;
  final String name;
  final bool isActive;

  const DiningArea({
    required this.id,
    required this.name,
    this.isActive = true,
  });
}

class RestaurantTable {
  final String id;
  final String areaId;
  final String label;
  final int? seats;
  final bool isActive;
  final int sortOrder;

  const RestaurantTable({
    required this.id,
    required this.areaId,
    required this.label,
    this.seats,
    this.isActive = true,
    this.sortOrder = 0,
  });
}
