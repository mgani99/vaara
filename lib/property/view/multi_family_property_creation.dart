import 'package:flutter/material.dart';
import 'package:my_app/route/route_constants.dart';

class MultiFamilyPropertyCreationScreen extends StatefulWidget {
  const MultiFamilyPropertyCreationScreen({super.key});

  @override
  State<MultiFamilyPropertyCreationScreen> createState() =>
      _MultiFamilyPropertyCreationScreenState();
}

class _MultiFamilyPropertyCreationScreenState
    extends State<MultiFamilyPropertyCreationScreen> {
  final nameCtrl = TextEditingController();
  final addressCtrl = TextEditingController();

  List<UnitFormModel> units = [];

  void addUnit() {
    setState(() {
      units.add(UnitFormModel());
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Add Multi-Family Property")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ------------------------------------------------------------
          // PROPERTY INFO
          // ------------------------------------------------------------
          Text("Property Info", style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),

          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: "Property Name"),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: addressCtrl,
            decoration: const InputDecoration(labelText: "Address"),
          ),

          const SizedBox(height: 20),

          // ------------------------------------------------------------
          // UNITS SECTION
          // ------------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Units", style: theme.textTheme.titleMedium),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: addUnit,
              ),
            ],
          ),

          ...units.map((unit) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButton<String>(
                    value: unit.type,
                    items: const [
                      DropdownMenuItem(
                        value: "residential",
                        child: Text("Residential"),
                      ),
                      DropdownMenuItem(
                        value: "commercial",
                        child: Text("Commercial"),
                      ),
                      DropdownMenuItem(
                        value: "parking",
                        child: Text("Parking"),
                      ),
                      DropdownMenuItem(
                        value: "storage",
                        child: Text("Storage"),
                      ),
                      DropdownMenuItem(
                        value: "garage",
                        child: Text("Garage"),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() => unit.type = v!);
                    },
                  ),

                  TextField(
                    decoration: const InputDecoration(labelText: "Unit Name"),
                    onChanged: (v) => unit.name = v,
                  ),

                  if (unit.type == "residential") ...[
                    TextField(
                      decoration: const InputDecoration(labelText: "Bedrooms"),
                      onChanged: (v) => unit.bedrooms = int.tryParse(v),
                    ),
                    TextField(
                      decoration: const InputDecoration(labelText: "Bathrooms"),
                      onChanged: (v) => unit.bathrooms = double.tryParse(v),
                    ),
                    TextField(
                      decoration: const InputDecoration(labelText: "Sqft"),
                      onChanged: (v) => unit.sqft = double.tryParse(v),
                    ),
                  ],

                  if (unit.type == "commercial") ...[
                    TextField(
                      decoration: const InputDecoration(labelText: "Sqft"),
                      onChanged: (v) => unit.sqft = double.tryParse(v),
                    ),
                  ],

                  if (unit.type == "parking") ...[
                    TextField(
                      decoration: const InputDecoration(labelText: "Stall Number"),
                      onChanged: (v) => unit.stallNumber = v,
                    ),
                  ],

                  if (unit.type == "storage") ...[
                    TextField(
                      decoration: const InputDecoration(labelText: "Storage Size"),
                      onChanged: (v) => unit.storageSize = v,
                    ),
                  ],

                  if (unit.type == "garage") ...[
                    TextField(
                      decoration: const InputDecoration(labelText: "Garage Type"),
                      onChanged: (v) => unit.garageType = v,
                    ),
                  ],
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {
              // TODO: Save property + units
            },
            child: const Text("Save Property"),
          ),
        ],
      ),
    );
  }
}

class UnitFormModel {
  String type = "residential";
  String name = "";
  int? bedrooms;
  double? bathrooms;
  double? sqft;
  String? stallNumber;
  String? storageSize;
  String? garageType;
}
