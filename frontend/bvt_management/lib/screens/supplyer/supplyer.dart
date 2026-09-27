import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../home/Home_screen.dart' show ChartColors;
import '../../services/supplyer.dart';
import '../../services/vet_api.dart' show ApiException;

class SupplierScreen extends StatefulWidget {
  const SupplierScreen({super.key});

  @override
  State<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
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

  // Fetch suppliers from the API
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _all = await SupplierApi.getSuppliers();
    } catch (_) {
      _all = [];
    }
    _applyFilter();
    if (mounted) setState(() => _loading = false);
  }

  // Filter the list by name, contact, phone or email
  void _applyFilter() {
    final query = _search.text.trim().toLowerCase();
    setState(() {
      _filtered = query.isEmpty
          ? _all
          : _all.where((s) {
              final haystack =
                  '${s['name']} ${s['contact_person']} ${s['phone']} ${s['email']}'
                      .toLowerCase();
              return haystack.contains(query);
            }).toList();
    });
  }

  Future<void> _openAdd() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SupplierForm(),
    );
    if (saved == true) _load();
  }

  Future<void> _openEdit(Map<String, dynamic> supplier) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SupplierForm(existing: supplier),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Map<String, dynamic> supplier) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('លុបអ្នកផ្គត់ផ្គង់?'),
        content: Text('តើអ្នកប្រាកដថាចង់លុប "${supplier['name']}" មែនទេ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('បោះបង់'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE05C86),
            ),
            child: const Text('លុប'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await SupplierApi.deleteSupplier(supplier['_id'].toString());
      _all.removeWhere((s) => s['_id'] == supplier['_id']);
      _applyFilter();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('បានលុបរួចរាល់')),
        );
      }
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('មានបញ្ហា: $e');
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF0E6B5C),
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 18),
                _buildSearchBar(),
                const SizedBox(height: 20),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF0E6B5C)),
                    ),
                  )
                else if (_filtered.isEmpty)
                  _emptyState()
                else
                  ..._filtered.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SupplierCard(
                        supplier: s,
                        onEdit: () => _openEdit(s),
                        onDelete: () => _delete(s),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'អ្នកផ្គត់ផ្គង់',
                style: GoogleFonts.fraunces(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A202C),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_all.length} អ្នកផ្គត់ផ្គង់សរុប',
                style: const TextStyle(color: Color(0xFF4A5568), fontSize: 13),
              ),
            ],
          ),
        ),
        Material(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: _openAdd,
            borderRadius: BorderRadius.circular(14),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.add_rounded, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _cardDeco(16),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF0E6B5C)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'ស្វែងរកអ្នកផ្គត់ផ្គង់...',
                hintStyle: TextStyle(color: Color(0xFF1A202C)),
                border: InputBorder.none,
              ),
            ),
          ),
          if (_search.text.isNotEmpty)
            IconButton(
              onPressed: () => _search.clear(),
              icon: const Icon(Icons.close_rounded, color: Color(0xFF1A202C)),
            ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 50),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: Color(0xFF0E6B5C),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              color: Color(0xFF0E6B5C),
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'មិនទាន់មានអ្នកផ្គត់ផ្គង់ទេ',
            style: TextStyle(
              color: Color(0xFF1A202C),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'ចុច + ដើម្បីបន្ថែមអ្នកផ្គត់ផ្គង់ថ្មី',
            style: TextStyle(color: Color(0xFF4A5568), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  final Map<String, dynamic> supplier;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SupplierCard({
    required this.supplier,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = supplier['name']?.toString() ?? '-';
    final contact = supplier['contact_person']?.toString() ?? '';
    final phone = supplier['phone']?.toString() ?? '';
    final email = supplier['email']?.toString() ?? '';
    final status = supplier['status']?.toString() ?? 'active';
    final initials = name.trim().isEmpty
        ? '?'
        : name
            .trim()
            .split(RegExp(r'\s+'))
            .map((w) => w.isNotEmpty ? w[0] : '')
            .take(2)
            .join()
            .toUpperCase();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Initials badge
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF0E6B5C),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Color(0xFF0E6B5C),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A202C),
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Status dot
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: status == 'active'
                                ? const Color(0xFF0E6B5C)
                                : const Color(0xFF4A5568),
                          ),
                        ),
                      ],
                    ),
                    if (contact.isNotEmpty)
                      Text(
                        contact,
                        style: const TextStyle(
                          color: Color(0xFF4A5568),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: Color(0xFF1A202C),
                ),
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('កែប្រែ')),
                  PopupMenuItem(value: 'delete', child: Text('លុប')),
                ],
              ),
            ],
          ),
          if (phone.isNotEmpty || email.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                if (phone.isNotEmpty) _iconText(Icons.call_outlined, phone),
                if (email.isNotEmpty)
                  _iconText(Icons.mail_outline_rounded, email),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF0E6B5C)),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: Color(0xFF1A202C)),
        ),
      ],
    );
  }
}

