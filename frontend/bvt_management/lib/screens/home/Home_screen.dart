import 'dart:convert';

import 'package:bvt_management/medicines/medicine_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../quick_action/quick_action.dart';
import '../forms/vet_forms.dart';
import '../../services/vet_api.dart';
import '../../services/supplyer.dart';
import '../../services/auth_api.dart';
import '../supplyer/supplyer.dart';
import '../auth/login.dart';
// import '../medicine/medicine_screen.dart';

class ChartColors {
  static const bg = Color(0xFFF4F7F5), surface = Colors.white, ink = Color(0xFF172B24), inkSoft = Color(0xFF6C7B74), line = Color(0xFFDCE6E1);
  static const teal = Color(0xFF087A69), tealDeep = Color(0xFF075C50), tealTint = Color(0xFFE1F3EE);
  static const amber = Color(0xFFE39827), amberTint = Color(0xFFFFF0D9), rose = Color(0xFFD45252), roseTint = Color(0xFFFFE9E8), navInactive = Color(0xFFBCD1CA);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  void _go(int tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    final pages = [
      _Dashboard(onNavigate: _go),
      _RecordsPage(kind: _PageKind.patients, onNavigate: _go),
      const MedicineScreen(), 
      _RecordsPage(kind: _PageKind.alerts, onNavigate: _go),
      _RecordsPage(kind: _PageKind.menu, onNavigate: _go),
      _RecordsPage(kind: _PageKind.vaccinations, onNavigate: _go),
      _RecordsPage(kind: _PageKind.appointments, onNavigate: _go),
      const SupplierScreen(),
    ];
    return Scaffold(
      body: SafeArea(child: Column(children: [
        Expanded(child: AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: KeyedSubtree(key: ValueKey(_tab), child: pages[_tab]))),
        _BottomNav(active: _tab, onChanged: _go),
      ])),
    );
  }
}

