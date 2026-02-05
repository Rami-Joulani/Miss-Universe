import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'select_customer_sheet.dart';
import 'select_open_group_sheet.dart';
import 'select_staff_sheet.dart';

class NewPaymentPage extends StatefulWidget {
  const NewPaymentPage({super.key});

  @override
  State<NewPaymentPage> createState() => _NewPaymentPageState();
}

class _NewPaymentPageState extends State<NewPaymentPage> {
  final _formKey = GlobalKey<FormState>();

  String _method = 'cash'; // cash | card
  String _type = 'deposit'; // deposit | final
  String _source = 'in_store'; // in_store | whatsapp | instagram | messenger
  String? _agreementLabel;
  String? _dressText; // kept for continuity
  DateTime _paidAt = DateTime.now();

  String? _customerId;
  String? _customerNamePhone;
  String? _groupKey; // link to previous deposit
  String? _groupLabel; // friendly label for selected deposit
  String? _receivedByStaffId;
  String? _receivedByLabel; // display only
  num? _expectedTotal; // required for deposit
  num? _amount;

  num? _currentBalance; // balance for selected group

  bool _submitting = false;

  Future<void> _pickCustomer() async {
    final result = await showModalBottomSheet<Map<String, String?>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const SelectCustomerSheet(),
    );
    if (result != null) {
      setState(() {
        _customerId = result['id'];
        _customerNamePhone = result['label'];
      });
    }
  }

  Future<void> _pickGroup() async {
    if (_customerId == null) return;
    final result = await showModalBottomSheet<Map<String,dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SelectOpenGroupSheet(customerId: _customerId!),
    );
    if (result != null) {
      setState(() {
        _groupKey = result['group_key'] as String?;
        _groupLabel = result['agreement_label'] as String? ?? 'غير مسمى';
      });
      await _loadBalance();
    }
  }

  Future<void> _pickReceivedBy() async {
    final result = await showModalBottomSheet<Map<String, String?>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const SelectStaffSheet(),
    );
    if (result != null) {
      setState(() {
        _receivedByStaffId = result['id'];
        _receivedByLabel = result['label'];
      });
    }
  }

  Future<void> _loadBalance() async {
    if (_customerId == null || _groupKey == null) return;
    try {
      final rows = await Supabase.instance.client
          .from('v_customer_balances')
          .select('balance')
          .eq('customer_id', _customerId!)
          .eq('group_key', _groupKey!)
          .limit(1);
      if (rows.isNotEmpty) {
        final b = (rows.first['balance']);
        setState(() {
          _currentBalance = (b is num) ? b : num.tryParse('$b');
        });
      }
    } catch (_) {
      // ignore
    }
  }

  String _formatDateTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d  $hh:$mm';
  }

  Future<void> _pickPaidAt() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _paidAt,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return;
    final timeOfDay = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_paidAt),
    );
    final time = timeOfDay ?? TimeOfDay.fromDateTime(_paidAt);
    setState(() {
      _paidAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_customerId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('اختر الزبون')));
      return;
    }

    setState(() => _submitting = true);

    try {
      final payload = {
        'amount': _amount,
        'method': _method,
        'type': _type,
        'customer_id': _customerId,
        'paid_at': _paidAt.toUtc().toIso8601String(),
        'notes': _agreementLabel, // reuse notes if you prefer
        'agreement_label': _agreementLabel,
        'dress_text': _dressText,
        'source': _source,
        if (_type == 'deposit') 'expected_total': _expectedTotal,
        if (_groupKey != null) 'group_key': _groupKey,
        if (_receivedByStaffId != null)
          'received_by_staff_id': _receivedByStaffId,
      };

      final res = await Supabase.instance.client
          .from('payments')
          .insert(payload)
          .select('id, group_key')
          .single();

      // If this was a deposit and no group chosen, the DB generated group_key; capture it
      _groupKey ??= (res['group_key'] as String?);

      if (mounted) {
        num? after;
        if (_type == 'final') {
          // if we have current balance, compute preview; else try to fetch fresh
          if (_currentBalance == null) {
            await _loadBalance();
          }
          final bal = _currentBalance;
          if (bal != null && _amount != null) {
            after = bal - _amount!;
            if (after < 0) after = 0;
          }
        }
        final msg = after == null
            ? 'تم حفظ الدفعة'
            : 'تم حفظ الدفعة، يتبقى: $after';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 6000),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(milliseconds: 8000),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل دفعة جديدة')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Customer picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('الزبون'),
                subtitle: Text(_customerNamePhone ?? 'اضغط للاختيار/الإضافة'),
                trailing: const Icon(Icons.search),
                onTap: _pickCustomer,
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('تاريخ الدفع'),
                subtitle: Text(_formatDateTime(_paidAt)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickPaidAt,
              ),
              const SizedBox(height: 8),

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('استلمت بواسطة'),
                subtitle: Text(_receivedByLabel ?? 'استخدام حساب الجهاز'),
                trailing: const Icon(Icons.person),
                onTap: _pickReceivedBy,
              ),
              const SizedBox(height: 8),

              // Type chips
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('عربون'),
                    selected: _type == 'deposit',
                    onSelected: (_) => setState(() => _type = 'deposit'),
                  ),
                  ChoiceChip(
                    label: const Text('دفعة نهائية/كاملة'),
                    selected: _type == 'final',
                    onSelected: (_) => setState(() => _type = 'final'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Amount
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'المبلغ',
                  prefixText: '₪ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  final x = num.tryParse((v ?? '').trim());
                  if (x == null || x <= 0) return 'Enter a valid amount';
                  return null;
                },
                onChanged: (v) {
                  setState(() {
                    _amount = num.tryParse(v.trim());
                  });
                },
              ),
              const SizedBox(height: 12),

              // Method
              DropdownButtonFormField<String>(
                initialValue: _method,
                decoration: const InputDecoration(labelText: 'طريقة الدفع'),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('نقدي')),
                  DropdownMenuItem(value: 'card', child: Text('بطاقة')),
                ],
                onChanged: (v) => setState(() => _method = v ?? 'cash'),
              ),
              const SizedBox(height: 12),

              // Source
              DropdownButtonFormField<String>(
                initialValue: _source,
                decoration: const InputDecoration(labelText: 'مكان البيع'),
                items: const [
                  DropdownMenuItem(value: 'in_store', child: Text('في المتجر')),
                  DropdownMenuItem(value: 'whatsapp', child: Text('WhatsApp')),
                  DropdownMenuItem(
                    value: 'instagram',
                    child: Text('Instagram'),
                  ),
                  DropdownMenuItem(
                    value: 'messenger',
                    child: Text('Messenger'),
                  ),
                ],
                onChanged: (v) => setState(() => _source = v ?? 'in_store'),
              ),
              const SizedBox(height: 12),

              // Deposit-specific fields
              if (_type == 'deposit') ...[
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'المبلغ المتوقع للفاتورة الكاملة',
                    prefixText: '₪ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    final x = num.tryParse((v ?? '').trim());
                    if (x == null || x <= 0) return 'Enter the full amount';
                    return null;
                  },
                  onChanged: (v) => _expectedTotal = num.tryParse(v.trim()),
                ),
              ] else ...[
                // Final payment must link to a group (deposit)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('ابحث عن العربون المرتبط'),
                  subtitle: Text(
                    _groupKey == null ? 'اضغط للاختيار' : _groupLabel ?? 'غير مسمى',
                  ),
                  trailing: const Icon(Icons.link),
                  onTap: _pickGroup,
                ),
                if (_groupKey != null) ...[
                  const SizedBox(height: 8),
                  Builder(
                    builder: (_) {
                      final bal = _currentBalance;
                      final amt = _amount;
                      final after = (bal != null && amt != null)
                          ? (bal - amt)
                          : null;
                      return Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('يتبقى حاليا: ${bal ?? '—'}'),
                              if (after != null)
                                Text(
                                  'يتبقى بعد المبلغ المدخل: ${after < 0 ? 0 : after}',
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],

              const SizedBox(height: 12),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'اسم/وصف الفستان',
                ),
                onChanged: (v) =>
                    _agreementLabel = v.trim().isEmpty ? null : v.trim(),
              ),

              const SizedBox(height: 24),
              FilledButton.icon(
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('ادخل الدفعة'),
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                ),
                onPressed: _submitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
