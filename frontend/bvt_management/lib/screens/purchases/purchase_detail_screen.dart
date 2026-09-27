import 'package:flutter/material.dart';

class PurchaseDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order;
  const PurchaseDetailScreen({super.key, required this.order});

  static const _green = Color(0xFF008575);
  static const _ink = Color(0xFF17213D);
  static const _line = Color(0xFFE5EEFF);

  @override
  Widget build(BuildContext context) {
    final items = (order['items'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final number = order['order_number']?.toString() ?? 'Purchase order';
    final supplier = order['supplier_name']?.toString() ?? 'អ្នកផ្គត់ផ្គង់';
    final status = order['status']?.toString() ?? 'ordered';
    final date = DateTime.tryParse(order['created_at']?.toString() ?? '');
    final dateText = date == null
        ? 'មិនមានកាលបរិច្ឆេទ'
        : '${_month(date.month)} ${date.day}, ${date.year}';
    final total = (order['total'] as num? ?? 0).toDouble();
    final subtotal = items.fold<double>(0, (sum, item) {
      final qty = (item['quantity'] as num? ?? 0).toDouble();
      final price = (item['purchase_price'] as num? ?? 0).toDouble();
      return sum + qty * price;
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    color: _ink,
                  ),
                  const Expanded(
                    child: Text(
                      'អត្ថបទបញ្ជាទិញ',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                children: [
                  _orderHeader(number, supplier, status, dateText),
                  const SizedBox(height: 26),
                  const Row(children: [
                    Icon(Icons.event_available_outlined, color: _ink, size: 23),
                    SizedBox(width: 10),
                    Text('មុខទំនិញក្នុងការបញ្ជាទិញ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  ]),
                  const SizedBox(height: 16),
                  if (items.isEmpty)
                    const _EmptyItems()
                  else
                    ...items.map(_itemCard),
                  const SizedBox(height: 30),
                  _totalCard(status, subtotal, total),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderHeader(String number, String supplier, String status, String date) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(border: Border.all(color: _line), borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Text('ព័ត៌មានការបញ្ជាទិញ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(color: const Color(0xFFE1F8E8), borderRadius: BorderRadius.circular(8)),
            child: Text(status, style: const TextStyle(color: _green, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 4),
        Text('#$number', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(number, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Row(children: [
              Flexible(child: Text(supplier, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
              const SizedBox(width: 5), const Icon(Icons.verified_outlined, color: _green, size: 20),
            ]),
          ])),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text('កាលបរិច្ឆេទបញ្ជាទិញ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.calendar_month_outlined, size: 15), const SizedBox(width: 4),
              Text(date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ]),
        ]),
      ]),
    );
  }

  Widget _itemCard(Map<String, dynamic> item) {
    final quantity = (item['quantity'] as num? ?? 0).toString();
    final sku = item['sku']?.toString();
    final label = (sku == null || sku.isEmpty) ? 'ថ្នាំក្នុងការបញ្ជាទិញ' : 'SKU: $sku';
    final unitPrice = (item['purchase_price'] as num? ?? 0).toDouble();
    final lineTotal = unitPrice * ((item['quantity'] as num? ?? 0).toDouble());
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: _line), borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        const Icon(Icons.inventory_2_outlined, size: 42, color: _ink),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item['medicine_name']?.toString() ?? 'ថ្នាំ', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6), Text(label, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4), Text('\$${lineTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Color(0xFF4A5568))),
        ])),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(7)),
            child: Text('× $quantity', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 4), const Text('Units', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }

  Widget _totalCard(String status, double subtotal, double total) {
    final received = status.toLowerCase() == 'received';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(border: Border.all(color: _line), borderRadius: BorderRadius.circular(18)),
      child: Column(children: [
        Row(children: [
          const Expanded(child: Text('ស្ថានភាពការទទួលទំនិញ', style: TextStyle(fontWeight: FontWeight.w700))),
          Icon(received ? Icons.check_circle_outline : Icons.schedule, color: _green, size: 22),
          const SizedBox(width: 8), Text(received ? 'បានទទួលទំនិញ' : 'កំពុងរង់ចាំទទួល', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('សរុបរង', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 5), Text('\$${subtotal.toStringAsFixed(2)}', style: const TextStyle(color: _green)),
            const SizedBox(height: 12), const Text('សរុបការបញ្ជាទិញ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ])),
          Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        ]),
      ]),
    );
  }

  static String _month(int month) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][month];
}

class _EmptyItems extends StatelessWidget {
  const _EmptyItems();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(border: Border.all(color: PurchaseDetailScreen._line), borderRadius: BorderRadius.circular(18)),
        child: const Text('មិនមានទិន្នន័យមុខទំនិញ'),
      );
}
