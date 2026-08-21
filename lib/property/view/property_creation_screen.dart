import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_app/onboarding/service/address_lookup_service.dart';
import 'package:my_app/session/app_data.dart';

import '../controller/property_creation_controller.dart';
import '../domain/property_type.dart';

class PropertyCreationScreen extends StatefulWidget {
  const PropertyCreationScreen({super.key});

  @override
  State<PropertyCreationScreen> createState() => _PropertyCreationScreenState();
}

class _PropertyCreationScreenState extends State<PropertyCreationScreen> {
  final PageController _controller = PageController();
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();

    _controller.addListener(() {
      final page = _controller.page;
      if (page != null && mounted) {
        setState(() => _currentStep = page.round());
      }
    });
  }

  // Required fields
  final _propertyName = TextEditingController();
  final _fullAddressCtrl = TextEditingController();

  // Parsed fields (hidden)
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();

  // Optional fields
  final _numUnitsCtrl = TextEditingController();
  final _sqftCtrl = TextEditingController();
  final _buildingTypeCtrl = TextEditingController();
  final _rentCtrl = TextEditingController();
  final _tenantNameCtrl = TextEditingController();
  final _tenantEmailCtrl = TextEditingController();

  PropertyType _propertyType = PropertyType.sfm;

  List<AddressResult> _addressSuggestions = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _propertyName.dispose();
    _fullAddressCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _numUnitsCtrl.dispose();
    _sqftCtrl.dispose();
    _buildingTypeCtrl.dispose();
    _rentCtrl.dispose();
    _tenantNameCtrl.dispose();
    _tenantEmailCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ------------------------------------------------------------
  // USPS AUTOCOMPLETE
  // ------------------------------------------------------------
  void _onAddressChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;

      if (value.trim().isEmpty) {
        setState(() => _addressSuggestions = []);
        return;
      }

      setState(() => _isSearching = true);

      try {
        final service = context.read<AddressLookupService>();
        final results = await service.search(value);

        if (!mounted) return;

        setState(() => _addressSuggestions = results);
      } finally {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  // ------------------------------------------------------------
  // SELECT ADDRESS → SHOW MODAL WITH PARSED FIELDS
  // ------------------------------------------------------------
  void _selectAddress(AddressResult result) {
    _fullAddressCtrl.text = result.formatted;

    _streetCtrl.text = result.street;
    _cityCtrl.text = result.city;
    _stateCtrl.text = result.state;

    _addressSuggestions = [];

    // Auto-fill property name
    _propertyName.text = extractStreetName(result.street);

    _showAddressConfirmationModal();
  }

  // ------------------------------------------------------------
  // MODAL CONFIRMATION
  // ------------------------------------------------------------
  void _showAddressConfirmationModal() {
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
                "Confirm Address",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              _confirmEditableField("Street Address", _streetCtrl),
              const SizedBox(height: 12),

              _confirmEditableField("City", _cityCtrl),
              const SizedBox(height: 12),

              _confirmEditableField("State", _stateCtrl),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () {
                  final abbr = abbreviateState(_stateCtrl.text.trim());
                  final full = "${_streetCtrl.text.trim()}, ${_cityCtrl.text.trim()}, $abbr";

                  setState(() {
                    _fullAddressCtrl.text = full;
                    _addressSuggestions = [];   // ⭐ hide suggestions
                  });

                  Navigator.pop(context);
                },
                child: const Text("Confirm"),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: _manualAddressEntry,
                child: const Text("Enter Address Manually"),
              ),
            ],
          ),
        );
      },
    );
  }


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

  Widget _confirmField(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              )),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // UI BUILD
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PropertyCreationController>();
    final session = context.watch<AppSession>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Property"),
        backgroundColor: Colors.lightBlue,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: PageView(
                  controller: _controller,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _page(_step1Property()),
                    _page(_step2Units()),
                    _page(_step3Review(session)),
                  ],
                ),
              ),
              _buildFooter(),
            ],
          ),

          if (controller.saving)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _page(Widget child) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: child,
        ),
      ),
    );
  }

  // HEADER
  Widget _buildHeader() {
    return Column(
      children: const [
        SizedBox(height: 16),
        Text(
          "Property Setup",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Divider(height: 1),
      ],
    );
  }

  // FOOTER
  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () {
                      if (_currentStep > 0) {
                        _controller.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text("Back"),
                  ),
                  const Spacer(),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentStep < 2) {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        } else {
                          _finishCreation();
                        }
                      },
                      child: Text(_currentStep == 2 ? "Finish" : "Next"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _finishCreation() async {
    final controller = context.read<PropertyCreationController>();
    final session = context.read<AppSession>();

    await _saveProperty(controller, session);
  }

  // ------------------------------------------------------------
  // STEP 1 — Property Type + Address + Name + Rent
  // ------------------------------------------------------------
  Widget _step1Property() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Property Type *",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      DropdownButtonFormField<PropertyType>(
        value: _propertyType,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
        ),
        items: PropertyType.values
            .map(
              (t) => DropdownMenuItem(
            value: t,
            child: Text(mapPropertyType(t)),
          ),
        )
            .toList(),
        onChanged: (val) {
          if (val == null) return;
          setState(() => _propertyType = val);
        },
      ),

      const SizedBox(height: 24),

      // FULL ADDRESS FIELD
      TextField(
        controller: _fullAddressCtrl,
        onChanged: _onAddressChanged,
        decoration: const InputDecoration(
          labelText: "Search Address *",
          border: OutlineInputBorder(),
        ),
      ),

      if (_addressSuggestions.isNotEmpty)
        ..._addressSuggestions.map(
              (a) => ListTile(
            title: Text(a.formatted),
            onTap: () => _selectAddress(a),
          ),
        ),

      const SizedBox(height: 24),

      TextField(
        controller: _propertyName,
        decoration: const InputDecoration(
          labelText: "Property Name *",
          border: OutlineInputBorder(),
        ),
      ),

      const SizedBox(height: 24),

      if (_propertyType == PropertyType.sfm) ...[
        TextField(
          controller: _rentCtrl,
          decoration: const InputDecoration(
            labelText: "Rent (Optional)",
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
        ),

        if (_rentCtrl.text.trim().isNotEmpty) ...[
          const SizedBox(height: 24),

          TextField(
            controller: _tenantNameCtrl,
            decoration: const InputDecoration(
              labelText: "Tenant Name *",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _tenantEmailCtrl,
            decoration: const InputDecoration(
              labelText: "Tenant Email *",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ],

      if (_propertyType == PropertyType.multifamily) ...[
        TextField(
          controller: _numUnitsCtrl,
          decoration: const InputDecoration(
            labelText: "Number of Units",
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
      ],

      if (_propertyType == PropertyType.commercial) ...[
        TextField(
          controller: _buildingTypeCtrl,
          decoration: const InputDecoration(
            labelText: "Building Type",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _sqftCtrl,
          decoration: const InputDecoration(
            labelText: "Total Sq Ft",
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    ],
  );

  // STEP 2 — Units
  Widget _step2Units() {
    if (_propertyType == PropertyType.sfm) {
      return const Center(
        child: Text(
          "Single-family properties have one unit.\nUnit will be created automatically.",
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          "Units",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        Text(
          "Multi-family and commercial properties support multiple units.\n"
              "Unit creation will be handled after property creation.",
        ),
      ],
    );
  }

  // STEP 3 — Review
  Widget _step3Review(AppSession session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Review Property",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        Text("Name: ${_propertyName.text}"),
        Text("Address: ${_fullAddressCtrl.text}"),   // ⭐ FIXED
        Text("Type: ${mapPropertyType(_propertyType)}"),

        if (_propertyType == PropertyType.sfm)
          Text("Rent: ${_rentCtrl.text}"),

        if (_propertyType == PropertyType.multifamily)
          Text("Units: ${_numUnitsCtrl.text}"),

        if (_propertyType == PropertyType.commercial) ...[
          Text("Building Type: ${_buildingTypeCtrl.text}"),
          Text("Sq Ft: ${_sqftCtrl.text}"),
        ],
      ],
    );
  }
  void _manualAddressEntry() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Enter Full Address"),
              const SizedBox(height: 20),

              TextField(
                controller: _fullAddressCtrl,
                decoration: const InputDecoration(
                  labelText: "Full Address",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () async {
                  final validated = await _validateWithUSPS(_fullAddressCtrl.text);

                  if (validated != null) {
                    _streetCtrl.text = validated.street;
                    _cityCtrl.text = validated.city;
                    _stateCtrl.text = validated.state;

                    Navigator.pop(context);
                    _showAddressConfirmationModal();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Address validation failed")),
                    );
                  }
                },
                child: const Text("Validate"),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<AddressResult?> _validateWithUSPS(String fullAddress) async {
    final service = context.read<AddressLookupService>();
    final results = await service.search(fullAddress);

    if (results.isEmpty) return null;
    return results.first;
  }

  // ------------------------------------------------------------
  // SAVE PROPERTY
  // ------------------------------------------------------------
  Future<void> _saveProperty(
      PropertyCreationController ctrl, AppSession session) async {
    final rentValue = double.tryParse(_rentCtrl.text);

    // VALIDATION ONLY WHEN RENT IS ENTERED
    if (_propertyType == PropertyType.sfm && rentValue != null) {
      if (_tenantNameCtrl.text.trim().isEmpty ||
          _tenantEmailCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Tenant name and email are required when rent is entered."),
          ),
        );
        return;
      }
    }

    // Continue with property creation
    final propertyId = await ctrl.createProperty(
      session: session,
      name: _propertyName.text.trim(),
      address: _streetCtrl.text.trim(),   // ⭐ structured fields
      city: _cityCtrl.text.trim(),
      state: _stateCtrl.text.trim(),
      type: mapPropertyType(_propertyType),
      rent: rentValue,
      numUnits: int.tryParse(_numUnitsCtrl.text),
      sqft: double.tryParse(_sqftCtrl.text),
      buildingType: _buildingTypeCtrl.text.trim(),
      tenantName: _tenantNameCtrl.text.trim(),
      tenantEmail: _tenantEmailCtrl.text.trim(),
    );

    if (!mounted) return;
    Navigator.pop(context, propertyId);
  }
}
