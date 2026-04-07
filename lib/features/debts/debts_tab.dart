import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:koin/core/models/debt.dart';
import 'package:koin/core/providers/debt_provider.dart';
import 'package:koin/core/providers/settings_provider.dart';
import 'package:koin/core/theme.dart';
import 'package:koin/core/utils/haptic_utils.dart';
import 'package:koin/core/utils/slide_up_route.dart';
import 'package:koin/core/widgets/pressable_scale.dart';
import 'package:koin/core/widgets/confirmation_sheet.dart';
import 'package:koin/features/debts/add_edit_debt_screen.dart';
import 'package:koin/features/debts/debt_details_screen.dart';

class DebtsTab extends ConsumerWidget {
  const DebtsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtsAsync = ref.watch(debtsProvider);
    final settings = ref.watch(settingsProvider);
    final currency = settings.currency;
    final fmt = NumberFormat.simpleCurrency(name: currency.code);

    return debtsAsync.when(
      data: (debts) {
        if (debts.isEmpty) {
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Align(
                  alignment: const Alignment(0, -0.25),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                              padding: const EdgeInsets.all(36),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceColor(context),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor(
                                      context,
                                    ).withValues(alpha: 0.1),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.handshake_rounded,
                                size: 56,
                                color: AppTheme.primaryColor(
                                  context,
                                ).withValues(alpha: 0.6),
                              ),
                            )
                            .animate()
                            .scale(
                              delay: 200.ms,
                              curve: Curves.easeOutBack,
                              duration: 600.ms,
                            )
                            .fadeIn(),
                        const SizedBox(height: 24),
                        Text(
                              'No debts or loans',
                              style: TextStyle(
                                color: AppTheme.textColor(context),
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            )
                            .animate()
                            .slideY(begin: 0.2, delay: 300.ms, duration: 400.ms)
                            .fadeIn(),
                        const SizedBox(height: 8),
                        Text(
                              'Keep track of money you owe\nor money owed to you.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.textLightColor(context),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            )
                            .animate()
                            .slideY(begin: 0.2, delay: 400.ms, duration: 400.ms)
                            .fadeIn(),
                        const SizedBox(height: 36),
                        SizedBox(
                              width: double.infinity,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: AppTheme.primaryGradient(context),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor(
                                        context,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    HapticService.medium();
                                    Navigator.push(
                                      context,
                                      SlideUpRoute(
                                        page: const AddEditDebtScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.add_rounded,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'Add Your First Debt',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .animate()
                            .slideY(begin: 0.2, delay: 500.ms, duration: 400.ms)
                            .fadeIn(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        final owedToMe = debts
            .where((d) => d.type == DebtType.owedToMe)
            .toList();
        final iOwe = debts.where((d) => d.type == DebtType.iOwe).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            if (owedToMe.isNotEmpty) ...[
              _buildSectionHeader(
                context,
                icon: Icons.arrow_downward_rounded,
                label: 'OWED TO YOU',
                color: AppTheme.incomeColor(context),
              ),
              const Gap(12),
              ...owedToMe.asMap().entries.map(
                (e) => Dismissible(
                  key: Key(e.value.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) =>
                      _showDeleteConfirmation(context, ref, e.value),
                  onDismissed: (direction) {
                    ref.read(debtsProvider.notifier).deleteDebt(e.value.id);
                  },
                  background: _buildDismissBackground(context),
                  child: DebtCard(
                    debt: e.value,
                    currencyFormat: fmt,
                    index: e.key,
                  ),
                ),
              ),
              const Gap(20),
            ],
            if (iOwe.isNotEmpty) ...[
              _buildSectionHeader(
                context,
                icon: Icons.arrow_upward_rounded,
                label: 'YOU OWE',
                color: AppTheme.expenseColor(context),
              ),
              const Gap(12),
              ...iOwe.asMap().entries.map(
                (e) => Dismissible(
                  key: Key(e.value.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) =>
                      _showDeleteConfirmation(context, ref, e.value),
                  onDismissed: (direction) {
                    ref.read(debtsProvider.notifier).deleteDebt(e.value.id);
                  },
                  background: _buildDismissBackground(context),
                  child: DebtCard(
                    debt: e.value,
                    currencyFormat: fmt,
                    index: e.key,
                  ),
                ),
              ),
              const Gap(20),
            ],
            _buildAddDebtButton(context),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: \$e')),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 12, color: color),
          ),
          const Gap(8),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textLightColor(context),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddDebtButton(BuildContext context) {
    return PressableScale(
      onTap: () {
        HapticService.medium();
        Navigator.push(context, SlideUpRoute(page: const AddEditDebtScreen()));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24, top: 8),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.dividerColor(context).withValues(alpha: 0.5),
            width: 1,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              color: AppTheme.textLightColor(context),
              size: 20,
            ),
            const Gap(10),
            Text(
              'Add New Debt',
              style: TextStyle(
                color: AppTheme.textLightColor(context),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    Debt debt,
  ) async {
    return await ConfirmationSheet.show(
      context: context,
      title: 'Delete Debt?',
      description:
          'Are you sure you want to delete this debt with "${debt.personName}"? This action cannot be undone.',
      confirmLabel: 'Delete Debt',
      confirmColor: AppTheme.expenseColor(context),
      icon: Icons.delete_outline_rounded,
      isDanger: true,
    );
  }

  Widget _buildDismissBackground(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 28),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.expenseColor(context),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Icon(
        Icons.delete_outline_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}

class DebtCard extends StatelessWidget {
  final Debt debt;
  final NumberFormat currencyFormat;
  final int index;

  const DebtCard({
    super.key,
    required this.debt,
    required this.currencyFormat,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
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

    return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PressableScale(
            onTap: () {
              HapticService.light();
              Navigator.push(
                context,
                SlideUpRoute(page: DebtDetailsScreen(debtId: debt.id)),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor(context),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppTheme.dividerColor(context).withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: avatar + name + amount
                  Row(
                    children: [
                      // Person initial avatar
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    debt.personName,
                                    style: TextStyle(
                                      color: AppTheme.textColor(context),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isSettled) ...[
                                  const Gap(8),
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
                                      'SETTLED',
                                      style: TextStyle(
                                        color: AppTheme.primaryColor(context),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const Gap(4),
                            Row(
                              children: [
                                if (debt.totalInstallments > 0) ...[
                                  Text(
                                    '${debt.totalInstallments} ${debt.frequency.name} payments',
                                    style: TextStyle(
                                      color: AppTheme.textLightColor(context),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ] else
                                  Text(
                                    isSettled
                                        ? 'Fully paid'
                                        : 'No installments',
                                    style: TextStyle(
                                      color: AppTheme.textLightColor(context),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFormat.format(debt.amount),
                            style: TextStyle(
                              color: AppTheme.textColor(context),
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const Gap(4),
                          Text(
                            isSettled
                                ? 'Completed'
                                : '${currencyFormat.format(remaining)} left',
                            style: TextStyle(
                              color: isSettled
                                  ? AppTheme.primaryColor(context)
                                  : AppTheme.textLightColor(context),
                              fontSize: 12,
                              fontWeight: isSettled
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Progress bar
                  if (!isSettled && debt.amount > 0) ...[
                    const Gap(16),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Stack(
                              children: [
                                Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppTheme.dividerColor(context),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: progress,
                                  child: Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          color,
                                          color.withValues(alpha: 0.7),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Gap(10),
                        Text(
                          percentText,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        )
        .animate()
        .slideY(
          begin: 0.15,
          delay: Duration(milliseconds: 80 * index),
          duration: 350.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(
          delay: Duration(milliseconds: 80 * index),
          duration: 350.ms,
        );
  }
}
