import 'dart:convert';
import 'package:bvt_management/screens/home/Home_screen.dart';
import 'package:bvt_management/services/medicine_api.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// import '../home/Home_screen.dart' show ChartColors;
// import '../../services/medicine_api.dart';
import '../../services/supplyer.dart';
import '../../services/vet_api.dart' show ApiException;

/// Helper: category (and similar fields) coming from the API can be either
/// a plain String or a populated Map (e.g. {name: "Antibiotic", ...}).
/// Always use this instead of calling `.toString()` directly on the raw
/// value, otherwise you'll get literal text like "{name: Antibiotic}".
String _extractName(dynamic raw) {
  if (raw == null) return '';
  if (raw is Map) return raw['name']?.toString() ?? '';
  return raw.toString();
}

class MedicineScreen extends StatefulWidget {
  const MedicineScreen({super.key});
  @override
  State<MedicineScreen> createState() => _MedicineScreenState();
}

class _MedicineScreenState extends State<MedicineScreen> {
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  List<Map<String, dynamic>> _suppliers = [];
  bool _loading = true;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _search.addListener(_applyFilter);
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([MedicineApi.getMedicines(), SupplierApi.getSuppliers()]);
      _all = results[0];
      _suppliers = results[1];
    } catch (_) {
      _all = [];
      _suppliers = [];
    }
    _applyFilter();
    if (mounted) setState(() => _loading = false);
  }

  void _applyFilter() {
    final query = _search.text.trim().toLowerCase();
    setState(() {
      _filtered = query.isEmpty
          ? _all
          : _all.where((m) {
              final categoryStr = _extractName(m['category']);
              final manufacturerStr = _extractName(m['manufacturer']);
              final haystack = '${m['name']} ${m['generic_name']} $categoryStr $manufacturerStr'.toLowerCase();
              return haystack.contains(query);
            }).toList();
    });
  }

  String? _supplierName(String? id) {
    if (id == null) return null;
    final match = _suppliers.where((s) => s['_id'].toString() == id).toList();
    return match.isEmpty ? null : match.first['name']?.toString();
  }

  Future<void> _openAdd() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MedicineForm(suppliers: _suppliers),
    );
    if (saved == true) _load();
  }

  Future<void> _openEdit(Map<String, dynamic> medicine) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MedicineForm(existing: medicine, suppliers: _suppliers),
    );
    if (saved == true) _load();
  }

  Future<void> _openAddBatch(Map<String, dynamic> medicine) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BatchForm(medicine: medicine, suppliers: _suppliers),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Map<String, dynamic> medicine) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('លុបថ្នាំ?'),
        content: Text('តើអ្នកប្រាកដថាចង់លុប "${medicine['name']}" មែនទេ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('បោះបង់')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: ChartColors.rose), child: const Text('លុប')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await MedicineApi.deleteMedicine(medicine['_id'].toString());
      _all.removeWhere((m) => m['_id'] == medicine['_id']);
      _applyFilter();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('បានលុបរួចរាល់')));
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('មានបញ្ហា: $e');
    }
  }

  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final lowStockCount = _all.where(MedicineApi.isLowStock).length;
    return Scaffold(
      backgroundColor: ChartColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: ChartColors.teal,
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('ថ្នាំ និងស្តុក', style: GoogleFonts.fraunces(fontSize: 28, fontWeight: FontWeight.w700, color: ChartColors.ink)),
                    const SizedBox(height: 4),
                    Text('${_all.length} ប្រភេទថ្នាំ${lowStockCount > 0 ? ' · $lowStockCount ស្តុកទាប' : ''}', style: TextStyle(color: lowStockCount > 0 ? ChartColors.rose : ChartColors.inkSoft, fontSize: 13)),
                  ]),
                ),
                Material(
                  color: ChartColors.teal,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: _openAdd,
                    borderRadius: BorderRadius.circular(14),
                    child: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.add_rounded, color: Colors.white)),
                  ),
                ),
              ]),
              const SizedBox(height: 18),
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: _cardDeco(16),
                child: Row(children: [
                  const Icon(Icons.search_rounded, color: ChartColors.teal),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _search,
                      decoration: const InputDecoration(hintText: 'ស្វែងរកថ្នាំ...', hintStyle: TextStyle(color: ChartColors.inkSoft), border: InputBorder.none),
                    ),
                  ),
                  if (_search.text.isNotEmpty) IconButton(onPressed: () => _search.clear(), icon: const Icon(Icons.close_rounded, color: ChartColors.inkSoft)),
                ]),
              ),
              const SizedBox(height: 20),
              if (_loading)
                const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Center(child: CircularProgressIndicator(color: ChartColors.teal)))
              else if (_filtered.isEmpty)
                _emptyState()
              else
                ..._filtered.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MedicineCard(
                        medicine: m,
                        supplierName: _supplierName(MedicineApi.latestSupplierId(m)),
                        onEdit: () => _openEdit(m),
                        onDelete: () => _delete(m),
                        onAddBatch: () => _openAddBatch(m),
                      ),
                    )),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() => Container(
        padding: const EdgeInsets.symmetric(vertical: 50),
        alignment: Alignment.center,
        child: Column(children: [
          Container(width: 70, height: 70, decoration: const BoxDecoration(color: ChartColors.amberTint, shape: BoxShape.circle), child: const Icon(Icons.medication_outlined, color: ChartColors.amber, size: 32)),
          const SizedBox(height: 14),
          const Text('មិនទាន់មានថ្នាំទេ', style: TextStyle(color: ChartColors.ink, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('ចុច + ដើម្បីបន្ថែមថ្នាំថ្មី', style: TextStyle(color: ChartColors.inkSoft, fontSize: 12)),
        ]),
      );
}

class _MedicineCard extends StatelessWidget {
  final Map<String, dynamic> medicine;
  final String? supplierName;
  final VoidCallback onEdit, onDelete, onAddBatch;
  const _MedicineCard({required this.medicine, required this.supplierName, required this.onEdit, required this.onDelete, required this.onAddBatch});

  @override
  Widget build(BuildContext context) {
    final name = medicine['name']?.toString() ?? '-';
    // FIX: category can be a populated Map ({name: "Antibiotic", ...}) —
    // extract the 'name' field instead of calling .toString() on the Map.
    final category = _extractName(medicine['category']);
    final price = (medicine['selling_price'] as num? ?? 0).toDouble();
    final quantity = MedicineApi.quantityOf(medicine);
    final isLow = MedicineApi.isLowStock(medicine);
    final image = medicine['image']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(17),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _imageBox(image, isLow),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, color: ChartColors.ink, fontSize: 15), overflow: TextOverflow.ellipsis)),
                if (isLow) ...[
                  const SizedBox(width: 6),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: ChartColors.roseTint, borderRadius: BorderRadius.circular(8)), child: const Text('ស្តុកទាប', style: TextStyle(fontSize: 10, color: ChartColors.rose, fontWeight: FontWeight.w700))),
                ],
              ]),
              if (category.isNotEmpty) Text(category, style: const TextStyle(color: ChartColors.inkSoft, fontSize: 12)),
            ]),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: ChartColors.inkSoft),
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
              if (v == 'batch') onAddBatch();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'batch', child: Text('បន្ថែមស្តុក')),
              PopupMenuItem(value: 'edit', child: Text('កែប្រែ')),
              PopupMenuItem(value: 'delete', child: Text('លុប')),
            ],
          ),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 16, runSpacing: 6, children: [
          _iconText(Icons.sell_outlined, 'តម្លៃ \$${price.toStringAsFixed(2)}'),
          _iconText(Icons.inventory_2_outlined, 'ស្តុក $quantity'),
          if (supplierName != null) _iconText(Icons.local_shipping_outlined, supplierName!),
        ]),
      ]),
    );
  }

  Widget _imageBox(String image, bool isLow) {
    final tint = isLow ? ChartColors.roseTint : ChartColors.amberTint;
    final accent = isLow ? ChartColors.rose : ChartColors.amber;
    if (image.isEmpty) {
      return Container(width: 46, height: 46, decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(14)), child: Icon(Icons.medication_outlined, color: accent));
    }
    try {
      final bytes = base64Decode(image.contains(',') ? image.split(',').last : image);
      return ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.memory(bytes, width: 46, height: 46, fit: BoxFit.cover));
    } catch (_) {
      return Container(width: 46, height: 46, decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(14)), child: Icon(Icons.medication_outlined, color: accent));
    }
  }

  Widget _iconText(IconData icon, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: ChartColors.teal),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 12, color: ChartColors.inkSoft)),
      ]);
}

