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
              Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 4),
                child: Text(
                  'Owed to you',
                  style: TextStyle(
                    color: AppTheme.textLightColor(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ...owedToMe.map((d) => DebtCard(debt: d, currencyFormat: fmt)),
              const Gap(16),
            ],
            if (iOwe.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 4),
                child: Text(
                  'You owe',
                  style: TextStyle(
                    color: AppTheme.textLightColor(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ...iOwe.map((d) => DebtCard(debt: d, currencyFormat: fmt)),
              const Gap(16),
            ],
            _buildAddDebtButton(context),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: \$e')),
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
}

class DebtCard extends StatelessWidget {
  final Debt debt;
  final NumberFormat currencyFormat;

  const DebtCard({super.key, required this.debt, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    final progress = (debt.currentAmount / debt.amount).clamp(0.0, 1.0);
    final isSettled = progress >= 1.0;
    final color = debt.type == DebtType.owedToMe
        ? AppTheme.incomeColor(context)
        : AppTheme.expenseColor(context);
    final bgIcon = debt.type == DebtType.owedToMe
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;

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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor(context),
            borderRadius: BorderRadius.circular(20),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSettled
                          ? AppTheme.primaryColor(
                              context,
                            ).withValues(alpha: 0.1)
                          : color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isSettled ? Icons.check_circle_rounded : bgIcon,
                      color: isSettled ? AppTheme.primaryColor(context) : color,
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debt.personName,
                          style: TextStyle(
                            color: AppTheme.textColor(context),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        if (debt.totalInstallments > 0) ...[
                          const Gap(4),
                          Text(
                            '${debt.totalInstallments} installments',
                            style: TextStyle(
                              color: AppTheme.textLightColor(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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
                          fontSize: 16,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        isSettled
                            ? 'Settled'
                            : '${currencyFormat.format(debt.currentAmount)} paid',
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
              if (!isSettled && debt.amount > 0) ...[
                const Gap(16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.dividerColor(context),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      debt.type == DebtType.owedToMe ? color : color,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
