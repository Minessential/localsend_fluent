import 'package:fluent_ui/fluent_ui.dart';

/// A [DropdownButton] with a custom theme.
/// Currently, there is no easy way to apply color and border radius to all [DropdownButton].
class CustomDropdownButton<T> extends StatelessWidget {
  final T value;
  final List<ComboBoxItem<T>> items;
  final ValueChanged<T>? onChanged;
  final bool expanded;

  const CustomDropdownButton({
    required this.value,
    required this.items,
    this.onChanged,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    return ComboBox<T>(
      value: value,
      isExpanded: expanded,
      items: items,
      onChanged: onChanged == null
          ? null
          : (value) {
              if (value != null) {
                onChanged!(value);
              }
            },
    );
  }
}
