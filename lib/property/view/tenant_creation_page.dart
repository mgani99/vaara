import 'dart:io' as io;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:my_app/property/domain/property_model.dart';
import 'package:my_app/property/service/tenant_service.dart';
import 'package:my_app/session/app_data.dart';
import '../../screens/view_util.dart';

enum TenantPageMode { create, edit, view }

class TenantCreationPage extends StatefulWidget {
  final String tenantId;
  final String leaseId;
  final TenantPageMode mode;

  const TenantCreationPage({
    super.key,
    required this.tenantId,
    required this.leaseId,
    required this.mode,
  });

  @override
  State<TenantCreationPage> createState() => _TenantCreationPageState();
}

class _TenantCreationPageState extends State<TenantCreationPage> {
  bool financialOpen = false;

  io.File? dlImageFile;
  Uint8List? dlImageBytes;
  String dlImageUrl = "";
  ImageProvider? dlImage;

  String tenantRole = "Lease Holder";   // default


  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  final TextEditingController bankController = TextEditingController();
  final TextEditingController accountController = TextEditingController();
  final TextEditingController zelleController = TextEditingController();

  late bool isReadOnly;

  bool get isCreate => widget.mode == TenantPageMode.create;

  late LeaseDetailsModel lease;
  @override
  void initState() {
    super.initState();

    isReadOnly = widget.mode == TenantPageMode.view;

    if (!isCreate) {
      _loadExistingTenant();
      financialOpen = true;
    }
  }

  void _loadExistingTenant() {
    final session = context.read<AppSession>();
    final tenant = session.tenantCache[widget.tenantId];
    lease = session.currentLeaseCache[widget.leaseId]!;
    if (tenant == null) return;

    nameController.text = tenant.name;
    emailController.text = tenant.email;
    phoneController.text = tenant.phone;

    bankController.text = tenant.bankName ?? "";
    accountController.text = tenant.accountNumber ?? "";
    zelleController.text = tenant.zelleId ?? "";

    dlImageUrl = tenant.dlImageUrl;

    if (dlImageUrl.isNotEmpty) {
      dlImage = NetworkImage(dlImageUrl);
    }
    // 🔥 Load role from lease
    if (lease != null) {
      tenantRole = lease.tenantRoles[widget.tenantId] ?? "Lease Holder";
    }
  }


  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();