class _Dashboard extends StatefulWidget {
  final ValueChanged<int> onNavigate;
  const _Dashboard({required this.onNavigate});
  @override
  State<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<_Dashboard> {
  Map<String, dynamic>? _summary;
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _topSuppliers = [];
  final _searchController = TextEditingController();
  List<_SearchResult> _searchResults = [];
  int _searchRequest = 0;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final result = await Future.wait([
        VetApi.getDashboardSummary(),
        VetApi.getAppointments(),
        SupplierApi.getSuppliers(),
      ]);
      if (mounted) {
        setState(() {
          _summary = result[0] as Map<String, dynamic>;
          _appointments = result[1] as List<Map<String, dynamic>>;
          _topSuppliers = (result[2] as List<Map<String, dynamic>>).take(3).toList();
        });
      }
    } catch (_) { if (mounted) setState(() => _summary = {}); }
  }

  Future<void> _search(String text) async {
    final query = text.trim().toLowerCase();
    final request = ++_searchRequest;
    if (query.isEmpty) { setState(() => _searchResults = []); return; }
    try {
      final data = await Future.wait([VetApi.getPatients(), VetApi.getMedicines(), SupplierApi.getSuppliers()]);
      if (!mounted || request != _searchRequest) return;
      final patients = data[0] as List<Map<String, dynamic>>;
      final medicines = data[1] as List<Map<String, dynamic>>;
      final suppliers = data[2] as List<Map<String, dynamic>>;
      final results = <_SearchResult>[];
      for (final owner in patients) {
        for (final animal in (owner['animals'] as List? ?? const [])) {
          final item = Map<String, dynamic>.from(animal as Map);
          final label = '${item['name'] ?? ''} ${item['species'] ?? ''} ${owner['name'] ?? ''}';
          if (label.toLowerCase().contains(query)) results.add(_SearchResult(name: item['name']?.toString() ?? 'សត្វ', detail: '${item['species'] ?? ''} · ${owner['name'] ?? ''}', icon: Icons.pets_rounded));
        }
      }
      for (final medicine in medicines) {
        final label = '${medicine['name'] ?? ''} ${medicine['generic_name'] ?? ''} ${medicine['category'] ?? ''}';
        if (label.toLowerCase().contains(query)) results.add(_SearchResult(name: medicine['name']?.toString() ?? 'ថ្នាំ', detail: medicine['category'] is Map ? medicine['category']['name']?.toString() ?? 'ថ្នាំ' : medicine['category']?.toString() ?? 'ថ្នាំ', icon: Icons.medication_outlined));
      }
      for (final supplier in suppliers) {
        final label = '${supplier['name'] ?? ''} ${supplier['contact_person'] ?? ''} ${supplier['phone'] ?? ''}';
        if (label.toLowerCase().contains(query)) results.add(_SearchResult(name: supplier['name']?.toString() ?? 'អ្នកផ្គត់ផ្គង់', detail: supplier['contact_person']?.toString().isNotEmpty == true ? supplier['contact_person'].toString() : 'អ្នកផ្គត់ផ្គង់', icon: Icons.local_shipping_outlined));
      }
      setState(() => _searchResults = results.take(6).toList());
    } catch (_) { if (mounted && request == _searchRequest) setState(() => _searchResults = []); }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('អរុណសួស្តី 👋', style: _title(25)), const SizedBox(height: 3),
          Text('គ្លីនិកសត្វពេទ្យ · Dr. Dara', style: _body()), const SizedBox(height: 10),
          Container(width: 54, height: 4, decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), gradient: const LinearGradient(colors: [ChartColors.teal, ChartColors.amber]))),
        ])),
        Stack(clipBehavior: Clip.none, children: [
          Container(width: 48, height: 48, decoration: _card(16), child: const Icon(Icons.notifications_none_rounded, color: ChartColors.tealDeep)),
          const Positioned(top: -4, right: -4, child: CircleAvatar(radius: 12, backgroundColor: ChartColors.rose, child: Text('3', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)))),
        ]),
      ]),
      const SizedBox(height: 24),
      Container(height: 54, padding: const EdgeInsets.symmetric(horizontal: 16), decoration: _card(17), child: Row(children: [
        const Icon(Icons.search_rounded, color: ChartColors.teal), const SizedBox(width: 12),
        Expanded(child: TextField(controller: _searchController, onChanged: _search, decoration: const InputDecoration(hintText: 'ស្វែងរកសត្វ, ថ្នាំ, អ្នកផ្គត់ផ្គង់...', hintStyle: TextStyle(color: ChartColors.inkSoft), border: InputBorder.none))),
        if (_searchController.text.isNotEmpty) IconButton(onPressed: () { _searchController.clear(); _search(''); }, icon: const Icon(Icons.close_rounded, color: ChartColors.inkSoft)),
      ])),
      if (_searchController.text.isNotEmpty) ...[
        const SizedBox(height: 8),
        if (_searchResults.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('រកមិនឃើញទិន្នន័យទេ', style: TextStyle(color: ChartColors.inkSoft))) else Container(decoration: _card(16), child: Column(children: _searchResults.map((result) => ListTile(leading: Icon(result.icon, color: ChartColors.teal), title: Text(result.name), subtitle: Text(result.detail), dense: true)).toList())),
      ],
      const SizedBox(height: 26), _Section('ទិដ្ឋភាពទូទៅ', action: 'ថ្ងៃនេះ'), const SizedBox(height: 12),
      if (_summary == null) const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator())) else GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.38, children: [
        _Stat(icon: Icons.medication_outlined, number: '${_summary!['medicine_count'] ?? 0}', label: 'ប្រភេទថ្នាំ', accent: ChartColors.teal, tint: ChartColors.tealTint),
        _Stat(icon: Icons.inventory_2_outlined, number: '${_summary!['low_stock_count'] ?? 0}', label: 'ស្តុកទាប', accent: ChartColors.amber, tint: ChartColors.amberTint, onTap: () => widget.onNavigate(2)),
        _Stat(icon: Icons.vaccines_outlined, number: '${_summary!['vaccines_due_30_days'] ?? 0}', label: 'វ៉ាក់សាំងត្រូវចាក់', accent: ChartColors.rose, tint: ChartColors.roseTint),
        _Stat(icon: Icons.pets_rounded, number: '${_summary!['animal_count'] ?? 0}', label: 'អ្នកជំងឺសរុប', accent: ChartColors.tealDeep, tint: ChartColors.tealTint),
      ]),
      const SizedBox(height: 26), const _Section('សកម្មភាពរហ័ស'), const SizedBox(height: 12), QuickActionsGrid(onNavigate: widget.onNavigate),
      const SizedBox(height: 26), _Section('អ្នកផ្គត់ផ្គង់', action: 'មើលទាំងអស់'), const SizedBox(height: 12),
      if (_topSuppliers.isEmpty)
        InkWell(
          onTap: () => widget.onNavigate(7),
          borderRadius: BorderRadius.circular(17),
          child: Container(padding: const EdgeInsets.all(16), decoration: _card(17), child: const Text('មិនទាន់មានអ្នកផ្គត់ផ្គង់ទេ · ចុចដើម្បីបន្ថែម', style: TextStyle(color: ChartColors.inkSoft))),
        )
      else
        ..._topSuppliers.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _Row(
                name: s['name']?.toString() ?? '-',
                detail: s['phone']?.toString() ?? '',
                icon: Icons.local_shipping_outlined,
                tint: ChartColors.tealTint,
                accent: ChartColors.teal,
                onTap: () => widget.onNavigate(7),
              ),
            )),
      const SizedBox(height: 26), const _Section('ការណាត់ជួបថ្ងៃនេះ', action: 'មើលទាំងអស់'), const SizedBox(height: 12),
      if (_appointments.isEmpty) const Text('មិនទាន់មានការណាត់ជួបនៅឡើយ', style: TextStyle(color: ChartColors.inkSoft)) else ..._appointments.take(3).map((item) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _Row(name: item['reason']?.toString() ?? 'ការណាត់ជួប', detail: item['scheduled_at']?.toString() ?? '-', icon: Icons.calendar_month_rounded, tint: ChartColors.amberTint, accent: ChartColors.amber))),
    ]),
  );
}

