import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:uuid/uuid.dart';
import 'package:koin/core/models/account.dart';
import 'package:koin/core/models/bank_templates.dart';
import 'package:koin/core/providers/account_provider.dart';
import 'package:koin/core/theme.dart';
import 'package:koin/core/widgets/confirmation_sheet.dart';
import 'package:koin/core/widgets/koin_back_button.dart';
import 'package:koin/core/utils/haptic_utils.dart';
import 'package:koin/core/widgets/account_item.dart';
import 'package:koin/core/providers/settings_provider.dart';

class AccountFormScreen extends ConsumerStatefulWidget {
  final Account? account;

  const AccountFormScreen({super.key, this.account});

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  late final TextEditingController nameController;
  late final TextEditingController balanceController;
  late int selectedIcon;
  late Color selectedColor;
  late bool excludeFromTotal;
  String? selectedLogoAsset;
  String? selectedTemplateId;
  bool _colorInitialized = false;
  Color? selectedCardColor; // null = Default (no explicit card background)
  final ScrollController _iconScrollController = ScrollController();
  final ScrollController _colorScrollController = ScrollController();
  final ScrollController _cardColorScrollController = ScrollController();
  final ScrollController _templateScrollController = ScrollController();

  final List<IconData> icons = [
    Icons.account_balance_wallet_rounded,
    Icons.account_balance_rounded,
    Icons.savings_rounded,
    Icons.payments_rounded,
    Icons.credit_card_rounded,
    Icons.wallet_rounded,
    Icons.money_rounded,
    Icons.currency_exchange_rounded,
    Icons.trending_up_rounded,
    Icons.monetization_on_rounded,
    Icons.paid_rounded,
    Icons.local_atm_rounded,
    Icons.request_quote_rounded,
    Icons.account_tree_rounded,
    Icons.business_center_rounded,
    Icons.storefront_rounded,
    Icons.currency_bitcoin_rounded,
    Icons.currency_pound_rounded,
    Icons.currency_yen_rounded,
    Icons.currency_franc_rounded,
  ];