    final String title =
    isCreate ? "New Tenant" : isReadOnly ? "Tenant Details" : "Edit Tenant";

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (!isCreate && isReadOnly)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() => isReadOnly = false);
              },
            ),

          if (!isCreate && !isReadOnly)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final tenant = session.tenantCache[widget.tenantId];
                if (tenant != null) {
                  await _softDeleteTenantFromLease(tenant);
                }
              },
            ),
        ],
      ),

      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 12),
          _buildContactInfoCard(),
          const SizedBox(height: 12),
          _buildFinancialSection(),
          const SizedBox(height: 20),

          if (!isReadOnly)
            _buildSaveButton(session),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // CONTACT INFO
  Widget _buildContactInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: GestureDetector(
              onTap: isReadOnly ? null : _pickDLImage,
              child: ClipOval(
                child: Container(
                  width: 90,
                  height: 90,
                  color: Colors.blue.shade100,
                  child: dlImage == null
                      ? Icon(Icons.camera_alt,
                      size: 32, color: Colors.blue.shade700)
                      : Image(image: dlImage!, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          _inputField(
            label: "Full Name *",
            controller: nameController,
            required: true,
            readOnly: isReadOnly,
          ),
          const SizedBox(height: 12),

          _inputField(
            label: "Email *",
            controller: emailController,
            required: true,
            readOnly: isReadOnly,
            inputFormatters: [EmailFormatter()],
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),

          _inputField(
            label: "Phone",
            controller: phoneController,
            readOnly: isReadOnly,
            inputFormatters: [PhoneFormatter()],
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),

          Text(
            "Tenant Role",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              ChoiceChip(
                label: const Text("Lease Holder"),
                selected: tenantRole == "Lease Holder",
                onSelected: isReadOnly ? null : (_) {
                  setState(() => tenantRole = "Lease Holder");
                },
              ),
              const SizedBox(width: 10),
              ChoiceChip(
                label: const Text("Occupant"),
                selected: tenantRole == "Occupant",
                onSelected: isReadOnly ? null : (_) {
                  setState(() => tenantRole = "Occupant");
                },
              ),
            ],
          ),

        ],
      ),
    );
  }

  // FINANCIAL SECTION
  Widget _buildFinancialSection() {
    return _sectionBox(
      title: "Financial Info",
      child: financialOpen
          ? Column(
        children: [
          _inputField(
            label: "Bank Name",
            controller: bankController,
            readOnly: isReadOnly,
          ),
          const SizedBox(height: 12),

          _inputField(
            label: "Account Number",
            controller: accountController,
            readOnly: isReadOnly,
          ),
          const SizedBox(height: 12),

          _inputField(
            label: "Zelle ID",
            controller: zelleController,
            readOnly: isReadOnly,
          ),
        ],
      )
          : const SizedBox.shrink(),
      trailing: _chevron(financialOpen, () {
        setState(() => financialOpen = !financialOpen);
      }),
      onToggle: () => setState(() => financialOpen = !financialOpen),
    );
  }

  Widget _sectionBox({
    required String title,
    required Widget child,
    required Widget trailing,
    required VoidCallback onToggle,
  }) {
    final bool isOpen = child is! SizedBox;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                trailing,
              ],
            ),
          ),
          if (isOpen) const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  // SAVE BUTTON
  Widget _buildSaveButton(AppSession session) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
        onPressed: () => _saveTenant(session),
        child: Text(isCreate ? "Save Tenant" : "Save Changes"),
      ),
    );
  }

  // INPUT FIELD
  Widget _inputField({
    required String label,
    required TextEditingController controller,
    bool required = false,
    bool readOnly = false,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            isDense: true,
            border: const OutlineInputBorder(),
            errorText: required && controller.text.isEmpty ? "Required" : null,
          ),
        ),
      ],
    );
  }

  Widget _chevron(bool open, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        open ? Icons.expand_less : Icons.expand_more,
        size: 22,
        color: Colors.black54,
      ),
    );
  }

  // PICK IMAGE
  void _pickDLImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    if (kIsWeb) {
      dlImageBytes = await picked.readAsBytes();
      dlImage = MemoryImage(dlImageBytes!);
    } else {
      dlImageFile = io.File(picked.path);
      dlImage = FileImage(dlImageFile!);
    }

    setState(() {});
  }

  // SAVE TENANT
  void _saveTenant(AppSession session) async {
    if (nameController.text.isEmpty || emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name and Email are required")),
      );
      return;
    }

    final tenantService = context.read<TenantService>();
    final lease = session.currentLeaseCache[widget.leaseId];

    // ------------------------------------------------------------
    // UPDATE EXISTING TENANT
    // ------------------------------------------------------------
    if (!isCreate) {
      final existing = session.tenantCache[widget.tenantId];
      if (existing == null) return;

      final updatedTenant = existing.copyWith(
        name: nameController.text,
        email: emailController.text,
        phone: phoneController.text,
        bankName: bankController.text,
        accountNumber: accountController.text,
        zelleId: zelleController.text,
        dlImageUrl: dlImageUrl,
      );

      // Update tenant in DB
      await tenantService.updateTenant(updatedTenant);

      // Update cache
      session.tenantCache[updatedTenant.tenantId] = updatedTenant;

      // 🔥 Update tenant role in lease
      if (lease != null) {
        final updatedRoles = Map<String, String>.from(lease.tenantRoles);
        updatedRoles[updatedTenant.tenantId] = tenantRole;

        final updatedLease = lease.copyWith(
          tenantRoles: updatedRoles,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        await session.leaseRepo.updateLease(updatedLease);
        session.currentLeaseCache[lease.leaseId] = updatedLease;
      }

      Navigator.pop(context, "tenant_updated");
      return;
    }

    // ------------------------------------------------------------
    // CREATE NEW TENANT
    // ------------------------------------------------------------
    final newTenant = TenantModel(
      tenantId: UniqueKey().toString(),
      orgId: session.activeOrgId!,
      name: nameController.text,
      email: emailController.text,
      phone: phoneController.text,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      bankName: bankController.text,
      accountNumber: accountController.text,
      zelleId: zelleController.text,
      dlImageUrl: dlImageUrl,
    );

    // Save tenant to DB
    final tenantId = await tenantService.createTenant(newTenant);

    // Update cache
    session.tenantCache[newTenant.tenantId] = newTenant;

    // 🔥 Attach tenant to lease + role
    if (lease != null) {
      final updatedTenantIds = [...lease.tenantIds, tenantId];

      final updatedRoles = Map<String, String>.from(lease.tenantRoles);
      updatedRoles[tenantId] = tenantRole;

      final updatedLease = lease.copyWith(
        tenantIds: updatedTenantIds,
        tenantRoles: updatedRoles,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      await session.leaseRepo.updateLease(updatedLease);
      session.currentLeaseCache[lease.leaseId] = updatedLease;
    }
    session.updateTenantInCache(newTenant);
    Navigator.pop(context, "tenant_added");
  }


  // SOFT DELETE TENANT
  Future<void> _softDeleteTenantFromLease(TenantModel tenant) async {
    final session = context.read<AppSession>();

    final lease = session.currentLeaseCache[widget.leaseId];
    if (lease == null) return;

    final updatedTenantIds =
    lease.tenantIds.where((id) => id != tenant.tenantId).toList();

    await session.leaseRepo.updateLeaseField(
      orgId: session.activeOrgId!,
      leaseId: lease.leaseId,
      field: "tenantIds",
      value: updatedTenantIds,
    );

    session.currentLeaseCache[lease.leaseId] =
        lease.copyWith(tenantIds: updatedTenantIds);

    Navigator.pop(context, "tenant_removed");
  }
}
