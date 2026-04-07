import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:koin/core/models/debt.dart';
import 'package:koin/core/providers/debt_provider.dart';
import 'package:koin/core/theme.dart';
import 'package:koin/core/utils/haptic_utils.dart';
import 'dart:ui';
import 'package:koin/core/providers/settings_provider.dart';
import 'package:uuid/uuid.dart';

class AddEditDebtScreen extends ConsumerStatefulWidget {
  final Debt? debt;
  const AddEditDebtScreen({super.key, this.debt});

  @override
  ConsumerState<AddEditDebtScreen> createState() => _AddEditDebtScreenState();
}

class _AddEditDebtScreenState extends ConsumerState<AddEditDebtScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _installmentsController = TextEditingController();

  late DebtType _selectedType;
  DateTime _startDate = DateTime.now();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final d = widget.debt;
    if (d != null) {
      _nameController.text = d.personName;
      _amountController.text = d.amount.toString();
      _notesController.text = d.description ?? '';
      _selectedType = d.type;
      _startDate = d.startDate;
      _installmentsController.text = d.totalInstallments > 0
          ? d.totalInstallments.toString()
          : '';
    } else {
      _selectedType = DebtType.owedToMe;
    }

    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _selectedType == DebtType.owedToMe ? 0 : 1,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedType = _tabController.index == 0
              ? DebtType.owedToMe
              : DebtType.iOwe;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _installmentsController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final amount = double.parse(
      _amountController.text.trim().replaceAll(',', ''),
    );
    final notes = _notesController.text.trim();
    final isEdit = widget.debt != null;
    final id = isEdit ? widget.debt!.id : const Uuid().v4();
    final currentAmount = isEdit ? widget.debt!.currentAmount : 0.0;

    final installmentsText = _installmentsController.text.trim();
    int installments = 0;
    if (installmentsText.isNotEmpty) {
      installments = int.tryParse(installmentsText) ?? 0;
    }

    final debt = Debt(
      id: id,
      personName: name,
      amount: amount,
      type: _selectedType,
      startDate: _startDate,
      description: notes.isEmpty ? null : notes,
      totalInstallments: installments,
      currentAmount: currentAmount,
    );

    if (isEdit) {
      await ref.read(debtsProvider.notifier).updateDebt(debt);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Debt updated')));
    } else {
      await ref.read(debtsProvider.notifier).addDebt(debt);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Debt created')));
    }

    if (mounted) {
      HapticService.light();
      Navigator.pop(context);
    }
  }

  void _delete() async {
    HapticService.heavy();
    await ref.read(debtsProvider.notifier).deleteDebt(widget.debt!.id);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Debt deleted')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.debt != null;
    final settings = ref.watch(settingsProvider);
    final currency = settings.currency;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Debt' : 'Add Debt',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (isEdit)
            IconButton(
              icon: Icon(
                Icons.delete_rounded,
                color: AppTheme.errorColor(context),
              ),
              onPressed: () {
                HapticService.medium();
                _delete();
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Type',
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const Gap(12),
              _buildColoredTypeSelector(context),
              const Gap(24),
              _buildTextInput(
                controller: _nameController,
                label: 'Person/Institution Name',
                hint: 'e.g., John Doe or BestBuy',
                icon: Icons.person_rounded,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter a name';
                  return null;
                },
              ),
              const Gap(24),
              _buildTextInput(
                controller: _amountController,
                label: 'Initial Amount (${currency.code})',
                hint: '${currency.symbol} 0.00',
                icon: Icons.payments_rounded,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'Enter an amount';
                  if (double.tryParse(val.replaceAll(',', '')) == null)
                    return 'Invalid amount';
                  return null;
                },
              ),

              const Gap(24),
              _buildTextInput(
                controller: _installmentsController,
                label: 'Total Installments (Optional)',
                hint: 'e.g., 12 months',
                icon: Icons.calendar_month_rounded,
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val != null &&
                      val.isNotEmpty &&
                      int.tryParse(val) == null) {
                    return 'Invalid number';
                  }
                  return null;
                },
              ),
              const Gap(24),
              _buildTextInput(
                controller: _notesController,
                label: 'Notes (Optional)',
                hint: 'Any details',
                icon: Icons.notes_rounded,
                maxLines: 3,
              ),
              const Gap(40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticService.medium();
                    _save();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor(context),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isEdit ? 'Save Changes' : 'Create Debt',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const Gap(8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: TextStyle(color: AppTheme.textColor(context), fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppTheme.textLightColor(context).withValues(alpha: 0.5),
            ),
            prefixIcon: maxLines == 1
                ? Icon(icon, color: AppTheme.textLightColor(context))
                : null,
            filled: true,
            fillColor: AppTheme.surfaceColor(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppTheme.dividerColor(context).withValues(alpha: 0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppTheme.dividerColor(context).withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppTheme.primaryColor(context),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.errorColor(context)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColoredTypeSelector(BuildContext context) {
    return AnimatedBuilder(
      animation: _tabController.animation!,
      builder: (context, child) {
        final animationValue = _tabController.animation!.value;
        final activeColor = Color.lerp(
          AppTheme.incomeColor(context),
          AppTheme.expenseColor(context),
          animationValue,
        )!;

        return Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor(context).withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppTheme.dividerColor(context).withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final tabWidth = constraints.maxWidth / 2;
                    return Stack(
                      children: [
                        // Sliding Indicator
                        Positioned(
                          top: 0,
                          bottom: 0,
                          left: animationValue * tabWidth,
                          width: tabWidth,
                          child: Container(
                            decoration: BoxDecoration(
                              color: activeColor,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: activeColor.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Tab Labels
                        Row(
                          children: [
                            _buildColoredTabItem(
                              context,
                              'I am owed',
                              0,
                              Icons.arrow_downward_rounded,
                            ),
                            _buildColoredTabItem(
                              context,
                              'I owe',
                              1,
                              Icons.arrow_upward_rounded,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildColoredTabItem(
    BuildContext context,
    String label,
    int index,
    IconData icon,
  ) {
    return AnimatedBuilder(
      animation: _tabController.animation!,
      builder: (context, child) {
        final animationValue = _tabController.animation!.value;
        final distance = (index - animationValue).abs();
        final value = (1.0 - distance).clamp(0.0, 1.0);
        final isActive = value > 0.5;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticService.selection();
              _tabController.animateTo(index);
            },
            behavior: HitTestBehavior.opaque,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: Color.lerp(
                      AppTheme.textLightColor(context),
                      Colors.white,
                      value,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    label,
                    style: TextStyle(
                      color: Color.lerp(
                        AppTheme.textLightColor(context),
                        Colors.white,
                        value,
                      ),
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