  @override
  void initState() {
    super.initState();
    final isEditing = widget.account != null;
    nameController = TextEditingController(text: widget.account?.name)
      ..addListener(_onInputChanged);
    balanceController = TextEditingController(
      text: isEditing ? widget.account!.initialBalance.toString() : '',
    )..addListener(_onInputChanged);
    selectedIcon =
        widget.account?.iconCodePoint ??
        Icons.account_balance_wallet_rounded.codePoint;
    excludeFromTotal = widget.account?.excludeFromTotal ?? false;
    selectedLogoAsset = widget.account?.logoAsset;
    selectedCardColor = widget.account?.cardColor;

    // Find matching template for existing account
    if (widget.account?.logoAsset != null) {
      final matchingTemplate = BankTemplate.templates.where(
        (t) => t.logoAsset == widget.account!.logoAsset,
      );
      if (matchingTemplate.isNotEmpty) {
        selectedTemplateId = matchingTemplate.first.id;
      }
    }

    // Auto-scroll to selected icon and color
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedIcon();
      _scrollToSelectedColor();
      _scrollToSelectedCardColor();
      _scrollToSelectedTemplate();
    });
  }

  void _onInputChanged() {
    setState(() {});
  }

  void _scrollToSelectedIcon() {
    final index = icons.indexWhere((icon) => icon.codePoint == selectedIcon);
    if (index != -1 && _iconScrollController.hasClients) {
      final offset = index * 60.0;
      final targetOffset = (offset - MediaQuery.of(context).size.width / 2 + 30)
          .clamp(0.0, _iconScrollController.position.maxScrollExtent);
      _iconScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _scrollToSelectedColor() {
    final index = AppTheme.accentColors.indexWhere(
      (c) => c.toARGB32() == selectedColor.toARGB32(),
    );
    if (index != -1 && _colorScrollController.hasClients) {
      final offset = index * 56.0;
      final targetOffset = (offset - MediaQuery.of(context).size.width / 2 + 28)
          .clamp(0.0, _colorScrollController.position.maxScrollExtent);
      _colorScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _scrollToSelectedTemplate() {
    if (selectedTemplateId == null || !_templateScrollController.hasClients) {
      return;
    }
    final templateIndex = BankTemplate.templates.indexWhere(
      (t) => t.id == selectedTemplateId,
    );
    if (templateIndex != -1) {
      final offset = (templateIndex + 1) * 88.0; // +1 for "Custom" item
      final targetOffset = (offset - MediaQuery.of(context).size.width / 2 + 44)
          .clamp(0.0, _templateScrollController.position.maxScrollExtent);
      _templateScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _scrollToSelectedCardColor() {
    if (selectedCardColor == null || !_cardColorScrollController.hasClients) {
      return;
    }
    final index = AppTheme.cardColors.indexWhere(
      (c) => c.toARGB32() == selectedCardColor!.toARGB32(),
    );
    if (index != -1) {
      final offset = 80.0 + index * 56.0;
      final targetOffset = (offset - MediaQuery.of(context).size.width / 2 + 28)
          .clamp(0.0, _cardColorScrollController.position.maxScrollExtent);
      _cardColorScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _applyTemplate(BankTemplate? template) {
    HapticService.light();
    setState(() {
      if (template == null) {
        selectedTemplateId = null;
        selectedLogoAsset = null;
        selectedIcon = icons.first.codePoint;
        selectedColor = AppTheme.accentColors.first;
      } else {
        selectedTemplateId = template.id;
        selectedLogoAsset = template.logoAsset;
        nameController.text = template.name;
        selectedIcon = template.iconCodePoint;
        selectedColor = Color(
          int.parse(template.colorHex.replaceFirst('#', '0xFF')),
        );
      }
    });

    // Auto-scroll to selected icon and color
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedIcon();
      _scrollToSelectedColor();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_colorInitialized) {
      if (widget.account != null) {
        selectedColor = widget.account!.color;
      } else {
        selectedColor = AppTheme.primaryColor(context);
      }
      _colorInitialized = true;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    balanceController.dispose();
    _iconScrollController.dispose();
    _colorScrollController.dispose();
    _cardColorScrollController.dispose();
    _templateScrollController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
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
    if (confirmed == true && mounted) {
      ref.read(accountProvider.notifier).deleteAccount(widget.account!.id);
      Navigator.pop(context);
    }
  }

  Future<void> _saveAccount() async {
    if (nameController.text.isNotEmpty) {
      HapticService.success();
      final isEditing = widget.account != null;
      final cardHex = selectedCardColor == null
          ? null
          : '#${selectedCardColor!.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
      final updatedAccount = Account(
        id: isEditing ? widget.account!.id : const Uuid().v4(),
        name: nameController.text,
        initialBalance: double.tryParse(balanceController.text) ?? 0.0,
        iconCodePoint: selectedIcon,
        colorHex:
            '#${selectedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
        excludeFromTotal: excludeFromTotal,
        position: isEditing
            ? widget.account!.position
            : ref.read(accountProvider).value?.length ?? 0,
        logoAsset: selectedLogoAsset,
        cardColorHex: cardHex,
      );

      if (isEditing) {
        await ref.read(accountProvider.notifier).updateAccount(updatedAccount);
      } else {
        await ref.read(accountProvider.notifier).addAccount(updatedAccount);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: AppTheme.dividerColor(context).withValues(alpha: 0.4),
          ),
        ),
        child: TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textColor(context),
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: AppTheme.textLightColor(context).withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              icon,
              color: AppTheme.textLightColor(context).withValues(alpha: 0.6),
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.account != null;
    final colors = AppTheme.accentColors;
    final cardBgColors = AppTheme.cardColors;
    final settings = ref.watch(settingsProvider);
    final currency = settings.currency;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Account' : 'Add Account'),
        leading: const Center(child: KoinBackButton()),
        leadingWidth: 70,
        actions: [
          if (isEditing)
            IconButton(
              onPressed: _deleteAccount,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
          const Gap(8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // ── Live Preview ──
            Row(
              children: [
                Icon(
                  Icons.visibility_rounded,
                  size: 16,
                  color: AppTheme.primaryColor(context).withValues(alpha: 0.7),
                ),
                const Gap(6),
                Text(
                  'Preview',
                  style: TextStyle(
                    color: AppTheme.textLightColor(
                      context,
                    ).withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const Gap(12),
            IgnorePointer(
              child: AccountItem(
                account: Account(
                  id: 'preview',
                  name: nameController.text.isEmpty
                      ? 'Account Name'
                      : nameController.text,
                  iconCodePoint: selectedIcon,
                  colorHex:
                      '#${selectedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
                  excludeFromTotal: excludeFromTotal,
                  logoAsset: selectedLogoAsset,
                  cardColorHex: selectedCardColor == null
                      ? null
                      : '#${selectedCardColor!.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
                ),
                balance: double.tryParse(balanceController.text) ?? 0.0,
                currencySymbol: currency.symbol,
                onTap: () {},
                // Disable private toggle interaction in preview
              ),
            ),
            const Gap(32),

            // ── Templates Section ──
            Row(
              children: [
                Icon(
                  Icons.style_rounded,
                  size: 16,
                  color: AppTheme.primaryColor(context).withValues(alpha: 0.7),
                ),
                const Gap(6),
                Text(
                  'Templates',
                  style: TextStyle(
                    color: AppTheme.textLightColor(
                      context,
                    ).withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const Gap(12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                controller: _templateScrollController,
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: BankTemplate.templates.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final isSelected = selectedTemplateId == null;
                    return GestureDetector(
                      onTap: () => _applyTemplate(null),
                      child: Container(
                        width: 76,
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? selectedColor.withValues(alpha: 0.1)
                                    : AppTheme.dividerColor(
                                        context,
                                      ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: isSelected
                                      ? selectedColor
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.tune_rounded,
                                color: isSelected
                                    ? selectedColor
                                    : AppTheme.textLightColor(
                                        context,
                                      ).withValues(alpha: 0.5),
                                size: 22,
                              ),
                            ),
                            const Gap(6),
                            Text(
                              'Custom',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppTheme.textColor(context)
                                    : AppTheme.textLightColor(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final template = BankTemplate.templates[index - 1];
                  final isSelected = selectedTemplateId == template.id;
                  final templateColor = Color(
                    int.parse(template.colorHex.replaceFirst('#', '0xFF')),
                  );

                  return GestureDetector(
                    onTap: () => _applyTemplate(template),
                    child: Container(
                      width: 76,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: isSelected
                                    ? templateColor
                                    : AppTheme.dividerColor(
                                        context,
                                      ).withValues(alpha: 0.3),
                                width: isSelected ? 2.5 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: templateColor.withValues(
                                          alpha: 0.25,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                isSelected ? 10.5 : 12.0,
                              ),
                              child: Image.asset(
                                template.logoAsset,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const Gap(6),
                          Text(
                            template.name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppTheme.textColor(context)
                                  : AppTheme.textLightColor(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Gap(24),

            _buildPremiumTextField(
              controller: nameController,
              label: 'Account Name',
              icon: Icons.label_outline_rounded,
              textCapitalization: TextCapitalization.words,
              enabled: selectedTemplateId == null,
            ),
            const Gap(16),
            _buildPremiumTextField(
              controller: balanceController,
              label: 'Initial Balance',
              icon: Icons.payments_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const Gap(24),

            Row(
              children: [
                Icon(
                  Icons.image_rounded,
                  size: 16,
                  color: AppTheme.primaryColor(context).withValues(alpha: 0.7),
                ),
                const Gap(6),
                Text(
                  'Icon',
                  style: TextStyle(
                    color: AppTheme.textLightColor(
                      context,
                    ).withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const Gap(12),
            IgnorePointer(
              ignoring: selectedTemplateId != null,
              child: Opacity(
                opacity: selectedTemplateId != null ? 0.5 : 1.0,
                child: SizedBox(
                  height: 50,
                  child: ListView.builder(
                    controller: _iconScrollController,
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    itemCount: icons.length,
                    itemBuilder: (context, index) {
                      final icon = icons[index];
                      final isSelected = selectedIcon == icon.codePoint;
                      return GestureDetector(
                        onTap: () {
                          HapticService.light();
                          setState(() => selectedIcon = icon.codePoint);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? selectedColor.withValues(alpha: 0.1)
                                : AppTheme.dividerColor(
                                    context,
                                  ).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? selectedColor
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: isSelected
                                ? selectedColor
                                : AppTheme.textLightColor(
                                    context,
                                  ).withValues(alpha: 0.5),
                            size: 24,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const Gap(24),

            Row(
              children: [
                Icon(
                  Icons.color_lens_rounded,
                  size: 16,
                  color: AppTheme.primaryColor(context).withValues(alpha: 0.7),
                ),
                const Gap(6),
                Text(
                  'Color',
                  style: TextStyle(
                    color: AppTheme.textLightColor(
                      context,
                    ).withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const Gap(12),
            IgnorePointer(
              ignoring: selectedTemplateId != null,
              child: Opacity(
                opacity: selectedTemplateId != null ? 0.5 : 1.0,
                child: SizedBox(
                  height: 50,
                  child: ListView.builder(
                    controller: _colorScrollController,
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    itemCount: colors.length,
                    itemBuilder: (context, index) {
                      final c = colors[index];
                      final isSelected =
                          selectedColor.toARGB32() == c.toARGB32();
                      return GestureDetector(
                        onTap: () {
                          HapticService.light();
                          setState(() => selectedColor = c);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: c.withValues(alpha: 0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 22,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const Gap(24),

            Row(
              children: [
                Icon(
                  Icons.wallpaper_rounded,
                  size: 16,
                  color: AppTheme.primaryColor(context).withValues(alpha: 0.7),
                ),
                const Gap(6),
                Text(
                  'Card Background',
                  style: TextStyle(
                    color: AppTheme.textLightColor(
                      context,
                    ).withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const Gap(12),
            IgnorePointer(
              ignoring: selectedTemplateId != null,
              child: Opacity(
                opacity: selectedTemplateId != null ? 0.5 : 1.0,
                child: SizedBox(
                  height: 50,
                  child: ListView(
                    controller: _cardColorScrollController,
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticService.light();
                          setState(() => selectedCardColor = null);
                        },
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: selectedCardColor == null
                                  ? AppTheme.primaryColor(
                                      context,
                                    ).withValues(alpha: 0.1)
                                  : AppTheme.dividerColor(
                                      context,
                                    ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: selectedCardColor == null
                                    ? AppTheme.primaryColor(context)
                                    : AppTheme.dividerColor(
                                        context,
                                      ).withValues(alpha: 0.3),
                                width: selectedCardColor == null ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.format_color_reset_rounded,
                                  size: 16,
                                  color: selectedCardColor == null
                                      ? AppTheme.primaryColor(context)
                                      : AppTheme.textLightColor(
                                          context,
                                        ).withValues(alpha: 0.5),
                                ),
                                const Gap(6),
                                Text(
                                  'Default',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: selectedCardColor == null
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: selectedCardColor == null
                                        ? AppTheme.primaryColor(context)
                                        : AppTheme.textLightColor(
                                            context,
                                          ).withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      ...cardBgColors.map((c) {
                        final isSelected =
                            selectedCardColor != null &&
                            selectedCardColor!.toARGB32() == c.toARGB32();
                        return GestureDetector(
                          onTap: () {
                            HapticService.light();
                            setState(() => selectedCardColor = c);
                          },
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 12),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: c.withValues(alpha: 0.4),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
            const Gap(24),

            Container(
              decoration: BoxDecoration(
                color: AppTheme.dividerColor(context).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.dividerColor(context).withValues(alpha: 0.1),
                ),
              ),
              child: SwitchListTile(
                title: const Text(
                  'Make Account Private',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'This will obfuscate the balance and exclude it from the total balance amount',
                  style: TextStyle(fontSize: 12),
                ),
                value: excludeFromTotal,
                onChanged: (value) {
                  HapticService.light();
                  setState(() => excludeFromTotal = value);
                },
                activeThumbColor: AppTheme.primaryColor(context),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const Gap(40),

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
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _saveAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    isEditing ? 'Save Changes' : 'Create Account',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const Gap(24),
          ],
        ),
      ),
    );
  }
}