class _SearchResult {
  final String name, detail;
  final IconData icon;
  const _SearchResult({required this.name, required this.detail, required this.icon});
}

class _Section extends StatelessWidget {
  final String title; final String? action;
  const _Section(this.title, {this.action});
  @override
  Widget build(BuildContext context) => Row(children: [Text(title, style: _title(19)), const Spacer(), if (action != null) Text(action!, style: const TextStyle(fontSize: 12, color: ChartColors.teal, fontWeight: FontWeight.bold))]);
}

class _Stat extends StatelessWidget {
  final IconData icon; final String number, label; final Color accent, tint;
  final VoidCallback? onTap;
  const _Stat({required this.icon, required this.number, required this.label, required this.accent, required this.tint, this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(padding: const EdgeInsets.all(15), decoration: _card(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: accent, size: 20)),
        const Spacer(), Text(number, style: _title(25)), const SizedBox(height: 2), Text(label, style: _body(fontSize: 12)),
      ])),
    ),
  );
}

enum _PageKind { patients, alerts, menu, vaccinations, appointments }

class _RecordsPage extends StatefulWidget {
  final _PageKind kind;
  final ValueChanged<int>? onNavigate;
  const _RecordsPage({required this.kind, this.onNavigate});
  @override
  State<_RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<_RecordsPage> {
  List<Map<String, dynamic>> _records = [];
  bool _loading = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final loader = switch (widget.kind) {
      _PageKind.patients => VetApi.getPatients,
      _PageKind.vaccinations => VetApi.getVaccinations,
      _PageKind.appointments => VetApi.getAppointments,
      _ => null,
    };
    if (loader == null) return;
    setState(() => _loading = true);
    try {
      _records = await loader();
    } catch (_) {
      _records = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('ចាកចេញពីប្រព័ន្ធ?'),
        content: const Text('តើអ្នកប្រាកដថាចង់ចាកចេញមែនទេ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('បោះបង់')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: ChartColors.rose), child: const Text('ចាកចេញ')),
        ],
      ),
    );
    if (confirm != true) return;

