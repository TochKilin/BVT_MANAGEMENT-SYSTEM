import 'package:flutter/material.dart';
import '../../services/medicine_api.dart';

const _notificationGreen = Color(0xFF008575);

int countMedicineNotifications(List<Map<String, dynamic>> medicines) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final cutoff = today.add(const Duration(days: 30));
  var count = 0;

  for (final medicine in medicines) {
    final batches = (medicine['batches'] as List? ?? const []).whereType<Map>();
    final quantity = batches.fold<int>(
      0,
      (sum, batch) => sum + ((batch['quantity'] as num? ?? 0).toInt()),
    );
    if (quantity <= 10) count++;

    var hasExpiredBatch = false;
    var hasExpiringBatch = false;
    for (final batch in batches) {
      final batchQuantity = (batch['quantity'] as num? ?? 0).toInt();
      final expiry = DateTime.tryParse(batch['expiry_date']?.toString() ?? '');
      if (expiry == null || batchQuantity <= 0) continue;
      final expiryDay = DateTime(expiry.year, expiry.month, expiry.day);
      if (expiryDay.isBefore(today)) {
        hasExpiredBatch = true;
      } else if (!expiryDay.isAfter(cutoff)) {
        hasExpiringBatch = true;
      }
    }
    if (hasExpiredBatch) count++;
    if (hasExpiringBatch) count++;
  }
  return count;
}

class NotificationScreen extends StatefulWidget {
  final VoidCallback? onOpenMedicines;

