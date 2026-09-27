import 'package:flutter/material.dart';
import '../../services/purchase_api.dart';
import '../../services/supplyer.dart';
import '../../services/medicine_api.dart';
import 'purchase_detail_screen.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});
  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try { final orders = await PurchaseApi.getPurchases(); if (mounted) setState(() => _orders = orders); }
    catch (e) { if (mounted) setState(() => _error = e.toString()); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _add() async {
    try {
      final values = await Future.wait([SupplierApi.getSuppliers(), MedicineApi.getMedicines()]);
      final suppliers = values[0]; final medicines = values[1];
      if (!mounted) return;
      if (suppliers.isEmpty || medicines.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('សូមបន្ថែមអ្នកផ្គត់ផ្គង់ និងថ្នាំជាមុនសិន')));
        return;
      }
      final result = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, builder: (_) => _PurchaseForm(suppliers: suppliers, medicines: medicines));
      if (result == true) _load();
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final filtered = _orders.where((o) => '${o['order_number']} ${o['supplier_name']}'.toLowerCase().contains(query)).toList();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ការបញ្ជាទិញ', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('${_orders.length} ការបញ្ជាទិញ', style: const TextStyle(fontSize: 15)),
            ])),
            Material(
              color: const Color(0xFF008575),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: _add,
                borderRadius: BorderRadius.circular(14),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.add_rounded, color: Colors.white, size: 24),
                ),
              ),
            ),
          ]),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(24, 18, 24, 20), child: TextField(controller: _search, onChanged: (_) => setState(() {}), decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'ស្វែងរក...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))))),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _error != null ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text('មិនអាចទាញទិន្នន័យបាន\n$_error', textAlign: TextAlign.center), TextButton(onPressed: _load, child: const Text('ព្យាយាមម្ដងទៀត'))])) : filtered.isEmpty ? const Center(child: Text('មិនទាន់មានការបញ្ជាទិញ')) : RefreshIndicator(onRefresh: _load, child: ListView.builder(padding: const EdgeInsets.fromLTRB(20, 0, 20, 80), itemCount: filtered.length, itemBuilder: (_, i) => _orderCard(filtered[i])))),
      ])),
    );
  }

  Widget _orderCard(Map<String, dynamic> order) {
    final items = (order['items'] as List? ?? const []).cast<Map>();
    final date = DateTime.tryParse(order['created_at']?.toString() ?? '');
    final dateText = date == null ? '' : '${date.month}/${date.day}/${date.year}';
    final amount = (order['total'] as num? ?? 0).toStringAsFixed(2);
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PurchaseDetailScreen(order: order))),
      borderRadius: BorderRadius.circular(18),
      child: Container(margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5EEFF)), borderRadius: BorderRadius.circular(18)), child: Row(children: [
      const Icon(Icons.inventory_2_outlined, size: 40, color: Color(0xFF17213D)), const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${order['order_number'] ?? 'PO'} ${order['supplier_name'] ?? ''}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)), const SizedBox(height: 7), Text('$dateText  ·  ${items.length} មុខ') ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('\$$amount', style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(order['status']?.toString() ?? '', style: const TextStyle(color: Color(0xFF008575)))])
    ])),
    );
  }
}

class _PurchaseForm extends StatefulWidget {
  final List<Map<String, dynamic>> suppliers, medicines;
  const _PurchaseForm({required this.suppliers, required this.medicines});
  @override
  State<_PurchaseForm> createState() => _PurchaseFormState();
}

class _PurchaseFormState extends State<_PurchaseForm> {
  final _formKey = GlobalKey<FormState>();
  String? supplierId, medicineId;
  final quantity = TextEditingController(text: '1');
  final price = TextEditingController();
  bool saving = false;
  @override
  void dispose() { quantity.dispose(); price.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => SafeArea(
        child: Container(
          height: MediaQuery.sizeOf(context).height * .82,
          padding: EdgeInsets.fromLTRB(
            20, 14, 20, 20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
                const SizedBox(height: 18),
                const Text('បង្កើតការបញ្ជាទិញ', style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A202C),
                )),
                const SizedBox(height: 16),
                Expanded(child: SingleChildScrollView(child: Column(children: [
                  _dropdown(
                    label: 'អ្នកផ្គត់ផ្គង់ *',
                    value: supplierId,
                    items: widget.suppliers.map((supplier) => DropdownMenuItem(
                      value: supplier['_id']?.toString(),
                      child: Text(supplier['name']?.toString() ?? ''),
                    )).toList(),
                    onChanged: (value) => setState(() => supplierId = value),
                  ),
                  _dropdown(
                    label: 'ថ្នាំ *',
                    value: medicineId,
                    items: widget.medicines.map((medicine) => DropdownMenuItem(
                      value: medicine['_id']?.toString(),
                      child: Text(medicine['name']?.toString() ?? ''),
                    )).toList(),
                    onChanged: (value) => setState(() => medicineId = value),
                  ),
                  _field(quantity, 'ចំនួន *', keyboard: TextInputType.number),
                  _field(
                    price,
                    'តម្លៃទិញក្នុងមួយឯកតា *',
                    keyboard: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ]))),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0E6B5C),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: saving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('រក្សាទុក'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _dropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<String>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          validator: (selected) => selected == null ? 'សូមជ្រើសរើស $label' : null,
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );

  Widget _field(TextEditingController controller, String label, {required TextInputType keyboard}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboard,
          validator: (value) {
            final parsed = num.tryParse(value?.trim() ?? '');
            final isQuantity = label.startsWith('ចំនួន');
            if (parsed == null ||
                (isQuantity && (int.tryParse(value?.trim() ?? '') == null || parsed <= 0)) ||
                (!isQuantity && parsed < 0)) {
              return label.startsWith('ចំនួន') ? 'ចំនួនត្រូវធំជាង 0' : 'សូមបញ្ចូលតម្លៃត្រឹមត្រូវ';
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final qty = int.tryParse(quantity.text); final unit = double.tryParse(price.text);
    if (supplierId == null || medicineId == null || qty == null || unit == null) return;
    setState(() => saving = true);
    try { await PurchaseApi.createPurchase(supplierId: supplierId!, medicineId: medicineId!, quantity: qty, purchasePrice: unit); if (mounted) Navigator.pop(context, true); }
    catch (e) { if (mounted) { setState(() => saving = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); } }
  }
}
