class CartItem {
  final String medicineId;
  final String batchId;
  final String name;
  final String batchNumber;
  final double unitPrice;
  final int stock;
  int quantity;

  CartItem({
    required this.medicineId,
    required this.batchId,
    required this.name,
    required this.batchNumber,
    required this.unitPrice,
    required this.stock,
    this.quantity = 1,
  });

  double get lineTotal => unitPrice * quantity;
}
