import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:koin/core/models/savings_goal.dart';
import 'package:koin/core/providers/account_provider.dart';
import 'package:koin/core/providers/dashboard_provider.dart';
import 'package:koin/core/providers/savings_provider.dart';
import 'package:koin/core/providers/settings_provider.dart';
import 'package:koin/core/theme.dart';
import 'package:koin/core/utils/haptic_utils.dart';
import 'package:koin/core/utils/icon_utils.dart';
import 'package:koin/core/utils/slide_up_route.dart';
import 'package:koin/core/widgets/account_sheet.dart';
import 'package:koin/core/widgets/animated_counter.dart';
import 'package:koin/core/widgets/confirmation_sheet.dart';
import 'package:koin/core/widgets/pressable_scale.dart';
import 'package:koin/features/savings/add_savings_goal_screen.dart';
import 'package:koin/features/savings/savings_details_screen.dart';
import 'package:koin/core/widgets/koin_segmented_control.dart';

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showEntranceAnimations = true;

  // Add more tabs here in the future (e.g., 'Investments', 'Debts')
  static const _tabs = ['Accounts', 'Goals'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        HapticService.selection();
      }
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _showEntranceAnimations = false);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(dashboardStatsProvider);
    final settings = ref.watch(settingsProvider);
    final currency = settings.currency;
    final fmt = NumberFormat.currency(symbol: currency.symbol);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ═══════════════════════════════════════════
        // FIXED HEADER: Balance + Segmented Tabs
        // ═══════════════════════════════════════════
        _buildHeader(context, stats, fmt),
        _buildSegmentedTabs(context),

        // ═══════════════════════════════════════════
        // TAB CONTENT (each tab scrolls independently)
        // ═══════════════════════════════════════════
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAccountsTab(context, currency),
              _buildSavingsTab(context),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // HEADER — Portfolio label + total balance
  // ═══════════════════════════════════════════════════════
  Widget _buildHeader(
    BuildContext context,
    DashboardStats stats,
    NumberFormat fmt,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 16,
        bottom: 4,
        left: 24,
        right: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PORTFOLIO',
            style: TextStyle(
              color: AppTheme.textLightColor(context).withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const Gap(4),
          AnimatedCounter(
            value: stats.currentBalance,
            formatter: (v) => fmt.format(v),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // SEGMENTED TAB BAR — premium pill-shaped switcher
  // ═══════════════════════════════════════════════════════
  Widget _buildSegmentedTabs(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: KoinSegmentedControl.custom(
        controller: _tabController,
        segments: [
          const KoinSegmentItem(label: 'Accounts'),
          const KoinSegmentItem(label: 'Goals'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // ACCOUNTS TAB
  // ═══════════════════════════════════════════════════════
  Widget _buildAccountsTab(BuildContext context, dynamic currency) {
    final accountsAsync = ref.watch(accountProvider);
    final stats = ref.watch(dashboardStatsProvider);

    return accountsAsync.when(
      data: (accounts) {
        if (accounts.isEmpty) {
          return _buildFullEmptyState(
            context,
            icon: Icons.account_balance_wallet_rounded,
            title: 'No accounts yet',
            subtitle: 'Add your first account to start\ntracking your money',
            buttonLabel: 'Add Your First Account',
            onTap: () {
              HapticService.medium();
              AccountSheet.show(context, ref);
            },
          );
        }
        return ReorderableListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          itemCount: accounts.length,
          footer: _buildAddAccountButton(context, ref),
          onReorder: (oldIndex, newIndex) {
            HapticService.medium();
            ref
                .read(accountProvider.notifier)
                .reorderAccounts(oldIndex, newIndex);
          },
          proxyDecorator: (child, index, animation) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final elevation =
                    Curves.easeOut.transform(animation.value) * 16;
                final scale =
                    1.0 + (Curves.easeOut.transform(animation.value) * 0.03);
                return Transform.scale(
                  scale: scale,
                  child: Material(
                    elevation: elevation,
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    shadowColor: AppTheme.primaryColor(
                      context,
                    ).withValues(alpha: 0.3),
                    child: child,
                  ),
                );
              },
              child: child,
            );
          },
          itemBuilder: (context, index) {
            final account = accounts[index];
            final balance = stats.accountBalances[account.id] ?? 0;

            Widget accountItem = PressableScale(
              onTap: () {
                HapticService.light();
                AccountSheet.show(context, ref, account: account);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor(context),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor(
                        context,
                      ).withValues(alpha: 0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: AppTheme.dividerColor(
                      context,
                    ).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Opacity(
                  opacity: account.excludeFromTotal ? 0.5 : 1.0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: account.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: account.color.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              IconUtils.getIcon(account.iconCodePoint),
                              color: account.color,
                              size: 24,
                            ),
                          ),
                        ),
                        const Gap(16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    account.name,
                                    style: TextStyle(
                                      color: AppTheme.textColor(context),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  if (account.excludeFromTotal) ...[
                                    const Gap(6),
                                    Icon(
                                      Icons.visibility_off_rounded,
                                      size: 14,
                                      color: AppTheme.textLightColor(context),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            AnimatedCounter(
                              value: balance,
                              formatter: (v) => NumberFormat.currency(
                                symbol: currency.symbol,
                              ).format(v),
                              duration: const Duration(milliseconds: 600),
                              style: TextStyle(
                                color: AppTheme.textColor(context),
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),
                        const Gap(12),
                        Listener(
                          onPointerDown: (_) => HapticService.light(),
                          child: ReorderableDragStartListener(
                            index: index,
                            child: Icon(
                              Icons.drag_indicator_rounded,
                              color: AppTheme.textLightColor(
                                context,
                              ).withValues(alpha: 0.2),
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );

            if (_showEntranceAnimations) {
              accountItem = accountItem
                  .animate()
                  .fade(delay: (index * 60).ms, duration: 400.ms)
                  .slideY(
                    begin: 0.1,
                    duration: 400.ms,
                    curve: Curves.easeOutCubic,
                  );
            }

            return KeyedSubtree(
              key: ValueKey(account.id),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Dismissible(
                  key: Key('dismiss_${account.id}'),
                  direction: DismissDirection.endToStart,
                  onUpdate: (details) {
                    if (details.reached && !details.previousReached) {
                      HapticService.selection();
                    }
                  },
                  background: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor(
                        context,
                      ).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: Icon(
                      Icons.delete_rounded,
                      color: AppTheme.errorColor(context),
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    HapticService.medium();
                    final confirmed = await ConfirmationSheet.show(
                      context: context,
                      title: 'Delete Account?',
                      description:
                          'All transactions associated with this account will be unlinked. This cannot be undone.',
                      confirmLabel: 'Delete',
                      confirmColor: AppTheme.errorColor(context),
                      icon: Icons.delete_forever_rounded,
                      isDanger: true,
                    );
                    return confirmed ?? false;
                  },
                  onDismissed: (_) {
                    HapticService.heavy();
                    ref
                        .read(accountProvider.notifier)
                        .deleteAccount(account.id);
                  },
                  child: accountItem,
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildAddAccountButton(BuildContext context, WidgetRef ref) {
    final button = PressableScale(
      onTap: () {
        HapticService.medium();
        AccountSheet.show(context, ref);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
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
              'Add New Account',
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

    if (_showEntranceAnimations) {
      return button
          .animate()
          .fade(delay: 300.ms, duration: 400.ms)
          .slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOutCubic);
    }
    return button;
  }

  // ═══════════════════════════════════════════════════════
  // SAVINGS TAB
  // ═══════════════════════════════════════════════════════
  Widget _buildSavingsTab(BuildContext context) {
    final goalsAsync = ref.watch(computedSavingsGoalsProvider);
    final settings = ref.watch(settingsProvider);
    final currencyFormat = NumberFormat.simpleCurrency(
      name: settings.currency.code,
    );

    return goalsAsync.when(
      data: (goals) {
        if (goals.isEmpty) {
          return _buildFullEmptyState(
            context,
            icon: Icons.savings_rounded,
            title: 'No goals yet',
            subtitle: 'Start your savings journey by\ncreating your first goal',
            buttonLabel: 'Create Your First Goal',
            onTap: () {
              HapticService.medium();
              Navigator.push(
                context,
                SlideUpRoute(page: const AddSavingsGoalScreen()),
              );
            },
          );
        }
        return RefreshIndicator(
          onRefresh: () {
            HapticService.light();
            return ref.read(savingsGoalsProvider.notifier).loadGoals();
          },
          color: AppTheme.primaryColor(context),
          backgroundColor: AppTheme.surfaceColor(context),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: goals.length + 2, // +1 hero, +1 add button
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildSavingsHeroCard(context, goals, currencyFormat);
              }
              if (index == goals.length + 1) {
                return _buildAddGoalButton(context, index);
              }
              final goal = goals[index - 1];
              return _buildGoalCard(context, goal, index, currencyFormat);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildAddGoalButton(BuildContext context, int index) {
    return PressableScale(
          onTap: () {
            Navigator.push(
              context,
              SlideUpRoute(page: const AddSavingsGoalScreen()),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 24),
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
                  'Add New Goal',
                  style: TextStyle(
                    color: AppTheme.textLightColor(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fade(delay: 300.ms, duration: 400.ms)
        .slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOutCubic);
  }

  // ═══════════════════════════════════════════════════════
  // FULL EMPTY STATE (centered, for empty tabs)
  // ═══════════════════════════════════════════════════════
  Widget _buildFullEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
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
                          icon,
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
                        title,
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
                        subtitle,
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
                              onTap();
                            },
                            icon: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                            ),
                            label: Text(
                              buttonLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
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

  // ═══════════════════════════════════════════════════════
  // SAVINGS HERO CARD (radial gauge summary)
  // ═══════════════════════════════════════════════════════
  Widget _buildSavingsHeroCard(
    BuildContext context,
    List<SavingsGoal> goals,
    NumberFormat currencyFormat,
  ) {
    final totalSaved = goals.fold<double>(0, (sum, g) => sum + g.currentAmount);
    final totalTarget = goals.fold<double>(0, (sum, g) => sum + g.targetAmount);
    final overallProgress = totalTarget > 0
        ? (totalSaved / totalTarget).clamp(0.0, 1.0)
        : 0.0;

    return Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(24),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient(context),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor(context).withValues(alpha: 0.25),
                blurRadius: 24,
                spreadRadius: -2,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Decorative circles
              Positioned(
                top: -40,
                right: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Overall Progress',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${goals.length} goal${goals.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(20),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: overallProgress),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    builder: (context, animatedProgress, child) {
                      final animatedPercent = (animatedProgress * 100)
                          .toStringAsFixed(0);
                      return SizedBox(
                        width: 120,
                        height: 120,
                        child: CustomPaint(
                          painter: _RadialProgressPainter(
                            progress: animatedProgress,
                            trackColor: Colors.white.withValues(alpha: 0.15),
                            progressColor: Colors.white,
                            strokeWidth: 8,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$animatedPercent%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 28,
                                    letterSpacing: -1,
                                    height: 1.1,
                                  ),
                                ),
                                Text(
                                  'saved',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 11,
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
                  const Gap(24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildHeroStat(
                          'Saved',
                          totalSaved,
                          currencyFormat,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      Expanded(
                        child: _buildHeroStat(
                          'Target',
                          totalTarget,
                          currencyFormat,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      Expanded(
                        child: _buildHeroStat(
                          'Remaining',
                          totalTarget - totalSaved,
                          currencyFormat,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fade(duration: 500.ms)
        .slideY(begin: 0.08, curve: Curves.easeOutCubic);
  }

  Widget _buildHeroStat(String label, double amount, NumberFormat fmt) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Gap(4),
        FittedBox(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: AnimatedCounter(
              value: amount,
              formatter: (v) => fmt.format(v),
              duration: const Duration(milliseconds: 1400),
              curve: Curves.easeOutCubic,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // GOAL CARD
  // ═══════════════════════════════════════════════════════
  Widget _buildGoalCard(
    BuildContext context,
    SavingsGoal goal,
    int index,
    NumberFormat currencyFormat,
  ) {
    final progressPercent = (goal.progress * 100).toStringAsFixed(0);
    final isCompleted = goal.progress >= 1.0;

    final accentColors = [
      AppTheme.primaryColor(context),
      const Color(0xFF6366F1),
      const Color(0xFF3B82F6),
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
    ];
    final accentColor = accentColors[index % accentColors.length];

    return PressableScale(
          onTap: () {
            HapticService.light();
            Navigator.push(
              context,
              SlideUpRoute(page: SavingsDetailsScreen(goal: goal)),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor(context),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                if (isCompleted)
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: -2,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    goal.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Gap(4),
                                  Text(
                                    '${currencyFormat.format(goal.currentAmount)} of ${currencyFormat.format(goal.targetAmount)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textLightColor(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Gap(12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$progressPercent%',
                                style: TextStyle(
                                  color: accentColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Gap(14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: goal.progress),
                            duration: Duration(
                              milliseconds: 800 + (index * 100),
                            ),
                            curve: Curves.easeOutCubic,
                            builder: (context, animatedProgress, _) {
                              return LinearProgressIndicator(
                                value: animatedProgress,
                                backgroundColor: accentColor.withValues(
                                  alpha: 0.08,
                                ),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  accentColor,
                                ),
                                minHeight: 5,
                              );
                            },
                          ),
                        ),
                        const Gap(12),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 13,
                              color: AppTheme.textLightColor(
                                context,
                              ).withValues(alpha: 0.5),
                            ),
                            const Gap(4),
                            Text(
                              '${goal.remainingDays}d left',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: goal.remainingDays <= 7
                                    ? AppTheme.expenseColor(context)
                                    : AppTheme.textLightColor(
                                        context,
                                      ).withValues(alpha: 0.5),
                              ),
                            ),
                            const Gap(12),
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
                            const Gap(12),
                            Text(
                              '${currencyFormat.format(goal.dailyNeeded)}/day',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textLightColor(
                                  context,
                                ).withValues(alpha: 0.5),
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: AppTheme.textLightColor(
                                context,
                              ).withValues(alpha: 0.3),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fade(delay: (index * 80).ms, duration: 400.ms)
        .slideY(begin: 0.06, curve: Curves.easeOutCubic);
  }
}

// ═══════════════════════════════════════════════════════
// RADIAL PROGRESS PAINTER
// ═══════════════════════════════════════════════════════
class _RadialProgressPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _RadialProgressPainter({
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
  bool shouldRepaint(covariant _RadialProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}
