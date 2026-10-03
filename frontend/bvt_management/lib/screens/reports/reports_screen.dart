import 'package:flutter/material.dart';
import '../../services/report_api.dart';

const _green = Color(0xFF008575);

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _days = 30;
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _report = {};

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
      final data = await ReportApi.getSummary(days: _days);
      if (mounted) setState(() => _report = data);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _money(dynamic value) =>
      '\$${(value as num? ?? 0).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final daily = (_report['daily_sales'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    final maxValue = daily.fold<double>(
      1,
      (max, item) => (item['total'] as num? ?? 0).toDouble() > max
          ? (item['total'] as num).toDouble()
          : max,
    );
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'របាយការណ៍',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'មិនអាចទាញរបាយការណ៍បាន\n$_error',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
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
                padding: const EdgeInsets.all(18),
                children: [
                  SegmentedButton<int>(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((states) =>
                          states.contains(WidgetState.selected)
                              ? const Color(0xFF0A4F44)
                              : Colors.white),
                      foregroundColor: WidgetStateProperty.resolveWith((states) =>
                          states.contains(WidgetState.selected)
                              ? Colors.white
                              : const Color(0xFF4A5568)),
                    ),
                    segments: const [
                      ButtonSegment(value: 7, label: Text('7 ថ្ងៃ')),
                      ButtonSegment(value: 30, label: Text('30 ថ្ងៃ')),
                      ButtonSegment(value: 90, label: Text('90 ថ្ងៃ')),
                    ],
                    selected: {_days},
                    onSelectionChanged: (selection) {
                      setState(() => _days = selection.first);
                      _load();
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _metric(
                          'ចំណូលពីការលក់',
                          _money(_report['sales_total']),
                          Icons.trending_up,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _metric(
                          'ចំណាយទិញ',
                          _money(_report['purchase_total']),
                          Icons.shopping_bag_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _metric(
                          'ប្រតិបត្តិការលក់',
                          '${_report['sales_count'] ?? 0}',
                          Icons.receipt_long_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _metric(
                          'ការបញ្ជាទិញ',
                          '${_report['purchase_count'] ?? 0}',
                          Icons.local_shipping_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _section(
                    title: 'ចំណូលតាមថ្ងៃ',
                    child: SizedBox(
                      height: 190,
                      child: daily.isEmpty
                          ? const Center(child: Text('មិនទាន់មានទិន្នន័យ'))
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: daily.map((item) {
                                final total = (item['total'] as num? ?? 0)
                                    .toDouble();
                                final date = item['date']?.toString() ?? '';
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Tooltip(
                                          message: '$date  ${_money(total)}',
                                          child: Container(
                                            height: 130 * total / maxValue + 3,
                                            decoration: BoxDecoration(
                                              color: total == 0
                                                  ? const Color(0xFFE7ECEB)
                                                  : _green,
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 7),
                                        Text(
                                          date.length >= 10
                                              ? date.substring(8)
                                              : '',
                                          style: const TextStyle(fontSize: 9),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _section(
                    title: 'ស្ថានភាពស្តុក',
                    child: Column(
                      children: [
                        _stat(
                          'ថ្នាំសរុប',
                          '${_report['medicine_count'] ?? 0} មុខ',
                        ),
                        _stat(
                          'ចំនួនឯកតាក្នុងស្តុក',
                          '${_report['stock_units'] ?? 0}',
                        ),
                        _stat(
                          'ថ្នាំស្តុកទាប (≤10)',
                          '${_report['low_stock_count'] ?? 0}',
                          color: Colors.orange,
                        ),
                        _stat(
                          'Batch ផុតកំណត់មានស្តុក',
                          '${_report['expired_batch_count'] ?? 0}',
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                ],
              ),
            ),
    );
  }

  Widget _metric(String title, String value, IconData icon) =>
      Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFFE3E7E8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF0A4F44),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: Colors.white, size: 21),
            ),
            const SizedBox(height: 13),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ],
        ),
      );
  Widget _section({required String title, required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE3E7E8)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );
  Widget _stat(String label, String value, {Color color = Colors.black87}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
      );
}
