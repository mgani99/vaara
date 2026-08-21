import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_app/session/app_data.dart';
import 'package:my_app/route/route_constants.dart';

enum PropertyExperience { newLandlord, experiencedLandlord }
enum PortfolioSize { oneToThree, fourToTen, moreThanTen }
enum ManagementStyle { selfManage, propertyManager }

class LandlordOnboardingScreen extends StatefulWidget {
  const LandlordOnboardingScreen({super.key});

  @override
  State<LandlordOnboardingScreen> createState() =>
      _LandlordOnboardingScreenState();
}

class _LandlordOnboardingScreenState extends State<LandlordOnboardingScreen> {
  final PageController _controller = PageController();

  PropertyExperience? _experience;
  PortfolioSize? _portfolioSize;
  ManagementStyle? _managementStyle;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final orgId = session.activeOrgId ?? "N/A";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome, Landlord"),
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
                    _page(_step1Welcome()),
                    _page(_step2Experience()),
                    _page(_step3Portfolio()),
                    _page(_step4ManagementStyle()),
                    _page(_step5Complete(orgId)),
                  ],
                ),
              ),
            ],
          ),

          // FOOTER FIXED TO BOTTOM
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildFooter(),
          ),
        ],
      ),

    );
  }
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

  // HEADER
  Widget _buildHeader() {
    return Column(
      children: const [
        LinearProgressIndicator(
          value: 0.2,
          minHeight: 6,
          backgroundColor: Colors.grey,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlue),
        ),
        SizedBox(height: 16),
        Divider(height: 1),
      ],
    );
  }

  // FOOTER

  Widget _buildFooter() {
    return Container(
      width: double.infinity,            // <-- FIX: give width constraints
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500), // <-- FIX
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
                        if (_currentStep < 4) {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        } else {
                          Navigator.pushNamed(
                            context,
                            propertyCreationRoute,
                          );
                        }
                      },
                      child: Text(_currentStep == 4 ? "Add Property" : "Next"),
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

  // STEP 1 — Welcome
  Widget _step1Welcome() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: const [
      Text(
        "Welcome to Rental.AI",
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 12),
      Text(
        "Let's learn a bit about your rental business so we can tailor your dashboard.",
        style: TextStyle(fontSize: 16),
      ),
    ],
  );

  // STEP 2 — Experience
  Widget _step2Experience() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "How experienced are you as a landlord?",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 16),
      RadioListTile<PropertyExperience>(
        title: const Text("I'm new to landlording"),
        value: PropertyExperience.newLandlord,
        groupValue: _experience,
        onChanged: (v) => setState(() => _experience = v),
      ),
      RadioListTile<PropertyExperience>(
        title: const Text("I've been managing rentals for years"),
        value: PropertyExperience.experiencedLandlord,
        groupValue: _experience,
        onChanged: (v) => setState(() => _experience = v),
      ),
    ],
  );

  // STEP 3 — Portfolio Size
  Widget _step3Portfolio() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "How many properties do you own?",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 16),
      RadioListTile<PortfolioSize>(
        title: const Text("1–3 properties"),
        value: PortfolioSize.oneToThree,
        groupValue: _portfolioSize,
        onChanged: (v) => setState(() => _portfolioSize = v),
      ),
      RadioListTile<PortfolioSize>(
        title: const Text("4–10 properties"),
        value: PortfolioSize.fourToTen,
        groupValue: _portfolioSize,
        onChanged: (v) => setState(() => _portfolioSize = v),
      ),
      RadioListTile<PortfolioSize>(
        title: const Text("More than 10"),
        value: PortfolioSize.moreThanTen,
        groupValue: _portfolioSize,
        onChanged: (v) => setState(() => _portfolioSize = v),
      ),
    ],
  );

  // STEP 4 — Management Style
  Widget _step4ManagementStyle() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "How do you manage your rentals?",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 16),
      RadioListTile<ManagementStyle>(
        title: const Text("I self-manage everything"),
        value: ManagementStyle.selfManage,
        groupValue: _managementStyle,
        onChanged: (v) => setState(() => _managementStyle = v),
      ),
      RadioListTile<ManagementStyle>(
        title: const Text("I work with a property manager"),
        value: ManagementStyle.propertyManager,
        groupValue: _managementStyle,
        onChanged: (v) => setState(() => _managementStyle = v),
      ),
    ],
  );

  // STEP 5 — Complete
  Widget _step5Complete(String orgId) => Column(
    children: [
      const Icon(Icons.check_circle, size: 60, color: Colors.green),
      const SizedBox(height: 16),
      const Text(
        "You're all set!",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Text("Org ID: $orgId"),
      const SizedBox(height: 24),
      const Text(
        "Let's add your first property to get started.",
        style: TextStyle(fontSize: 16),
      ),
    ],
  );

}
