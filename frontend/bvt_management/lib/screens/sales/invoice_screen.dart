import 'package:flutter/material.dart';

import '../../models/cart_item.dart';

const _green = Color(0xFF008575);
const _ink = Color(0xFF17213D);

class InvoiceScreen extends StatelessWidget {
  final List<CartItem> items;
  final Map<String, dynamic> sale;
  final double paid;
  const InvoiceScreen({super.key, required this.items, required this.sale, required this.paid});

  String _money(num value) => '\$${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final total = (sale['total'] as num?)?.toDouble() ?? items.fold<double>(0, (sum, item) => sum + item.lineTotal);
    final date = DateTime.tryParse(sale['created_at']?.toString() ?? '') ?? DateTime.now();
    final number = sale['sale_number']?.toString() ?? 'SO-${sale['_id'] ?? '00001'}';
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, foregroundColor: _ink, elevation: 0, centerTitle: true, title: const Text('វិក្កយបត្រ', style: TextStyle(fontWeight: FontWeight.w800)), actions: [Padding(padding: const EdgeInsets.only(right: 14), child: Chip(avatar: const Icon(Icons.circle, color: _green, size: 13), label: const Text('បានបង់'), backgroundColor: const Color(0xFFE7F4F1))) ]),
      body: SafeArea(child: Column(children: [
        Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(20, 10, 20, 18), children: [
          const Center(child: Column(children: [CircleAvatar(radius: 38, backgroundColor: Color(0xFFD9D9D9), child: Icon(Icons.pets, color: _ink, size: 42)), SizedBox(height: 8), Text('VETCARE', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)), SizedBox(height: 3), Text('មន្ទីរសត្វ និងឱសថស្ថាន • វិក្កយបត្រលក់', style: TextStyle(fontWeight: FontWeight.w700))])),
          const SizedBox(height: 18),
          Container(padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD8D8D8)), borderRadius: BorderRadius.circular(14)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [Flexible(child: Text('No. #$number', style: const TextStyle(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)), const Text('•'), Text('${_month(date.month)} ${date.day}, ${date.year}', style: const TextStyle(fontWeight: FontWeight.w700))])),
          const SizedBox(height: 18),
          const Row(children: [Expanded(child: Text('ទំនិញ / ការពិពណ៌នា', style: TextStyle(fontWeight: FontWeight.w800))), Text('តម្លៃ', style: TextStyle(fontWeight: FontWeight.w800))]),
          const SizedBox(height: 10),
          ...items.map(_itemCard),
          const SizedBox(height: 18),
          const Divider(),
          _summaryRow('តម្លៃទំនិញសរុប', _money((sale['subtotal'] as num?) ?? total)),
          _summaryRow('ពន្ធ / ការបញ្ចុះតម្លៃ (0%)', _money(((sale['tax'] as num?) ?? 0) - ((sale['discount'] as num?) ?? 0))),
          _summaryRow('តម្លៃត្រូវបង់', _money(total), bold: true),
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD8D8D8)), borderRadius: BorderRadius.circular(15)), child: Column(children: [Row(children: [const Icon(Icons.payments_outlined, color: _green), const SizedBox(width: 10), const Expanded(child: Text('បង់ប្រាក់: សាច់ប្រាក់', style: TextStyle(fontWeight: FontWeight.w700))), Text(_money(paid), style: const TextStyle(color: _green, fontWeight: FontWeight.w800))]), const SizedBox(height: 10), Row(children: [const Expanded(child: Text('ប្រាក់អាប់ត្រូវប្រគល់')), Text(_money(paid > total ? paid - total : 0), style: const TextStyle(color: _green, fontWeight: FontWeight.w800))])])),
          const SizedBox(height: 20),
          Center(child: Column(children: [const Text('|||| |||| |||| |||| ||||', style: TextStyle(fontSize: 24, letterSpacing: 2, color: _ink)), const SizedBox(height: 2), Text('TXN-${number.replaceAll(RegExp(r'[^A-Za-z0-9]'), '')}', style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1))])),
        ])),
        Padding(padding: const EdgeInsets.fromLTRB(18, 6, 18, 16), child: Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.share_outlined), label: const Text('ចែករំលែក'), style: OutlinedButton.styleFrom(foregroundColor: _ink, backgroundColor: const Color(0xFFD9D9D9), minimumSize: const Size.fromHeight(52), side: BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))), const SizedBox(width: 12), Expanded(child: FilledButton.icon(onPressed: () => Navigator.pop(context, true), icon: const Icon(Icons.print_outlined), label: const Text('បិទវិក្កយបត្រ'), style: FilledButton.styleFrom(backgroundColor: _green, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))) ])),
      ])),
    );
  }

  Widget _itemCard(CartItem item) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD8D8D8)), borderRadius: BorderRadius.circular(15)), child: Row(children: [Container(width: 52, height: 52, decoration: BoxDecoration(color: const Color(0xFFD9D9D9), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.medication_outlined, color: _ink, size: 27)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800)), Text('x${item.quantity} at ${_money(item.unitPrice)} / unit', style: const TextStyle(fontSize: 13))])), Text(_money(item.lineTotal), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))]));

  Widget _summaryRow(String title, String value, {bool bold = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [Expanded(child: Text(title, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontSize: bold ? 18 : 15))), Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w700, fontSize: bold ? 21 : 17))]));

  String _month(int month) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month - 1];
}
