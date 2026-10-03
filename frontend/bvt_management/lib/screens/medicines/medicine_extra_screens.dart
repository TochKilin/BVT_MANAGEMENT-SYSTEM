import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/medicine_api.dart';
import '../../services/vet_api.dart' show ApiException;

const _medicineGreen = Color(0xFF008674);

class MedicineCategoryScreen extends StatefulWidget {
  const MedicineCategoryScreen({super.key});
  @override
  State<MedicineCategoryScreen> createState() => _MedicineCategoryScreenState();
}

class _MedicineCategoryScreenState extends State<MedicineCategoryScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  final _search = TextEditingController();
  @override
  void initState() {
    super.initState();
    _future = MedicineApi.getCategories();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final request = MedicineApi.getCategories();
    setState(() => _future = request);
    try {
      await request;
    } catch (_) {}
  }

  Future<void> _addCategory() async {
    final controller = TextEditingController();
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'បន្ថែមប្រភេទថ្នាំ',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'ឈ្មោះប្រភេទ',
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: _medicineGreen,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _medicineGreen,
                          minimumSize: const Size.fromHeight(50),
                          side: const BorderSide(color: _medicineGreen),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('បោះបង់'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.pop(sheetContext, controller.text.trim()),
                        style: FilledButton.styleFrom(
                          backgroundColor: _medicineGreen,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('រក្សាទុក'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final categoryName = name?.trim() ?? '';
    if (categoryName.isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      controller.dispose();
      return;
    }
    try {
      await MedicineApi.createCategory(categoryName);
      if (mounted) await _reload();
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      title: const Text(
        'ប្រភេទថ្នាំ',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      actions: [
        IconButton.filled(
          onPressed: _addCategory,
          icon: const Icon(Icons.add),
          style: IconButton.styleFrom(
            backgroundColor: _medicineGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
      ],
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(
            child: CircularProgressIndicator(color: _medicineGreen),
          );
        if (snapshot.hasError)
          return _message('មិនអាចទាញទិន្នន័យបាន', onRetry: _reload);
        final query = _search.text.trim().toLowerCase();
        final categories =
            (snapshot.data ?? <Map<String, dynamic>>[])
                .where(
                  (item) => (item['name']?.toString() ?? '')
                      .toLowerCase()
                      .contains(query),
                )
                .toList()
              ..sort(
                (a, b) => (a['name']?.toString() ?? '').compareTo(
                  b['name']?.toString() ?? '',
                ),
              );
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'ស្វែងរកប្រភេទថ្នាំ...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            Expanded(
              child: categories.isEmpty
                  ? _message('មិនទាន់មានប្រភេទថ្នាំ')
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final entry = categories[index];
                        return InkWell(
                          onTap: () =>
                              Navigator.pop(context, entry['name']?.toString()),
                          borderRadius: BorderRadius.circular(17),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFD9D9D9),
                              ),
                              borderRadius: BorderRadius.circular(17),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.medication_outlined,
                                  color: _medicineGreen,
                                  size: 30,
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry['name']?.toString() ?? '',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'ថ្នាំ៖ ${entry['medicine_count'] ?? 0}',
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    ),
  );
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Map<String, dynamic>> _medicines = [];
  bool _loading = true;
  String? _error;
  String? _selectedMedicineId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final medicines = await MedicineApi.getMedicines();
      if (mounted)
        setState(() {
          _medicines = medicines;
          _loading = false;
        });
    } catch (error) {
      if (mounted)
        setState(() {
          _error = error.toString();
          _loading = false;
        });
    }
  }

  int get _totalUnits => _medicines.fold(
    0,
    (sum, medicine) => sum + MedicineApi.quantityOf(medicine),
  );
  int get _lowStockCount => _medicines.where(MedicineApi.isLowStock).length;
  int get _expiredUnits {
    final now = DateTime.now();
    return _medicines.fold(0, (sum, medicine) {
      final batches = (medicine['batches'] as List? ?? const [])
          .whereType<Map>();
      return sum +
          batches
              .where((batch) {
                final expiry = DateTime.tryParse(
                  batch['expiry_date']?.toString() ?? '',
                );
                return expiry != null && expiry.isBefore(now);
              })
              .fold<int>(
                0,
                (total, batch) =>
                    total + ((batch['quantity'] as num?)?.toInt() ?? 0),
              );
    });
  }

  int get _categoryCount => _medicines
      .map(MedicineApi.categoryName)
      .where((name) => name.trim().isNotEmpty)
      .toSet()
      .length;

  List<Map<String, dynamic>> get _inventoryRows {
    final rows = <Map<String, dynamic>>[];
    for (final medicine in _medicines) {
      if (_selectedMedicineId != null &&
          medicine['_id']?.toString() != _selectedMedicineId)
        continue;
      final batches = (medicine['batches'] as List? ?? const [])
          .whereType<Map>();
      if (batches.isEmpty) {
        rows.add({
          'medicine': medicine,
          'quantity': 0,
          'expiry_date': null,
          'batch_number': '',
        });
      } else {
        for (final batch in batches) {
          rows.add({'medicine': medicine, ...Map<String, dynamic>.from(batch)});
        }
      }
    }
    rows.sort((a, b) {
      final dateA =
          DateTime.tryParse(a['expiry_date']?.toString() ?? '') ??
          DateTime(9999);
      final dateB =
          DateTime.tryParse(b['expiry_date']?.toString() ?? '') ??
          DateTime(9999);
      return dateA.compareTo(dateB);
    });
    return rows;
  }

  Future<void> _scan() async {
    final medicine = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const MedicineQrCodeScreen()),
    );
    if (mounted && medicine != null)
      setState(() => _selectedMedicineId = medicine['_id']?.toString());
  }

  Future<void> _adjustStock({required bool receive}) async {
    if (_medicines.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('សូមបន្ថែមថ្នាំជាមុនសិន')));
      return;
    }
    final qtyController = TextEditingController();
    Map<String, dynamic>? selected = _medicines.firstWhere(
      (medicine) => medicine['_id']?.toString() == _selectedMedicineId,
      orElse: () => _medicines.first,
    );
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(27)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9D9D9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    receive ? 'បញ្ចូលស្តុក' : 'បញ្ចេញស្តុក',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: selected,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'ជ្រើសរើសថ្នាំ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items: _medicines
                        .map(
                          (medicine) => DropdownMenuItem(
                            value: medicine,
                            child: Text(medicine['name']?.toString() ?? ''),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setSheetState(() => selected = value),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'ចំនួនឯកតា',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () {
                        final quantity = int.tryParse(
                          qtyController.text.trim(),
                        );
                        if (selected == null ||
                            quantity == null ||
                            quantity <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'សូមជ្រើសរើសថ្នាំ និងបញ្ចូលចំនួនត្រឹមត្រូវ',
                              ),
                            ),
                          );
                          return;
                        }
                        Navigator.pop(sheetContext, {
                          'medicine': selected,
                          'quantity': quantity,
                        });
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _medicineGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('បញ្ជាក់'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    qtyController.dispose();
    if (result == null || !mounted) return;
    final medicine = result['medicine'] as Map<String, dynamic>;
    final quantity = result['quantity'] as int;
    try {
      if (receive) {
        await MedicineApi.addBatch(
          medicineId: medicine['_id'].toString(),
          quantity: quantity,
          purchasePrice: (medicine['purchase_price'] as num?)?.toDouble() ?? 0,
          sellingPrice: (medicine['selling_price'] as num?)?.toDouble() ?? 0,
          expiryDate: DateTime.now().add(const Duration(days: 365)),
        );
      } else {
        await MedicineApi.stockOut(
          medicineId: medicine['_id'].toString(),
          quantity: quantity,
        );
      }
      if (mounted) await _load();
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      title: const Text(
        'សារពើភ័ណ្ឌ',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 19),
        onPressed: () => Navigator.maybePop(context),
      ),
      actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: _medicineGreen))
        : _error != null
        ? _message(_error!, onRetry: _load)
        : RefreshIndicator(
            color: _medicineGreen,
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _metric(
                        'ប្រភេទថ្នាំ',
                        _categoryCount,
                        'ប្រភេទសរុប',
                        _medicineGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _metric(
                        'ស្តុកសរុប',
                        _totalUnits,
                        'ឯកតា',
                        Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _metric(
                        'ស្តុកទាប',
                        _lowStockCount,
                        'ប្រភេទថ្នាំ',
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _metric(
                        'ផុតកំណត់',
                        _expiredUnits,
                        'ឯកតា',
                        const Color(0xFFB58A00),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _action(
                        Icons.inventory_2_outlined,
                        'បញ្ចូលស្តុក',
                        'ទទួលស្តុកថ្មី',
                        active: true,
                        onTap: () => _adjustStock(receive: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _action(
                        Icons.store_outlined,
                        'បញ្ចេញស្តុក',
                        'ចេញពីស្តុក',
                        onTap: () => _adjustStock(receive: false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 72,
                      height: 76,
                      child: Material(
                        color: const Color(0xFFDADADA),
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: _scan,
                          borderRadius: BorderRadius.circular(16),
                          child: const Icon(
                            Icons.qr_code_scanner,
                            size: 31,
                            color: Color(0xFF19152B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_selectedMedicineId != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () =>
                          setState(() => _selectedMedicineId = null),
                      icon: const Icon(Icons.close),
                      label: const Text('សម្អាតតម្រង'),
                    ),
                  ),
                const SizedBox(height: 20),
                if (_inventoryRows.isEmpty)
                  _message('មិនទាន់មានទិន្នន័យស្តុក')
                else
                  ..._inventoryRows.map(
                    (row) => Padding(
                      padding: const EdgeInsets.only(bottom: 11),
                      child: _inventoryCard(row),
                    ),
                  ),
              ],
            ),
          ),
  );

  Widget _metric(String title, int value, String caption, Color color) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD9D9D9)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            Text(caption),
          ],
        ),
      );
  Widget _action(
    IconData icon,
    String title,
    String subtitle, {
    bool active = false,
    required VoidCallback onTap,
  }) => SizedBox(
    height: 76,
    child: Material(
      color: active ? _medicineGreen : const Color(0xFFDADADA),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Icon(
                icon,
                color: active ? Colors.white : Colors.black87,
                size: 24,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: active ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: active ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  Widget _inventoryCard(Map<String, dynamic> row) {
    final medicine = row['medicine'] as Map<String, dynamic>;
    final quantity = (row['quantity'] as num?)?.toInt() ?? 0;
    final expiry = DateTime.tryParse(row['expiry_date']?.toString() ?? '');
    final expired =
        expiry != null && expiry.isBefore(DateTime.now()) && quantity > 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD9D9D9)),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: const Color(0xFF0A4F44),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.medication_outlined, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine['name']?.toString() ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Batch ${row['batch_number'] ?? '-'} • ផុតកំណត់៖ ${_shortDate(expiry)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: expired
                  ? const Color(0xFFFFD9D6)
                  : const Color(0xFFDADADA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              expired ? 'ផុតកំណត់ $quantity' : '$quantity units',
              style: TextStyle(
                fontSize: 11,
                color: expired ? Colors.red : Colors.black87,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _shortDate(DateTime? date) => date == null
      ? 'មិនបានកំណត់'
      : '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class MedicinePriceScreen extends StatefulWidget {
  final Map<String, dynamic> medicine;
  const MedicinePriceScreen({super.key, required this.medicine});
  @override
  State<MedicinePriceScreen> createState() => _MedicinePriceScreenState();
}

class _MedicinePriceScreenState extends State<MedicinePriceScreen> {
  late final TextEditingController _purchase;
  late final TextEditingController _selling;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    final batches = (widget.medicine['batches'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    final storedPurchase =
        (widget.medicine['purchase_price'] as num?)?.toDouble() ?? 0;
    final purchase = storedPurchase > 0 || batches.isEmpty
        ? storedPurchase
        : (batches.last['purchase_price'] as num? ?? 0).toDouble();
    _purchase = TextEditingController(text: purchase.toStringAsFixed(2));
    _selling = TextEditingController(
      text: ((widget.medicine['selling_price'] as num?)?.toDouble() ?? 0)
          .toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _purchase.dispose();
    _selling.dispose();
    super.dispose();
  }

  double get _margin =>
      (double.tryParse(_selling.text) ?? 0) -
      (double.tryParse(_purchase.text) ?? 0);
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      title: const Text(
        'កំណត់តម្លៃ',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 19),
        onPressed: () => Navigator.pop(context),
      ),
    ),
    body: Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.medicine['name']?.toString() ?? '',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 24),
          _priceField('តម្លៃដើម', _purchase),
          const SizedBox(height: 22),
          _priceField('តម្លៃលក់', _selling),
          const SizedBox(height: 22),
          AnimatedBuilder(
            animation: Listenable.merge([_purchase, _selling]),
            builder: (_, __) => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF5F3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'ប្រាក់ចំណេញក្នុងមួយឯកតា: \$${_margin.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _medicineGreen,
                ),
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: _medicineGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'រក្សាទុក',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    ),
  );
  Widget _priceField(String label, TextEditingController controller) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        onChanged: (_) => setState(() {}),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          prefixText: '\$ ',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
          ),
        ),
      ),
    ],
  );
  Future<void> _save() async {
    final purchase = double.tryParse(_purchase.text.trim());
    final selling = double.tryParse(_selling.text.trim());
    if (purchase == null || selling == null || purchase < 0 || selling < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('សូមបញ្ចូលតម្លៃឲ្យបានត្រឹមត្រូវ')),
      );
      return;
    }
    final oldPurchase =
        (widget.medicine['purchase_price'] as num?)?.toDouble() ?? 0;
    final oldSelling =
        (widget.medicine['selling_price'] as num?)?.toDouble() ?? 0;
    if (purchase == oldPurchase && selling == oldSelling) {
      Navigator.pop(context, true);
      return;
    }
    setState(() => _saving = true);
    try {
      await MedicineApi.updateMedicine(widget.medicine['_id'].toString(), {
        'purchase_price': purchase,
        'selling_price': selling,
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class MedicineQrCodeScreen extends StatefulWidget {
  const MedicineQrCodeScreen({super.key});
  @override
  State<MedicineQrCodeScreen> createState() => _MedicineQrCodeScreenState();
}

class _MedicineQrCodeScreenState extends State<MedicineQrCodeScreen> {
  final MobileScannerController _scanner = MobileScannerController();
  late Future<List<Map<String, dynamic>>> _medicines;
  bool _handlingCode = false;
  String? _message;
  @override
  void initState() {
    super.initState();
    _medicines = MedicineApi.getMedicines();
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handlingCode || capture.barcodes.isEmpty) return;
    final code = capture.barcodes.first.rawValue?.trim();
    if (code == null || code.isEmpty) return;
    _handlingCode = true;
    await _findMedicine(code);
  }

  Future<void> _findMedicine(String code) async {
    setState(() {
      _handlingCode = true;
      _message = null;
    });
    try {
      final medicines = await _medicines;
      Map<String, dynamic>? match;
      for (final medicine in medicines) {
        final batches = (medicine['batches'] as List? ?? const [])
            .whereType<Map>();
        final batchMatch = batches.any(
          (batch) => batch['batch_number']?.toString().trim() == code,
        );
        if (medicine['barcode']?.toString().trim() == code ||
            medicine['_id']?.toString() == code ||
            batchMatch) {
          match = medicine;
          break;
        }
      }
      if (!mounted) return;
      if (match != null) {
        Navigator.pop(context, match);
      } else {
        setState(() {
          _message = 'រកមិនឃើញថ្នាំដែលមាន Barcode/QR នេះទេ';
          _handlingCode = false;
        });
        await _scanner.start();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _message = error.toString();
          _handlingCode = false;
        });
        await _scanner.start();
      }
    }
  }

  Future<void> _enterManually() async {
    await _scanner.stop();
    final controller = TextEditingController();
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'បញ្ចូល Barcode / QR',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'លេខកូដ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: _medicineGreen,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.pop(sheetContext, controller.text.trim()),
                    style: FilledButton.styleFrom(
                      backgroundColor: _medicineGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('ស្វែងរកថ្នាំ'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    if (code != null && code.trim().isNotEmpty) {
      await _findMedicine(code.trim());
    } else {
      await _scanner.start();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      title: const Text(
        'ស្កេនថ្នាំ',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 19),
        onPressed: () => Navigator.pop(context),
      ),
    ),
    body: Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(controller: _scanner, onDetect: _onDetect),
                      IgnorePointer(
                        child: Center(
                          child: Container(
                            width: 210,
                            height: 210,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _medicineGreen,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                      if (_handlingCode)
                        const ColoredBox(
                          color: Color(0x33000000),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _message ?? 'ស្កេន Barcode / QR របស់ថ្នាំ',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _message == null ? Colors.black87 : Colors.red,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: _handlingCode ? null : _enterManually,
              style: FilledButton.styleFrom(
                backgroundColor: _medicineGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'បញ្ចូលដោយដៃ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class MedicineInformationScreen extends StatelessWidget {
  final Map<String, dynamic> medicine;
  const MedicineInformationScreen({super.key, required this.medicine});
  Future<void> _scanAndOpen(BuildContext context) async {
    final scanned = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const MedicineQrCodeScreen()),
    );
    if (!context.mounted || scanned == null) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MedicineInformationScreen(medicine: scanned),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      title: const Text(
        'ព័ត៌មានថ្នាំ',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 19),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          tooltip: 'ស្កេន Barcode / QR',
          onPressed: () => _scanAndOpen(context),
          icon: const Icon(Icons.qr_code_scanner, color: _medicineGreen),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
      children: [
        _info('Generic Name', medicine['generic_name']),
        _info('Manufacturer', medicine['manufacturer']),
        _info('Dosage Form', medicine['dosage_form']),
        _info('Description', medicine['description']),
      ],
    ),
  );
  Widget _info(String title, dynamic value) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFD9D9D9)),
      borderRadius: BorderRadius.circular(17),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(
          value?.toString().trim().isNotEmpty == true
              ? value.toString()
              : 'មិនមានព័ត៌មាន',
          style: const TextStyle(fontSize: 15),
        ),
      ],
    ),
  );
}

class MedicineDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> medicine;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const MedicineDetailsScreen({
    super.key,
    required this.medicine,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final stock = MedicineApi.quantityOf(medicine);
    final inStock = stock > 0;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'ព័ត៌មានថ្នាំ',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 19),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(
                medicine['name']?.toString() ?? 'ថ្នាំ',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _detailRow('Stock', '$stock'),
              _detailRow(
                'Status',
                '',
                trailing: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: inStock ? const Color(0xFF00C853) : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              _detailRow('Unit', medicine['unit']?.toString() ?? 'Bottle'),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: onEdit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _medicineGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'កែប្រែ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: onDelete,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDADADA),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'លុបថ្នាំ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Widget? trailing}) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        trailing ??
            Text(
              value,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
      ],
    ),
  );
}

Widget _message(String text, {Future<void> Function()? onRetry}) => Center(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(text),
      if (onRetry != null)
        TextButton(onPressed: onRetry, child: const Text('ព្យាយាមម្តងទៀត')),
    ],
  ),
);
