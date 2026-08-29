import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../property/domain/property_model.dart';
import '../../session/app_data.dart';

import '../service/payment_service.dart';

class PaymentFormPage extends StatefulWidget {

  final PaymentModel? payment;

  const PaymentFormPage({
    super.key,
    this.payment,
  });

  @override
  State<PaymentFormPage> createState() => _PaymentFormPageState();
}

class _PaymentFormPageState extends State<PaymentFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _amountCtrl;
  late TextEditingController _noteCtrl;

  String _paymentType = "Rent";
  String _transactionType = "debit"; // debit = money received
  DateTime _selectedDate = DateTime.now();
  late  PaymentService _service;

  final List<String> _paymentTypes = [
    "Rent",
    "Security Deposit",
    "Late Fee",
    "Utility",
    "Damage Fee",
    "Other",
  ];

  final List<String> _transactionTypes = [
    "debit",   // money received
    "credit",  // refund / adjustment
  ];

  @override
  void initState() {
    super.initState();
    _service = context.read<PaymentService>();
    final p = widget.payment;

    _amountCtrl = TextEditingController(
      text: p != null ? p.amount.toString() : "",
    );

    _noteCtrl = TextEditingController(
      text: p != null ? p.note : "",
    );

    _paymentType = p?.paymentType ?? "Rent";
    _transactionType = p?.transactionType ?? "debit";

    _selectedDate = p != null
        ? DateTime.fromMillisecondsSinceEpoch(p.paymentDateEpoch)
        : DateTime.now();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;

    final session = context.read<AppSession>();
    final orgId = session.activeOrgId!;

    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid amount")),
      );
      return;
    }

    final isEditing = widget.payment != null;

    final payment = PaymentModel(
      paymentId: isEditing
          ? widget.payment!.paymentId
          : DateTime.now().millisecondsSinceEpoch.toString(),
      orgId: orgId,
      propertyId: widget.payment?.propertyId,
      unitId: widget.payment?.unitId,
      tenantId: widget.payment?.tenantId,
      transactionType: _transactionType,
      paymentType: _paymentType,
      amount: amount,
      paymentDateEpoch: _selectedDate.millisecondsSinceEpoch,
      note: _noteCtrl.text.trim(),
      status: "active",
      createdAt: isEditing
          ? widget.payment!.createdAt
          : DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      isDeleted: false,
      deletedAt: null,
    );

    _service = context.read<PaymentService>();
    if (isEditing) {
      await context.read<PaymentService>().updatePayment(payment,oldAmount: 0);
    } else {
      await _service.addPayment(payment);
    }

    Navigator.pop(context);
  }

  Future<void> _deletePayment() async {
    if (widget.payment == null) return;
    final session = context.read<AppSession>();
    _service = context.read<PaymentService>();
    await _service.deletePayment(session.activeOrgId!,widget.payment!.paymentId!);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.payment != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Payment" : "Add Payment"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // AMOUNT
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(
                  labelText: "Amount",
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                validator: (v) =>
                v == null || v.trim().isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 12),

              // PAYMENT TYPE
              DropdownButtonFormField<String>(
                value: _paymentType,
                decoration: const InputDecoration(
                  labelText: "Payment Type",
                  border: OutlineInputBorder(),
                ),
                items: _paymentTypes
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _paymentType = v!),
              ),
              const SizedBox(height: 12),

              // TRANSACTION TYPE
              DropdownButtonFormField<String>(
                value: _transactionType,
                decoration: const InputDecoration(
                  labelText: "Transaction Type",
                  border: OutlineInputBorder(),
                ),
                items: _transactionTypes
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _transactionType = v!),
              ),
              const SizedBox(height: 12),

              // NOTE
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: "Note",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),

              // DATE PICKER
              ListTile(
                title: Text(
                  "Payment Date: ${DateFormat('MMM dd, yyyy').format(_selectedDate)}",
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),

              const SizedBox(height: 20),

              // SAVE BUTTON
              ElevatedButton(
                onPressed: _savePayment,
                child: Text(isEditing ? "Update Payment" : "Add Payment"),
              ),

              const SizedBox(height: 12),

              // DELETE BUTTON
              if (isEditing)
                ElevatedButton(
                  onPressed: _deletePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                  ),
                  child: const Text(
                    "Delete Payment",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