  const NotificationScreen({super.key, this.onOpenMedicines});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _medicines = [];

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
      if (mounted) setState(() => _medicines = medicines);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _matching(String type) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _medicines.where((medicine) {
      final batches = (medicine['batches'] as List? ?? const [])
          .whereType<Map>();
      final quantity = batches.fold<int>(
        0,
        (sum, batch) => sum + ((batch['quantity'] as num? ?? 0).toInt()),
      );
      if (type == 'low') return quantity <= 10;
      return batches.any((batch) {
        final batchQuantity = (batch['quantity'] as num? ?? 0).toInt();
        final expiry = DateTime.tryParse(
          batch['expiry_date']?.toString() ?? '',
        );
        if (expiry == null || batchQuantity <= 0) return false;
        final expiryDay = DateTime(expiry.year, expiry.month, expiry.day);
        if (type == 'expired') return expiryDay.isBefore(today);
        return !expiryDay.isBefore(today) &&
            !expiryDay.isAfter(today.add(const Duration(days: 30)));
      });
    }).toList();
  }

  Future<void> _openDetail(String type, Map<String, dynamic> medicine) async {
    final openMedicines = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            NotificationDetailScreen(type: type, medicine: medicine),
      ),
    );
    if (openMedicines == true) widget.onOpenMedicines?.call();
  }

  @override
  Widget build(BuildContext context) {
    final groups = [
      (
        'expired',
        'ថ្នាំផុតកំណត់',
        'Expired',
        Icons.medication_liquid_outlined,
        const Color.fromARGB(255, 213, 15, 1),
      ),
      (
        'low',
        'ស្តុកទាប',
        'Low stock',
        Icons.inventory_2_outlined,
        const Color(0xFF0A4F44),
      ),
      (
        'expiring',
        'ជិតផុតកំណត់',
        'Expiring soon',
        Icons.hourglass_bottom_rounded,
        const Color.fromARGB(255, 182, 114, 12),
      ),
    ];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'ការជូនដំណឹង',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _notificationGreen),
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'មិនអាចទាញការជូនដំណឹងបាន\n$_error',
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: _load,
                      child: const Text('ព្យាយាមម្ដងទៀត'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
                children: [
                  for (final group in groups)
                    Builder(
                      builder: (context) {
                        final matches = _matching(group.$1);
                        if (matches.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _NotificationRow(
                            title: group.$2,
                            subtitle: group.$1 == 'expired'
                                ? '${matches.length} មុខ • ${group.$3}'
                                : group.$1 == 'low'
                                ? '${matches.length} មុខ • សូមពិនិត្យស្តុក'
                                : '${matches.length} មុខ • ${group.$3}',
                            icon: group.$4,
                            color: group.$5,
                            filledIcon: group.$1 == 'low',
                            onTap: () => _openDetail(group.$1, matches.first),
                          ),
                        );
                      },
                    ),
                  if (!_medicines.any(
                    (medicine) => [
                      'expired',
                      'low',
                      'expiring',
                    ].any((type) => _matching(type).contains(medicine)),
                  ))
                    const Padding(
                      padding: EdgeInsets.only(top: 100),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              size: 54,
                              color: Colors.black26,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'មិនមានការជូនដំណឹងថ្មីទេ',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool filledIcon;
  final VoidCallback onTap;

  const _NotificationRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.filledIcon = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFDADADA)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: filledIcon ? color : color.withOpacity(.08),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: filledIcon ? Colors.white : color, size: 26),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF17213D)),
              onSelected: (_) => onTap(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'view', child: Text('មើលព័ត៌មាន')),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class NotificationDetailScreen extends StatelessWidget {
  final String type;
  final Map<String, dynamic> medicine;

  const NotificationDetailScreen({
    super.key,
    required this.type,
    required this.medicine,
  });

  @override
  Widget build(BuildContext context) {
    final batches = (medicine['batches'] as List? ?? const []).whereType<Map>();
    final now = DateTime.now();
    final relevantBatch = batches.firstWhere((batch) {
      final expiry = DateTime.tryParse(batch['expiry_date']?.toString() ?? '');
      final quantity = (batch['quantity'] as num? ?? 0).toInt();
      if (type == 'low') return true;
      if (expiry == null || quantity <= 0) return false;
      final today = DateTime(now.year, now.month, now.day);
      final date = DateTime(expiry.year, expiry.month, expiry.day);
      return type == 'expired'
          ? date.isBefore(today)
          : !date.isBefore(today) &&
                !date.isAfter(today.add(const Duration(days: 30)));
    }, orElse: () => <String, dynamic>{});
    final name = medicine['name']?.toString() ?? 'ថ្នាំ';
    final batchName = relevantBatch['batch_number']?.toString() ?? '—';
    final expiry = DateTime.tryParse(
      relevantBatch['expiry_date']?.toString() ?? '',
    );
    final expiryText = expiry == null
        ? ''
        : '${expiry.year}-${expiry.month.toString().padLeft(2, '0')}-${expiry.day.toString().padLeft(2, '0')}';
    final expired = type == 'expired';
    final low = type == 'low';
    final title = expired
        ? 'ថ្នាំផុតកំណត់'
        : low
        ? 'ស្តុកថ្នាំទាប'
        : 'ថ្នាំជិតផុតកំណត់';
    final message = expired
        ? '$name • Batch $batchName បានផុតកំណត់${expiryText.isEmpty ? '' : ' នៅថ្ងៃទី $expiryText'}។'
        : low
        ? '$name មានស្តុកសរុបត្រឹមតែ ${MedicineApi.quantityOf(medicine)} ឯកតាប៉ុណ្ណោះ។'
        : '$name • Batch $batchName នឹងផុតកំណត់${expiryText.isEmpty ? '' : ' នៅថ្ងៃទី $expiryText'}។';
    final color = expired
        ? Colors.red
        : low
        ? Colors.orange
        : Colors.orange;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'ការជូនដំណឹង',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          expired
                              ? Icons.medication_liquid_outlined
                              : low
                              ? Icons.inventory_2_outlined
                              : Icons.hourglass_bottom_rounded,
                          color: color,
                          size: 30,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    if (low && relevantBatch.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Batch: $batchName',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: _notificationGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'មើលថ្នាំ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
