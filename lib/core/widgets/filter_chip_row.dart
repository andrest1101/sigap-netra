import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Satu opsi chip filter: label + ikon opsional + nilai (null = "Semua").
typedef FilterChipOption<T extends Object> = ({
  String label,
  IconData? icon,
  T? value,
});

/// Baris chip filter bersama: dipakai identik di tab Perangkat (timeline)
/// dan layar Log koneksi agar tidak ada dua implementasi yang divergen.
///
/// Generik atas `T` supaya core tidak bergantung ke entity feature mana pun.
/// Selalu `spacing + runSpacing` agar baris tidak menempel saat wrap.
class FilterChipRow<T extends Object> extends StatelessWidget {
  const FilterChipRow({
    required this.options,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<FilterChipOption<T>> options;
  final T? selected;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: DesignTokens.spaceSm,
      runSpacing: DesignTokens.spaceSm,
      children: [
        for (final option in options)
          ChoiceChip(
            avatar: option.icon == null ? null : Icon(option.icon, size: 16),
            label: Text(option.label),
            selected: selected == option.value,
            onSelected: (_) => onChanged(option.value),
          ),
      ],
    );
  }
}