class _SupplierForm extends StatefulWidget {
  final Map<String, dynamic>? existing;

  const _SupplierForm({this.existing});

  @override
  State<_SupplierForm> createState() => _SupplierFormState();
}

class _SupplierFormState extends State<_SupplierForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name,
      _contact,
      _phone,
      _email,
      _address,
      _notes;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final s = widget.existing ?? const {};
    _name = TextEditingController(text: s['name']?.toString() ?? '');
    _contact =
        TextEditingController(text: s['contact_person']?.toString() ?? '');
    _phone = TextEditingController(text: s['phone']?.toString() ?? '');
    _email = TextEditingController(text: s['email']?.toString() ?? '');
    _address = TextEditingController(text: s['address']?.toString() ?? '');
    _notes = TextEditingController(text: s['notes']?.toString() ?? '');
  }

  @override
  void dispose() {
    for (final c in [_name, _contact, _phone, _email, _address, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await SupplierApi.updateSupplier(widget.existing!['_id'].toString(), {
          'name': _name.text.trim(),
          'contact_person': _contact.text.trim(),
          'phone': _phone.text.trim(),
          'email': _email.text.trim(),
          'address': _address.text.trim(),
          'notes': _notes.text.trim(),
        });
      } else {
        await SupplierApi.createSupplier(
          name: _name.text.trim(),
          contactPerson: _contact.text.trim(),
          phone: _phone.text.trim(),
          email: _email.text.trim(),
          address: _address.text.trim(),
          notes: _notes.text.trim(),
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

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: MediaQuery.sizeOf(context).height * .82,
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFFF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _isEdit ? 'កែប្រែអ្នកផ្គត់ផ្គង់' : 'បន្ថែមអ្នកផ្គត់ផ្គង់',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A202C),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _field(_name, 'ឈ្មោះអ្នកផ្គត់ផ្គង់ *'),
                      _field(_contact, 'អ្នកទំនាក់ទំនង'),
                      _field(
                        _phone,
                        'លេខទូរស័ព្ទ *',
                        keyboard: TextInputType.phone,
                      ),
                      _field(
                        _email,
                        'អ៊ីមែល',
                        keyboard: TextInputType.emailAddress,
                      ),
                      _field(_address, 'អាសយដ្ឋាន'),
                      _field(_notes, 'កំណត់ចំណាំ'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0E6B5C),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(_isEdit ? 'រក្សាទុកការកែប្រែ' : 'រក្សាទុក'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Fields whose label contains '*' are required
  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        validator: (value) =>
            label.contains('*') && (value == null || value.trim().isEmpty)
                ? 'សូមបំពេញព័ត៌មាននេះ'
                : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
      ),
    );
  }
}

BoxDecoration _cardDeco(double radius) {
  return BoxDecoration(
    color: const Color(0xFFF8FAF9),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: const Color(0xFFE2E8F0)),
    boxShadow: const [
      BoxShadow(
        color: Color(0x0A172B24),
        blurRadius: 16,
        offset: Offset(0, 5),
      ),
    ],
  );
}