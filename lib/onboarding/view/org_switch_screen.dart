import 'package:flutter/material.dart';
import 'package:my_app/onboarding/controller/org_switch_controller.dart';
import 'package:provider/provider.dart';

import 'package:my_app/route/route_constants.dart';

class OrgSwitcherScreen extends StatefulWidget {
  const OrgSwitcherScreen({super.key});

  @override
  State<OrgSwitcherScreen> createState() => _OrgSwitcherScreenState();
}

class _OrgSwitcherScreenState extends State<OrgSwitcherScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OrgSwitcherController>().load();
  }

  Widget build(BuildContext context) {
    final controller = context.watch<OrgSwitcherController>();
    final state = controller.state;

    if (state is OrgSwitcherLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is OrgSwitcherError) {
      return Center(child: Text("Error: ${state.message}"));
    }

    if (state is OrgSwitcherLoaded) {
      final orgIds = state.orgIds;

      return ListView.builder(
        itemCount: orgIds.length,
        itemBuilder: (context, index) {
          final orgId = orgIds[index];

          return ListTile(
            title: Text("Organization $orgId"),
            onTap: () => controller.selectOrg(orgId),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

}
