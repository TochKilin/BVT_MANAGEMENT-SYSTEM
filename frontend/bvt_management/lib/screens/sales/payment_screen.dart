import 'package:flutter/material.dart';

import '../../models/cart_item.dart';
import '../../services/sales_api.dart';
import 'invoice_screen.dart';

const _green = Color(0xFF008575);
const _ink = Color(0xFF17213D);

class PaymentScreen extends StatefulWidget {
  final List<CartItem> items;
  const PaymentScreen({super.key, required this.items});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _method = 'Cash';
  double? _received;
  bool _busy = false;
  double get _total => widget.items.fold(0, (sum, item) => sum + item.lineTotal);
  double get _amountReceived => _received ?? _total;

  Future<void> _pay() async {
    setState(() => _busy = true);
    try {
      final sale = await SalesApi.checkout(widget.items);
      if (!mounted) return;
      final viewed = await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) => InvoiceScreen(items: widget.items, sale: sale, paid: _amountReceived > _total ? _amountReceived : _total),
      ));
      // The sale is already recorded. Once the invoice route closes, return
      // success so the cart is cleared even if the user uses system back.
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(backgroundColor: Colors.white, foregroundColor: _ink, elevation: 0, centerTitle: true, title: const Text('ការទូទាត់', style: TextStyle(fontWeight: FontWeight.w800))),
    body: SafeArea(child: ListView(padding: const EdgeInsets.all(22), children: [
      Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5EEFF)), borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('វិក្កយបត្រសរុប', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('\$${_total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Row(children: [Icon(Icons.check_circle_outline, color: _green, size: 18), SizedBox(width: 6), Text('បានគិតតម្លៃទំនិញរួចរាល់')]),
      ])),
      const SizedBox(height: 28),
      Row(children: [const Expanded(child: Text('វិធីសាស្ត្រទូទាត់', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))), TextButton.icon(onPressed: () {}, icon: const Icon(Icons.lock_outline, size: 17), label: const Text('POS មានសុវត្ថិភាព'))]),
      const SizedBox(height: 8),
      Row(children: [Expanded(child: _methodCard('Cash', Icons.payments_outlined)), const SizedBox(width: 10), Expanded(child: _methodCard('Card', Icons.credit_card)), const SizedBox(width: 10), Expanded(child: _methodCard('QR', Icons.qr_code_2))]),
      const SizedBox(height: 34),
      Row(children: [const Expanded(child: Text('ទឹកប្រាក់ទទួលបាន', style: TextStyle(fontWeight: FontWeight.w800))), Text('បញ្ចុះតម្លៃ (0%)', style: TextStyle(color: Colors.grey.shade700))]),
      const SizedBox(height: 12),
      TextField(keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (v) => setState(() => _received = double.tryParse(v) ?? 0), decoration: InputDecoration(prefixText: '\$', hintText: _total.toStringAsFixed(2), suffixIcon: IconButton(onPressed: () => setState(() => _received = null), icon: const Icon(Icons.close)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
      const SizedBox(height: 22),
      const Text('ចំនួនទឹកប្រាក់រហ័ស', style: TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      Wrap(spacing: 8, children: [_total, 20.0, 30.0, 50.0].map((amount) => ActionChip(label: Text(amount == _total ? 'ត្រឹមត្រូវ (\$${amount.toStringAsFixed(2)})' : '\$${amount.toStringAsFixed(2)}'), onPressed: () => setState(() => _received = amount))).toList()),
      const SizedBox(height: 20),
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFDDDDDD)), borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('ប្រាក់អាប់ត្រូវប្រគល់', style: TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 10), Text('\$${(_amountReceived > _total ? _amountReceived - _total : 0).toStringAsFixed(2)} USD', style: const TextStyle(color: _green, fontSize: 26, fontWeight: FontWeight.w800))])),
      const SizedBox(height: 28),
      SizedBox(height: 56, child: FilledButton(onPressed: _busy ? null : _pay, style: FilledButton.styleFrom(backgroundColor: _green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: _busy ? const CircularProgressIndicator(color: Colors.white) : const Text('បញ្ជាក់ការទូទាត់', style: TextStyle(fontWeight: FontWeight.w700)))),
    ])),
  );

  Widget _methodCard(String name, IconData icon) {
    final selected = _method == name;
    return InkWell(onTap: () => setState(() => _method = name), borderRadius: BorderRadius.circular(14), child: Container(height: 105, decoration: BoxDecoration(color: Colors.white, border: Border.all(color: selected ? _green : const Color(0xFFD8D8D8), width: selected ? 1.5 : 1), borderRadius: BorderRadius.circular(14)), child: Stack(children: [if (selected) const Positioned(right: 8, top: 8, child: Icon(Icons.check_circle, color: _green, size: 18)), Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: selected ? _green : _ink, size: 29), const SizedBox(height: 8), Text(name, style: const TextStyle(fontWeight: FontWeight.w700))]))])));
  }
}
