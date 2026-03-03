import 'package:flutter/material.dart';
import '../../../app/constants.dart';

class OnboardingLanguageDropdown extends StatefulWidget {
  final String? value;
  final ValueChanged<String> onChanged;
  final List<String> options;

  const OnboardingLanguageDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    required this.options,
  });

  @override
  State<OnboardingLanguageDropdown> createState() => _OnboardingLanguageDropdownState();
}

class _OnboardingLanguageDropdownState extends State<OnboardingLanguageDropdown> {
  bool _open = false;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    final filtered = widget.options
        .where((l) => l.toLowerCase().contains(_search.text.trim().toLowerCase()))
        .toList();

    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _open = !_open),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Text(
                  widget.value ?? 'Select Language',
                  style: t.textTheme.bodyLarge?.copyWith(
                    color: widget.value == null
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.keyboard_arrow_down_rounded),
              ],
            ),
          ),
        ),
        if (_open) ...[
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: TextField(
                    controller: _search,
                    style: t.textTheme.bodyLarge,
                    decoration: const InputDecoration(
                      hintText: 'SEARCH',
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const Divider(height: 1),
                ...filtered.map(
                  (opt) => ListTile(
                    dense: true,
                    title: Text(opt, style: t.textTheme.bodyLarge),
                    onTap: () {
                      widget.onChanged(opt);
                      setState(() => _open = false);
                    },
                  ),
                ),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('No matches', style: t.textTheme.bodyMedium),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}