import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class FiltersPanel extends StatelessWidget {
  const FiltersPanel({
    super.key,
    this.lutFile,
    required this.exposure,
    required this.contrast,
    required this.saturation,
    required this.temperature,
    required this.tint,
    required this.lutFileToggle,

    this.onLutFileSelected,
    this.onExposureChanged,
    this.onContrastChanged,
    this.onSaturationChanged,
    this.onTemperatureChanged,
    this.onTintChanged,

    this.onFilterChangeStart,
    this.onFilterChangeEnd,
    this.onLutFileToggle,
  });

  final String? lutFile;
  final bool lutFileToggle;
  final double exposure;
  final double contrast;
  final double saturation;
  final double temperature;
  final double tint;

  final ValueChanged<bool?>? onLutFileToggle;
  final ValueChanged<String>? onLutFileSelected;
  final ValueChanged<double>? onFilterChangeEnd;
  final ValueChanged<double>? onFilterChangeStart;

  final ValueChanged<double>? onExposureChanged;
  final ValueChanged<double>? onContrastChanged;
  final ValueChanged<double>? onSaturationChanged;
  final ValueChanged<double>? onTemperatureChanged;
  final ValueChanged<double>? onTintChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);

    return Column(
      spacing: 20,
      children: [
        FilterSliderBlock(
          max: 10.0,
          min: -10.0,
          divisions: 20,
          isFloat: false,
          value: exposure,
          title: 'Exposure',
          onChanged: onExposureChanged,
          onChangeEnd: onFilterChangeEnd,
          onChangeStart: onFilterChangeStart,

          thumbColor: colorScheme.tertiary,
          activeColor: colorScheme.tertiary,
          inactiveColor: colorScheme.tertiaryFixed,
        ),
        FilterSliderBlock(
          max: 4.0,
          min: 0.0,
          isFloat: true,
          value: contrast,
          title: 'Contrast',
          onChanged: onContrastChanged,
          onChangeEnd: onFilterChangeEnd,
          onChangeStart: onFilterChangeStart,

          thumbColor: colorScheme.tertiary,
          activeColor: colorScheme.tertiary,
          inactiveColor: colorScheme.tertiaryFixed,
        ),

        FilterSliderBlock(
          max: 2.0,
          min: 0.0,
          isFloat: true,
          value: saturation,
          title: 'Saturation',
          onChanged: onSaturationChanged,
          onChangeEnd: onFilterChangeEnd,
          onChangeStart: onFilterChangeStart,

          thumbColor: colorScheme.tertiary,
          activeColor: colorScheme.tertiary,
          inactiveColor: colorScheme.tertiaryFixed,
        ),

        FilterSliderBlock(
          min: 2000,
          max: 10000,
          isFloat: false,
          value: temperature,
          title: 'Temperature',
          onChanged: onTemperatureChanged,
          onChangeEnd: onFilterChangeEnd,
          onChangeStart: onFilterChangeStart,

          thumbColor: colorScheme.tertiary,
          activeColor: colorScheme.tertiary,
          inactiveColor: colorScheme.tertiaryFixed,
        ),

        FilterSliderBlock(
          max: 200.0,
          min: -200.0,
          value: tint,
          title: 'Tint',
          isFloat: false,
          onChanged: onTintChanged,
          onChangeEnd: onFilterChangeEnd,
          onChangeStart: onFilterChangeStart,

          thumbColor: colorScheme.tertiary,
          activeColor: colorScheme.tertiary,
          inactiveColor: colorScheme.tertiaryFixed,
        ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card.filled(
              margin: EdgeInsets.zero,
              color: Colors.grey.shade200,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                  bottom: Radius.circular(10),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                child: Text('LUT', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 4),
            Card.filled(
              color: Colors.grey.shade200,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(10),
                  bottom: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Checkbox(value: lutFileToggle, onChanged: onLutFileToggle),
                  if (lutFile != null)
                    Expanded(child: Text(lutFile!.split('/').last))
                  else
                    Spacer(),
                  TextButton.icon(
                    onPressed: () async {
                      if (onLutFileSelected == null) {
                        return;
                      }

                      final result = await FilePicker.platform.pickFiles(
                        dialogTitle: 'Select LUT file',
                        type: FileType.any,
                        allowMultiple: false,
                      );

                      if (result != null) {
                        final path = result.paths.first!;

                        if (path.endsWith('.cube')) {
                          onLutFileSelected?.call(path);
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Select a valid .cube file'),
                              ),
                            );
                          }
                        }
                      }
                    },
                    label: Text('Pick'),
                    icon: Icon(Symbols.upload_file_rounded),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class FilterSliderBlock extends StatelessWidget {
  const FilterSliderBlock({
    super.key,
    this.divisions,
    this.thumbColor,
    this.activeColor,
    this.inactiveColor,
    required this.min,
    required this.max,
    required this.value,
    required this.title,
    required this.isFloat,
    required this.onChanged,
    required this.onChangeEnd,
    required this.onChangeStart,
  });

  final int? divisions;
  final bool isFloat;

  final double min;
  final double max;
  final double value;
  final String title;

  final Color? thumbColor;
  final Color? activeColor;
  final Color? inactiveColor;

  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final ValueChanged<double>? onChangeStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card.filled(
          margin: EdgeInsets.zero,
          color: Colors.grey.shade200,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
              bottom: Radius.circular(10),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
            child: Row(
              children: [
                Expanded(child: Text(title, style: TextStyle(fontSize: 16))),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                  decoration: BoxDecoration(
                    color: onChanged != null ? activeColor : Colors.grey,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(6),
                    ),
                  ),
                  child: Text(
                    value.toStringAsFixed(isFloat ? 2 : 0),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Card.filled(
          color: Colors.grey.shade200,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(10),
              bottom: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Slider(
              min: min,
              max: max,
              value: value,
              divisions: divisions,
              onChanged: onChanged,
              padding: EdgeInsets.zero,

              thumbColor: thumbColor,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
            ),
          ),
        ),
      ],
    );
  }
}
