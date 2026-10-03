import 'package:flutter/material.dart';
import '../../services/unit_api.dart';

class UnitsScreen extends StatefulWidget {
  const UnitsScreen({super.key});
  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> {
  List<Map<String, dynamic>> _units = [];
  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = _units.isEmpty; _refreshing = _units.isNotEmpty; _error = null; });
    try { final units = await UnitApi.getUnits(); if (mounted) setState(() => _units = units); }
    catch (error) { if (mounted) setState(() => _error = '$error'); }
    finally { if (mounted) setState(() { _loading = false; _refreshing = false; }); }
  }

  Future<void> _add(String type) async {
    final name = await showDialog<String>(context: context, builder: (_) => _UnitNameDialog(type: type));
    if (name == null || name.isEmpty) return;
    try {
      final created = await UnitApi.createUnit(type: type, name: name);
      if (mounted) setState(() => _units = [..._units, created]);
    }
    catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error'))); }
  }

  Future<void> _delete(Map<String, dynamic> unit) async {
    try { await UnitApi.deleteUnit(unit['_id'].toString()); await _load(); }
    catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error'))); }
  }

  Widget _section(String type, String title, String subtitle, IconData icon) {
    final rows = _units.where((unit) => unit['type'] == type).toList();
    return Card(color: Colors.white, margin: const EdgeInsets.only(bottom: 16), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: const Color(0xFF0E6B5C)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), Text(subtitle, style: const TextStyle(color: Colors.black54))])), IconButton(onPressed: () => _add(type), icon: const Icon(Icons.add_circle, color: Color(0xFF0E6B5C)))]),
      const Divider(),
      if (rows.isEmpty) const Text('មិនទាន់មានខ្នាត'),
      Wrap(spacing: 8, runSpacing: 8, children: rows.map((unit) => InputChip(label: Text(unit['name']?.toString() ?? ''), onDeleted: () => _delete(unit))).toList()),
    ])));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F8F7),
    appBar: AppBar(title: const Text('គ្រប់គ្រងខ្នាត'), backgroundColor: Colors.white, actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!), TextButton(onPressed: _load, child: const Text('ព្យាយាមម្ដងទៀត'))]))
            : Column(children: [
                if (_refreshing) const LinearProgressIndicator(minHeight: 2),
                Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [const Text('បង្កើតខ្នាតម្តង ហើយជ្រើសប្រើក្នុងទម្រង់ថ្នាំ និងវ៉ាក់សាំង។', style: TextStyle(fontSize: 15)), const SizedBox(height: 14), _section('medicine', 'ខ្នាតថ្នាំ', 'ឧ. kg, g, mg, គ្រាប់, ដប', Icons.medication_outlined), _section('vaccine', 'ខ្នាតវ៉ាក់សាំង', 'ឧ. ml, l, dose, vial', Icons.vaccines_outlined)])),
              ]),
  );
}

class _UnitNameDialog extends StatefulWidget {
  final String type;
  const _UnitNameDialog({required this.type});

  @override
  State<_UnitNameDialog> createState() => _UnitNameDialogState();
}

class _UnitNameDialogState extends State<_UnitNameDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.type == 'medicine' ? 'បន្ថែមខ្នាតថ្នាំ' : 'បន្ថែមខ្នាតវ៉ាក់សាំង'),
    content: TextField(controller: _controller, autofocus: true, decoration: const InputDecoration(labelText: 'ឈ្មោះខ្នាត', hintText: 'ឧ. g, ml, vial')),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('បោះបង់')),
      FilledButton(onPressed: () => Navigator.pop(context, _controller.text.trim()), child: const Text('បន្ថែម')),
    ],
  );
}
