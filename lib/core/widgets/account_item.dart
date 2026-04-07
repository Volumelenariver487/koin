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

  /// Whether the card has a coloured (non-default) background.
  bool get _hasColoredBackground =>
      account.cardColor != null || account.logoAsset != null;

  /// Resolves the card background:
  ///  1. Explicit card color set by the user  →  use that
  ///  2. Logo-based account                   →  use brand color w/ high opacity
  ///  3. Default                              →  surface color
  Color _cardBackground(BuildContext context) {
    if (account.cardColor != null) {
      return account.cardColor!.withValues(alpha: 0.9);
    }
    if (account.logoAsset != null) {
      return account.color.withValues(alpha: 0.9);
    }
    return AppTheme.surfaceColor(context);
  }

  Color _shadowColor(BuildContext context) {
    if (account.cardColor != null) {
      return account.cardColor!.withValues(alpha: 0.20);
    }
    if (account.logoAsset != null) {
      return account.color.withValues(alpha: 0.20);
    }
    return Colors.black.withValues(alpha: 0.03);
  }

  @override
  Widget build(BuildContext context) {
    final isPrivate = account.excludeFromTotal;
    final colored = _hasColoredBackground;

    return PressableScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _cardBackground(context),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _shadowColor(context),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              // ── Account Icon / Logo ──
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: account.logoAsset == null
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            account.color.withValues(alpha: 0.15),
                            account.color.withValues(alpha: 0.06),
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: account.logoAsset != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          account.logoAsset!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
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
                        color: colored
                            ? Colors.white.withValues(alpha: 0.95)
                            : AppTheme.textColor(context),
                        fontWeight: FontWeight.w700,
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
                              color: colored
                                  ? Colors.white.withValues(alpha: 0.5)
                                  : AppTheme.textLightColor(
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
                              color: colored
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : AppTheme.textLightColor(context),
                              fontWeight: FontWeight.w600,
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
                      color: colored
                          ? Colors.white.withValues(
                              alpha: isPrivate ? 0.4 : 0.8,
                            )
                          : (isPrivate
                                ? AppTheme.textLightColor(
                                    context,
                                  ).withValues(alpha: 0.35)
                                : AppTheme.primaryColor(
                                    context,
                                  ).withValues(alpha: 0.55)),
                    ),
                  ),
                ),
              ],

              // ── Trailing (drag handle etc.) ──
              if (trailing != null) ...[
                const Gap(4),
                Theme(
                  data: Theme.of(context).copyWith(
                    iconTheme: IconThemeData(
                      color: colored
                          ? Colors.white.withValues(alpha: 0.4)
                          : AppTheme.textLightColor(
                              context,
                            ).withValues(alpha: 0.2),
                    ),
                  ),
                  child: trailing!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
