import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../services/api_client.dart';
import '../auth/auth_repository.dart';
import '../../utils/notify.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _loading = false;
  String? _error;
  num? _balance;
  List<Map<String, dynamic>> _tx = [];

  final NumberFormat _moneyFmt = NumberFormat.currency(
    name: 'RWF',
    symbol: 'RWF ',
    decimalDigits: 0,
  );
  final DateFormat _dateFmt = DateFormat('yyyy-MM-dd HH:mm');

  ApiClient _client(WidgetRef ref) {
    final token = ref.read(authTokenProvider);
    return ApiClient(token: token);
  }

  String _formatTs(dynamic v) {
    if (v == null) return '';
    if (v is String) return v;
    if (v is Map) {
      final seconds = v['seconds'] ?? v['_seconds'];
      final nanos = v['nanoseconds'] ?? v['_nanoseconds'] ?? 0;
      if (seconds is num) {
        final ms = (nanos is num) ? (nanos ~/ 1000000) : 0;
        final dt = DateTime.fromMillisecondsSinceEpoch(
          seconds.toInt() * 1000 + ms,
          isUtc: true,
        ).toLocal();
        return _dateFmt.format(dt);
      }
    }
    return v.toString();
  }

  Future<void> _logout() async {
    ref.read(authTokenProvider.notifier).state = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } catch (_) {}
    if (mounted) context.go('/login');
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = _client(ref);
      final bal = await client.dio.get('/account/balance');
      final tx = await client.dio.get('/transactions');
      setState(() {
        _balance = (bal.data as Map)['balance'] as num?;
        _tx = List<Map<String, dynamic>>.from(tx.data as List);
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  bool get _isLowBalance => (_balance ?? 0) < 5000; // RWF threshold

  Future<void> _amountDialog(String type) async {
    final ctrl = TextEditingController();
    final amount = await showDialog<num?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(type == 'deposit' ? 'Deposit' : 'Withdraw'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final v = num.tryParse(ctrl.text.trim());
              Navigator.pop(ctx, v);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (amount == null || amount <= 0) return;
    if (type == 'withdraw' && _balance != null && amount > _balance!) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Insufficient funds')));
      }
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = _client(ref);
      await client.dio.post('/transactions/$type', data: {'amount': amount});
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${type[0].toUpperCase()}${type.substring(1)} successful',
            ),
          ),
        );
      }
      // Also show a local web notification as a backup UX signal
      final prettyAmount = _moneyFmt.format(amount);
      await showWebNotification(
        type == 'deposit' ? 'Deposit successful' : 'Withdrawal successful',
        '${type == 'deposit' ? 'Credited' : 'Debited'} $prettyAmount',
      );
    } catch (e) {
      String msg = e.toString();
      try {
        // Try to extract backend message if available
        // ignore: avoid_dynamic_calls
        final data = (e as dynamic).response?.data;
        if (data is Map && data['message'] is String) {
          msg = data['message'] as String;
        }
      } catch (_) {}
      setState(() {
        _error = msg;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
      // ignore: avoid_print
      print('[tx] ' + type + ' failed: ' + msg);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 24),
            const SizedBox(width: 8),
            const Text('Dashboard'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _loading ? null : _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            if (_isLowBalance)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E5),
                  border: Border.all(color: const Color(0xFFFFD7A8)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Low balance: ${_balance?.toStringAsFixed(0)} RWF. Consider depositing to avoid failed withdrawals.',
                  style: const TextStyle(color: Color(0xFF7A4B00)),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Balance',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _balance == null ? '—' : _moneyFmt.format(_balance),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: [
                              FilledButton(
                                onPressed: _loading
                                    ? null
                                    : () => _amountDialog('deposit'),
                                child: const Text('Deposit'),
                              ),
                              OutlinedButton(
                                onPressed: _loading
                                    ? null
                                    : () => _amountDialog('withdraw'),
                                child: const Text('Withdraw'),
                              ),
                              IconButton(
                                onPressed: _loading ? null : _load,
                                icon: const Icon(Icons.refresh),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Recent transactions',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading && _tx.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      itemCount: _tx.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final t = _tx[i];
                        final type = (t['type'] as String?) ?? '';
                        final amount = t['amount'];
                        final ts = _formatTs(t['createdAt']);
                        return ListTile(
                          leading: Icon(
                            type == 'deposit'
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: type == 'deposit'
                                ? Colors.green
                                : Colors.red,
                          ),
                          title: Text(
                            '$type  ·  ${_moneyFmt.format(amount is num ? amount : num.tryParse('$amount') ?? 0)}',
                          ),
                          subtitle: Text(ts),
                          trailing: Text(
                            _moneyFmt.format(
                              (t['balanceAfter'] is num)
                                  ? t['balanceAfter'] as num
                                  : (num.tryParse('${t['balanceAfter']}') ?? 0),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
