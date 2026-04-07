import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koin/core/database_helper.dart';
import 'package:koin/core/models/planned_payment.dart';

class PlannedPaymentNotifier extends AsyncNotifier<List<PlannedPayment>> {
  @override
  Future<List<PlannedPayment>> build() async {
    return await DatabaseHelper.instance.getPlannedPayments();
  }

  Future<void> loadPlannedPayments() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await DatabaseHelper.instance.getPlannedPayments();
    });
  }

  Future<void> addPlannedPayment(PlannedPayment payment) async {
    await DatabaseHelper.instance.insertPlannedPayment(payment);
    await loadPlannedPayments();
  }

  Future<void> updatePlannedPayment(PlannedPayment payment) async {
    await DatabaseHelper.instance.updatePlannedPayment(payment);
    await loadPlannedPayments();
  }

  Future<void> deletePlannedPayment(String id) async {
    await DatabaseHelper.instance.deletePlannedPayment(id);
    await loadPlannedPayments();
  }
}

final plannedPaymentProvider =
    AsyncNotifierProvider<PlannedPaymentNotifier, List<PlannedPayment>>(() {
      return PlannedPaymentNotifier();
    });
