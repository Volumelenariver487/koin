import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:koin/core/models/debt.dart';
import 'package:koin/core/models/debt_repayment.dart';
import 'package:koin/core/providers/debt_provider.dart';
import 'package:koin/core/providers/settings_provider.dart';
import 'package:koin/core/theme.dart';
import 'package:koin/core/utils/haptic_utils.dart';
import 'package:koin/core/utils/slide_up_route.dart';
import 'package:koin/features/debts/add_edit_debt_screen.dart';
import 'package:koin/core/models/account.dart';
import 'package:koin/core/providers/account_provider.dart';
import 'package:koin/core/utils/icon_utils.dart';
import 'package:koin/core/widgets/confirmation_sheet.dart';
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

  Future<void> _showDeleteConfirmation(Debt debt) async {
    final confirmed = await ConfirmationSheet.show(
      context: context,
      title: 'Delete Debt?',
      description:
          'Are you sure you want to delete this debt? This action cannot be undone and will delete all associated payment history.',
      confirmLabel: 'Delete Debt',
      confirmColor: AppTheme.errorColor(context),
      icon: Icons.delete_outline_rounded,
      isDanger: true,
    );

    if (confirmed == true && mounted) {
      HapticService.heavy();
      await ref.read(debtsProvider.notifier).deleteDebt(debt.id);
      if (mounted) {
        Navigator.pop(context);
      }
    }
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
                  final debt = debts.cast<Debt?>().firstWhere(
                    (d) => d?.id == widget.debtId,
                    orElse: () => null,
                  );
                  if (debt != null && debt.id == widget.debtId) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_rounded),
                          onPressed: () {
                            HapticService.light();
                            Navigator.push(
                              context,
                              SlideUpRoute(page: AddEditDebtScreen(debt: debt)),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () => _showDeleteConfirmation(debt),
                        ),
                      ],
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
          final debt = debts.cast<Debt?>().firstWhere(
            (d) => d?.id == widget.debtId,
            orElse: () => null,
          );
          if (debt == null) {
            return const Center(child: Text('Debt not found'));
          }

          final progress = (debt.currentAmount / debt.amount).clamp(0.0, 1.0);
          final isSettled = progress >= 1.0;
          final remaining = (debt.amount - debt.currentAmount).clamp(
            0.0,
            debt.amount,
          );
          final color = debt.type == DebtType.owedToMe
              ? AppTheme.incomeColor(context)
              : AppTheme.expenseColor(context);
          final percentText = '${(progress * 100).toInt()}%';

          return CustomScrollView(
            slivers: [
              // ── Hero Header ──
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
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar with gradient

                      // Person name + status badge
                      Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                debt.personName,
                                style: TextStyle(
                                  color: AppTheme.textColor(context),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          )
                          .animate()
                          .slideY(begin: 0.15, delay: 200.ms, duration: 400.ms)
                          .fadeIn(),
                      if (debt.totalInstallments > 0) ...[
                        const Gap(6),
                        Text(
                          '${debt.totalInstallments} ${debt.frequency.name} payments',
                          style: TextStyle(
                            color: AppTheme.textLightColor(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const Gap(24),

                      // Hero remaining amount
                      Text(
                        isSettled ? 'Fully Paid' : 'Remaining',
                        style: TextStyle(
                          color: AppTheme.textLightColor(context),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ).animate().fadeIn(delay: 250.ms),
                      const Gap(4),
                      Text(
                            isSettled
                                ? currencyFormat.format(debt.amount)
                                : currencyFormat.format(remaining),
                            style: TextStyle(
                              color: isSettled
                                  ? AppTheme.primaryColor(context)
                                  : AppTheme.textColor(context),
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          )
                          .animate()
                          .slideY(begin: 0.1, delay: 300.ms, duration: 400.ms)
                          .fadeIn(),
                      if (!isSettled) ...[
                        const Gap(2),
                        Text(
                          'of ${currencyFormat.format(debt.amount)} total',
                          style: TextStyle(
                            color: AppTheme.textLightColor(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const Gap(24),

                      // Stat cards row
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              label: 'Repaid',
                              value: currencyFormat.format(debt.currentAmount),
                              color: color,
                            ),
                          ),
                          const Gap(12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              label: 'Progress',
                              value: percentText,
                              color: AppTheme.primaryColor(context),
                            ),
                          ),
                        ],
                      ),
                      const Gap(20),

                      // Gradient progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          children: [
                            Container(
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppTheme.dividerColor(context),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: progress,
                              child: Container(
                                height: 12,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      color,
                                      color.withValues(alpha: 0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Add repayment button
                      if (!isSettled) ...[
                        const Gap(28),
                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [color, color.withValues(alpha: 0.8)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () => _addRepayment(context, debt),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Log Payment',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Payment History Section ──
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 100),
                sliver: repaymentsAsync.when(
                  data: (repayments) {
                    if (repayments.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const Gap(24),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceColor(context),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.receipt_long_rounded,
                                size: 32,
                                color: AppTheme.textLightColor(
                                  context,
                                ).withValues(alpha: 0.4),
                              ),
                            ),
                            const Gap(16),
                            Text(
                              'No payments yet',
                              style: TextStyle(
                                color: AppTheme.textLightColor(context),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Gap(4),
                            Text(
                              'Tap "Log Payment" to record a repayment',
                              style: TextStyle(
                                color: AppTheme.textLightColor(
                                  context,
                                ).withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        // Section header at index 0
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                Text(
                                  'Payment History',
                                  style: TextStyle(
                                    color: AppTheme.textColor(context),
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const Gap(10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor(
                                      context,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${repayments.length}',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor(context),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final r = repayments[index - 1];
                        return _buildRepaymentTile(
                          context,
                          repayment: r,
                          currencyFormat: currencyFormat,
                          color: color,
                          tileIndex: index - 1,
                        );
                      }, childCount: repayments.length + 1),
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

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.dividerColor(context).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textLightColor(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepaymentTile(
    BuildContext context, {
    required DebtRepayment repayment,
    required NumberFormat currencyFormat,
    required Color color,
    required int tileIndex,
  }) {
    return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.dividerColor(context).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.receipt_long_rounded, color: color, size: 18),
              ),
              const Gap(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      repayment.note?.isNotEmpty == true
                          ? repayment.note!
                          : 'Payment',
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Gap(3),
                    Text(
                      DateFormat.yMMMd().format(repayment.date),
                      style: TextStyle(
                        color: AppTheme.textLightColor(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                currencyFormat.format(repayment.amount),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: -0.3,
                ),
              ),
              const Gap(4),
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.textLightColor(
                      context,
                    ).withValues(alpha: 0.5),
                    size: 18,
                  ),
                  onPressed: () {
                    HapticService.medium();
                    ref.read(debtsProvider.notifier).deleteRepayment(repayment);
                  },
                ),
              ),
            ],
          ),
        )
        .animate()
        .slideX(
          begin: 0.1,
          delay: Duration(milliseconds: 60 * tileIndex),
          duration: 300.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(
          delay: Duration(milliseconds: 60 * tileIndex),
          duration: 300.ms,
        );
  }
}

// ──────────────────────────────────────────────────────────────
//  Premium Log Payment Bottom Sheet
// ──────────────────────────────────────────────────────────────

class _AddRepaymentSheet extends ConsumerStatefulWidget {
  final Debt debt;
  const _AddRepaymentSheet({required this.debt});

  @override
  ConsumerState<_AddRepaymentSheet> createState() => _AddRepaymentSheetState();
}

class _AddRepaymentSheetState extends ConsumerState<_AddRepaymentSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _noteFocusNode = FocusNode();
  String? _selectedAccountId;
  String _currentExpression = '';

  @override
  void initState() {
    super.initState();
    if (widget.debt.totalInstallments > 0) {
      final payment = widget.debt.amount / widget.debt.totalInstallments;
      var paymentStr = payment.toStringAsFixed(2);
      if (paymentStr.endsWith('.00')) {
        paymentStr = paymentStr.substring(0, paymentStr.length - 3);
      }
      _amountController.text = paymentStr;
    }
    _currentExpression = _amountController.text;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final accounts = ref.watch(accountProvider).value ?? [];
    final color = widget.debt.type == DebtType.owedToMe
        ? AppTheme.incomeColor(context)
        : AppTheme.expenseColor(context);

    final selectedAccount = _selectedAccountId != null
        ? accounts.firstWhere(
            (a) => a.id == _selectedAccountId,
            orElse: () => accounts.first,
          )
        : (accounts.isNotEmpty ? accounts.first : null);

    if (_selectedAccountId == null && selectedAccount != null) {
      _selectedAccountId = selectedAccount.id;
    }

    final hasAmount =
        _currentExpression.isNotEmpty && _currentExpression != '0';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          0,
          12,
          0,
          MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 40,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle ──
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.dividerColor(context).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(16),

            // ── Title bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticService.light();
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.dividerColor(
                            context,
                          ).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: AppTheme.textLightColor(context),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Log Payment',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textLightColor(context),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            const Gap(24),

            // ── Hero Amount ──
            Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Text(
                        settings.currency.code,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color.withValues(alpha: 0.5),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const Gap(4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${settings.currency.symbol} ',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: color.withValues(alpha: 0.4),
                            ),
                          ),
                          IntrinsicWidth(
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                hoverColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                              ),
                              child: TextField(
                                controller: _amountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                textAlign: TextAlign.center,
                                onChanged: (val) =>
                                    setState(() => _currentExpression = val),
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w800,
                                  color: hasAmount
                                      ? color
                                      : color.withValues(alpha: 0.35),
                                  letterSpacing: -2,
                                  height: 1.1,
                                ),
                                decoration: InputDecoration(
                                  hintText: '0',
                                  hintStyle: TextStyle(
                                    color: color.withValues(alpha: 0.35),
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  filled: false,
                                  fillColor: Colors.transparent,
                                  isDense: true,
                                  isCollapsed: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(8),
                      Container(
                        width: hasAmount ? 60 : 40,
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: color.withValues(alpha: 0.25),
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.1, curve: Curves.easeOutCubic),

            const Gap(28),

            // ── Account selection ──
            Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor(context),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppTheme.dividerColor(
                          context,
                        ).withValues(alpha: 0.7),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSelectionRow(
                          context,
                          fallbackIcon: Icons.account_balance_wallet_rounded,
                          label: 'Account',
                          selectedName: selectedAccount?.name,
                          selectedColor: selectedAccount?.color,
                          selectedIconCodePoint: selectedAccount?.iconCodePoint,
                          placeholder: 'Select account',
                          onTap: () => _openAccountPicker(context, accounts),
                        ),
                      ],
                    ),
                  ),
                )
                .animate()
                .fadeIn(delay: 100.ms, duration: 300.ms)
                .slideY(begin: 0.1, curve: Curves.easeOutCubic),

            const Gap(16),

            // ── Note field ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppTheme.dividerColor(
                      context,
                    ).withValues(alpha: 0.7),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLightColor(context),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.sticky_note_2_rounded,
                          size: 17,
                          color: AppTheme.textLightColor(context),
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: TextField(
                          controller: _noteController,
                          focusNode: _noteFocusNode,
                          onTap: () {
                            HapticService.light();
                          },
                          onTapOutside: (_) => FocusScope.of(context).unfocus(),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppTheme.textColor(context),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Add a note...',
                            hintStyle: TextStyle(
                              color: AppTheme.textLightColor(
                                context,
                              ).withValues(alpha: 0.45),
                              fontWeight: FontWeight.w400,
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Gap(24),

            // ── Confirm button ──
            Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [color, color.withValues(alpha: 0.85)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          HapticService.medium();
                          final amtStr = _amountController.text.replaceAll(
                            ',',
                            '',
                          );
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
                            accountId: _selectedAccountId,
                          );

                          await ref
                              .read(debtsProvider.notifier)
                              .addRepayment(repayment);
                          if (context.mounted) Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Confirm Payment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .animate()
                .fadeIn(delay: 200.ms, duration: 300.ms)
                .slideY(begin: 0.15, curve: Curves.easeOutCubic),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionRow(
    BuildContext context, {
    required IconData fallbackIcon,
    required String label,
    required String? selectedName,
    required Color? selectedColor,
    required int? selectedIconCodePoint,
    required String placeholder,
    required VoidCallback onTap,
  }) {
    final hasSelection =
        selectedName != null &&
        selectedColor != null &&
        selectedIconCodePoint != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticService.light();
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: hasSelection
                      ? selectedColor.withValues(alpha: 0.12)
                      : AppTheme.surfaceLightColor(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  hasSelection
                      ? IconUtils.getIcon(selectedIconCodePoint)
                      : fallbackIcon,
                  size: 17,
                  color: hasSelection
                      ? selectedColor
                      : AppTheme.textLightColor(context),
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textLightColor(
                          context,
                        ).withValues(alpha: 0.65),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      hasSelection ? selectedName : placeholder,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: hasSelection
                            ? AppTheme.textColor(context)
                            : AppTheme.textLightColor(
                                context,
                              ).withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(4),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textLightColor(context).withValues(alpha: 0.4),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAccountPicker(
    BuildContext context,
    List<Account> accounts,
  ) async {
    final id = await _showPremiumSelectionSheet<String>(
      context: context,
      title: 'Account',
      subtitle: 'Choose the account for this payment',
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        final acc = accounts[index];
        return _PremiumSheetItem(
          name: acc.name,
          accentColor: acc.color,
          iconCodePoint: acc.iconCodePoint,
          selected: acc.id == _selectedAccountId,
          onTap: () => Navigator.pop(context, acc.id),
        );
      },
    );
    if (id != null && mounted) {
      setState(() => _selectedAccountId = id);
    }
  }

  Future<T?> _showPremiumSelectionSheet<T>({
    required BuildContext context,
    required String title,
    required String subtitle,
    required int itemCount,
    required Widget Function(BuildContext context, int index) itemBuilder,
  }) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.62;
    final color = widget.debt.type == DebtType.owedToMe
        ? AppTheme.incomeColor(context)
        : AppTheme.expenseColor(context);

    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(sheetContext).padding.top + 12,
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Container(
                constraints: BoxConstraints(maxHeight: maxHeight),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor(sheetContext),
                  border: Border.all(
                    color: AppTheme.dividerColor(sheetContext),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 32,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Gap(10),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.dividerColor(sheetContext),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const Gap(10),
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                  color: AppTheme.textColor(sheetContext),
                                ),
                              ),
                            ],
                          ),
                          const Gap(4),
                          Padding(
                            padding: const EdgeInsets.only(left: 14),
                            child: Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.35,
                                color: AppTheme.textLightColor(sheetContext),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          8,
                          16,
                          16 + bottomInset,
                        ),
                        itemCount: itemCount,
                        separatorBuilder: (context, index) => const Gap(8),
                        itemBuilder: (context, index) {
                          return itemBuilder(context, index)
                              .animate()
                              .fadeIn(delay: (index * 40).ms, duration: 250.ms)
                              .slideX(
                                begin: 0.04,
                                duration: 250.ms,
                                curve: Curves.easeOutCubic,
                              );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PremiumSheetItem extends StatelessWidget {
  const _PremiumSheetItem({
    required this.name,
    required this.accentColor,
    required this.iconCodePoint,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final Color accentColor;
  final int iconCodePoint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticService.selection();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? primary.withValues(alpha: 0.45)
                  : AppTheme.dividerColor(context).withValues(alpha: 0.65),
              width: selected ? 1.5 : 1,
            ),
            color: selected
                ? primary.withValues(alpha: 0.08)
                : AppTheme.surfaceLightColor(context).withValues(alpha: 0.45),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  IconUtils.getIcon(iconCodePoint),
                  color: accentColor,
                  size: 22,
                ),
              ),
              const Gap(14),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: AppTheme.textColor(context),
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: primary, size: 26)
              else
                SizedBox(
                  width: 26,
                  height: 26,
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.dividerColor(
                            context,
                          ).withValues(alpha: 0.4),
                          width: 1.5,
                        ),
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
}
