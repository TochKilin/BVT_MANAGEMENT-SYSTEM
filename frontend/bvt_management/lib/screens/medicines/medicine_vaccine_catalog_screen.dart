import 'dart:convert';

import 'package:flutter/material.dart';
import '../../services/medicine_api.dart';
import '../../services/purchase_api.dart';

class MedicineVaccineCatalogScreen extends StatefulWidget {
  final VoidCallback onBack;
  const MedicineVaccineCatalogScreen({super.key, required this.onBack});

  @override
  State<MedicineVaccineCatalogScreen> createState() => _MedicineVaccineCatalogScreenState();
}

class _MedicineVaccineCatalogScreenState extends State<MedicineVaccineCatalogScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final values = await Future.wait([MedicineApi.getMedicines(), PurchaseApi.getPurchases()]);
      final medicines = values[0].map((item) => {...item, '_kind': 'medicine'});
      final vaccineLines = values[1].expand((order) {
        final lines = (order['items'] as List? ?? const []).whereType<Map>();
        return lines
            .where((line) => line['product_type']?.toString() == 'vaccine')
            .map((line) => Map<String, dynamic>.from(line));
      });
      final vaccinesByName = <String, Map<String, dynamic>>{};
      for (final item in vaccineLines) {
        final name = (item['product_name'] ?? item['vaccine_name'] ?? '').toString().trim();
        if (name.isEmpty) continue;
        final key = name.toLowerCase();
        final current = vaccinesByName[key];
        if (current == null) {
          vaccinesByName[key] = {...item, 'product_name': name, '_kind': 'vaccine'};
        } else {
          current['quantity'] = ((current['quantity'] as num?)?.toInt() ?? 0) +
              ((item['quantity'] as num?)?.toInt() ?? 0);
          if (current['image']?.toString().isEmpty ?? true) current['image'] = item['image'];
        }
      }
      if (mounted) setState(() { _items = [...medicines, ...vaccinesByName.values]; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _items = []; _loading = false; });
    }
  }

  String _name(Map<String, dynamic> item) => item['_kind'] == 'vaccine'
      ? item['product_name']?.toString() ?? 'វ៉ាក់សាំង'
      : item['name']?.toString() ?? 'ថ្នាំ';

  int _stock(Map<String, dynamic> item) {
    if (item['_kind'] == 'vaccine') {
      return (item['quantity'] as num?)?.toInt() ?? 0;
    }
    final batches = (item['batches'] as List? ?? const []).whereType<Map>();
    return batches.fold<int>(
      0,
      (total, batch) => total + ((batch['quantity'] as num?)?.toInt() ?? 0),
    );
  }

  Future<void> _showDetails(Map<String, dynamic> item) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final isVaccine = item['_kind'] == 'vaccine';
      final details = <(String, String)>[
        ('ប្រភេទ', isVaccine ? 'វ៉ាក់សាំង' : 'ថ្នាំ'),
        ('ស្តុក', '${_stock(item)} ${item['unit'] ?? ''}'.trim()),
        if (!isVaccine && item['generic_name']?.toString().trim().isNotEmpty == true)
          ('ឈ្មោះទូទៅ', item['generic_name'].toString()),
        if (item['category'] != null && item['category'].toString().trim().isNotEmpty)
          ('ប្រភេទផលិតផល', item['category'] is Map ? item['category']['name']?.toString() ?? '' : item['category'].toString()),
        if (item['manufacturer']?.toString().trim().isNotEmpty == true)
          ('ក្រុមហ៊ុនផលិត', item['manufacturer'].toString()),
        if (item['dosage_form']?.toString().trim().isNotEmpty == true)
          ('ទម្រង់ថ្នាំ', item['dosage_form'].toString()),
        if (item['description']?.toString().trim().isNotEmpty == true)
          ('ការពិពណ៌នា', item['description'].toString()),
        if (item['selling_price'] != null) ('តម្លៃលក់', item['selling_price'].toString()),
        if (isVaccine && item['purchase_price'] != null)
          ('តម្លៃទិញ', item['purchase_price'].toString()),
      ];
      return SafeArea(
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .88),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(
                color: const Color(0xFFD5DADD), borderRadius: BorderRadius.circular(4)))),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(height: 240, child: _image(item)),
              ),
              const SizedBox(height: 16),
              Text(_name(item), style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              ...details.map((detail) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 118, child: Text(detail.$1, style: const TextStyle(color: Colors.black54))),
                  Expanded(child: Text(detail.$2, style: const TextStyle(fontWeight: FontWeight.w600))),
                ]),
              )),
            ],
          ),
        ),
      );
    },
  );

  Widget _image(Map<String, dynamic> item) {
    final raw = item['image']?.toString() ?? '';
    Widget fallback() => Container(
      color: item['_kind'] == 'vaccine' ? const Color(0xFFDDF5FA) : const Color(0xFFE4F2EE),
      child: Icon(item['_kind'] == 'vaccine' ? Icons.vaccines_rounded : Icons.medication_rounded,
          size: 58, color: const Color(0xFF087F6B)),
    );
    if (raw.isEmpty) return fallback();
    try {
      final encoded = raw.contains(',') ? raw.split(',').last : raw;
      return Image.memory(base64Decode(encoded), fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback());
    } catch (_) { return fallback(); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: const Text('ថ្នាំ និងវ៉ាក់សាំង', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
    ),
    body: RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF087F6B)))
          : _items.isEmpty
              ? ListView(children: const [SizedBox(height: 140), Center(child: Text('មិនទាន់មានថ្នាំ ឬវ៉ាក់សាំងទេ'))])
              : CustomScrollView(slivers: [
                  const SliverPadding(padding: EdgeInsets.fromLTRB(24, 20, 24, 18), sliver: SliverToBoxAdapter(
                    child: Text('ថ្នាំ និងវ៉ាក់សាំង', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  )),
                  SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 18), sliver: SliverGrid.builder(
                    itemCount: _items.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 18,
                      mainAxisExtent: 264,
                    ),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final vaccine = item['_kind'] == 'vaccine';
                      final amount = _stock(item);
                      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(22),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => _showDetails(item),
                            child: SizedBox.expand(child: _image(item)),
                          ),
                        )),
                        const SizedBox(height: 10),
                        Text(_name(item), maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('${vaccine ? 'វ៉ាក់សាំង' : 'ថ្នាំ'} • ស្តុក $amount', maxLines: 1,
                            overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                      ]);
                    },
                  )),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ]),
    ),
  );
}
