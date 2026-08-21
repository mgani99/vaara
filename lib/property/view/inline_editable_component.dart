import 'package:flutter/material.dart';
import 'package:my_app/property/domain/property_model.dart';


class InlineEditableText extends StatefulWidget {
  final String value;
  final TextStyle? style;
  final Function(String) onSave;

  const InlineEditableText({
    super.key,
    required this.value,
    required this.onSave,
    this.style,
  });

  @override
  State<InlineEditableText> createState() => _InlineEditableTextState();
}

class _InlineEditableTextState extends State<InlineEditableText> {
  bool editing = false;
  late TextEditingController ctrl;

  @override
  void initState() {
    super.initState();
    ctrl = TextEditingController(text: widget.value);
  }



  @override
  Widget build(BuildContext context) {
    if (!editing) {
      return GestureDetector(
        onTap: () => setState(() => editing = true),
        child: Text(widget.value, style: widget.style),
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.check, color: Colors.green),
          onPressed: () {
            widget.onSave(ctrl.text.trim());
            setState(() => editing = false);
          },
        ),
      ],
    );
  }
}
Future<void> showBedBathEditModal({
  required BuildContext context,
  required UnitModel unit,
  required Function(int bedrooms, double bathrooms) onSave,
}) async {
  final theme = Theme.of(context);

  int bedrooms = unit.bedrooms ?? 0;
  double bathrooms = unit.bathrooms?? 0.0;

  await showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Edit Bedrooms & Bathrooms",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 24),

              // Bedrooms
              Text("Bedrooms", style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  _incrementButton(
                    icon: Icons.remove,
                    onTap: () {
                      if (bedrooms > 0) bedrooms -= 1;
                      (context as Element).markNeedsBuild();
                    },
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "$bedrooms",
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(width: 12),
                  _incrementButton(
                    icon: Icons.add,
                    onTap: () {
                      bedrooms += 1;
                      (context as Element).markNeedsBuild();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Bathrooms
              Text("Bathrooms", style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  _incrementButton(
                    icon: Icons.remove,
                    onTap: () {
                      if (bathrooms > 0) bathrooms -= 0.5;
                      bathrooms = double.parse(bathrooms.toStringAsFixed(1));
                      (context as Element).markNeedsBuild();
                    },
                  ),
                  const SizedBox(width: 12),
                  Text(
                    bathrooms.toStringAsFixed(1),
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(width: 12),
                  _incrementButton(
                    icon: Icons.add,
                    onTap: () {
                      bathrooms += 0.5;
                      bathrooms = double.parse(bathrooms.toStringAsFixed(1));
                      (context as Element).markNeedsBuild();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      child: const Text("Cancel"),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      child: const Text("Save"),
                      onPressed: () {
                        onSave(bedrooms, bathrooms);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

}


Widget _incrementButton({
  required IconData icon,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 20),
    ),
  );
}


class InlineEditableNumber extends StatefulWidget {
  final num value;
  final ValueChanged<num> onSave;

  const InlineEditableNumber({
    super.key,
    required this.value,
    required this.onSave,
  });

  @override
  State<InlineEditableNumber> createState() => _InlineEditableNumberState();
}

class _InlineEditableNumberState extends State<InlineEditableNumber> {
  bool editing = false;
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.value.toString());
  }

  @override
  Widget build(BuildContext context) {
    if (!editing) {
      return Row(
        children: [
          Expanded(
            child: Text(
              widget.value.toString(),
              style: const TextStyle(fontSize: 16),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 18, color: Colors.black54),
            onPressed: () => setState(() => editing = true),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
          ),
        ),
        TextButton(
          onPressed: () {
            final parsed = num.tryParse(controller.text);
            if (parsed != null) {
              widget.onSave(parsed);
            }
            setState(() => editing = false);
          },
          child: const Text("Save"),
        ),
        TextButton(
          onPressed: () {
            controller.text = widget.value.toString();
            setState(() => editing = false);
          },
          child: const Text("Cancel"),
        ),
      ],
    );
  }
}




class InlineEditableMultiline extends StatefulWidget {
  final String value;
  final ValueChanged<String> onSave;

  const InlineEditableMultiline({
    super.key,
    required this.value,
    required this.onSave,
  });

  @override
  State<InlineEditableMultiline> createState() =>
      _InlineEditableMultilineState();
}

class _InlineEditableMultilineState extends State<InlineEditableMultiline> {
  bool editing = false;
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.value);
  }

  @override
  Widget build(BuildContext context) {
    if (!editing) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              widget.value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 18, color: Colors.black54),
            onPressed: () => setState(() => editing = true),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          maxLines: 6,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                widget.onSave(controller.text.trim());
                setState(() => editing = false);
              },
              child: const Text("Save"),
            ),
            TextButton(
              onPressed: () {
                controller.text = widget.value;
                setState(() => editing = false);
              },
              child: const Text("Cancel"),
            ),
          ],
        ),
      ],
    );
  }
}

