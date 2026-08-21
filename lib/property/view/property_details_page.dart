import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_app/session/app_data.dart';
import 'package:my_app/property/domain/property_model.dart';


class PropertyDetailsScreen extends StatefulWidget {
  final String propertyId;
  final bool readOnly;

  const PropertyDetailsScreen({
    super.key,
    required this.propertyId,
    this.readOnly = false,
  });

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}


class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  late PropertyModel property;
  PropertyValuationModel? valuation;
  PropertyTaxModel? tax;
  PropertyInsuranceModel? insurance;

  bool isReadOnly = true;

  bool basicOpen = true;
  bool priceOpen = false;
  bool taxOpen = false;
  bool insuranceOpen = false;

  // Controllers
  late TextEditingController nameCtrl;
  late TextEditingController addressCtrl;
  late TextEditingController typeCtrl;
  late TextEditingController numUnitsCtrl;
  late TextEditingController parcelCtrl;

  late TextEditingController currentValueCtrl;
  late TextEditingController purchasePriceCtrl;
  late TextEditingController purchaseDateCtrl;

  late TextEditingController taxFullYearCtrl;
  late TextEditingController taxFrequencyCtrl;
  late TextEditingController taxDueCtrl;
  late TextEditingController taxInstallmentCtrl;

  late TextEditingController insuranceProviderCtrl;
  late TextEditingController insuranceDueCtrl;
  late TextEditingController insuranceFrequencyCtrl;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final session = context.read<AppSession>();
    final repo = session.propertyRepo;

    property = session.propertyCache[widget.propertyId]!;

    valuation = await repo.getValuation(session.activeOrgId!, widget.propertyId);
    tax = await repo.getTax(session.activeOrgId!, widget.propertyId);
    insurance = await repo.getInsurance(session.activeOrgId!, widget.propertyId);

    nameCtrl = TextEditingController(text: property.name);
    addressCtrl = TextEditingController(text: property.address);
    typeCtrl = TextEditingController(text: property.type);
    numUnitsCtrl = TextEditingController(text: "${property.numUnits ?? ""}");
    parcelCtrl = TextEditingController(text: property.parcelNumber ?? "");

    currentValueCtrl = TextEditingController(text: "${valuation?.currentValue ?? ""}");
    purchasePriceCtrl = TextEditingController(text: "${valuation?.purchasePrice ?? ""}");
    purchaseDateCtrl = TextEditingController(text: valuation?.purchaseDate ?? "");

    taxFullYearCtrl = TextEditingController(text: "${tax?.fullYearAmount ?? ""}");
    taxFrequencyCtrl = TextEditingController(text: tax?.frequency ?? "");
    taxDueCtrl = TextEditingController(text: tax?.dueOn ?? "");
    taxInstallmentCtrl = TextEditingController(text: "${tax?.installmentAmount ?? ""}");

    insuranceProviderCtrl = TextEditingController(text: insurance?.provider ?? "");
    insuranceDueCtrl = TextEditingController(text: insurance?.dueOn ?? "");
    insuranceFrequencyCtrl = TextEditingController(text: insurance?.frequency ?? "");

    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(property.name ?? "Property"),
        actions: [
          IconButton(
            icon: Icon(isReadOnly ? Icons.edit : Icons.check),
            onPressed: () async {
              if (!isReadOnly) {
                await _saveAll(session);
              }
              setState(() => isReadOnly = !isReadOnly);
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _topImage(),
          const SizedBox(height: 12),
          _section("Basic Info", basicOpen, () {
            setState(() => basicOpen = !basicOpen);
          }, _basicInfo()),
          if (valuation == null)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text("No valuation data found"),
            ),




          _section("Price & Value", priceOpen, () {
            setState(() => priceOpen = !priceOpen);
          }, _priceValue()),

          _section("Tax", taxOpen, () {
            setState(() => taxOpen = !taxOpen);
          }, _taxSection()),

          _section("Insurance", insuranceOpen, () {
            setState(() => insuranceOpen = !insuranceOpen);
          }, _insuranceSection()),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _topImage() {
    return Container(
      height: 220,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/property.png"),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _section(String title, bool open, VoidCallback toggle, Widget child) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: toggle,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                Icon(
                  open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 20,
                ),
              ],
            ),
          ),
          if (open) ...[
            const SizedBox(height: 10),
            child,
          ]
        ],
      ),
    );
  }

  Widget _basicInfo() {
    return Column(
      children: [
        _row("Property Name *", nameCtrl),
        _divider(),
        _row("Address *", addressCtrl),
        _divider(),
        _row("Property Type *", typeCtrl),
        _divider(),
        _row("Number of Units *", numUnitsCtrl, TextInputType.number),
        _divider(),
        _row("Parcel Number", parcelCtrl),
      ],
    );
  }

  Widget _priceValue() {
    return Column(
      children: [
        _row("Current Value", currentValueCtrl, TextInputType.number),
        _divider(),
        _row("Purchase Price", purchasePriceCtrl, TextInputType.number),
        _divider(),
        _row("Purchase Date", purchaseDateCtrl),
      ],
    );
  }

  Widget _taxSection() {
    return Column(
      children: [
        _row("Full Year Tax Amount", taxFullYearCtrl, TextInputType.number),
        _divider(),
        _row("Frequency", taxFrequencyCtrl),
        _divider(),
        _row("Due On", taxDueCtrl),
        _divider(),
        _row("Installment Amount", taxInstallmentCtrl, TextInputType.number),
      ],
    );
  }

  Widget _insuranceSection() {
    return Column(
      children: [
        _row("Provider", insuranceProviderCtrl),
        _divider(),
        _row("Due On", insuranceDueCtrl),
        _divider(),
        _row("Frequency", insuranceFrequencyCtrl),
      ],
    );
  }

  Widget _row(String label, TextEditingController ctrl,
      [TextInputType type = TextInputType.text]) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.black87)),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: TextField(
            controller: ctrl,
            readOnly: isReadOnly,
            keyboardType: type,
            decoration: InputDecoration(
              isDense: true,
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isReadOnly
                      ? Colors.grey.shade300
                      : Colors.blue.shade300,
                ),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      color: Colors.grey.shade300,
      margin: const EdgeInsets.symmetric(vertical: 8),
    );
  }

  Future<void> _saveAll(AppSession session) async {
    final repo = session.propertyRepo;

    // Update PropertyModel
    final updatedProperty = property.copyWith(
      name: nameCtrl.text.trim(),
      address: addressCtrl.text.trim(),
      type: typeCtrl.text.trim(),
      numUnits: int.tryParse(numUnitsCtrl.text.trim()) ?? property.numUnits,
      parcelNumber: parcelCtrl.text.trim(),
    );

    session.propertyCache[updatedProperty.propertyId] = updatedProperty;
    await repo.updateProperty(updatedProperty);

    // Update Valuation
    final updatedValuation = PropertyValuationModel(
      valuationId: widget.propertyId,
      propertyId: widget.propertyId,
      currentValue: double.tryParse(currentValueCtrl.text.trim()),
      purchasePrice: double.tryParse(purchasePriceCtrl.text.trim()),
      purchaseDate: purchaseDateCtrl.text.trim(),
      createdAt: valuation?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await repo.updateValuation(session.activeOrgId!, updatedValuation);

    // Update Tax
    final updatedTax = PropertyTaxModel(
      taxId: widget.propertyId,
      propertyId: widget.propertyId,
      fullYearAmount: double.tryParse(taxFullYearCtrl.text.trim()),
      frequency: taxFrequencyCtrl.text.trim(),
      dueOn: taxDueCtrl.text.trim(),
      installmentAmount: double.tryParse(taxInstallmentCtrl.text.trim()),
      createdAt: tax?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await repo.updateTax(session.activeOrgId!, updatedTax);

    // Update Insurance
    final updatedInsurance = PropertyInsuranceModel(
      insuranceId: widget.propertyId,
      propertyId: widget.propertyId,
      provider: insuranceProviderCtrl.text.trim(),
      dueOn: insuranceDueCtrl.text.trim(),
      frequency: insuranceFrequencyCtrl.text.trim(),
      premium: insurance?.premium,
      createdAt: insurance?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await repo.updateInsurance(session.activeOrgId!, updatedInsurance);
  }
}
