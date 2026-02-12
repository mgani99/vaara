import 'package:flutter/material.dart';
import 'package:my_app/payments/controller/payment_list_controller.dart';
import 'package:my_app/payments/service/payment_list_service.dart';
import 'package:my_app/session/app_data.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';


class PaymentListPage extends StatelessWidget {
  const PaymentListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PaymentListController(
        service: context.read<PaymentListService>(),
        orgId: context.read<AppSession>().activeOrgId!,
      )..init(),
      child: const _PaymentListView(),
    );
  }
}

class _PaymentListView extends StatelessWidget {
  const _PaymentListView();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PaymentListController>();

    if (c.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment Tracker"),
      ),
      body: ListView(
        children: [
          _monthNav(c),
          _summary(c),
          _unitList(c),
        ],
      ),
    );
  }

  Widget _monthNav(PaymentListController c) {
    final fmt = DateFormat("MMMM yyyy");
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(icon: const Icon(Icons.arrow_back), onPressed: c.prevMonth),
        Text(fmt.format(c.paymentMonth),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        IconButton(icon: const Icon(Icons.arrow_forward), onPressed: c.nextMonth),
      ],
    );
  }

  Widget _summary(PaymentListController c) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        "Units: ${c.unitCache.length} • Payments: ${c.payments.length}",
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _unitList(PaymentListController c) {
    return Column(
      children: c.unitCache.values.map((unit) {
        return ListTile(
          title: Text(unit.name),
          subtitle: Text("Unit ID: ${unit.unitId}"),
          trailing: const Icon(Icons.chevron_right),
        );
      }).toList(),
    );
  }
}
