import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import '../core/constants.dart';
import '../providers/customer_provider.dart';

/// Bottom sheet for searching and creating customers with debounced search
class SelectCustomerSheet extends StatefulWidget {
  const SelectCustomerSheet({super.key});

  @override
  State<SelectCustomerSheet> createState() => _SelectCustomerSheetState();
}

class _SelectCustomerSheetState extends State<SelectCustomerSheet> {
  final _controller = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _searchSubject = BehaviorSubject<String>();
  StreamSubscription? _searchSubscription;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    
    // Setup debounced search - waits 300ms after user stops typing
    _searchSubscription = _searchSubject
        .debounceTime(AppConstants.searchDebounceDuration)
        .distinct()
        .listen((query) {
      if (mounted) {
        context.read<CustomerProvider>().searchCustomers(query);
      }
    });
  }

  @override
  void dispose() {
    _searchSubscription?.cancel();
    _searchSubject.close();
    _controller.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchSubject.add(value);
  }

  Future<void> _openCreateFormSheet() async {
    _nameCtrl.clear();
    _phoneCtrl.clear();
    
    final res = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'اضف زبون',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'الاسم',
                      hintText: 'مطلوب (حرفان على الأقل)',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                    autofocus: true,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف',
                      hintText: 'مطلوب (٦ أرقام على الأقل)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(bottomSheetContext, false),
                        child: const Text('الغاء'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => Navigator.pop(bottomSheetContext, true),
                        child: const Text('حفظ'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    
    if (res != true || !mounted) return;
    
    // Show loading state
    setState(() => _isCreating = true);
    
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    
    // Create customer using provider
    final customer = await context.read<CustomerProvider>().createCustomer(
      name: name,
      phone: phone,
    );
    
    setState(() => _isCreating = false);
    
    if (customer != null && mounted) {
      // Success - return to parent
      Navigator.pop<Map<String, String?>>(context, {
        'id': customer.id,
        'label': '${customer.name} • ${customer.phone}',
      });
    } else if (mounted) {
      // Error - show message
      final error = context.read<CustomerProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'فشل إضافة الزبون'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search field with debouncing
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'البحث عن زبون',
                  hintText: 'ادخل الاسم أو رقم الهاتف',
                  border: const OutlineInputBorder(),
                  suffixIcon: _isCreating
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Icon(Icons.search),
                ),
                onChanged: _onSearchChanged,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              
              // Search results
              Consumer<CustomerProvider>(
                builder: (context, provider, _) {
                  // Show loading indicator
                  if (provider.isSearching) {
                    return const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    );
                  }

                  // Show error if any
                  if (provider.error != null && provider.searchResults.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        provider.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  // Show results
                  if (provider.searchResults.isNotEmpty) {
                    return Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: provider.searchResults.length,
                        itemBuilder: (_, i) {
                          final customer = provider.searchResults[i];
                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text(customer.name),
                            subtitle: Text(customer.phone),
                            onTap: () {
                              Navigator.pop<Map<String, String?>>(context, {
                                'id': customer.id,
                                'label': '${customer.name} • ${customer.phone}',
                              });
                            },
                          );
                        },
                      ),
                    );
                  }

                  // Show "no results" message
                  if (_controller.text.trim().isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'لا توجد نتائج',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'يمكنك إضافة زبون جديد',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }

                  // Default state
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'ابدأ الكتابة للبحث عن زبون',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 8),
              const Divider(),
              
              // Add new customer button
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _isCreating ? null : _openCreateFormSheet,
                  icon: const Icon(Icons.person_add),
                  label: const Text('اضف زبون جديد'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
