import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../../services/medicine_api.dart';
import '../../services/purchase_api.dart';
import '../../services/supplyer.dart';
import '../../services/unit_api.dart';

class InboundPurchaseScreen extends StatefulWidget {
  final String initialType;
  const InboundPurchaseScreen({super.key, this.initialType = 'medicine'});

  @override
  State<InboundPurchaseScreen> createState() => _InboundPurchaseScreenState();
}

class _InboundPurchaseScreenState extends State<InboundPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  final _price = TextEditingController();
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _medicines = [];
  List<String> _medicineUnits = [];
  List<String> _vaccineUnits = [];
  String? _vaccineUnit;
  String? _medicineUnit;
  String _type = 'medicine';
  String? _supplierId;
  String? _medicineId;
  String _vaccineImage = '';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType == 'vaccine' ? 'vaccine' : 'medicine';
    _loadOptions();
  }

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final values = await Future.wait([
        SupplierApi.getSuppliers(),
        MedicineApi.getMedicines(),
        UnitApi.getUnits(),
      ]);
      if (!mounted) return;
      setState(() {
        _suppliers = values[0];
        _medicines = values[1];
        _medicineUnits = values[2].where((unit) => unit['type'] == 'medicine').map((unit) => unit['name'].toString()).toList();
        _vaccineUnits = values[2].where((unit) => unit['type'] == 'vaccine').map((unit) => unit['name'].toString()).toList();
        _medicineUnits = {..._medicineUnits, ..._medicines.map((medicine) => medicine['unit']?.toString() ?? '').where((unit) => unit.isNotEmpty)}.toList();
        _vaccineUnit = _vaccineUnits.contains('ml') ? 'ml' : (_vaccineUnits.isEmpty ? null : _vaccineUnits.first);
        _loading = false;
      });
    } catch (error) {
      if (mounted) setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final quantity = int.tryParse(_quantity.text.trim());
    final price = double.tryParse(_price.text.trim());
    if (quantity == null || price == null || _supplierId == null) return;
    setState(() => _saving = true);
    try {
      Map<String, dynamic>? selectedMedicine;
      for (final item in _medicines) {
        if (item['_id']?.toString() == _medicineId) {
          selectedMedicine = item;
          break;
        }
      }
      await PurchaseApi.createInboundPurchase(
        supplierId: _supplierId!,
        productType: _type,
        productName: _type == 'vaccine'
            ? _name.text.trim()
            : selectedMedicine?['name']?.toString() ?? '',
        medicineId: _type == 'medicine' ? _medicineId : null,
        quantity: quantity,
        purchasePrice: price,
        unit: _type == 'vaccine'
            ? _vaccineUnit ?? ''
            : _medicineUnit ?? selectedMedicine?['unit']?.toString() ?? '',
        image: _type == 'vaccine' ? _vaccineImage : selectedMedicine?['image']?.toString() ?? '',
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _pickVaccineImage() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 65,
        maxWidth: 1000,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) throw StateError('រូបភាពទទេ');
      if (mounted) {
        setState(() => _vaccineImage = 'data:image/jpeg;base64,${base64Encode(bytes)}');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('មិនអាចជ្រើសរើសរូបវ៉ាក់សាំងបានទេ: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF9),
      appBar: AppBar(title: const Text('កត់ត្រាទិញចូល'), backgroundColor: Colors.white),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    widget.initialType == 'vaccine' ? 'ទិញចូលវ៉ាក់សាំង' : 'ទិញចូលវ៉ាក់សាំង ឬថ្នាំ',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(widget.initialType == 'vaccine'
                      ? 'កត់ត្រាវ៉ាក់សាំង អ្នកផ្គត់ផ្គង់ ចំនួន និងតម្លៃទិញ។'
                      : 'កត់ត្រាអ្នកផ្គត់ផ្គង់ ចំនួន និងតម្លៃទិញ។'),
                  const SizedBox(height: 20),
                  if (widget.initialType != 'vaccine') ...[
                    DropdownButtonFormField<String>(
                      value: _type,
                      decoration: const InputDecoration(labelText: 'ប្រភេទទំនិញ', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
                      items: const [
                        DropdownMenuItem(value: 'medicine', child: Text('ថ្នាំ')),
                        DropdownMenuItem(value: 'vaccine', child: Text('វ៉ាក់សាំង')),
                      ],
                      onChanged: (value) => setState(() {
                        _type = value ?? 'medicine';
                        _medicineId = null;
                        _medicineUnit = null;
                        _vaccineUnit = _vaccineUnits.contains('ml') ? 'ml' : (_vaccineUnits.isEmpty ? null : _vaccineUnits.first);
                      }),
                    ),
                    const SizedBox(height: 14),
                  ],
                  DropdownButtonFormField<String>(
                    value: _supplierId,
                    decoration: const InputDecoration(labelText: 'អ្នកផ្គត់ផ្គង់ *', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
                    items: _suppliers.map((item) => DropdownMenuItem(
                      value: item['_id']?.toString(),
                      child: Text(item['name']?.toString() ?? ''),
                    )).toList(),
                    validator: (value) => value == null ? 'សូមជ្រើសរើសអ្នកផ្គត់ផ្គង់' : null,
                    onChanged: (value) => setState(() => _supplierId = value),
                  ),
                  const SizedBox(height: 14),
                  if (_type == 'medicine')
                    DropdownButtonFormField<String>(
                      value: _medicineId,
                      decoration: const InputDecoration(labelText: 'ថ្នាំ *', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
                      items: _medicines.map((item) => DropdownMenuItem(
                        value: item['_id']?.toString(),
                        child: Text(item['name']?.toString() ?? ''),
                      )).toList(),
                      validator: (value) => value == null ? 'សូមជ្រើសរើសថ្នាំ' : null,
                      onChanged: (value) {
                        final selected = _medicines.where((item) => item['_id']?.toString() == value).firstOrNull;
                        setState(() {
                          _medicineId = value;
                          final existingUnit = selected?['unit']?.toString() ?? '';
                          _medicineUnit = _medicineUnits.contains(existingUnit) ? existingUnit : (_medicineUnits.isEmpty ? null : _medicineUnits.first);
                        });
                      },
                    )
                  else
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'ឈ្មោះវ៉ាក់សាំង *', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
                      validator: (value) => value == null || value.trim().isEmpty ? 'សូមបញ្ចូលឈ្មោះវ៉ាក់សាំង' : null,
                    ),
                  if (_type == 'vaccine') ...[
                    const SizedBox(height: 14),
                    Row(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 72,
                          height: 72,
                          color: const Color(0xFFEAF5F2),
                          child: _vaccineImage.isEmpty
                              ? const Icon(Icons.vaccines_outlined, color: Color(0xFF0E6B5C))
                              : Image.memory(base64Decode(_vaccineImage.split(',').last), fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: OutlinedButton.icon(
                        onPressed: _saving ? null : _pickVaccineImage,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(_vaccineImage.isEmpty ? 'ជ្រើសរូបវ៉ាក់សាំង' : 'ប្តូររូបវ៉ាក់សាំង'),
                      )),
                      if (_vaccineImage.isNotEmpty)
                        IconButton(onPressed: _saving ? null : () => setState(() => _vaccineImage = ''), icon: const Icon(Icons.close_rounded)),
                    ]),
                  ],
                  if (_type == 'medicine' && _medicineId != null) ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _medicineUnits.contains(_medicineUnit) ? _medicineUnit : null,
                      decoration: const InputDecoration(labelText: 'ខ្នាតថ្នាំ *', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
                      items: _medicineUnits.map((unit) => DropdownMenuItem(value: unit, child: Text(unit))).toList(),
                      onChanged: (value) => setState(() => _medicineUnit = value),
                      validator: (value) => value == null ? 'សូមជ្រើសរើសខ្នាតថ្នាំ' : null,
                    ),
                  ] else if (_type == 'vaccine') ...[
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _vaccineUnits.contains(_vaccineUnit) ? _vaccineUnit : null,
                      decoration: const InputDecoration(labelText: 'ខ្នាតវ៉ាក់សាំង *', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
                      items: _vaccineUnits.map((unit) => DropdownMenuItem(value: unit, child: Text(unit))).toList(),
                      onChanged: (value) => setState(() => _vaccineUnit = value),
                      validator: (value) => value == null ? 'សូមជ្រើសរើសខ្នាតវ៉ាក់សាំង' : null,
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _quantity,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'ចំនួន *', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
                    validator: (value) {
                      final parsed = int.tryParse(value?.trim() ?? '');
                      return parsed == null || parsed < 1 ? 'ចំនួនត្រូវធំជាង 0' : null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _price,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'តម្លៃទិញក្នុងមួយឯកតា *', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
                    validator: (value) {
                      final parsed = double.tryParse(value?.trim() ?? '');
                      return parsed == null || parsed < 0 ? 'សូមបញ្ចូលតម្លៃត្រឹមត្រូវ' : null;
                    },
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_outlined),
                    label: const Text('រក្សាទុកការទិញចូល'),
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0E6B5C), padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                ],
              ),
            ),
    );
  }
}
