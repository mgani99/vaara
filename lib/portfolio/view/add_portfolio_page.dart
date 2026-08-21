import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_app/portfolio/controller/add_portfolio_controller.dart';

class AddPortfolioPage extends StatelessWidget {
  const AddPortfolioPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AddPortfolioController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Portfolio"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Portfolio Name", style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),

            TextField(
              controller: controller.nameController,
              decoration: InputDecoration(
                hintText: "e.g. Long Island Rentals",
                border: OutlineInputBorder(),
                errorText: controller.errorMessage,
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.isLoading
                    ? null
                    : () async {
                  final ok = await controller.submit();
                  if (ok && context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: controller.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Create Portfolio"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
