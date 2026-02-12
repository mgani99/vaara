import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_app/onboarding/service/address_lookup_service.dart';
import 'package:my_app/onboarding/service/landlord_onboarding_service.dart';
import 'package:my_app/session/app_data.dart';
import 'package:my_app/route/route_constants.dart';

class LandlordOnboardingScreen extends StatefulWidget {
  const LandlordOnboardingScreen({super.key});

  @override
  State<LandlordOnboardingScreen> createState() =>
      _LandlordOnboardingScreenState();
}

class _LandlordOnboardingScreenState extends State<LandlordOnboardingScreen> {
  final PageController _controller = PageController();
  int _step = 0;
  bool _loading = false;

  String? _propertyId;
  String? _unitId;

  final _propertyName = TextEditingController();
  final _propertyAddress = TextEditingController();
  final _unitName = TextEditingController();
  final _unitRent = TextEditingController();
  final _tenantEmail = TextEditingController();
  final _coOwnerEmail = TextEditingController();

  List<AddressResult> _addressSuggestions = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _propertyName.dispose();
    _propertyAddress.dispose();
    _unitName.dispose();
    _unitRent.dispose();
    _tenantEmail.dispose();
    _coOwnerEmail.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onAddressChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (value.trim().isEmpty) {
        setState(() => _addressSuggestions = []);
        return;
      }
      setState(() => _isSearching = true);
      try {
        final service = context.read<AddressLookupService>();
        final results = await service.search(value);
        setState(() => _addressSuggestions = results);
      } finally {
        setState(() => _isSearching = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final orgId = session.activeOrgId ?? "N/A";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Landlord Onboarding"),
        backgroundColor: Colors.lightBlue,
        elevation: 0,
        leading: _step > 0 && _step < 4
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _loading ? null : _handleBack,
        )
            : null,
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
                    _page(_step2Unit()),
                    _page(_step3Tenant()),
                    _page(_step4CoOwner()),
                    _page(_step5Complete(orgId)),
                  ],
                ),
              ),
              _buildFixedControlBar(),
            ],
          ),
          if (_loading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    double progress = (_step + 1) / 5;
    const titles = ["Property", "Unit", "Tenant", "Co-Owner", "Complete"];

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          minHeight: 6,
          backgroundColor: Colors.grey.shade200,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.lightBlue),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.lightBlue,
                child: Text("${_step + 1}",
                    style: const TextStyle(fontSize: 12, color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Text(
                titles[_step],
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildFixedControlBar() {
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
                  if (_step > 0 && _step < 4)
                    TextButton(
                      onPressed: _loading ? null : _handleBack,
                      child: const Text("Back"),
                    ),
                  const Spacer(),
                  SizedBox(
                    width: 120,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _handleContinue,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(_step == 4 ? "Finish" : "Next"),
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

  // ------------------------------------------------------------
  // STEP CONTENT
  // ------------------------------------------------------------
  Widget _step1Property() => Column(children: [
    TextField(
      controller: _propertyName,
      decoration: const InputDecoration(labelText: "Property Name"),
    ),
    const SizedBox(height: 16),
    TextField(
      controller: _propertyAddress,
      onChanged: _onAddressChanged,
      decoration: InputDecoration(
        labelText: "Address",
        suffixIcon: _isSearching
            ? const Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : null,
      ),
    ),
    if (_addressSuggestions.isNotEmpty)
      ..._addressSuggestions.map(
            (a) => ListTile(
          title: Text(a.displayName),
          onTap: () {
            setState(() {
              _propertyAddress.text = a.displayName;
              _addressSuggestions = [];
            });
          },
        ),
      ),
  ]);

  Widget _step2Unit() => Column(children: [
    TextField(
      controller: _unitName,
      decoration: const InputDecoration(labelText: "Unit Name"),
    ),
    const SizedBox(height: 16),
    TextField(
      controller: _unitRent,
      decoration: const InputDecoration(labelText: "Rent"),
      keyboardType: TextInputType.number,
    ),
  ]);

  Widget _step3Tenant() => TextField(
    controller: _tenantEmail,
    decoration: const InputDecoration(labelText: "Tenant Email"),
  );

  Widget _step4CoOwner() => TextField(
    controller: _coOwnerEmail,
    decoration:
    const InputDecoration(labelText: "Co-Owner Email (Optional)"),
  );

  Widget _step5Complete(String id) => Column(children: [
    const Icon(Icons.check_circle, size: 60, color: Colors.green),
    const Text("All Set!",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    Text("Org ID: $id"),
  ]);

  // ------------------------------------------------------------
  // LOGIC
  // ------------------------------------------------------------
  Future<void> _handleContinue() async {
    final onboarding = context.read<LandlordOnboardingService>();

    try {
      setState(() => _loading = true);

      if (_step == 0) {
        _propertyId = await onboarding.createProperty(
          name: _propertyName.text.trim(),
          address: _propertyAddress.text.trim(),
          type: "single_family", // default for now
        );
      } else if (_step == 1) {
        _unitId = await onboarding.createUnit(
          propertyId: _propertyId!,
          name: _unitName.text.trim(),
          rent: double.tryParse(_unitRent.text.trim()) ?? 0,
        );
      } else if (_step == 2 && _tenantEmail.text.isNotEmpty) {
        await onboarding.inviteTenant(
          email: _tenantEmail.text.trim(),
          propertyId: _propertyId!,
          unitId: _unitId!,
        );
      } else if (_step == 3 && _coOwnerEmail.text.isNotEmpty) {
        await onboarding.inviteCoOwner(
          email: _coOwnerEmail.text.trim(),
        );
      } else if (_step == 4) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          homeRoute,
              (r) => false,
        );
        return;
      }

      setState(() {
        _step++;
        _controller.animateToPage(
          _step,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _handleBack() {
    setState(() {
      _step--;
      _controller.animateToPage(
        _step,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }
}