    await AuthApi.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    final formType = switch (kind) {
      _PageKind.patients => VetFormType.patient,
      _PageKind.vaccinations => VetFormType.vaccination,
      _PageKind.appointments => VetFormType.appointment,
      _ => null,
    };
    final data = switch (kind) {
      _PageKind.patients => ('អ្នកជំងឺ', 'បញ្ជីពី MongoDB', 'បន្ថែមអ្នកជំងឺ', Icons.add_rounded, const <Widget>[]),
      _PageKind.alerts => ('ជូនដំណឹង', 'ការជូនដំណឹងនឹងបង្ហាញនៅទីនេះ', 'អានទាំងអស់', Icons.done_all_rounded, const <Widget>[]),
      _PageKind.menu => ('ម៉ឺនុយ', 'គ្រប់គ្រងគ្លីនិករបស់អ្នក', 'ការកំណត់', Icons.settings_outlined, [
        _Row(name: 'វ៉ាក់សាំង', detail: 'កាលវិភាគ dose និងការរំលឹក', icon: Icons.vaccines_outlined, tint: ChartColors.tealTint, accent: ChartColors.teal, onTap: () => widget.onNavigate?.call(5)),
        _Row(name: 'ការណាត់ជួប', detail: 'គ្រប់គ្រងពេលជួបពេទ្យ', icon: Icons.calendar_month_rounded, tint: ChartColors.amberTint, accent: ChartColors.amber, onTap: () => widget.onNavigate?.call(6)),
        _Row(name: 'អ្នកផ្គត់ផ្គង់', detail: 'គ្រប់គ្រងអ្នកផ្គត់ផ្គង់ និងការទិញ', icon: Icons.local_shipping_outlined, tint: ChartColors.tealTint, accent: ChartColors.teal, onTap: () => widget.onNavigate?.call(7)),
        const _Row(name: 'ការលក់ និងវិក្កយបត្រ', detail: 'មើលប្រតិបត្តិការលក់ប្រចាំថ្ងៃ', icon: Icons.receipt_long_outlined, tint: ChartColors.amberTint, accent: ChartColors.amber),
        const _Row(name: 'របាយការណ៍', detail: 'សង្ខេបប្រាក់ចំណូល និងស្តុក', icon: Icons.bar_chart_rounded, tint: ChartColors.tealTint, accent: ChartColors.teal),
        _Row(name: 'ចាកចេញពីប្រព័ន្ធ', detail: 'Logout ចេញពីគណនីបច្ចុប្បន្ន', icon: Icons.logout_rounded, tint: ChartColors.roseTint, accent: ChartColors.rose, onTap: _logout),
      ]),
      _PageKind.vaccinations => ('វ៉ាក់សាំង', 'បញ្ជីពី MongoDB', 'កត់ត្រាវ៉ាក់សាំង', Icons.add_rounded, const <Widget>[]),
      _PageKind.appointments => ('ការណាត់ជួប', 'បញ្ជីពី MongoDB', 'កំណត់ការណាត់ជួប', Icons.add_rounded, const <Widget>[]),
    };
    return SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 24, 20, 28), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(data.$1, style: _title(28)), const SizedBox(height: 5), Text(data.$2, style: _body()), const SizedBox(height: 22),
      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: formType == null ? null : () async { final saved = await showVetForm(context, formType); if (saved == true && mounted) { await _load(); if (!mounted) return; ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('បានរក្សាទុកទៅ MongoDB រួចហើយ'))); } }, icon: Icon(data.$4), label: Text(data.$3), style: FilledButton.styleFrom(backgroundColor: ChartColors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))))),
      const SizedBox(height: 18), if (_loading) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())) else ..._rows(kind, data.$5).map((item) => Padding(padding: const EdgeInsets.only(bottom: 12), child: item)),
    ]));
  }

  List<Widget> _rows(_PageKind kind, List<Widget> fallback) {
    if (![_PageKind.patients, _PageKind.vaccinations, _PageKind.appointments].contains(kind)) return fallback;
    if (_records.isEmpty) return const [Text('មិនទាន់មានទិន្នន័យទេ', style: TextStyle(color: ChartColors.inkSoft))];
    if (kind == _PageKind.patients) {
      return _records.expand((owner) {
        final animals = (owner['animals'] as List? ?? const []).cast<Map>();
        return animals.map((animal) => _Row(name: animal['name']?.toString() ?? 'សត្វ', detail: '${animal['species'] ?? ''} · ${owner['name'] ?? ''}', icon: Icons.pets_rounded, tint: ChartColors.tealTint, accent: ChartColors.teal, image: animal['photo']?.toString() ?? ''));
      }).toList();
    }
    return _records.map((item) {
      final isVaccine = kind == _PageKind.vaccinations;
      final name = isVaccine ? item['vaccine_name'] : item['reason'];
      final detail = isVaccine ? 'Dose បន្ទាប់: ${item['next_due_at'] ?? '-'}' : 'កាលវិភាគ: ${item['scheduled_at'] ?? '-'}';
      return _Row(name: name?.toString() ?? '-', detail: detail, icon: isVaccine ? Icons.vaccines_outlined : Icons.calendar_month_rounded, tint: ChartColors.tealTint, accent: ChartColors.teal, image: isVaccine ? item['image']?.toString() ?? '' : '');
    }).toList();
  }
}

