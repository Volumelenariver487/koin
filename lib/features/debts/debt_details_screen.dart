import 'dart:math';
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
import 'package:koin/core/widgets/animated_counter.dart';
import 'package:koin/features/debts/add_edit_debt_screen.dart';
import 'package:koin/core/models/account.dart';
import 'package:koin/core/models/transaction.dart';
import 'package:koin/core/providers/account_provider.dart';
import 'package:koin/core/providers/transaction_provider.dart';
import 'package:koin/core/utils/icon_utils.dart';
import 'package:koin/core/utils/snackbar_utils.dart';
import 'package:koin/core/widgets/confirmation_sheet.dart';
import 'package:koin/core/widgets/koin_back_button.dart';
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

          return SafeArea(
            child: Column(
              children: [
                // ── Top bar ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const KoinBackButton(),
                      const Gap(16),
                      Expanded(
                        child: Text(
                          'Debt Details',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: AppTheme.textColor(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 22),
                        onPressed: () {
                          HapticService.light();
                          Navigator.push(
                            context,
                            SlideUpRoute(page: AddEditDebtScreen(debt: debt)),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 22,
                          color: AppTheme.expenseColor(context),
                        ),
                        onPressed: () => _showDeleteConfirmation(debt),
                      ),
                    ],
                  ),
                ),
                // ── Body ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Gauge Header Card ──
                        _buildGaugeHeader(
                          context,
                          debt: debt,
                          progress: progress,
                          isSettled: isSettled,
                          remaining: remaining,
                          color: color,
                          currencyFormat: currencyFormat,
                        ),
                        const Gap(20),
                        // ── Log Payment Button ──
                        if (!isSettled)
                          _buildLogPaymentButton(context, debt, color),
                        if (!isSettled) const Gap(28),
                        // ── Payment History ──
                        _buildPaymentHistorySection(
                          context,
                          repaymentsAsync: repaymentsAsync,
                          currencyFormat: currencyFormat,
                          color: color,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: \$e')),
      ),
    );
  }

  // ── Gauge Header Card ──
  Widget _buildGaugeHeader(
    BuildContext context, {
    required Debt debt,
    required double progress,
    required bool isSettled,
    required double remaining,
    required Color color,
    required NumberFormat currencyFormat,
  }) {
    final primaryColor = AppTheme.primaryColor(context);

    return Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor(context),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Person name + type badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          debt.personName,
                          style: TextStyle(
                            color: AppTheme.textColor(context),
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Gap(8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSettled
                                ? primaryColor.withValues(alpha: 0.1)
                                : color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isSettled
                                ? 'SETTLED'
                                : debt.type == DebtType.owedToMe
                                ? 'OWES YOU'
                                : 'YOU OWE',
                            style: TextStyle(
                              color: isSettled ? primaryColor : color,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
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
                      ],
                    ),
                  ),
                ],
              ),
              const Gap(28),

              // Radial gauge
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.08),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedProgress, child) {
                    final animatedPercent = (animatedProgress * 100)
                        .toStringAsFixed(1);
                    return SizedBox(
                      width: 160,
                      height: 160,
                      child: CustomPaint(
                        painter: _RadialGaugePainter(
                          progress: animatedProgress,
                          trackColor: AppTheme.dividerColor(context),
                          progressColor: color,
                          strokeWidth: 10,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedCounter(
                                value: double.parse(animatedPercent),
                                formatter: (v) =>
                                    '${v.toStringAsFixed(v >= 100 ? 0 : 1)}%',
                                duration: const Duration(milliseconds: 400),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: color,
                                  letterSpacing: -1,
                                  height: 1.1,
                                ),
                              ),
                              const Gap(2),
                              Text(
                                isSettled ? 'completed' : 'repaid',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textLightColor(
                                    context,
                                  ).withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ).animate().scale(
                begin: const Offset(0.85, 0.85),
                end: const Offset(1.0, 1.0),
                duration: 600.ms,
                curve: Curves.elasticOut,
              ),
              const Gap(28),

              // Stat row
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      color: AppTheme.incomeColor(context),
                      label: 'Repaid',
                      value: debt.currentAmount,
                      formatter: currencyFormat.format,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: AppTheme.dividerColor(context),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      color: color,
                      label: 'Total',
                      value: debt.amount,
                      formatter: currencyFormat.format,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: AppTheme.dividerColor(context),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      color: AppTheme.expenseColor(context),
                      label: 'Remaining',
                      value: remaining,
                      formatter: currencyFormat.format,
                    ),
                  ),
                ],
              ),

              // Due date pill
              if (debt.dueDate != null) ...[
                const Gap(20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLightColor(context),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 15,
                        color: _isDueOverdue(debt.dueDate!)
                            ? AppTheme.expenseColor(context)
                            : AppTheme.textLightColor(
                                context,
                              ).withValues(alpha: 0.6),
                      ),
                      const Gap(8),
                      Text(
                        _formatDueDateLabel(debt.dueDate!),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _isDueOverdue(debt.dueDate!)
                              ? AppTheme.expenseColor(context)
                              : AppTheme.textColor(context),
                        ),
                      ),
                      const Gap(8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppTheme.textLightColor(
                            context,
                          ).withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Gap(8),
                      Text(
                        'due ${DateFormat.yMMMd().format(debt.dueDate!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textLightColor(
                            context,
                          ).withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        )
        .animate()
        .fade(duration: 400.ms)
        .slideY(begin: 0.04, curve: Curves.easeOutCubic);
  }

  Widget _buildStatItem(
    BuildContext context, {
    required Color color,
    required String label,
    required double value,
    required String Function(double) formatter,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const Gap(6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textLightColor(context).withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const Gap(6),
        FittedBox(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: AnimatedCounter(
              value: value,
              formatter: formatter,
              duration: const Duration(milliseconds: 1000),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogPaymentButton(BuildContext context, Debt debt, Color color) {
    return SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
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
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
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
        )
        .animate()
        .fadeIn(delay: 200.ms, duration: 400.ms)
        .slideY(begin: 0.1, curve: Curves.easeOutCubic);
  }

  Widget _buildPaymentHistorySection(
    BuildContext context, {
    required AsyncValue<List<DebtRepayment>> repaymentsAsync,
    required NumberFormat currencyFormat,
    required Color color,
  }) {
    return repaymentsAsync.when(
      data: (repayments) {
        if (repayments.isEmpty) {
          return Center(
            child:
                Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Gap(24),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor(context),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor(
                                  context,
                                ).withValues(alpha: 0.06),
                                blurRadius: 30,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.receipt_long_rounded,
                            size: 36,
                            color: AppTheme.textLightColor(
                              context,
                            ).withValues(alpha: 0.35),
                          ),
                        ),
                        const Gap(16),
                        Text(
                          'No payments yet',
                          style: TextStyle(
                            color: AppTheme.textColor(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Gap(6),
                        Text(
                          'Tap "Log Payment" to record a repayment',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textLightColor(
                              context,
                            ).withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 400.ms)
                    .slideY(begin: 0.1, curve: Curves.easeOutCubic),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Text(
                  'Payment History',
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const Gap(10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${repayments.length}',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(16),
            // Payment tiles with timeline
            ...repayments.asMap().entries.map((entry) {
              final index = entry.key;
              final r = entry.value;
              final isLast = index == repayments.length - 1;
              return _buildRepaymentTile(
                context,
                repayment: r,
                currencyFormat: currencyFormat,
                color: color,
                tileIndex: index,
                paymentNumber: repayments.length - index,
                isLast: isLast,
              );
            }),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: \$e')),
    );
  }

  Widget _buildRepaymentTile(
    BuildContext context, {
    required DebtRepayment repayment,
    required NumberFormat currencyFormat,
    required Color color,
    required int tileIndex,
    required int paymentNumber,
    required bool isLast,
  }) {
    return Dismissible(
      key: Key(repayment.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await ConfirmationSheet.show(
          context: context,
          title: 'Delete Payment?',
          description:
              'Are you sure you want to delete this payment of ${currencyFormat.format(repayment.amount)}? This action cannot be undone.',
          confirmLabel: 'Delete Payment',
          confirmColor: AppTheme.expenseColor(context),
          icon: Icons.delete_outline_rounded,
          isDanger: true,
        );
      },
      onDismissed: (direction) {
        ref.read(debtsProvider.notifier).deleteRepayment(repayment);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppTheme.expenseColor(context),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child:
          IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Timeline connector
                    SizedBox(
                      width: 32,
                      child: Column(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Center(
                              child: Text(
                                '#$paymentNumber',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.dividerColor(
                                    context,
                                  ).withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Gap(12),
                    // Payment card
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor(context),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppTheme.dividerColor(
                              context,
                            ).withValues(alpha: 0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
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
                                color: color,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
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
              ),
    );
  }

  String _formatDueDateLabel(DateTime dueDate) {
    final now = DateTime.now();
    final diff = dueDate.difference(now).inDays;
    if (diff < 0) return '${-diff} days overdue';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return '$diff days left';
  }

  bool _isDueOverdue(DateTime dueDate) {
    return dueDate.isBefore(DateTime.now());
  }
}

// ── Radial Gauge Painter ──
class _RadialGaugePainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _RadialGaugePainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RadialGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
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

                          // Automatically add a transaction
                          final transaction = AppTransaction(
                            id: const Uuid().v4(),
                            amount: repayment.amount,
                            date: repayment.date,
                            type: widget.debt.type == DebtType.iOwe
                                ? TransactionType.expense
                                : TransactionType.income,
                            categoryId: widget.debt.type == DebtType.iOwe
                                ? 'cat_others'
                                : 'cat_others_inc',
                            accountId: repayment.accountId ?? 'default_account',
                            note:
                                'Debt Payment: ${widget.debt.personName}${repayment.note != null ? ' - ${repayment.note}' : ''}',
                          );

                          await ref
                              .read(transactionProvider.notifier)
                              .addTransaction(
                                transaction.copyWith(
                                  debtRepaymentId: repayment.id,
                                ),
                              );

                          if (context.mounted) {
                            KoinSnackBar.success(
                              context,
                              'Payment Logged',
                              subtitle:
                                  'Transaction added to ${selectedAccount?.name ?? 'Account'}',
                            );
                            Navigator.pop(context);
                          }
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
