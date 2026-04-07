import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koin/core/models/transaction.dart';
import 'package:koin/core/providers/planned_payment_provider.dart';
import 'package:koin/core/providers/category_provider.dart';
import 'package:koin/core/providers/settings_provider.dart';
import 'package:koin/core/theme.dart';
import 'package:koin/features/planned_payments/add_edit_planned_payment_screen.dart';
import 'package:koin/core/widgets/pressable_scale.dart';
import 'package:koin/core/utils/haptic_utils.dart';
import 'package:intl/intl.dart';

class PlannedPaymentsScreen extends ConsumerWidget {
  const PlannedPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(plannedPaymentProvider);
    final settings = ref.watch(settingsProvider);
    final currency = settings.currency;
    final categories = ref.watch(categoriesProvider).value ?? [];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        title: const Text(
          'Subscriptions',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppTheme.surfaceColor(context),
        elevation: 0,
      ),
      body: paymentsAsync.when(
        data: (payments) {
          if (payments.isEmpty) {
            return const Center(child: Text('No subscriptions found.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              final category = categories.firstWhere(
                (c) => c.id == payment.categoryId,
                orElse: () => categories.first,
              );

              final isExpense = payment.type == TransactionType.expense;
              final amountColor = isExpense
                  ? AppTheme.expenseColor(context)
                  : AppTheme.incomeColor(context);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PressableScale(
                  onTap: () {
                    HapticService.light();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddEditPlannedPaymentScreen(payment: payment),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor(context),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(
                              int.parse(
                                category.colorHex.replaceFirst('#', '0xFF'),
                              ),
                            ).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            IconData(
                              category.iconCodePoint,
                              fontFamily: 'MaterialIcons',
                            ),
                            color: Color(
                              int.parse(
                                category.colorHex.replaceFirst('#', '0xFF'),
                              ),
                            ),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                payment.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Next: \${DateFormat.yMMMd().format(payment.nextDate)} • \${payment.frequency.name}',
                                style: TextStyle(
                                  color: AppTheme.textLightColor(context),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${isExpense ? '-' : '+'}${NumberFormat.currency(symbol: currency.symbol).format(payment.amount)}",
                              style: TextStyle(
                                color: amountColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            if (payment.isAutoProcess)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Icon(
                                  Icons.autorenew,
                                  size: 14,
                                  color: AppTheme.primaryColor(context),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: \$error')),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor(context),
        onPressed: () {
          HapticService.light();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditPlannedPaymentScreen(),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