// ---------------- ADD / EDIT MEDICINE FORM ----------------

class _MedicineForm extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final List<Map<String, dynamic>> suppliers;
  const _MedicineForm({this.existing, required this.suppliers});
  @override
  State<_MedicineForm> createState() => _MedicineFormState();
}

class _MedicineFormState extends State<_MedicineForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name, _genericName, _category, _manufacturer, _sellingPrice, _quantity, _purchasePrice;
  String? _supplierId;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final m = widget.existing ?? const {};
    _name = TextEditingController(text: m['name']?.toString() ?? '');
    _genericName = TextEditingController(text: m['generic_name']?.toString() ?? '');
    // FIX: extract 'name' from category Map instead of showing "{name: xxx}"
    _category = TextEditingController(text: _extractName(m['category']));
    _manufacturer = TextEditingController(text: _extractName(m['manufacturer']));
    _sellingPrice = TextEditingController(text: m['selling_price']?.toString() ?? '');
    _quantity = TextEditingController(text: _isEdit ? '' : '0');
    _purchasePrice = TextEditingController(text: '0');
    _supplierId = _isEdit ? MedicineApi.latestSupplierId(m) : null;
  }

  @override
  void dispose() {
    for (final c in [_name, _genericName, _category, _manufacturer, _sellingPrice, _quantity, _purchasePrice]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await MedicineApi.updateMedicine(widget.existing!['_id'].toString(), {
          'name': _name.text.trim(),
          'generic_name': _genericName.text.trim(),
          'category': _category.text.trim(),
          'manufacturer': _manufacturer.text.trim(),
          'selling_price': double.tryParse(_sellingPrice.text) ?? 0,
          'batches': widget.existing!['batches'], // រក្សា batch ចាស់ (មិនកែពេល edit info ទូទៅ)
        });
      } else {
        await MedicineApi.createMedicine(
          name: _name.text.trim(),
          genericName: _genericName.text.trim(),
          category: _category.text.trim(),
          manufacturer: _manufacturer.text.trim(),
          sellingPrice: double.tryParse(_sellingPrice.text) ?? 0,
          initialQuantity: int.tryParse(_quantity.text) ?? 0,
          purchasePrice: double.tryParse(_purchasePrice.text) ?? 0,
          supplierId: _supplierId,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('មិនអាចភ្ជាប់ API server: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Container(
          height: MediaQuery.sizeOf(context).height * .88,
          padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
          decoration: const BoxDecoration(color: ChartColors.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: ChartColors.line, borderRadius: BorderRadius.circular(4)))),
              const SizedBox(height: 18),
              Text(_isEdit ? 'កែប្រែថ្នាំ' : 'បន្ថែមថ្នាំ', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: ChartColors.ink)),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(children: [
                    _field(_name, 'ឈ្មោះថ្នាំ *'),
                    _field(_genericName, 'ឈ្មោះទូទៅ (Generic)'),
                    _field(_category, 'ប្រភេទថ្នាំ'),
                    _field(_manufacturer, 'ក្រុមហ៊ុនផលិត'),
                    _field(_sellingPrice, 'តម្លៃលក់ *', keyboard: const TextInputType.numberWithOptions(decimal: true)),
                    if (!_isEdit) ...[
                      _field(_quantity, 'ចំនួនស្តុកដើម *', keyboard: TextInputType.number),
                      _field(_purchasePrice, 'តម្លៃទិញ (មួយឯកតា)', keyboard: const TextInputType.numberWithOptions(decimal: true)),
                      _supplierDropdown(),
                    ] else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: ChartColors.tealTint, borderRadius: BorderRadius.circular(12)),
                          child: const Text('ដើម្បីបន្ថែម/កែស្តុក សូមប្រើ "បន្ថែមស្តុក" ពី card ថ្នាំ', style: TextStyle(fontSize: 12, color: ChartColors.tealDeep)),
                        ),
                      ),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(backgroundColor: ChartColors.teal, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_isEdit ? 'រក្សាទុកការកែប្រែ' : 'រក្សាទុក'),
                ),
              ),
            ]),
          ),
        ),
      );

  Widget _supplierDropdown() => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<String>(
          value: _supplierId,
          decoration: InputDecoration(labelText: 'អ្នកផ្គត់ផ្គង់', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: ChartColors.line))),
          items: [
            const DropdownMenuItem(value: null, child: Text('មិនបញ្ជាក់')),
            ...widget.suppliers.map((s) => DropdownMenuItem(value: s['_id'].toString(), child: Text(s['name']?.toString() ?? '-'))),
          ],
          onChanged: (v) => setState(() => _supplierId = v),
        ),
      );

  Widget _field(TextEditingController controller, String label, {TextInputType? keyboard}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboard,
          validator: (value) => label.contains('*') && (value == null || value.trim().isEmpty) ? 'សូមបំពេញព័ត៌មាននេះ' : null,
          decoration: InputDecoration(labelText: label, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: ChartColors.line))),
        ),
      );
}

