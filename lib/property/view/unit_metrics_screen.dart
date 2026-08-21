import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_app/session/app_data.dart';
import 'package:my_app/property/service/unit_service.dart';
import 'package:my_app/property/domain/property_model.dart';

class UnitMetricsScreen extends StatefulWidget {
  final String unitId;

  const UnitMetricsScreen({super.key, required this.unitId});

  @override
  State<UnitMetricsScreen> createState() => _UnitMetricsScreenState();
}

class _UnitMetricsScreenState extends State<UnitMetricsScreen> {
  late UnitModel unit;
  bool editing = false;

  late TextEditingController sqftController;
  late int bedrooms;
  late double bathrooms;

  @override
  void initState() {
    super.initState();

    final session = context.read<AppSession>();
    unit = session.unitCache[widget.unitId]!;

    bedrooms = unit.bedrooms ?? 0;
    bathrooms = unit.bathrooms ?? 0.0;

    sqftController = TextEditingController(
      text: unit.sqft != null ? unit.sqft!.toStringAsFixed(0) : "",
    );

    // 🔥 Auto‑editable if values missing
    if ((unit.sqft ?? 0) == 0 || (unit.bedrooms ?? 0) == 0 || (unit.bathrooms ?? 0.0) == 0.0) {
      editing = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();

    return Scaffold(
      appBar: AppBar(
        title: Text("Unit Details - ${unit.name}", style: const TextStyle(fontSize: 14)),
        actions: [
          IconButton(
            icon: Icon(editing ? Icons.close : Icons.edit, color: Colors.black87),
            onPressed: () => setState(() => editing = !editing),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _metricsCard(),

            const SizedBox(height: 20),

            if (editing)
              ElevatedButton(
                onPressed: _saveMetrics,
                child: const Text("Save Metrics", style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // METRICS CARD
  // ------------------------------------------------------------
  Widget _metricsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Metrics", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // SQFT
          editing
              ? TextField(
            controller: sqftController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Sqft",
              border: OutlineInputBorder(),
            ),
          )
              : Text("Sqft: ${unit.sqft?.toStringAsFixed(0) ?? "0"}"),

          const SizedBox(height: 20),

          // BEDROOMS
          editing
              ? _incrementField(
            label: "Bedrooms",
            valueText: "$bedrooms",
            onIncrement: () => setState(() => bedrooms++),
            onDecrement: () => setState(() {
              if (bedrooms > 0) bedrooms--;
            }),
          )
              : Text("Bedrooms: ${unit.bedrooms ?? 0}"),

          const SizedBox(height: 20),

          // BATHROOMS
          editing
              ? _incrementField(
            label: "Bathrooms",
            valueText: bathrooms.toStringAsFixed(1),
            onIncrement: () => setState(() => bathrooms += 0.5),
            onDecrement: () => setState(() {
              if (bathrooms > 0) bathrooms -= 0.5;
            }),
          )
              : Text("Bathrooms: ${unit.bathrooms?.toStringAsFixed(1) ?? "0.0"}"),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // INCREMENT FIELD
  // ------------------------------------------------------------
  Widget _incrementField({
    required String label,
    required String valueText,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(onTap: onDecrement, child: const Icon(Icons.remove_circle_outline, size: 22)),
              Text(valueText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              InkWell(onTap: onIncrement, child: const Icon(Icons.add_circle_outline, size: 22)),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // SAVE METRICS
  // ------------------------------------------------------------
  Future<void> _saveMetrics() async {
    final session = context.read<AppSession>();
    final unitService = context.read<UnitService>();

    final double? newSqft = double.tryParse(sqftController.text);

    final updated = unit.copyWith(
      sqft: newSqft,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
    );

    await unitService.repo.updateUnit(updated);

    session.unitCache[unit.unitId] = updated;
    session.notifyListeners();

    Navigator.pop(context);
  }
}
