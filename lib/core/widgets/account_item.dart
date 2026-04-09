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

  BoxDecoration _cardDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_hasColoredBackground) {
      final baseColor = account.cardColor ?? account.color;
      return BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor.withValues(alpha: 0.95),
            baseColor.withValues(alpha: 0.8),
          ],
          stops: const [0.2, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: baseColor.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: baseColor.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 0.5,
        ),
      );
    }

    final surfaceColor = AppTheme.surfaceColor(context);
    return BoxDecoration(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : AppTheme.dividerColor(context).withValues(alpha: 0.6),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.03),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  List<Widget> _buildBackgroundShapes(bool colored) {
    if (!colored) return const [];

    final hash = account.id.hashCode.abs();
    final shapeType = hash % 4;

    switch (shapeType) {
      case 0:
        return [
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
        ];
      case 1:
        return [
          Positioned(
            right: -40,
            bottom: -50,
            child: Transform.rotate(
              angle: 0.5,
              child: Container(
                width: 140,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
          ),
        ];
      case 2:
        return [
          Positioned(
            right: 40,
            top: -20,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: -20,
            bottom: -10,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
        ];
      case 3:
      default:
        return [
          Positioned(
            left: -40,
            bottom: -40,
            child: Transform.rotate(
              angle: 0.8,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  color: Colors.white.withValues(alpha: 0.14),
                ),
              ),
            ),
          ),
          Positioned(
            right: -20,
            top: 20,
            child: Container(
              width: 80,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPrivate = account.excludeFromTotal;
    final colored = _hasColoredBackground;

    return PressableScale(
      onTap: onTap,
      pressedScale: 0.98,
      child: Container(
        decoration: _cardDecoration(context),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            ..._buildBackgroundShapes(colored),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // ── Account Icon / Logo ──
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: account.logoAsset == null
                          ? (colored
                                ? Colors.white.withValues(alpha: 0.15)
                                : account.color.withValues(alpha: 0.1))
                          : null,
                      border: account.logoAsset == null
                          ? Border.all(
                              color: colored
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : account.color.withValues(alpha: 0.15),
                              width: 1,
                            )
                          : null,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: account.logoAsset != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              account.logoAsset!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Center(
                            child: Icon(
                              IconUtils.getIcon(account.iconCodePoint),
                              color: colored ? Colors.white : account.color,
                              size: 24,
                            ),
                          ),
                  ),
                  const Gap(16),

                  // ── Name + Balance (two lines) ──
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          style: TextStyle(
                            color: colored
                                ? Colors.white.withValues(alpha: 0.85)
                                : AppTheme.textLightColor(context),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            letterSpacing: -0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Gap(2),
                        isPrivate
                            ? Text(
                                '••••••',
                                style: TextStyle(
                                  color: colored
                                      ? Colors.white
                                      : AppTheme.textColor(context),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  letterSpacing: 2,
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
                                      ? Colors.white
                                      : AppTheme.textColor(context),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  letterSpacing: -0.5,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        child: Icon(
                          isPrivate
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          size: 20,
                          color: colored
                              ? Colors.white.withValues(
                                  alpha: isPrivate ? 0.5 : 0.8,
                                )
                              : (isPrivate
                                    ? AppTheme.textLightColor(
                                        context,
                                      ).withValues(alpha: 0.4)
                                    : AppTheme.primaryColor(
                                        context,
                                      ).withValues(alpha: 0.6)),
                        ),
                      ),
                    ),
                  ],

                  // ── Trailing (drag handle etc.) ──
                  if (trailing != null) ...[
                    const Gap(8),
                    Theme(
                      data: Theme.of(context).copyWith(
                        iconTheme: IconThemeData(
                          color: colored
                              ? Colors.white.withValues(alpha: 0.5)
                              : AppTheme.textLightColor(
                                  context,
                                ).withValues(alpha: 0.3),
                        ),
                      ),
                      child: trailing!,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