// ---------------- ADD BATCH (RESTOCK) FORM ----------------

class _BatchForm extends StatefulWidget {
  final Map<String, dynamic> medicine;
  final List<Map<String, dynamic>> suppliers;
  const _BatchForm({required this.medicine, required this.suppliers});
  @override
  State<_BatchForm> createState() => _BatchFormState();
}

class _BatchFormState extends State<_BatchForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  final _purchasePrice = TextEditingController();
  final _sellingPrice = TextEditingController();
  String? _supplierId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _sellingPrice.text = widget.medicine['selling_price']?.toString() ?? '';
    _supplierId = MedicineApi.latestSupplierId(widget.medicine);
  }

  @override
  void dispose() {
    _quantity.dispose();
    _purchasePrice.dispose();
    _sellingPrice.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await MedicineApi.addBatch(
        medicineId: widget.medicine['_id'].toString(),
        quantity: int.tryParse(_quantity.text) ?? 0,
        purchasePrice: double.tryParse(_purchasePrice.text) ?? 0,
        sellingPrice: double.tryParse(_sellingPrice.text) ?? 0,
        supplierId: _supplierId,
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('មានបញ្ហា: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
          decoration: const BoxDecoration(color: ChartColors.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Form(
            key: _formKey,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: ChartColors.line, borderRadius: BorderRadius.circular(4)))),
              const SizedBox(height: 18),
              Text('បន្ថែមស្តុក — ${widget.medicine['name']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ChartColors.ink)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantity,
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'សូមបញ្ចូលចំនួន' : null,
                decoration: InputDecoration(labelText: 'ចំនួនស្តុកចូល *', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: ChartColors.line))),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _purchasePrice,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'តម្លៃទិញ (មួយឯកតា)', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: ChartColors.line))),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sellingPrice,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'តម្លៃលក់', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: ChartColors.line))),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _supplierId,
                decoration: InputDecoration(labelText: 'អ្នកផ្គត់ផ្គង់', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: ChartColors.line))),
                items: [
                  const DropdownMenuItem(value: null, child: Text('មិនបញ្ជាក់')),
                  ...widget.suppliers.map((s) => DropdownMenuItem(value: s['_id'].toString(), child: Text(s['name']?.toString() ?? '-'))),
                ],
                onChanged: (v) => setState(() => _supplierId = v),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(backgroundColor: ChartColors.teal, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('រក្សាទុកស្តុក'),
                ),
              ),
            ]),
          ),
        ),
      );
}

BoxDecoration _cardDeco(double radius) => BoxDecoration(
      color: ChartColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: ChartColors.line),
      boxShadow: const [BoxShadow(color: Color(0x0A172B24), blurRadius: 16, offset: Offset(0, 5))],
    );