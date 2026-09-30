import 'package:flutter/material.dart';
import '../../models/cart_item.dart';
import '../../services/vet_api.dart';
import 'cart_screen.dart';

class SalesPosScreen extends StatefulWidget {
  const SalesPosScreen({super.key});
  @override
  State<SalesPosScreen> createState() => _SalesPosScreenState();
}

class _SalesPosScreenState extends State<SalesPosScreen> {
  final _search = TextEditingController();
  final List<CartItem> _cart = [];
  List<Map<String, dynamic>> _medicines = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await VetApi.getMedicines();
      if (mounted) setState(() => _medicines = data);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _lots {
    final query = _search.text.trim().toLowerCase();
    final lots = <Map<String, dynamic>>[];
    for (final medicine in _medicines) {
      final batches = (medicine['batches'] as List? ?? const [])
          .whereType<Map>();
      for (final raw in batches) {
        final batch = Map<String, dynamic>.from(raw);
        final label =
            '${medicine['name'] ?? ''} ${medicine['generic_name'] ?? ''} ${batch['batch_number'] ?? ''}'
                .toLowerCase();
        if (label.contains(query) && (batch['quantity'] as num? ?? 0) > 0) {
          lots.add({'medicine': medicine, 'batch': batch});
        }
      }
    }
    return lots;
  }

  void _add(Map<String, dynamic> medicine, Map<String, dynamic> batch) {
    final medicineId = medicine['_id']?.toString();
    final batchId = batch['_id']?.toString();
    if (medicineId == null || batchId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('មិនអាចកំណត់ batch ID បាន')));
      return;
    }
    final existing = _cart.where((item) => item.batchId == batchId).firstOrNull;
    if (existing != null) {
      if (existing.quantity >= existing.stock) return;
      setState(() => existing.quantity++);
    } else {
      setState(
        () => _cart.add(
          CartItem(
            medicineId: medicineId,
            batchId: batchId,
            name: medicine['name']?.toString() ?? 'ថ្នាំ',
            batchNumber: batch['batch_number']?.toString() ?? '',
            unitPrice:
                (batch['selling_price'] as num? ??
                        medicine['selling_price'] as num? ??
                        0)
                    .toDouble(),
            stock: (batch['quantity'] as num? ?? 0).toInt(),
          ),
        ),
      );
    }
  }

  Future<void> _openCart() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('សូមបន្ថែមថ្នាំទៅកន្ត្រកជាមុនសិន')),
      );
      return;
    }
    final checkedOut = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => CartScreen(items: _cart)));
    if (checkedOut == true && mounted) {
      setState(_cart.clear);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ការលក់ត្រូវបានរក្សាទុក និងស្តុកត្រូវបានកាត់'),
          ),
        );
      }
    } else if (mounted) {
      setState(() {});
    }
  }

  double get _total => _cart.fold(0, (sum, item) => sum + item.lineTotal);

  @override
  Widget build(BuildContext context) {
    final lots = _lots;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF17213D),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'ការលក់',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _openCart,
            icon: Badge(
              label: Text(
                '${_cart.fold<int>(0, (sum, e) => sum + e.quantity)}',
              ),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'ស្វែងរកថ្នាំ...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'ថ្នាំមានក្នុងស្តុក',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '${lots.length} មុខ',
                    style: const TextStyle(
                      color: Color(0xFF008575),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'មិនអាចទាញទិន្នន័យបាន\n$_error',
                            textAlign: TextAlign.center,
                          ),
                          TextButton(
                            onPressed: _load,
                            child: const Text('ព្យាយាមម្ដងទៀត'),
                          ),
                        ],
                      ),
                    )
                  : lots.isEmpty
                  ? const Center(child: Text('មិនមានថ្នាំក្នុងស្តុក'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                      itemCount: lots.length,
                      itemBuilder: (_, i) => _lotCard(lots[i]),
                    ),
            ),
            if (_cart.isNotEmpty) _cartFooter(),
          ],
        ),
      ),
    );
  }

  Widget _lotCard(Map<String, dynamic> lot) {
    final medicine = lot['medicine'] as Map<String, dynamic>;
    final batch = lot['batch'] as Map<String, dynamic>;
    final price =
        (batch['selling_price'] as num? ??
                medicine['selling_price'] as num? ??
                0)
            .toDouble();
    final qty = (batch['quantity'] as num? ?? 0).toInt();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromARGB(255, 158, 158, 159)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 39,
            color: Color.fromARGB(255, 175, 175, 175),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine['name']?.toString() ?? 'ថ្នាំ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${medicine['generic_name'] ?? ''}${medicine['generic_name'] == null || medicine['generic_name'].toString().isEmpty ? '' : ' • '}Batch #${batch['batch_number'] ?? ''}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  'ស្តុក: $qty',
                  style: const TextStyle(
                    color: Color(0xFF008575),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${price.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 12),
          IconButton.filledTonal(
            onPressed: () => _add(medicine, batch),
            icon: const Icon(Icons.add),
            tooltip: 'បន្ថែមទៅកន្ត្រក',
          ),
        ],
      ),
    );
  }

  Widget _cartFooter() => Container(
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
    decoration: const BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Color(0x12000000),
          blurRadius: 12,
          offset: Offset(0, -3),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'កន្ត្រកទិញ',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            _countPill(),
          ],
        ),
        const SizedBox(height: 8),
        ..._cart
            .take(2)
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.name} · ${item.batchNumber}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '− ${item.quantity} +',
                      style: const TextStyle(
                        color: Color(0xFF17213D),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('\$${item.lineTotal.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ),
        const Divider(),
        Row(
          children: [
            const Expanded(
              child: Text(
                'សរុប',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '\$${_total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _openCart,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF008575),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('ទៅកាន់កន្ត្រក'),
          ),
        ),
      ],
    ),
  );

  Widget _countPill() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFE0E0E0),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text('${_cart.fold<int>(0, (sum, item) => sum + item.quantity)}'),
  );
}
