import 'package:flutter/material.dart';
import '../../models/cart_item.dart';
import 'payment_screen.dart';

class CartScreen extends StatefulWidget {
  final List<CartItem> items;
  const CartScreen({super.key, required this.items});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> get _items => widget.items;
  double get _subtotal => _items.fold(0, (sum, item) => sum + item.lineTotal);

  void _change(CartItem item, int delta) {
    setState(() {
      final next = item.quantity + delta;
      if (next <= 0) {
        _items.remove(item);
      } else if (next <= item.stock) {
        item.quantity = next;
      }
    });
  }

  Future<void> _checkout() async {
    if (_items.isEmpty) return;
    final checkedOut = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PaymentScreen(items: _items)),
    );
    if (checkedOut == true && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF17213D),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'កន្ត្រកទិញ',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'ទំនិញដែលបានជ្រើសរើស',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    'Lot Verified',
                    style: TextStyle(
                      color: const Color(0xFF008575),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _items.isEmpty
                  ? const Center(child: Text('កន្ត្រកទទេ'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      itemCount: _items.length,
                      itemBuilder: (_, index) => _cartItem(_items[index]),
                    ),
            ),
            if (_items.isNotEmpty) _summary(),
          ],
        ),
      ),
    );
  }

  Widget _cartItem(CartItem item) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFE5EEFF)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 5),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 38,
                color: Color(0xFF17213D),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Batch #${item.batchNumber} • \$${item.unitPrice.toStringAsFixed(2)} / unit',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF69F04E),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      'ស្តុកនៅសល់: ${item.stock}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${item.lineTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${item.quantity} × \$${item.unitPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _qtyButton(Icons.remove, () => _change(item, -1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '× ${item.quantity}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _qtyButton(
                Icons.add,
                item.quantity < item.stock ? () => _change(item, 1) : null,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _qtyButton(IconData icon, VoidCallback? onPressed) => SizedBox(
    width: 34,
    height: 32,
    child: IconButton.filledTonal(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFFE0E0E0),
        foregroundColor: const Color(0xFF17213D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),
  );

  Widget _summary() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Text('សរុបតម្លៃទំនិញ')),
            Text(
              '\$${_subtotal.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(child: Text('បញ្ចុះតម្លៃ')),
            Text(
              '\$0.00',
              style: TextStyle(
                color: Color(0xFF008575),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Row(
          children: [
            Expanded(child: Text('ពន្ធ')),
            Text(
              '\$0.00',
              style: TextStyle(
                color: Color(0xFF008575),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const Divider(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(
              child: Text(
                'Total',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              '\$${_subtotal.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _checkout,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF008575),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('បន្តទៅការទូទាត់'),
          ),
        ),
      ],
    ),
  );
}
