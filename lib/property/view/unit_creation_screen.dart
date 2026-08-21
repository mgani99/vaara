import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_app/session/app_data.dart';
import 'package:my_app/property/service/unit_service.dart';
import 'package:my_app/property/domain/property_model.dart';

class UnitCreationScreen extends StatefulWidget {
  final String unitId;

  const UnitCreationScreen({super.key, required this.unitId});

  @override
  State<UnitCreationScreen> createState() => _UnitCreationScreenState();
}

class _UnitCreationScreenState extends State<UnitCreationScreen> {
  bool editing = false;   // 🔥 NEW — controls read/edit mode

  // -----------------------------
  // UNIT INFO
  // -----------------------------
  String unitName = "";
  String unitType = "Residential";

  String streetAddress = "";
  String city = "";
  String state = "";
  String description = "";

  UnitModel? unit;

  late TextEditingController nameController;
  late TextEditingController streetController;
  late TextEditingController cityController;
  late TextEditingController stateController;
  late TextEditingController descriptionController;

  @override
  void initState() {
    super.initState();

    final session = context.read<AppSession>();
    unit = session.unitCache[widget.unitId];
    final property = session.propertyCache[unit!.propertyId];

    // Address fallback logic
    streetAddress =
    (unit!.address != null && unit!.address!.trim().isNotEmpty)
        ? unit!.address!
        : "${property!.address}, ${unit!.name}";

    city = unit!.city?.trim().isNotEmpty == true
        ? unit!.city!
        : (property!.city ?? "");

    state = unit!.state?.trim().isNotEmpty == true
        ? unit!.state!
        : (property!.state ?? "");

    unitName = unit!.name;
    description = unit!.description ?? "";

    // Controllers
    nameController = TextEditingController(text: unitName);
    streetController = TextEditingController(text: streetAddress);
    cityController = TextEditingController(text: city);
    stateController = TextEditingController(text: state);
    descriptionController = TextEditingController(text: description);
  }

  bool get unitInfoValid =>
      unitName.isNotEmpty &&
          unitType.isNotEmpty &&
          streetAddress.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final unit = session.unitCache[widget.unitId];
    final property = session.propertyCache[unit!.propertyId];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          "Unit Details - ${property?.name ?? ""}",
          style: const TextStyle(fontSize: 14),
        ),

        // 🔥 EDIT ICON
        actions: [
          IconButton(
            icon: Icon(
              editing ? Icons.close : Icons.edit,
              color: Colors.black87,
            ),
            onPressed: () {
              setState(() => editing = !editing);
            },
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _unitInfoCard(),
          const SizedBox(height: 20),

          if (editing)
            ElevatedButton(
              onPressed: _saveUnit,
              child: const Text("Save Unit", style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // UNIT INFO CARD (NO METRICS ANYMORE)
  // ------------------------------------------------------------
  Widget _unitInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _editableField(
              label: "Unit Name",
              controller: nameController,
              mandatory: true,
              enabled: editing,
              onChanged: (v) => unitName = v,
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Unit Type", style: TextStyle(fontSize: 12)),
                editing
                    ? DropdownButton<String>(
                  value: unitType,
                  items: const [
                    DropdownMenuItem(value: "Residential", child: Text("Residential")),
                    DropdownMenuItem(value: "Parking", child: Text("Parking")),
                    DropdownMenuItem(value: "Garage", child: Text("Garage")),
                    DropdownMenuItem(value: "Store Front", child: Text("Store Front")),
                  ],
                  onChanged: (v) => setState(() => unitType = v!),
                )
                    : Text(unitType, style: const TextStyle(fontSize: 12)),
              ],
            ),

            const SizedBox(height: 20),

            _editableField(
              label: "Street Address",
              controller: streetController,
              mandatory: true,
              enabled: editing,
              onChanged: (v) => streetAddress = v,
            ),

            const SizedBox(height: 20),

            _readOnlyField("City", city),
            const SizedBox(height: 20),

            _readOnlyField("State", state),
            const SizedBox(height: 20),

            _editableField(
              label: "Description (optional)",
              controller: descriptionController,
              mandatory: false,
              enabled: editing,
              keyboard: TextInputType.multiline,
              minLines: 6,
              maxLines: null,
              onChanged: (v) => description = v,
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // SAVE UNIT
  // ------------------------------------------------------------
  Future<void> _saveUnit() async {
    if (!unitInfoValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all mandatory fields")),
      );
      return;
    }

    final session = context.read<AppSession>();
    final unitService = context.read<UnitService>();

    UnitModel newUnit = unit!.copyWith(
      address: streetAddress,
      name: unitName,
      type: unitType,
      description: description,
    );

    await unitService.repo.updateUnit(newUnit);

    session.unitCache[widget.unitId] = newUnit;
    session.notifyListeners();

    Navigator.pop(context);
  }

  // ------------------------------------------------------------
  // REUSABLE WIDGETS
  // ------------------------------------------------------------
  Widget _editableField({
    required String label,
    required bool mandatory,
    required TextEditingController controller,
    required Function(String) onChanged,
    bool enabled = true,
    TextInputType keyboard = TextInputType.text,
    int? minLines,
    int? maxLines,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboard,
      minLines: minLines,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: mandatory ? Colors.grey : Colors.grey.shade300),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      onChanged: onChanged,
    );
  }

  Widget _readOnlyField(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(value, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

