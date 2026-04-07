import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:koin/core/models/debt.dart';
import 'package:koin/core/models/debt_repayment.dart';
import 'package:koin/core/providers/debt_provider.dart';
import 'package:koin/core/providers/settings_provider.dart';
import 'package:koin/core/theme.dart';
import 'package:koin/core/utils/haptic_utils.dart';
import 'package:koin/core/utils/slide_up_route.dart';
import 'package:koin/features/debts/add_edit_debt_screen.dart';
import 'package:uuid/uuid.dart';

class DebtDetailsScreen extends ConsumerStatefulWidget {
  final String debtId;
  const DebtDetailsScreen({super.key, required this.debtId});

  @override
  ConsumerState<DebtDetailsScreen> createState() => _DebtDetailsScreenState();
}

class _DebtDetailsScreenState extends ConsumerState<DebtDetailsScreen> {
  void _addRepayment(BuildContext context, Debt debt) {
    HapticService.light();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddRepaymentSheet(debt: debt),
    );
  }

  @override
  Widget build(BuildContext context) {
    final debtsAsync = ref.watch(debtsProvider);
    final repaymentsAsync = ref.watch(debtRepaymentsProvider(widget.debtId));
    final settings = ref.watch(settingsProvider);
    final currencyFormat = NumberFormat.simpleCurrency(
      name: settings.currency.code,
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Debt Details',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          debtsAsync.whenOrNull(
                data: (debts) {
                  final debt = debts.firstWhere(
                    (d) => d.id == widget.debtId,
                    orElse: () => debts.first,
                  );
                  if (debt.id == widget.debtId) {
                    return IconButton(
                      icon: const Icon(Icons.edit_rounded),
                      onPressed: () {
                        HapticService.light();
                        Navigator.push(
                          context,
                          SlideUpRoute(page: AddEditDebtScreen(debt: debt)),
                        );
                      },
                    );
                  }
                  return const SizedBox();
                },
              ) ??
              const SizedBox(),
        ],
      ),
      body: debtsAsync.when(
        data: (debts) {
          final debt = debts.firstWhere(
            (d) => d.id == widget.debtId,
            orElse: () => debts.first,
          );
          if (debt.id != widget.debtId) {
            return const Center(child: Text('Debt not found'));
          }

          final progress = (debt.currentAmount / debt.amount).clamp(0.0, 1.0);
          final isSettled = progress >= 1.0;
          final color = debt.type == DebtType.owedToMe
              ? AppTheme.incomeColor(context)
              : AppTheme.expenseColor(context);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    MediaQuery.paddingOf(context).top + 64,
                    24,
                    32,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor(context),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isSettled
                            ? Icons.check_circle_rounded
                            : Icons.account_balance_wallet_rounded,
                        size: 64,
                        color: color,
                      ),
                      const Gap(16),
                      Text(
                        debt.personName,
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Gap(24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Repaid',
                                style: TextStyle(
                                  color: AppTheme.textLightColor(context),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Gap(4),
                              Text(
                                currencyFormat.format(debt.currentAmount),
                                style: TextStyle(
                                  color: color,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Total',
                                style: TextStyle(
                                  color: AppTheme.textLightColor(context),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Gap(4),
                              Text(
                                currencyFormat.format(debt.amount),
                                style: TextStyle(
                                  color: AppTheme.textColor(context),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Gap(16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 12,
                          backgroundColor: AppTheme.dividerColor(context),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                      if (!isSettled) ...[
                        const Gap(32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _addRepayment(context, debt),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Add Repayment',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                sliver: repaymentsAsync.when(
                  data: (repayments) {
                    if (repayments.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text('No repayments logged yet.'),
                          ),
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final r = repayments[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.dividerColor(
                                context,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.receipt_long_rounded,
                                  color: color,
                                  size: 20,
                                ),
                              ),
                              const Gap(16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.note?.isNotEmpty == true
                                          ? r.note!
                                          : 'Repayment',
                                      style: TextStyle(
                                        color: AppTheme.textColor(context),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const Gap(4),
                                    Text(
                                      DateFormat.yMMMd().format(r.date),
                                      style: TextStyle(
                                        color: AppTheme.textLightColor(context),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                currencyFormat.format(r.amount),
                                style: TextStyle(
                                  color: AppTheme.textColor(context),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: AppTheme.errorColor(context),
                                  size: 20,
                                ),
                                onPressed: () {
                                  HapticService.medium();
                                  ref
                                      .read(debtsProvider.notifier)
                                      .deleteRepayment(r);
                                },
                              ),
                            ],
                          ),
                        );
                      }, childCount: repayments.length),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => SliverToBoxAdapter(
                    child: Center(child: Text('Error: \$e')),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: \$e')),
      ),
    );
  }
}

class _AddRepaymentSheet extends ConsumerStatefulWidget {
  final Debt debt;
  const _AddRepaymentSheet({required this.debt});

  @override
  ConsumerState<_AddRepaymentSheet> createState() => _AddRepaymentSheetState();
}

class _AddRepaymentSheetState extends ConsumerState<_AddRepaymentSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Log Payment',
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.close_rounded,
                  color: AppTheme.textLightColor(context),
                ),
              ),
            ],
          ),
          const Gap(24),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              labelText: 'Amount (${ref.read(settingsProvider).currency.code})',
              prefixText: '${ref.read(settingsProvider).currency.symbol} ',
              filled: true,
              fillColor: AppTheme.surfaceColor(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const Gap(16),
          TextField(
            controller: _noteController,
            style: TextStyle(color: AppTheme.textColor(context)),
            decoration: InputDecoration(
              labelText: 'Note (Optional)',
              filled: true,
              fillColor: AppTheme.surfaceColor(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const Gap(32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                HapticService.medium();
                final amtStr = _amountController.text.replaceAll(',', '');
                if (amtStr.isEmpty) return;
                final amt = double.tryParse(amtStr) ?? 0.0;
                if (amt <= 0) return;

                final repayment = DebtRepayment(
                  id: const Uuid().v4(),
                  debtId: widget.debt.id,
                  amount: amt,
                  date: DateTime.now(),
                  note: _noteController.text.trim().isNotEmpty
                      ? _noteController.text.trim()
                      : null,
                );

                await ref.read(debtsProvider.notifier).addRepayment(repayment);
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor(context),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
