import 'package:flutter/material.dart';
import '../../services/vet_api.dart';

const _treatmentGreen = Color(0xFF008674);

class TreatmentListScreen extends StatefulWidget {
  const TreatmentListScreen({super.key});
  @override
  State<TreatmentListScreen> createState() => _TreatmentListScreenState();
}

class _TreatmentListScreenState extends State<TreatmentListScreen> {
  late Future<List<Map<String, dynamic>>> _records;
  @override
  void initState() { super.initState(); _records = _loadRecords(); }
  Future<List<Map<String, dynamic>>> _loadRecords() async {
    final result = await Future.wait([VetApi.getMedicalRecords(), VetApi.getPatients()]);
    final owners = result[1] as List<Map<String, dynamic>>;
    final ownerById = <String, Map<String, dynamic>>{
      for (final owner in owners) owner['_id']?.toString() ?? '': owner,
    };
    return (result[0] as List<Map<String, dynamic>>).map((record) {
      final owner = ownerById[record['owner_id']?.toString() ?? ''];
      final animals = (owner?['animals'] as List? ?? const []).whereType<Map>();
      Map? animal;
      for (final item in animals) {
        if (item['_id']?.toString() == record['animal_id']?.toString()) {
          animal = item;
          break;
        }
      }
      return {...record, 'animal_name': animal?['name']?.toString() ?? 'អ្នកជំងឺ'};
    }).toList();
  }
  Future<void> _reload() async {
    final next = _loadRecords();
    setState(() => _records = next);
    try { await next; } catch (_) {}
  }

  Future<void> _createTreatment() async {
    final created = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const CreateTreatmentScreen()),
    );
    if (!mounted || created == null) return;
    List<Map<String, dynamic>> current;
    try { current = await _records; } catch (_) { current = []; }
    if (!mounted) return;
    setState(() => _records = Future.value([created, ...current]));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(backgroundColor: Colors.white, surfaceTintColor: Colors.white, title: const Text('ការព្យាបាល', style: TextStyle(fontWeight: FontWeight.w800)), leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 19), onPressed: () => Navigator.maybePop(context)), actions: [
      IconButton(onPressed: _createTreatment, icon: const Icon(Icons.add_circle, color: _treatmentGreen, size: 34)),
    ]),
    body: FutureBuilder<List<Map<String, dynamic>>>(future: _records, builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: _treatmentGreen));
      if (snapshot.hasError) return _empty('មិនអាចទាញទិន្នន័យបាន', retry: _reload);
      final rows = snapshot.data ?? [];
      if (rows.isEmpty) return _empty('មិនទាន់មានកំណត់ត្រាការព្យាបាល');
      return RefreshIndicator(
        color: _treatmentGreen,
        onRefresh: _reload,
        child: ListView.separated(
          padding: const EdgeInsets.all(18),
          itemCount: rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _TreatmentCard(
            record: rows[index],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TreatmentDetailScreen(record: rows[index]),
              ),
            ),
          ),
        ),
      );
    }),
    floatingActionButton: FloatingActionButton.extended(backgroundColor: _treatmentGreen, foregroundColor: Colors.white, onPressed: _createTreatment, icon: const Icon(Icons.add), label: const Text('កត់ត្រាការព្យាបាល')),
  );
}

class _TreatmentCard extends StatelessWidget {
  final Map<String, dynamic> record;
  final VoidCallback onTap;
  const _TreatmentCard({required this.record, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final items = _items(record);
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD9D9D9)), borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Container(width: 58, height: 58, decoration: BoxDecoration(color: const Color(0xFFE6E6E6), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.pets, color: _treatmentGreen, size: 30)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_animalName(record), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)), Text(_date(record['visit_date']), style: const TextStyle(color: Colors.black54))])), const Icon(Icons.chevron_right)]),
      const SizedBox(height: 14), Text(record['diagnosis']?.toString().isNotEmpty == true ? record['diagnosis'].toString() : 'មិនទាន់បញ្ចូលរោគវិនិច្ឆ័យ', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      if (items.isNotEmpty) ...[const SizedBox(height: 8), Text(items.map((item) => item['medicine_name'] ?? '').join(' • '), maxLines: 2, overflow: TextOverflow.ellipsis)],
    ])));
  }
}

class TreatmentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> record;
  const TreatmentDetailScreen({super.key, required this.record});
  @override
  Widget build(BuildContext context) {
    final items = _items(record);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'ការព្យាបាល',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 19),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        children: [
          _panel(
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E2E2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.pets,
                    color: _treatmentGreen,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _animalName(record),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _tag('សុខភាព'),
                        ],
                      ),
                      Text(
                        'កត់ត្រាថ្ងៃ ${_date(record['visit_date'])}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'ការធ្វើរោគវិនិច្ឆ័យ',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 9),
          _panel(
            child: Row(
              children: [
                const Icon(
                  Icons.health_and_safety_outlined,
                  color: _treatmentGreen,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record['diagnosis']?.toString() ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      if ((record['symptoms']?.toString() ?? '').isNotEmpty)
                        Text(record['symptoms'].toString()),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'ផែនការព្យាបាល',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 9),
          _panel(
            child: Text(
              record['treatment']?.toString().isNotEmpty == true
                  ? record['treatment'].toString()
                  : 'មិនមានព័ត៌មាន',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'ថ្នាំដែលបានចេញវេជ្ជបញ្ជា',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 9),
          if (items.isEmpty)
            _panel(child: const Text('មិនមានថ្នាំក្នុងកំណត់ត្រានេះ'))
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _panel(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E2E2),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.medication_outlined,
                          color: _treatmentGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['medicine_name']?.toString() ?? '',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${item['dosage'] ?? ''} ${item['unit'] ?? ''} • ${item['frequency'] ?? ''}',
                            ),
                            Text(
                              'រយៈពេល ${item['duration'] ?? ''}',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CreateTreatmentScreen extends StatefulWidget {
  const CreateTreatmentScreen({super.key});
  @override
  State<CreateTreatmentScreen> createState() => _CreateTreatmentScreenState();
}

class _CreateTreatmentScreenState extends State<CreateTreatmentScreen> {
  final _form = GlobalKey<FormState>();
  final _symptoms = TextEditingController();
  final _diagnosis = TextEditingController();
  final _treatment = TextEditingController();
  final _dosage = TextEditingController();
  final _frequency = TextEditingController();
  final _duration = TextEditingController();
  List<Map<String, dynamic>> _owners = [], _medicines = [];
  Map<String, dynamic>? _owner, _animal, _medicine;
  bool _loading = true, _saving = false;
  String? _error;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async { try { final data = await Future.wait([VetApi.getPatients(), VetApi.getMedicines()]); if (mounted) setState(() { _owners = data[0]; _medicines = data[1]; _loading = false; }); } catch (e) { if (mounted) setState(() { _error = e.toString(); _loading = false; }); } }
  @override
  void dispose() { _symptoms.dispose(); _diagnosis.dispose(); _treatment.dispose(); _dosage.dispose(); _frequency.dispose(); _duration.dispose(); super.dispose(); }
  List<Map<String, dynamic>> _animals() => (_owner?['animals'] as List? ?? const []).whereType<Map<String, dynamic>>().toList();
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: Colors.white, appBar: AppBar(backgroundColor: Colors.white, surfaceTintColor: Colors.white, title: const Text('កត់ត្រាការព្យាបាល', style: TextStyle(fontWeight: FontWeight.w800)), leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 19), onPressed: () => Navigator.pop(context))), body: _loading ? const Center(child: CircularProgressIndicator(color: _treatmentGreen)) : _error != null ? _empty(_error!, retry: _load) : Form(key: _form, child: ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 30), children: [
    _drop<Map<String, dynamic>>('ម្ចាស់សត្វ', _owner, _owners, (item) => item['name']?.toString() ?? '', (v) => setState(() { _owner = v; _animal = null; })),
    const SizedBox(height: 12), _drop<Map<String, dynamic>>('អ្នកជំងឺ', _animal, _animals(), (item) => item['name']?.toString() ?? '', (v) => setState(() => _animal = v)),
    const SizedBox(height: 12), _input('រោគសញ្ញា', _symptoms, required: false), const SizedBox(height: 12), _input('រោគវិនិច្ឆ័យ', _diagnosis), const SizedBox(height: 12), _input('ផែនការព្យាបាល', _treatment, lines: 3),
    const SizedBox(height: 18), const Text('ថ្នាំដែលបានចេញវេជ្ជបញ្ជា', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 10),
    _drop<Map<String, dynamic>>('ជ្រើសរើសថ្នាំ', _medicine, _medicines, (item) => item['name']?.toString() ?? '', (v) => setState(() => _medicine = v), required: false),
    if (_medicine != null) ...[const SizedBox(height: 12), InputDecorator(decoration: _decoration('ខ្នាត'), child: Text((_medicine!['unit']?.toString().trim().isNotEmpty ?? false) ? _medicine!['unit'].toString() : 'មិនបានកំណត់')), const SizedBox(height: 12), _input('កម្រិតថ្នាំ', _dosage, required: false, hint: 'ឧ. 10 mg/kg'), const SizedBox(height: 12), _input('របៀបប្រើ', _frequency, required: false, hint: 'ឧ. 2 ដងក្នុងមួយថ្ងៃ'), const SizedBox(height: 12), _input('រយៈពេល', _duration, required: false, hint: 'ឧ. 7 ថ្ងៃ')],
    const SizedBox(height: 24), SizedBox(height: 54, child: FilledButton(onPressed: _saving ? null : _save, style: FilledButton.styleFrom(backgroundColor: _treatmentGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('រក្សាទុកការព្យាបាល', style: TextStyle(fontWeight: FontWeight.w700)))),
  ])));

  Widget _drop<T extends Map<String, dynamic>>(String label, T? value, List<T> options, String Function(T) title, ValueChanged<T?> onChanged, {bool required = true}) => DropdownButtonFormField<T>(value: value, isExpanded: true, decoration: _decoration(label), hint: Text(label), items: options.map((item) => DropdownMenuItem<T>(value: item, child: Text(title(item), overflow: TextOverflow.ellipsis))).toList(), onChanged: onChanged, validator: (v) => required && v == null ? 'សូមជ្រើសរើស$label' : null);
  Widget _input(String label, TextEditingController controller, {bool required = true, int lines = 1, String? hint}) => TextFormField(controller: controller, maxLines: lines, decoration: _decoration(label).copyWith(hintText: hint), validator: (value) => required && (value == null || value.trim().isEmpty) ? 'សូមបំពេញ$label' : null);
  InputDecoration _decoration(String label) => InputDecoration(labelText: label, contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFD8D8D8))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _treatmentGreen, width: 1.5)));
  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final prescriptions = _medicine == null ? <Map<String, dynamic>>[] : [<String, dynamic>{'medicine_id': _medicine!['_id'], 'medicine_name': _medicine!['name']?.toString() ?? '', 'unit': _medicine!['unit']?.toString() ?? '', 'dosage': _dosage.text.trim(), 'frequency': _frequency.text.trim(), 'duration': _duration.text.trim()}];
    setState(() => _saving = true);
    try { final created = await VetApi.createMedicalRecord(ownerId: _owner!['_id'].toString(), animalId: _animal!['_id'].toString(), symptoms: _symptoms.text.trim(), diagnosis: _diagnosis.text.trim(), treatment: _treatment.text.trim(), prescriptionItems: prescriptions); if (mounted) Navigator.pop(context, {...created, 'animal_name': _animal!['name']?.toString() ?? 'អ្នកជំងឺ'}); }
    catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))); }
    finally { if (mounted) setState(() => _saving = false); }
  }
}

List<Map<String, dynamic>> _items(Map<String, dynamic> record) {
  final prescription = record['prescription'];
  final raw = prescription is Map ? prescription['items'] : null;
  return (raw as List? ?? const []).whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
}
String _animalName(Map<String, dynamic> record) => record['animal_name']?.toString() ?? 'អ្នកជំងឺ';
String _date(dynamic value) { final date = DateTime.tryParse(value?.toString() ?? ''); return date == null ? '' : '${date.day.toString().padLeft(2, '0')} ${_month(date.month)}, ${date.year}'; }
String _month(int month) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month - 1];
Widget _tag(String text) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFE1E1E1), borderRadius: BorderRadius.circular(20)), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)));
Widget _panel({required Widget child}) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD9D9D9)), borderRadius: BorderRadius.circular(17)), child: child);
Widget _empty(String text, {Future<void> Function()? retry}) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(text, textAlign: TextAlign.center), if (retry != null) TextButton(onPressed: retry, child: const Text('ព្យាយាមម្តងទៀត'))]));