class _Row extends StatelessWidget {
  final String name, detail; final IconData icon; final Color tint, accent;
  final VoidCallback? onTap;
  final String image;
  final String? badge;
  const _Row({required this.name, required this.detail, required this.icon, required this.tint, required this.accent, this.onTap, this.image = '', this.badge});
  @override
  Widget build(BuildContext context) => Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(17), child: Container(padding: const EdgeInsets.all(14), decoration: _card(17), child: Row(children: [
    _imageBox(), const SizedBox(width: 13),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Flexible(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, color: ChartColors.ink), overflow: TextOverflow.ellipsis)),
        if (badge != null) ...[
          const SizedBox(width: 6),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: ChartColors.roseTint, borderRadius: BorderRadius.circular(8)), child: Text(badge!, style: const TextStyle(fontSize: 10, color: ChartColors.rose, fontWeight: FontWeight.w700))),
        ],
      ]),
      const SizedBox(height: 4), Text(detail, style: _body(fontSize: 12)),
    ])), const Icon(Icons.chevron_right_rounded, color: ChartColors.inkSoft),
  ]))));

  Widget _imageBox() {
    if (image.isEmpty) return Container(width: 45, height: 45, decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: accent));
    try {
      final bytes = base64Decode(image.contains(',') ? image.split(',').last : image);
      return ClipRRect(borderRadius: BorderRadius.circular(13), child: Image.memory(bytes, width: 45, height: 45, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback()));
    } catch (_) { return _fallback(); }
  }

  Widget _fallback() => Container(width: 45, height: 45, decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: accent));
}

class _BottomNav extends StatelessWidget {
  final int active; final ValueChanged<int> onChanged;
  const _BottomNav({required this.active, required this.onChanged});
  static const items = [(Icons.home_rounded, 'ទំព័រដើម'), (Icons.pets_rounded, 'អ្នកជំងឺ'), (Icons.medication_outlined, 'ថ្នាំ'), (Icons.notifications_none_rounded, 'ជូនដំណឹង'), (Icons.menu_rounded, 'ម៉ឺនុយ')];
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.fromLTRB(8, 10, 8, 12), decoration: const BoxDecoration(color: ChartColors.tealDeep, borderRadius: BorderRadius.vertical(top: Radius.circular(25))), child: Row(children: List.generate(items.length, (i) {
    final selected = active == i; final item = items[i];
    return Expanded(child: InkWell(onTap: () => onChanged(i), borderRadius: BorderRadius.circular(16), child: Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(item.$1, color: selected ? ChartColors.amber : ChartColors.navInactive, size: 23), const SizedBox(height: 3), AnimatedContainer(duration: const Duration(milliseconds: 180), height: 4, width: selected ? 18 : 4, decoration: BoxDecoration(color: selected ? ChartColors.amber : Colors.transparent, borderRadius: BorderRadius.circular(8))),
    ]))));
  })));
}

BoxDecoration _card(double radius) => BoxDecoration(color: ChartColors.surface, borderRadius: BorderRadius.circular(radius), border: Border.all(color: ChartColors.line), boxShadow: const [BoxShadow(color: Color(0x0A172B24), blurRadius: 16, offset: Offset(0, 5))]);
TextStyle _title(double size) => GoogleFonts.fraunces(fontSize: size, fontWeight: FontWeight.w700, color: ChartColors.ink);
TextStyle _body({double fontSize = 13}) => TextStyle(fontSize: fontSize, color: ChartColors.inkSoft);