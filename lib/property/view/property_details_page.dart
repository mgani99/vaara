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
  late TextEditingController streetCtrl;
  late TextEditingController cityCtrl;
  late TextEditingController stateCtrl;

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
  late TextEditingController insuranceAmountCtrl;

  bool isLoading = true;
  bool taxReminder = false;
  bool insuranceReminder = false;


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
    streetCtrl = TextEditingController(text: property.address ?? "");
    cityCtrl = TextEditingController(text: property.city ?? "");
    stateCtrl = TextEditingController(text: property.state ?? "");

// Concatenate for the view
    addressCtrl = TextEditingController(
        text: "${streetCtrl.text}, ${cityCtrl.text}, ${stateCtrl.text}"
    );

   // addressCtrl = TextEditingController(text: property.address);
    typeCtrl = TextEditingController(text: property.type);
    numUnitsCtrl = TextEditingController(text: "${property.numUnits ?? ""}");
    parcelCtrl = TextEditingController(text: property.parcelNumber ?? "");

    currentValueCtrl = TextEditingController(
        text: formatMoney("${valuation?.currentValue ?? ""}")
    );

    purchasePriceCtrl = TextEditingController(
        text: formatMoney("${valuation?.purchasePrice ?? ""}")
    );

    purchaseDateCtrl = TextEditingController(text: valuation?.purchaseDate ?? "");

    taxFullYearCtrl = TextEditingController(text: "${tax?.fullYearAmount ?? ""}");
    taxFrequencyCtrl = TextEditingController(text: tax?.frequency ?? "");
    taxDueCtrl = TextEditingController(text: tax?.dueOn ?? "");
    taxInstallmentCtrl = TextEditingController(text: "${tax?.installmentAmount ?? ""}");

    insuranceProviderCtrl = TextEditingController(text: insurance?.provider ?? "");
    insuranceDueCtrl = TextEditingController(text: insurance?.dueOn ?? "");
    insuranceFrequencyCtrl = TextEditingController(text: insurance?.frequency ?? "");
    insuranceAmountCtrl = TextEditingController(
        text: formatMoney("${insurance?.premium ?? ""}")
    );


    setState(() => isLoading = false);
  }


  String formatMoney(String? v) {
    if (v == null || v.isEmpty) return "";
    final n = double.tryParse(v.replaceAll(",", "").replaceAll("\$", ""));
    if (n == null) return v;

    final intValue = n.toInt();
    final formatted = intValue.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => "${m[1]},",
    );

    return "\$$formatted";
  }



  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
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
          image: AssetImage("assets/home.png"),
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
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,   // ⭐ BLACK
                  ),
                ),

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
        GestureDetector(
          onTap: isReadOnly ? null : _showAddressEditModal,
          child: AbsorbPointer(
            child: _row("Address *", addressCtrl),
          ),
        ),

        _divider(),
    _dropdownRow(
    "Property Type *",
    typeCtrl,
    ["single_family", "multi_family"],
    ),

        _divider(),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Text(
                    "Number of Units *",
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                  ),
                  const SizedBox(width: 6),
                  _infoIcon(),   // ⭐ NEW
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: TextField(
                controller: numUnitsCtrl,
                readOnly: isReadOnly,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  isDense: true,
                  border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(2.0),
                    borderSide: BorderSide(
                      color: isReadOnly ? Colors.grey.shade300 : Colors.blue.shade300,
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: Colors.blue, width: 1.4),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
                style: const TextStyle(fontSize: 12),

                // ⭐ NEW LOGIC
                onChanged: (v) {
                  if (!isReadOnly) {
                    final num = int.tryParse(v.trim()) ?? 0;

                    if (num > 1 && typeCtrl.text != "multi_family") {
                      setState(() {
                        typeCtrl.text = "multi_family";
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "More than one rentable unit will require a multi-family profile.",
                          ),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                },
              ),

            ),
          ],
        ),

        _divider(),
        _row("Parcel Number", parcelCtrl),
      ],
    );
  }
  Widget _infoIcon() {
    return GestureDetector(
      onTap: () => _showUnitsInfo(),
      child: const Icon(
        Icons.info_outline,
        size: 16,
        color: Colors.blue,
      ),
    );
  }
  void _showUnitsInfo() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Number of Units",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "Total number of rentable units including garage, store front, parking space etc.",
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddressEditModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Edit Address",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              _confirmEditableField("Street Address", streetCtrl),
              const SizedBox(height: 12),

              _confirmEditableField("City", cityCtrl),
              const SizedBox(height: 12),

              _stateAutocompleteField(),


              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () {
                  final abbr = abbreviateState(stateCtrl.text.trim());
                  final full = "${streetCtrl.text.trim()}, ${cityCtrl.text.trim()}, $abbr";

                  setState(() {
                    addressCtrl.text = full;   // ⭐ UI concatenated
                  });

                  Navigator.pop(context);
                },
                child: const Text("Confirm"),
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _stateAutocompleteField() {
    final List<String> states = usStateAbbreviations.keys.toList();

    return StatefulBuilder(
      builder: (context, setModalState) {
        List<String> filtered = states
            .where((s) =>
            s.toLowerCase().contains(stateCtrl.text.toLowerCase()))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("State", style: TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 6),

            TextField(
              controller: stateCtrl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => setModalState(() {}),
            ),

            if (filtered.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView(
                  shrinkWrap: true,
                  children: filtered.map((s) {
                    return ListTile(
                      dense: true,
                      title: Text(s),
                      onTap: () {
                        stateCtrl.text = s;
                        setModalState(() {});
                      },
                    );
                  }).toList(),
                ),
              ),
          ],
        );
      },
    );
  }

  /// USPS State Abbreviation Map
   Map<String, String> usStateAbbreviations = {
    "Alabama": "AL", "Alaska": "AK", "Arizona": "AZ", "Arkansas": "AR",
    "California": "CA", "Colorado": "CO", "Connecticut": "CT", "Delaware": "DE",
    "Florida": "FL", "Georgia": "GA", "Hawaii": "HI", "Idaho": "ID",
    "Illinois": "IL", "Indiana": "IN", "Iowa": "IA", "Kansas": "KS",
    "Kentucky": "KY", "Louisiana": "LA", "Maine": "ME", "Maryland": "MD",
    "Massachusetts": "MA", "Michigan": "MI", "Minnesota": "MN",
    "Mississippi": "MS", "Missouri": "MO", "Montana": "MT", "Nebraska": "NE",
    "Nevada": "NV", "New Hampshire": "NH", "New Jersey": "NJ",
    "New Mexico": "NM", "New York": "NY", "North Carolina": "NC",
    "North Dakota": "ND", "Ohio": "OH", "Oklahoma": "OK", "Oregon": "OR",
    "Pennsylvania": "PA", "Rhode Island": "RI", "South Carolina": "SC",
    "South Dakota": "SD", "Tennessee": "TN", "Texas": "TX", "Utah": "UT",
    "Vermont": "VT", "Virginia": "VA", "Washington": "WA",
    "West Virginia": "WV", "Wisconsin": "WI", "Wyoming": "WY"
  };
  Widget _confirmEditableField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ],
    );
  }

  String abbreviateState(String state) => usStateAbbreviations[state] ?? state;

  Widget _dropdownRow(
      String label,
      TextEditingController ctrl,
      List<String> items, {
        Function(String)? onChanged,
      }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.black)),
        ),
        const SizedBox(width: 8),

        Expanded(
          flex: 3,
          child: DropdownButtonFormField<String>(
            value: ctrl.text.isEmpty ? null : ctrl.text,
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),

            onChanged: isReadOnly
                ? null
                : (v) {
              ctrl.text = v!;
              if (onChanged != null) onChanged(v);
            },

            decoration: InputDecoration(
              isDense: true,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,   // ⭐ RECTANGLE
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2.0),   // ⭐ RECTANGLE
                borderSide: BorderSide(
                  color: isReadOnly
                      ? Colors.grey.shade300
                      : Colors.blue.shade300,
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,   // ⭐ RECTANGLE
                borderSide: BorderSide(
                  color: Colors.blue,
                  width: 1.4,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
            ),

            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }


  Widget _priceValue() {
    return Column(
      children: [
        _currencyRow("Current Value", currentValueCtrl),
        _divider(),
        _currencyRow("Purchase Price", purchasePriceCtrl),
        _divider(),
    _datePickerRow("Purchase Date", purchaseDateCtrl),

    ],
    );
  }
  Widget _currencyRow(String label, TextEditingController ctrl) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.black)),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: TextField(
            controller: ctrl,
            readOnly: isReadOnly,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              isDense: true,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,   // ⭐ FULL RECTANGLE
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2.0),   // ⭐ FULL RECTANGLE
                borderSide: BorderSide(
                  color: isReadOnly
                      ? Colors.grey.shade300
                      : Colors.blue.shade300,
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,   // ⭐ FULL RECTANGLE
                borderSide: BorderSide(
                  color: Colors.blue,
                  width: 1.4,
                ),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            style: const TextStyle(fontSize: 12),
            onChanged: (v) {
              if (!isReadOnly) {
                final raw = v.replaceAll("\$", "").replaceAll(",", "");
                ctrl.text = formatMoney(raw);
                ctrl.selection = TextSelection.fromPosition(
                  TextPosition(offset: ctrl.text.length),
                );

                if (label == "Full Year Tax Amount") {
                  final fullYear = double.tryParse(raw);
                  if (fullYear != null) {
                    final installment = calculateInstallment(
                      fullYear,
                      taxFrequencyCtrl.text.trim(),
                    );
                    taxInstallmentCtrl.text =
                        formatMoney(installment.toString());
                  }
                }
              }
            },
          ),
        ),
      ],
    );
  }


  Widget _datePickerRow(String label, TextEditingController ctrl) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black),
          ),
        ),
        const SizedBox(width: 8),

        Expanded(
          flex: 3,
          child: GestureDetector(
            onTap: isReadOnly
                ? null
                : () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                ctrl.text = "${picked.year}-${picked.month}-${picked.day}";
                setState(() {});
              }
            },
            child: AbsorbPointer(
              child: TextField(
                controller: ctrl,
                readOnly: true,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  isDense: true,

                  // ⭐ FULL RECTANGLE
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(2.0),
                    borderSide: BorderSide(
                      color: isReadOnly
                          ? Colors.grey.shade300
                          : Colors.blue.shade300,
                    ),
                  ),

                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(
                      color: Colors.blue,
                      width: 1.4,
                    ),
                  ),

                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                ),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _taxSection() {
    return Column(
      children: [
        _currencyRow("Full Year Tax Amount", taxFullYearCtrl),

        _divider(),
        _dropdownRow(
          "Frequency",
          taxFrequencyCtrl,
          ["monthly", "quarterly", "semiannual", "yearly"],
          onChanged: (v) {
            if (!isReadOnly) {
              taxFrequencyCtrl.text = v!;
              final fullYear = double.tryParse(
                  taxFullYearCtrl.text.replaceAll("\$", "").replaceAll(",", "")
              );
              if (fullYear != null) {
                final installment = calculateInstallment(fullYear, v);
                taxInstallmentCtrl.text = formatMoney(installment.toString());
              }
              setState(() {});
            }
          },
        ),

        _divider(),
        _dueOnRow("Due On", taxDueCtrl, taxReminder, (v) {
          setState(() => taxReminder = v);
        }),


        _divider(),
        _row("Installment Amount", taxInstallmentCtrl, TextInputType.number),
      ],
    );
  }
  Widget _dueOnRow(String label, TextEditingController ctrl, bool reminderValue, Function(bool) onReminderChanged) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.black)),
        ),
        const SizedBox(width: 8),

        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: isReadOnly
                      ? null
                      : () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      ctrl.text = "${picked.year}-${picked.month}-${picked.day}";
                      setState(() {});
                    }
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      controller: ctrl,
                      readOnly: true,
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        isDense: true,
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.zero,   // ⭐ RECTANGLE
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(2.0),   // ⭐ RECTANGLE
                          borderSide: BorderSide(
                            color: isReadOnly
                                ? Colors.grey.shade300
                                : Colors.blue.shade300,
                          ),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.zero,   // ⭐ RECTANGLE
                          borderSide: BorderSide(
                            color: Colors.blue,
                            width: 1.4,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              Checkbox(
                value: reminderValue,
                onChanged: isReadOnly ? null : (v) => onReminderChanged(v!),
              ),

              const Icon(Icons.notifications, size: 18, color: Colors.blue),
            ],
          ),
        ),
      ],
    );
  }


  double calculateInstallment(double fullYear, String frequency) {
    switch (frequency) {
      case "monthly":
        return fullYear / 12;
      case "quarterly":
        return fullYear / 4;
      case "semiannual":
        return fullYear / 2;
      case "yearly":
        return fullYear;
      default:
        return fullYear;
    }
  }

  Widget _insuranceSection() {
    return Column(
      children: [
        _row("Provider", insuranceProviderCtrl),
        _divider(),

        _dueOnRow("Due On", insuranceDueCtrl, insuranceReminder, (v) {
          setState(() => insuranceReminder = v);
        }),

        _divider(),

        _dropdownRow(
          "Frequency",
          insuranceFrequencyCtrl,
          ["monthly", "quarterly", "semiannual", "yearly"],
        ),
        _divider(),

        _currencyRow("Insurance Amount", insuranceAmountCtrl),
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
              style: const TextStyle(fontSize: 12, color: Colors.black)),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: TextField(
            textAlign: TextAlign.right,
            controller: ctrl,
            readOnly: isReadOnly,
            keyboardType: type,
            decoration: InputDecoration(
              isDense: true,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,   // ⭐ FULL RECTANGLE
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2.0),   // ⭐ FULL RECTANGLE
                borderSide: BorderSide(
                  color: isReadOnly
                      ? Colors.grey.shade300
                      : Colors.blue.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,   // ⭐ FULL RECTANGLE
                borderSide: const BorderSide(
                  color: Colors.blue,
                  width: 1.4,
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
      address: streetCtrl.text.trim(),
      city: cityCtrl.text.trim(),
      state: stateCtrl.text.trim(),

      type: typeCtrl.text.trim(),
      numUnits: int.tryParse(numUnitsCtrl.text.trim()) ?? property.numUnits,
      parcelNumber: parcelCtrl.text.trim(),
    );

    session.propertyCache[updatedProperty.propertyId] = updatedProperty;
    await repo.updateProperty(updatedProperty);
    double? _parseMoney(String raw) {
      final cleaned = raw.replaceAll("\$", "").replaceAll(",", "").trim();
      return double.tryParse(cleaned);
    }

    // Update Valuation
    final updatedValuation = PropertyValuationModel(
      valuationId: widget.propertyId,
      propertyId: widget.propertyId,
      currentValue: _parseMoney(currentValueCtrl.text),
      purchasePrice: _parseMoney(purchasePriceCtrl.text),
      purchaseDate: purchaseDateCtrl.text.trim(),
      createdAt: valuation?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await repo.updateValuation(session.activeOrgId!, updatedValuation);

    // Update Tax
    final updatedTax = PropertyTaxModel(
      taxId: widget.propertyId,
      propertyId: widget.propertyId,
      fullYearAmount: _parseMoney(taxFullYearCtrl.text.trim()),
      frequency: taxFrequencyCtrl.text.trim(),
      dueOn: taxDueCtrl.text.trim(),
      installmentAmount: _parseMoney(taxInstallmentCtrl.text.trim()),
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


      premium: double.tryParse(
          insuranceAmountCtrl.text.replaceAll("\$", "")
      ),
      createdAt: insurance?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );


    await repo.updateInsurance(session.activeOrgId!, updatedInsurance);
  }
}
