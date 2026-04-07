import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koin/core/models/planned_payment.dart';
import 'package:koin/core/models/transaction.dart';
import 'package:koin/core/providers/planned_payment_provider.dart';
import 'package:koin/core/providers/category_provider.dart';
import 'package:koin/core/providers/account_provider.dart';
import 'package:koin/core/theme.dart';
import 'package:intl/intl.dart';
import 'package:koin/core/utils/haptic_utils.dart';
import 'package:uuid/uuid.dart';

class AddEditPlannedPaymentScreen extends ConsumerStatefulWidget {
  final PlannedPayment? payment;

  const AddEditPlannedPaymentScreen({super.key, this.payment});

  @override
  ConsumerState<AddEditPlannedPaymentScreen> createState() =>
      _AddEditPlannedPaymentScreenState();
}

class _AddEditPlannedPaymentScreenState
    extends ConsumerState<AddEditPlannedPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;

  TransactionType _selectedType = TransactionType.expense;
  String? _selectedCategoryId;
  String? _selectedAccountId;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  PaymentFrequency _selectedFrequency = PaymentFrequency.monthly;
  bool _isAutoProcess = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.payment?.title ?? '');
    _amountController = TextEditingController(
      text: widget.payment?.amount.toStringAsFixed(2) ?? '',
    );
    if (widget.payment != null) {
      _selectedType = widget.payment!.type;
      _selectedCategoryId = widget.payment!.categoryId;
      _selectedAccountId = widget.payment!.accountId;
      _startDate = widget.payment!.startDate;
      _endDate = widget.payment!.endDate;
      _selectedFrequency = widget.payment!.frequency;
      _isAutoProcess = widget.payment!.isAutoProcess;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null || _selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select category and account')),
      );
      return;
    }

    HapticService.light();

    final amount = double.tryParse(_amountController.text) ?? 0.0;

    // Calculate next date based on frequency and start date
    DateTime nextDate = _startDate;
    final now = DateTime.now();
    while (nextDate.isBefore(now)) {
      switch (_selectedFrequency) {
        case PaymentFrequency.daily:
          nextDate = nextDate.add(const Duration(days: 1));
          break;
        case PaymentFrequency.weekly:
          nextDate = nextDate.add(const Duration(days: 7));
          break;
        case PaymentFrequency.biWeekly:
          nextDate = nextDate.add(const Duration(days: 14));
          break;
        case PaymentFrequency.monthly:
          nextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day);
          break;
        case PaymentFrequency.quarterly:
          nextDate = DateTime(nextDate.year, nextDate.month + 3, nextDate.day);
          break;
        case PaymentFrequency.yearly:
          nextDate = DateTime(nextDate.year + 1, nextDate.month, nextDate.day);
          break;
      }
    }

    final newPayment = PlannedPayment(
      id: widget.payment?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      amount: amount,
      type: _selectedType,
      categoryId: _selectedCategoryId!,
      accountId: _selectedAccountId!,
      startDate: _startDate,
      endDate: _endDate,
      nextDate: nextDate,
      frequency: _selectedFrequency,
      isAutoProcess: _isAutoProcess,
    );

    if (widget.payment == null) {
      await ref
          .read(plannedPaymentProvider.notifier)
          .addPlannedPayment(newPayment);
    } else {
      await ref
          .read(plannedPaymentProvider.notifier)
          .updatePlannedPayment(newPayment);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider);
    final accountsState = ref.watch(accountProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        title: Text(
          widget.payment == null ? 'New Subscription' : 'Edit Subscription',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppTheme.surfaceColor(context),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            color: AppTheme.primaryColor(context),
            onPressed: _savePayment,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title (e.g., Netflix)',
                  filled: true,
                  fillColor: AppTheme.surfaceColor(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  filled: true,
                  fillColor: AppTheme.surfaceColor(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TransactionType>(
                initialValue: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Type',
                  filled: true,
                  fillColor: AppTheme.surfaceColor(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: TransactionType.values
                    .where((t) => t != TransactionType.transfer)
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.name.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedType = val);
                },
              ),
              const SizedBox(height: 16),
              categoriesState.when(
                data: (categories) {
                  final opts = categories.where((c) => c.type == _selectedType);
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      filled: true,
                      fillColor: AppTheme.surfaceColor(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: opts.map((c) {
                      return DropdownMenuItem(value: c.id, child: Text(c.name));
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedCategoryId = val),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Error: \$e'),
              ),
              const SizedBox(height: 16),
              accountsState.when(
                data: (accounts) {
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedAccountId,
                    decoration: InputDecoration(
                      labelText: 'Account',
                      filled: true,
                      fillColor: AppTheme.surfaceColor(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: accounts.map((a) {
                      return DropdownMenuItem(value: a.id, child: Text(a.name));
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedAccountId = val),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Error: \$e'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PaymentFrequency>(
                initialValue: _selectedFrequency,
                decoration: InputDecoration(
                  labelText: 'Frequency',
                  filled: true,
                  fillColor: AppTheme.surfaceColor(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: PaymentFrequency.values.map((f) {
                  return DropdownMenuItem(
                    value: f,
                    child: Text(f.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedFrequency = val);
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Start Date'),
                subtitle: Text(DateFormat.yMMMd().format(_startDate)),
                trailing: const Icon(Icons.calendar_today),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                tileColor: AppTheme.surfaceColor(context),
                onTap: () async {
                  final dt = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (dt != null) setState(() => _startDate = dt);
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Auto-Process Payment'),
                subtitle: const Text('Creates a transaction automatically'),
                value: _isAutoProcess,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                tileColor: AppTheme.surfaceColor(context),
                onChanged: (val) => setState(() => _isAutoProcess = val),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
