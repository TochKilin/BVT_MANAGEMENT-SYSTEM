import 'dart:convert';

import 'package:bvt_management/medicines/medicine_screen.dart';
import 'package:bvt_management/screens/purchases/purchases_screen.dart';
import 'package:bvt_management/screens/sales/sales_pos_screen.dart';
import 'package:bvt_management/screens/reports/reports_screen.dart';
import 'package:bvt_management/screens/notifications/notification_screens.dart';
import 'package:bvt_management/screens/auth/profile_screen.dart';
import 'package:bvt_management/screens/prescriptions/prescription_screens.dart';
import 'package:bvt_management/screens/treatments/treatment_screens.dart';
import 'package:bvt_management/screens/medicines/medicine_extra_screens.dart'
    show InventoryScreen;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../quick_action/quick_action.dart';
import '../forms/vet_forms.dart';
import '../../services/vet_api.dart';
import '../../services/supplyer.dart';
import '../../services/auth_api.dart';
import '../supplyer/supplyer.dart';
import '../auth/login.dart';

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
      NotificationScreen(onOpenMedicines: () => _go(2)),
      _RecordsPage(kind: _PageKind.menu, onNavigate: _go),
      _RecordsPage(kind: _PageKind.vaccinations, onNavigate: _go),
      _RecordsPage(kind: _PageKind.appointments, onNavigate: _go),
      const SupplierScreen(),
      const PurchasesScreen(),
      const PrescriptionListScreen(),
      const TreatmentListScreen(),
      const InventoryScreen(),
      const ReportsScreen(),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: KeyedSubtree(key: ValueKey(_tab), child: pages[_tab]),
              ),
            ),
            _BottomNav(active: _tab, onChanged: _go),
          ],
        ),
      ),
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
  Map<String, dynamic>? _user;
  int _notificationCount = 0;

  final _searchController = TextEditingController();
  List<_SearchResult> _searchResults = [];
  int _searchRequest = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _loadUser();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await AuthApi.getUser();
    if (mounted) setState(() => _user = user);
  }

  Future<void> _openProfile() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
    _loadUser();
  }

  Future<void> _load() async {
    try {
      final result = await Future.wait([
        VetApi.getDashboardSummary(),
        VetApi.getAppointments(),
        SupplierApi.getSuppliers(),
        VetApi.getMedicines(),
      ]);

      if (mounted) {
        setState(() {
          _summary = result[0] as Map<String, dynamic>;
          _appointments = result[1] as List<Map<String, dynamic>>;
          _topSuppliers = (result[2] as List<Map<String, dynamic>>)
              .take(3)
              .toList();
          _notificationCount = countMedicineNotifications(
            result[3] as List<Map<String, dynamic>>,
          );
        });
      }
    } catch (_) {
      if (mounted) setState(() => _summary = {});
    }
  }

  Future<void> _search(String text) async {
    final query = text.trim().toLowerCase();
    final request = ++_searchRequest;

    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    try {
      final data = await Future.wait([
        VetApi.getPatients(),
        VetApi.getMedicines(),
        SupplierApi.getSuppliers(),
      ]);

      if (!mounted || request != _searchRequest) return;

      final patients = data[0];
      final medicines = data[1];
      final suppliers = data[2];
      final results = <_SearchResult>[];

      for (final owner in patients) {
        for (final animal in (owner['animals'] as List? ?? const [])) {
          final item = Map<String, dynamic>.from(animal as Map);
          final label =
              '${item['name'] ?? ''} ${item['species'] ?? ''} ${owner['name'] ?? ''}';

          if (label.toLowerCase().contains(query)) {
            results.add(
              _SearchResult(
                name: item['name']?.toString() ?? 'សត្វ',
                detail: '${item['species'] ?? ''} · ${owner['name'] ?? ''}',
                icon: Icons.pets_rounded,
              ),
            );
          }
        }
      }

      for (final medicine in medicines) {
        final label =
            '${medicine['name'] ?? ''} ${medicine['generic_name'] ?? ''} ${medicine['category'] ?? ''}';

        if (label.toLowerCase().contains(query)) {
          results.add(
            _SearchResult(
              name: medicine['name']?.toString() ?? 'ថ្នាំ',
              detail: medicine['category'] is Map
                  ? medicine['category']['name']?.toString() ?? 'ថ្នាំ'
                  : medicine['category']?.toString() ?? 'ថ្នាំ',
              icon: Icons.medication_outlined,
            ),
          );
        }
      }

      for (final supplier in suppliers) {
        final label =
            '${supplier['name'] ?? ''} ${supplier['contact_person'] ?? ''} ${supplier['phone'] ?? ''}';

        if (label.toLowerCase().contains(query)) {
          results.add(
            _SearchResult(
              name: supplier['name']?.toString() ?? 'អ្នកផ្គត់ផ្គង់',
              detail: supplier['contact_person']?.toString().isNotEmpty == true
                  ? supplier['contact_person'].toString()
                  : 'អ្នកផ្គត់ផ្គង់',
              icon: Icons.local_shipping_outlined,
            ),
          );
        }
      }

      setState(() => _searchResults = results.take(6).toList());
    } catch (_) {
      if (mounted && request == _searchRequest) {
        setState(() => _searchResults = []);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawAvatarUrl = _user?['avatarUrl']?.toString();
    final avatarUrl = rawAvatarUrl == null || rawAvatarUrl.isEmpty
        ? null
        : (rawAvatarUrl.startsWith('http://') ||
                  rawAvatarUrl.startsWith('https://')
              ? rawAvatarUrl
              : '${VetApi.baseUrl}${rawAvatarUrl.startsWith('/') ? rawAvatarUrl : '/$rawAvatarUrl'}');
    final userName = _user?['name']?.toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _openProfile,
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFFE0E0E0),
                  backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: (avatarUrl == null || avatarUrl.isEmpty)
                      ? const Icon(
                          Icons.person_rounded,
                          color: Color(0xFF4A5568),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('សួស្តី', style: _title(25)),
                    const SizedBox(height: 3),
                    Text(
                      'គ្លីនិកសត្វពេទ្យ · ${userName ?? 'Dr. Dara'}',
                      style: _body(),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 54,
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0E6B5C), Color(0xFF4A5568)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => widget.onNavigate(3),
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: _card(16),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: Color(0xFF0A4F44),
                        ),
                      ),
                      if (_notificationCount > 0)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: const Color(0xFFE05C86),
                            child: Text(
                              _notificationCount > 99
                                  ? '99+'
                                  : '$_notificationCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: _card(17),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Color(0xFF0A4F44)),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _search,
                    decoration: const InputDecoration(
                      hintText: 'ស្វែងរកសត្វ, ថ្នាំ, អ្នកផ្គត់ផ្គង់...',
                      hintStyle: TextStyle(color: Colors.black),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _search('');
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
              ],
            ),
          ),
          if (_searchController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            if (_searchResults.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'រកមិនឃើញទិន្នន័យទេ',
                  style: TextStyle(color: Colors.black),
                ),
              )
            else
              Container(
                decoration: _card(16),
                child: Column(
                  children: _searchResults
                      .map(
                        (result) => ListTile(
                          leading: Icon(
                            result.icon,
                            color: const Color(0xFF0E6B5C),
                          ),
                          title: Text(result.name),
                          subtitle: Text(result.detail),
                          dense: true,
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
          const SizedBox(height: 26),
          _Section('ទិដ្ឋភាពទូទៅ', action: 'ថ្ងៃនេះ'),
          const SizedBox(height: 12),
          if (_summary == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: CircularProgressIndicator(),
              ),
            )
          else
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.38,
              children: [
                _Stat(
                  icon: Icons.medication_outlined,
                  number: '${_summary!['medicine_count'] ?? 0}',
                  label: 'ប្រភេទថ្នាំ',
                  accent: const Color(0xFF0E6B5C),
                  tint: const Color(0xFFD9D9D9),
                ),
                _Stat(
                  icon: Icons.inventory_2_outlined,
                  number: '${_summary!['low_stock_count'] ?? 0}',
                  label: 'ស្តុកទាប',
                  accent: const Color(0xFFF59E0B),
                  tint: const Color(0xFFD9D9D9),
                  onTap: () => widget.onNavigate(2),
                ),
                _Stat(
                  icon: Icons.vaccines_outlined,
                  number: '${_summary!['vaccines_due_30_days'] ?? 0}',
                  label: 'វ៉ាក់សាំងត្រូវចាក់',
                  accent: const Color(0xFFE05C86),
                  tint: const Color(0xFFD9D9D9),
                ),
                _Stat(
                  icon: Icons.pets_rounded,
                  number: '${_summary!['animal_count'] ?? 0}',
                  label: 'អ្នកជំងឺសរុប',
                  accent: const Color(0xFF0A4F44),
                  tint: const Color(0xFFD9D9D9),
                ),
              ],
            ),
          const SizedBox(height: 26),
          const _Section('សកម្មភាព'),
          const SizedBox(height: 12),
          QuickActionsGrid(onNavigate: widget.onNavigate),
          const SizedBox(height: 26),
          _Section('អ្នកផ្គត់ផ្គង់', action: 'មើលទាំងអស់'),
          const SizedBox(height: 12),
          if (_topSuppliers.isEmpty)
            InkWell(
              onTap: () => widget.onNavigate(7),
              borderRadius: BorderRadius.circular(17),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: _card(17),
                child: const Text(
                  'មិនទាន់មានអ្នកផ្គត់ផ្គង់ទេ · ចុចដើម្បីបន្ថែម',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            )
          else
            ..._topSuppliers.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _Row(
                  name: s['name']?.toString() ?? '-',
                  detail: s['phone']?.toString() ?? '',
                  icon: Icons.local_shipping_outlined,
                  tint: const Color(0xFF0E6B5C),
                  accent: const Color(0xFFFFFFFF),
                  onTap: () => widget.onNavigate(7),
                ),
              ),
            ),
          const SizedBox(height: 26),
          const _Section('ការណាត់ជួបថ្ងៃនេះ', action: 'មើលទាំងអស់'),
          const SizedBox(height: 12),
          if (_appointments.isEmpty)
            const Text(
              'មិនទាន់មានការណាត់ជួបនៅឡើយ',
              style: TextStyle(color: Colors.black),
            )
          else
            ..._appointments
                .take(3)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _Row(
                      name: item['reason']?.toString() ?? 'ការណាត់ជួប',
                      detail: item['scheduled_at']?.toString() ?? '-',
                      icon: Icons.calendar_month_rounded,
                      tint: const Color(0xFFF59E0B),
                      accent: const Color(0xFFFFFFFF),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _SearchResult {
  final String name;
  final String detail;
  final IconData icon;
  const _SearchResult({
    required this.name,
    required this.detail,
    required this.icon,
  });
}

class _Section extends StatelessWidget {
  final String title;
  final String? action;

  const _Section(this.title, {this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: _title(19)),
        const Spacer(),
        if (action != null)
          Text(
            action!,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF0E6B5C),
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String number;
  final String label;
  final Color accent;
  final Color tint;
  final VoidCallback? onTap;

  const _Stat({
    required this.icon,
    required this.number,
    required this.label,
    required this.accent,
    required this.tint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: _card(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF0E6B5C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFFFFFFFF), size: 20),
              ),
              const Spacer(),
              Text(number, style: _title(25)),
              const SizedBox(height: 2),
              Text(label, style: _body(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
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
  final _appointmentSearch = TextEditingController();
  String _appointmentFilter = 'all';
  bool _newestFirst = true;

  @override
  void dispose() {
    _appointmentSearch.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

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
      if (widget.kind == _PageKind.appointments && _records.isNotEmpty) {
        final owners = await VetApi.getPatients();
        final ownersById = {
          for (final owner in owners) owner['_id']?.toString(): owner,
        };
        _records = _records.map((appointment) {
          final owner = ownersById[appointment['owner_id']?.toString()];
          final animals = (owner?['animals'] as List? ?? const [])
              .cast<Map>()
              .map((animal) => Map<String, dynamic>.from(animal));
          Map<String, dynamic>? matchedAnimal;
          for (final animal in animals) {
            if (animal['_id']?.toString() == appointment['animal_id']?.toString()) {
              matchedAnimal = animal;
              break;
            }
          }
          return {
            ...appointment,
            'owner_name': owner?['name']?.toString() ?? '',
            'animal_name': matchedAnimal?['name']?.toString() ?? '',
          };
        }).toList();
      }
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('បោះបង់'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE05C86),
            ),
            child: const Text('ចាកចេញ'),
          ),
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
      _PageKind.patients => (
        'អ្នកជំងឺ',
        'ទិន្ន័យទាំងអស់',
        'បន្ថែមអ្នកជំងឺ',
        Icons.add_rounded,
        const <Widget>[],
      ),
      _PageKind.alerts => (
        'ជូនដំណឹង',
        'ការជូនដំណឹងនឹងបង្ហាញនៅទីនេះ',
        'អានទាំងអស់',
        Icons.done_all_rounded,
        const <Widget>[],
      ),
      _PageKind.menu => (
        'ម៉ឺនុយ',
        'គ្រប់គ្រងគ្លីនិករបស់អ្នក',
        'ការកំណត់',
        Icons.settings_outlined,
        [
          _Row(
            name: 'ប្រវត្តិរូប',
            detail: 'មើល និងកែប្រែព័ត៌មានផ្ទាល់ខ្លួន',
            icon: Icons.person_outline_rounded,
            tint: const Color(0xFF0E6B5C),
            accent: const Color(0xFFFFFFFF),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          _Row(
            name: 'វ៉ាក់សាំង',
            detail: 'កាលវិភាគ dose និងការរំលឹក',
            icon: Icons.vaccines_outlined,
            tint: const Color(0xFF0E6B5C),
            accent: const Color(0xFFFFFFFF),
            onTap: () => widget.onNavigate?.call(5),
          ),
          _Row(
            name: 'ការណាត់ជួប',
            detail: 'គ្រប់គ្រងពេលជួបពេទ្យ',
            icon: Icons.calendar_month_rounded,
            tint: const Color(0xFFF59E0B),
            accent: const Color(0xFFFFFFFF),
            onTap: () => widget.onNavigate?.call(6),
          ),
          _Row(
            name: 'អ្នកផ្គត់ផ្គង់',
            detail: 'គ្រប់គ្រងអ្នកផ្គត់ផ្គង់ និងការទិញ',
            icon: Icons.local_shipping_outlined,
            tint: const Color(0xFF0E6B5C),
            accent: const Color(0xFFFFFFFF),
            onTap: () => widget.onNavigate?.call(7),
          ),
          _Row(
            name: 'ការបញ្ជាទិញ',
            detail: 'បញ្ជី purchase orders ដែលរក្សាទុកក្នុង database',
            icon: Icons.shopping_cart_outlined,
            tint: const Color(0xFF0E6B5C),
            accent: const Color(0xFFFFFFFF),
            onTap: () => widget.onNavigate?.call(8),
          ),
          _Row(
            name: 'ការលក់ និងវិក្កយបត្រ',
            detail: 'មើលប្រតិបត្តិការលក់ប្រចាំថ្ងៃ',
            icon: Icons.receipt_long_outlined,
            tint: Color(0xFFF59E0B),
            accent: Color(0xFFFFFFFF),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SalesPosScreen())),
          ),
          _Row(
            name: 'របាយការណ៍',
            detail: 'សង្ខេបប្រាក់ចំណូល និងស្តុក',
            icon: Icons.bar_chart_rounded,
            tint: Color(0xFF0E6B5C),
            accent: Color(0xFFFFFFFF),
            onTap: () => widget.onNavigate?.call(12),
          ),
          _Row(
            name: 'ចាកចេញពីប្រព័ន្ធ',
            detail: 'Logout ចេញពីគណនីបច្ចុប្បន្ន',
            icon: Icons.logout_rounded,
            tint: const Color(0xFFE05C86),
            accent: const Color(0xFFFFFFFF),
            onTap: _logout,
          ),
        ],
      ),
      _PageKind.vaccinations => (
        'វ៉ាក់សាំង',
        'ទិន្ន័យទាំងអស់',
        'កត់ត្រាវ៉ាក់សាំង',
        Icons.add_rounded,
        const <Widget>[],
      ),
      _PageKind.appointments => (
        'ការណាត់ជួប',
        'ទិន្ន័យទាំងអស់',
        'កំណត់ការណាត់ជួប',
        Icons.add_rounded,
        const <Widget>[],
      ),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data.$1, style: _title(28)),
          const SizedBox(height: 5),
          Text(data.$2, style: _body()),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: formType == null
                  ? null
                  : () async {
                      final saved = await showVetForm(context, formType);
                      if (saved == true && mounted) {
                        await _load();
                        if (!mounted) return;
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('បានរក្សាទុកទៅ MongoDB រួចហើយ'),
                          ),
                        );
                      }
                    },
              icon: Icon(data.$4),
              label: Text(data.$3),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0E6B5C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (kind == _PageKind.appointments) ...[
            TextField(
              controller: _appointmentSearch,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'ស្វែងរកការណាត់ជួប...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _appointmentSearch.text.isEmpty ? null : IconButton(
                  onPressed: () { _appointmentSearch.clear(); setState(() {}); },
                  icon: const Icon(Icons.close_rounded),
                ),
                filled: true,
                fillColor: const Color(0xFFF7FAF9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: Color(0xFF0E6B5C),
                    width: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: DropdownButtonFormField<String>(
                value: _appointmentFilter,
                decoration: InputDecoration(labelText: 'តម្រង', border: OutlineInputBorder(borderRadius: BorderRadius.circular(13))),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('ទាំងអស់')),
                  DropdownMenuItem(value: 'upcoming', child: Text('Upcoming')),
                  DropdownMenuItem(value: 'past', child: Text('Past')),
                ],
                onChanged: (value) => setState(() => _appointmentFilter = value ?? 'all'),
              )),
              const SizedBox(width: 10),
              Expanded(child: DropdownButtonFormField<bool>(
                value: _newestFirst,
                decoration: InputDecoration(labelText: 'តម្រៀបតាមថ្ងៃ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(13))),
                items: const [
                  DropdownMenuItem(value: true, child: Text('ថ្មីទៅចាស់')),
                  DropdownMenuItem(value: false, child: Text('ចាស់ទៅថ្មី')),
                ],
                onChanged: (value) => setState(() => _newestFirst = value ?? true),
              )),
            ]),
            const SizedBox(height: 16),
          ],
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else
            ..._rows(kind, data.$5).map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: item,
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _rows(_PageKind kind, List<Widget> fallback) {
    if (![
      _PageKind.patients,
      _PageKind.vaccinations,
      _PageKind.appointments,
    ].contains(kind)) {
      return fallback;
    }

    if (_records.isEmpty) {
      return const [
        Text('មិនទាន់មានទិន្នន័យទេ', style: TextStyle(color: Colors.black)),
      ];
    }

    if (kind == _PageKind.patients) {
      return _records.expand((owner) {
        final animals = (owner['animals'] as List? ?? const []).cast<Map>();
        return animals.map(
          (animal) => _Row(
            name: animal['name']?.toString() ?? 'សត្វ',
            detail: '${animal['species'] ?? ''} · ${owner['name'] ?? ''}',
            icon: Icons.pets_rounded,
            tint: const Color.fromARGB(255, 4, 29, 25),
            accent: const Color(0xFF0E6B5C),
            image: animal['photo']?.toString() ?? '',
            trailing: PopupMenuButton<String>(
              onSelected: (action) async {
                if (action == 'edit') {
                  final saved = await showVetForm(
                    context,
                    VetFormType.patient,
                    owner: owner,
                    animal: Map<String, dynamic>.from(animal),
                  );
                  if (saved == true && mounted) await _load();
                } else if (action == 'delete') {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('លុបអ្នកជំងឺ?'),
                      content: Text(
                        'តើអ្នកចង់លុប ${animal['name'] ?? 'សត្វនេះ'} មែនទេ?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('បោះបង់'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'លុប',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    try {
                      await VetApi.deletePatient(
                        ownerId: owner['_id'].toString(),
                        animalId: animal['_id'].toString(),
                      );
                      if (mounted) await _load();
                    } on ApiException catch (error) {
                      if (mounted)
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(error.message)));
                    }
                  }
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('កែប្រែ')),
                PopupMenuItem(value: 'delete', child: Text('លុប')),
              ],
            ),
          ),
        );
      }).toList();
    }

    var displayedRecords = _records;
    if (kind == _PageKind.appointments) {
      final query = _appointmentSearch.text.trim().toLowerCase();
      final now = DateTime.now();
      displayedRecords = _records.where((item) {
        final scheduled = DateTime.tryParse(item['scheduled_at']?.toString() ?? '');
        if (scheduled == null) return false;
        if (_appointmentFilter == 'upcoming' && scheduled.isBefore(now)) return false;
        if (_appointmentFilter == 'past' && !scheduled.isBefore(now)) return false;
        if (query.isEmpty) return true;
        final searchable = '${item['reason'] ?? ''} ${item['animal_name'] ?? ''} ${item['owner_name'] ?? ''} ${item['scheduled_at'] ?? ''}'.toLowerCase();
        return searchable.contains(query);
      }).toList();
      displayedRecords.sort((a, b) {
        final aDate = DateTime.tryParse(a['scheduled_at']?.toString() ?? '') ?? DateTime(1970);
        final bDate = DateTime.tryParse(b['scheduled_at']?.toString() ?? '') ?? DateTime(1970);
        return _newestFirst ? bDate.compareTo(aDate) : aDate.compareTo(bDate);
      });
      if (displayedRecords.isEmpty) {
        return const [Text('រកមិនឃើញការណាត់ជួបដែលត្រូវនឹងលក្ខខណ្ឌទេ', style: TextStyle(color: Colors.black54))];
      }
    }

    return displayedRecords.map((item) {
      final isVaccine = kind == _PageKind.vaccinations;
      final name = isVaccine ? item['vaccine_name'] : item['reason'];
      final detail = isVaccine
          ? 'Dose បន្ទាប់: ${item['next_due_at'] ?? '-'}'
          : 'កាលវិភាគ: ${item['scheduled_at'] ?? '-'}';

      final actions = isVaccine
          ? PopupMenuButton<String>(
              onSelected: (action) async {
                if (action == 'edit') {
                  final saved = await showVetForm(
                    context,
                    VetFormType.vaccination,
                    record: item,
                  );
                  if (saved == true && mounted) await _load();
                } else if (action == 'delete') {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('លុបកំណត់ត្រាវ៉ាក់សាំង?'),
                      content: Text(
                        'តើអ្នកចង់លុប ${item['vaccine_name'] ?? 'វ៉ាក់សាំងនេះ'} មែនទេ?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('បោះបង់'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text(
                            'លុប',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    try {
                      await VetApi.deleteVaccination(item['_id'].toString());
                      if (mounted) await _load();
                    } on ApiException catch (error) {
                      if (mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(error.message)));
                      }
                    }
                  }
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('កែប្រែ')),
                PopupMenuItem(value: 'delete', child: Text('លុប')),
              ],
            )
          : null;

      final scheduled = DateTime.tryParse(item['scheduled_at']?.toString() ?? '');
      final appointmentBadge = !isVaccine && scheduled != null
          ? (scheduled.isBefore(DateTime.now()) ? 'Past' : 'Upcoming')
          : null;

      Future<void> showAppointmentDetails() async {
        if (isVaccine) return;
        final action = await showDialog<String>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(item['reason']?.toString() ?? 'ការណាត់ជួប'),
            content: Text('កាលវិភាគ: ${item['scheduled_at'] ?? '-'}\nស្ថានភាព: ${appointmentBadge ?? '-'}\nម្ចាស់សត្វ: ${item['owner_name']?.toString().isNotEmpty == true ? item['owner_name'] : '-'}\nសត្វ: ${item['animal_name']?.toString().isNotEmpty == true ? item['animal_name'] : '-'}'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('បិទ')),
              TextButton(onPressed: () => Navigator.pop(dialogContext, 'edit'), child: const Text('កែប្រែ')),
              TextButton(onPressed: () => Navigator.pop(dialogContext, 'delete'), child: const Text('លុប', style: TextStyle(color: Colors.red))),
            ],
          ),
        );
        if (!mounted) return;
        if (action == 'edit') {
          final saved = await showVetForm(context, VetFormType.appointment, record: item);
          if (saved == true && mounted) await _load();
        } else if (action == 'delete') {
          final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
            title: const Text('លុបការណាត់ជួប?'),
            content: Text('តើអ្នកចង់លុប ${item['reason'] ?? 'ការណាត់ជួបនេះ'} មែនទេ?'),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('បោះបង់')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('លុប', style: TextStyle(color: Colors.red)))],
          ));
          if (confirmed == true) {
            try { await VetApi.deleteAppointment(item['_id'].toString()); if (mounted) await _load(); }
            on ApiException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message))); }
          }
        }
      }

      return _Row(
        name: name?.toString() ?? '-',
        detail: detail,
        icon: isVaccine
            ? Icons.vaccines_outlined
            : Icons.calendar_month_rounded,
        tint: isVaccine
            ? const Color(0xFFE0F2EF)
            : const Color(0xFFF59E0B),
        accent: isVaccine
            ? const Color(0xFF0E6B5C)
            : const Color(0xFFFFFFFF),
        image: isVaccine ? item['image']?.toString() ?? '' : '',
        trailing: actions,
        badge: appointmentBadge,
        onTap: isVaccine ? null : showAppointmentDetails,
      );
    }).toList();
  }
}

