import 'package:flutter/material.dart';
import 'package:my_app/login/controller/tenant_invite_controller.dart';
import 'package:my_app/route/route_constants.dart';
import 'package:provider/provider.dart';

class TenantInviteScreen extends StatefulWidget {
  final Map<String, dynamic> invite;

  const TenantInviteScreen({super.key, required this.invite});

  @override
  State<TenantInviteScreen> createState() => _TenantInviteScreenState();
}

class _TenantInviteScreenState extends State<TenantInviteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TenantInviteController>().loadInviteDetails(widget.invite);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TenantInviteController>();
    final state = controller.state;

    if (state is TenantInviteAccepted) {
      print('in screen accepted');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          homeRoute,
              (route) => false,
        );
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Invitation")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _buildContent(controller, state),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(TenantInviteController controller, TenantInviteState state) {
    if (state is TenantInviteLoading || state is TenantInviteIdle) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is TenantInviteError) {
      return Text("Error: ${state.message}");
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.mail, size: 64, color: Colors.blue),
        const SizedBox(height: 16),
        Text(
          "You’ve been invited to join:",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),

        Text("Organization: ${controller.orgName ?? 'Loading...'}"),
        Text("Property: ${controller.propertyName ?? 'Loading...'}"),
        Text("Unit: ${controller.unitName ?? 'Loading...'}"),

        const SizedBox(height: 24),

        ElevatedButton(
          onPressed: () => controller.accept(widget.invite),
          child: const Text("Accept Invitation"),
        ),
        const SizedBox(height: 12),

        TextButton(
          onPressed: () => controller.decline(widget.invite["inviteId"]),
          child: const Text("Decline"),
        ),
      ],
    );
  }
}
