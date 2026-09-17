import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../property/domain/property_model.dart';
import '../../session/app_data.dart';
import '../service/payment_service.dart';

class PaymentFormPage extends StatefulWidget {
  final PaymentModel? payment;
  final String? unitId;
  final String? tenantId;

  const PaymentFormPage({
    super.key,
    this.payment,
    this.unitId,
    this.tenantId,
  });

  @override
  State<PaymentFormPage> createState() => _PaymentFormPageState();
}

class _PaymentFormPageState extends State<PaymentFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _amountCtrl;
  late TextEditingController _noteCtrl;

  String _paymentType = "Rent";
  String _transactionType = "debit";
  DateTime _selectedDate = DateTime.now();

  late PaymentService _service;

  final List<String> _paymentTypes = [
    "Rent",
    "Security Deposit",
    "Late Fee",
    "Utility",
    "Damage Fee",
    "Other",
  ];

  final List<String> _transactionTypes = [
    "debit",
    "credit",
  ];

  @override
  void initState() {
    super.initState();
    _service = context.read<PaymentService>();

    final p = widget.payment;

    _amountCtrl = TextEditingController(text: p?.amount.toString() ?? "");
    _noteCtrl = TextEditingController(text: p?.note ?? "");

    _paymentType = p?.paymentType ?? "Rent";
    _transactionType = p?.transactionType ?? "debit";

    _selectedDate = p != null
        ? DateTime.fromMillisecondsSinceEpoch(p.effectiveDateEpoch)
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

    // -----------------------------
    // CREATE OR UPDATE PAYMENT MODEL
    // -----------------------------
    final payment = isEditing
        ? widget.payment!.copyWith(
      amount: amount,
      paymentType: _paymentType,
      transactionType: _transactionType,
      effectiveDateEpoch: _selectedDate.millisecondsSinceEpoch,
      note: _noteCtrl.text.trim(),
      recordedAtEpoch: DateTime.now().millisecondsSinceEpoch,
    )
        : PaymentModel(
      paymentId: DateTime.now().millisecondsSinceEpoch.toString(),
      orgId: orgId,
      propertyId: session.unitCache[widget.unitId]!.propertyId,
      unitId: widget.unitId!,
      tenantId: widget.tenantId!,
      transactionType: _transactionType,
      paymentType: _paymentType,
      amount: amount,
      effectiveDateEpoch: _selectedDate.millisecondsSinceEpoch,
      note: _noteCtrl.text.trim(),
      status: "active",
      recordedAtEpoch: DateTime.now().millisecondsSinceEpoch,

      isDeleted:false,
      deletedAt: null, actualDateEpoch:0, isSystemGenerated: false, validFromEpoch: DateTime.now().millisecondsSinceEpoch,
    );

    // -----------------------------
    // SAVE TO FIREBASE
    // -----------------------------
    if (isEditing) {
      await _service.updatePayment(payment, oldAmount: 0);
    } else {
      await _service.addPayment(payment);
    }

    // -----------------------------
    // UPDATE CACHE
    // -----------------------------
    session.updatePaymentInCache(payment);

    Navigator.pop(context);
  }

  Future<void> _deletePayment() async {
    if (widget.payment == null) return;

    final session = context.read<AppSession>();
    await _service.deletePayment(session.activeOrgId!, widget.payment!.paymentId!);

    session.paymentCache.remove(widget.payment!.paymentId!);
    session.noifyListeners();
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
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(
                  labelText: "Amount",
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) =>
                v == null || v.trim().isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 12),

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

              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: "Note",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),

              ListTile(
                title: Text(
                  "Payment Date: ${DateFormat('MMM dd, yyyy').format(_selectedDate)}",
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _savePayment,
                child: Text(isEditing ? "Update Payment" : "Add Payment"),
              ),

              const SizedBox(height: 12),

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
