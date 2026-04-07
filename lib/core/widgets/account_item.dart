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
  final Widget? trailing;

  const AccountItem({
    super.key,
    required this.account,
    required this.balance,
    required this.currencySymbol,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor(context),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor(context).withValues(alpha: 0.04),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: AppTheme.dividerColor(context).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Opacity(
          opacity: account.excludeFromTotal ? 0.8 : 1.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                    if (account.excludeFromTotal)
                      Text(
                        '••••',
                        style: TextStyle(
                          color: AppTheme.textColor(
                            context,
                          ).withValues(alpha: 0.6),
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          letterSpacing: 2,
                        ),
                      )
                    else
                      AnimatedCounter(
                        value: balance,
                        formatter: (v) => NumberFormat.currency(
                          symbol: currencySymbol,
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
                if (trailing != null) ...[const Gap(12), trailing!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