class _Row extends StatelessWidget {
  final String name;
  final String detail;
  final IconData icon;
  final Color tint;
  final Color accent;
  final VoidCallback? onTap;
  final String image;
  final String? badge;
  final Widget? trailing;

  const _Row({
    required this.name,
    required this.detail,
    required this.icon,
    required this.tint,
    required this.accent,
    this.onTap,
    this.image = '',
    this.trailing,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: _card(17),
          child: Row(
            children: [
              _imageBox(),
              const SizedBox(width: 13),
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
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDE3EC),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFFE05C86),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(detail, style: _body(fontSize: 12)),
                  ],
                ),
              ),
              trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF4A5568),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageBox() {
    if (image.isEmpty) {
      return Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: accent),
      );
    }

    try {
      final bytes = base64Decode(
        image.contains(',') ? image.split(',').last : image,
      );
      return ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Image.memory(
          bytes,
          width: 45,
          height: 45,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallback(),
        ),
      );
    } catch (_) {
      return _fallback();
    }
  }

  Widget _fallback() {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: Color(0xFFE0F2EF),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: Color(0xFF0A4F44)),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int active;
  final ValueChanged<int> onChanged;

  const _BottomNav({required this.active, required this.onChanged});

  static const items = [
    (Icons.home_rounded, 'ទំព័រដើម'),
    (Icons.pets_rounded, 'អ្នកជំងឺ'),
    (Icons.medication_outlined, 'ថ្នាំ'),
    (Icons.notifications_none_rounded, 'ជូនដំណឹង'),
    (Icons.menu_rounded, 'ម៉ឺនុយ'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0A4F44),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final selected = active == i;
          final item = items[i];

          return Expanded(
            child: InkWell(
              onTap: () => onChanged(i),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.$1,
                      color: selected
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFF718096),
                      size: 23,
                    ),
                    const SizedBox(height: 3),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 4,
                      width: selected ? 18 : 4,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFFFFFFF)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

BoxDecoration _card(double radius) {
  return BoxDecoration(
    color: const Color(0xFFF8FAF9),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: const Color(0xFFE2E8F0)),
    boxShadow: const [
      BoxShadow(color: Color(0x0A172B24), blurRadius: 16, offset: Offset(0, 5)),
    ],
  );
}

TextStyle _title(double size) {
  return GoogleFonts.fraunces(
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: const Color(0xFF1A202C),
  );
}

TextStyle _body({double fontSize = 13}) {
  return TextStyle(fontSize: fontSize, color: const Color(0xFF4A5568));
}
