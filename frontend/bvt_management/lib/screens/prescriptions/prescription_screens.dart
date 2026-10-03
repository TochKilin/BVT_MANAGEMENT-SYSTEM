import 'package:flutter/material.dart';
import '../../services/prescription_api.dart';
import '../../services/vet_api.dart';

const _green = Color(0xFF008674);
const _ink = Color(0xFF19152B);

class PrescriptionListScreen extends StatefulWidget {
  const PrescriptionListScreen({super.key});
  @override
  State<PrescriptionListScreen> createState() => _PrescriptionListScreenState();
}

class _PrescriptionListScreenState extends State<PrescriptionListScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  int _filter = 0;
  @override
  void initState() { super.initState(); _future = PrescriptionApi.getAll(); }
  Future<void> _refresh() async {
    final next = PrescriptionApi.getAll();
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {
      // FutureBuilder displays the request error and offers a retry.
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(backgroundColor: Colors.white, surfaceTintColor: Colors.white, title: const Text('វេជ្ជបញ្ជា', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black)), actions: [
      Padding(padding: const EdgeInsets.only(right: 16), child: FilledButton(onPressed: () async {
        final created = await Navigator.push<Map<String, dynamic>>(context, MaterialPageRoute(builder: (_) => const CreatePrescriptionScreen()));
        if (!mounted || created == null) return;
        List<Map<String, dynamic>> current;
        try { current = await _future; } catch (_) { current = []; }
        if (!mounted) return;
        setState(() => _future = Future.value([...current, created]));
        await _refresh();
      }, style: FilledButton.styleFrom(backgroundColor: _green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), minimumSize: const Size(52, 52)), child: const Icon(Icons.add, size: 28))),
    ]),
    body: Column(children: [
      FutureBuilder<List<Map<String, dynamic>>>(future: _future, builder: (context, snap) {
        final records = snap.data ?? [];
        final active = records.where((r) => r['status'] == 'active').length;
        return Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 16), child: Row(children: [const Text('វេជ្ជបញ្ជា', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)), const SizedBox(width: 12), _pill('$active Active')]));
      }),
      SizedBox(height: 42, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), children: ['ទាំងអស់', 'សកម្ម', 'បានបញ្ចប់', 'អស់សុពលភាព'].asMap().entries.map((e) => Padding(padding: const EdgeInsets.only(right: 10), child: ChoiceChip(label: Text(e.value), selected: _filter == e.key, onSelected: (_) => setState(() => _filter = e.key), selectedColor: _green, backgroundColor: const Color(0xFFE0E0E0), labelStyle: TextStyle(color: _filter == e.key ? Colors.white : Colors.black, fontWeight: FontWeight.w700), showCheckmark: false))).toList())),
      const SizedBox(height: 22),
      Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(future: _future, builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: _green));
        if (snap.hasError) return _stateMessage('មិនអាចទាញយកទិន្នន័យបាន', onRetry: _refresh);
        final all = snap.data ?? [];
        final rows = all.where((r) => _filter == 0 || (_filter == 1 ? r['status'] == 'active' : _filter == 2 ? r['status'] == 'completed' : r['status'] == 'expired')).toList();
        if (rows.isEmpty) return _stateMessage('មិនទាន់មានវេជ្ជបញ្ជា');
        return RefreshIndicator(color: _green, onRefresh: _refresh, child: ListView.separated(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), itemCount: rows.length, separatorBuilder: (_, __) => const SizedBox(height: 14), itemBuilder: (context, i) => _PrescriptionCard(item: rows[i])));
      })),
    ]),
  );
}

class _PrescriptionCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _PrescriptionCard({required this.item});
  @override
  Widget build(BuildContext context) {
    final status = item['status']?.toString() ?? 'active';
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD8D8D8)), borderRadius: BorderRadius.circular(17)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 70, height: 70, decoration: BoxDecoration(color: const Color(0xFFE6E6E6), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.pets, color: _green, size: 34)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item['medicine_name']?.toString() ?? 'ថ្នាំ', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)), Text('${item['dosage'] ?? ''} • ${item['frequency'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 5), Text('រយៈពេល ${item['duration'] ?? ''}', style: const TextStyle(color: Colors.black54))])), Text(status == 'active' ? 'សកម្ម' : status, style: const TextStyle(color: _green, fontWeight: FontWeight.bold))]),
      const Divider(height: 24), Row(children: [const Icon(Icons.calendar_today_outlined, size: 16, color: _green), const SizedBox(width: 6), Expanded(child: Text(_date(item['created_at']))), Text('${item['quantity'] ?? 1} ${item['unit']?.toString().isNotEmpty == true ? item['unit'] : 'ឯកតា'}', style: const TextStyle(fontWeight: FontWeight.w700))]),
    ]));
  }
  String _date(dynamic raw) { final d = DateTime.tryParse(raw?.toString() ?? ''); return d == null ? '' : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}'; }
}

class CreatePrescriptionScreen extends StatefulWidget {
  const CreatePrescriptionScreen({super.key});
  @override
  State<CreatePrescriptionScreen> createState() => _CreatePrescriptionScreenState();
}

