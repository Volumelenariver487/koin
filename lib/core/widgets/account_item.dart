import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:koin/core/models/account.dart';
import 'package:koin/core/theme.dart';
import 'package:koin/core/utils/icon_utils.dart';
import 'package:koin/core/widgets/animated_counter.dart';
import 'package:koin/core/widgets/pressable_scale.dart';

class AccountItem extends StatelessWidget {
  final Account account;
  final double balance;
  final String currencySymbol;
  final VoidCallback onTap;
  final VoidCallback? onPrivateToggle;
  final Widget? trailing;

  const AccountItem({
    super.key,
    required this.account,
    required this.balance,
    required this.currencySymbol,
    required this.onTap,
    this.onPrivateToggle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isPrivate = account.excludeFromTotal;

    return PressableScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.dividerColor(context).withValues(alpha: 0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              // ── Account Icon ──
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      account.color.withValues(alpha: 0.15),
                      account.color.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Center(
                  child: Icon(
                    IconUtils.getIcon(account.iconCodePoint),
                    color: account.color,
                    size: 22,
                  ),
                ),
              ),
              const Gap(14),

              // ── Name + Balance (two lines) ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(3),
                    isPrivate
                        ? Text(
                            '••••••',
                            style: TextStyle(
                              color: AppTheme.textLightColor(
                                context,
                              ).withValues(alpha: 0.45),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: 3,
                            ),
                          )
                        : AnimatedCounter(
                            value: balance,
                            formatter: (v) => NumberFormat.currency(
                              symbol: currencySymbol,
                            ).format(v),
                            duration: const Duration(milliseconds: 600),
                            style: TextStyle(
                              color: AppTheme.textLightColor(context),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              letterSpacing: -0.2,
                            ),
                          ),
                  ],
                ),
              ),

              // ── Privacy Toggle ──
              if (onPrivateToggle != null) ...[
                GestureDetector(
                  onTap: onPrivateToggle,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      isPrivate
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 18,
                      color: isPrivate
                          ? AppTheme.textLightColor(
                              context,
                            ).withValues(alpha: 0.35)
                          : AppTheme.primaryColor(
                              context,
                            ).withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ],

              // ── Trailing (drag handle etc.) ──
              if (trailing != null) ...[const Gap(4), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}