class _CreatePrescriptionScreenState extends State<CreatePrescriptionScreen> {
  final _form = GlobalKey<FormState>();
  final _dosage = TextEditingController();
  final _frequency = TextEditingController();
  final _duration = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  final _notes = TextEditingController();
  List<Map<String, dynamic>> _owners = [], _medicines = [];
  Map<String, dynamic>? _owner, _animal, _medicine;
  bool _loading = true, _saving = false;
  String? _error;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final values = await Future.wait([VetApi.getPatients(), VetApi.getMedicines()]); if (!mounted) return; setState(() { _owners = values[0]; _medicines = values[1]; _loading = false; }); }
    catch (e) { if (mounted) setState(() { _loading = false; _error = e.toString(); }); }
  }
  @override
  void dispose() { _dosage.dispose(); _frequency.dispose(); _duration.dispose(); _quantity.dispose(); _notes.dispose(); super.dispose(); }
  List<Map<String, dynamic>> _animals(Map<String, dynamic>? owner) => (owner?['animals'] as List? ?? const []).whereType<Map<String, dynamic>>().toList();
  String _name(Map<String, dynamic> item) => item['name']?.toString() ?? item['medicine_name']?.toString() ?? '';
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFFD8D8D8), body: SafeArea(child: Align(alignment: Alignment.bottomCenter, child: Container(width: double.infinity, height: MediaQuery.sizeOf(context).height * .93, padding: const EdgeInsets.fromLTRB(22, 10, 22, 20), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))), child: Column(children: [Container(width: 58, height: 7, decoration: BoxDecoration(color: const Color(0xFFD8D8D8), borderRadius: BorderRadius.circular(8))), const SizedBox(height: 32), Row(children: [IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new, size: 18)), const Text('វេជ្ជបញ្ជាថ្មី', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800))]), const SizedBox(height: 14), Expanded(child: _loading ? const Center(child: CircularProgressIndicator(color: _green)) : _error != null ? _stateMessage(_error!, onRetry: _load) : Form(key: _form, child: ListView(children: [
    _field('ជ្រើសរើសម្ចាស់សត្វ', child: DropdownButtonFormField<Map<String, dynamic>>(value: _owner, isExpanded: true, decoration: _decoration(), hint: const Text('ជ្រើសរើសម្ចាស់សត្វ'), items: _owners.map((o) => DropdownMenuItem(value: o, child: Text(o['name']?.toString() ?? ''))).toList(), onChanged: (v) => setState(() { _owner = v; _animal = null; }), validator: (v) => v == null ? 'សូមជ្រើសរើសម្ចាស់សត្វ' : null)),
    const SizedBox(height: 14), _field('ជ្រើសរើសសត្វ', child: DropdownButtonFormField<Map<String, dynamic>>(value: _animal, isExpanded: true, decoration: _decoration(), hint: const Text('ជ្រើសរើសសត្វ'), items: _animals(_owner).map((a) => DropdownMenuItem(value: a, child: Text(a['name']?.toString() ?? ''))).toList(), onChanged: (v) => setState(() => _animal = v), validator: (v) => v == null ? 'សូមជ្រើសរើសសត្វ' : null)),
    const SizedBox(height: 14), _field('ជ្រើសរើសថ្នាំ', child: DropdownButtonFormField<Map<String, dynamic>>(value: _medicine, isExpanded: true, decoration: _decoration(), hint: const Text('ស្វែងរកថ្នាំ'), items: _medicines.map((m) => DropdownMenuItem(value: m, child: Text(_name(m)))).toList(), onChanged: (v) => setState(() => _medicine = v), validator: (v) => v == null ? 'សូមជ្រើសរើសថ្នាំ' : null)),
    if (_medicine != null) ...[const SizedBox(height: 14), InputDecorator(decoration: _decoration().copyWith(labelText: 'ខ្នាត'), child: Text((_medicine!['unit']?.toString().trim().isNotEmpty ?? false) ? _medicine!['unit'].toString() : 'មិនបានកំណត់'))],
    const SizedBox(height: 14), _text('កម្រិតថ្នាំ', _dosage, hint: 'ឧ. 250 mg'), const SizedBox(height: 14), _text('ប្រេកង់ប្រើប្រាស់', _frequency, hint: 'ឧ. BID • 2 ដង/ថ្ងៃ'), const SizedBox(height: 14), _text('រយៈពេល', _duration, hint: 'ឧ. 10 ថ្ងៃ'), const SizedBox(height: 14), _text('បរិមាណ', _quantity, number: true), const SizedBox(height: 14), _text('កំណត់ចំណាំ', _notes, required: false),
    const SizedBox(height: 25), SizedBox(height: 56, child: FilledButton(onPressed: _saving ? null : _save, style: FilledButton.styleFrom(backgroundColor: _green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: _saving ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('រក្សាទុកវេជ្ជបញ្ជា', style: TextStyle(fontWeight: FontWeight.w700)))), const SizedBox(height: 16),
    ]))),
    ])))));

  Widget _field(String label, {required Widget child}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [child]);
  InputDecoration _decoration() => InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFD8D8D8))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFD8D8D8))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: _green, width: 1.5)));
  Widget _text(String label, TextEditingController c, {String? hint, bool number = false, bool required = true}) => TextFormField(controller: c, keyboardType: number ? TextInputType.number : TextInputType.text, decoration: _decoration().copyWith(labelText: label, hintText: hint), validator: (v) => required && (v == null || v.trim().isEmpty) ? 'សូមបំពេញ $label' : null);
  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try { final created = await PrescriptionApi.create({'owner_id': _owner!['_id'], 'animal_id': _animal!['_id'], 'medicine_id': _medicine!['_id'], 'medicine_name': _name(_medicine!), 'unit': _medicine!['unit']?.toString() ?? '', 'dosage': _dosage.text.trim(), 'frequency': _frequency.text.trim(), 'duration': _duration.text.trim(), 'quantity': int.tryParse(_quantity.text) ?? 1, 'notes': _notes.text.trim()}); if (mounted) Navigator.pop(context, created); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
    finally { if (mounted) setState(() => _saving = false); }
  }
}

Widget _pill(String text) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFDADADA), borderRadius: BorderRadius.circular(20)), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)));
Widget _stateMessage(String text, {Future<void> Function()? onRetry}) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(text, textAlign: TextAlign.center), if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('ព្យាយាមម្តងទៀត'))]));
