import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/tokens.dart';

class SearchableDropdownField extends StatefulWidget {
  final List<String> items;
  final String? initialValue;
  final String hintText;
  final bool enabled;
  final ValueChanged<String?>? onChanged;
  final FormFieldValidator<String>? validator;

  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const SearchableDropdownField({
    super.key,
    required this.items,
    this.onChanged,
    this.initialValue,
    this.hintText = 'Pilih...',
    this.enabled = true,
    this.validator,
    this.focusNode,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  State<SearchableDropdownField> createState() =>
      _SearchableDropdownFieldState();
}

class _SearchableDropdownFieldState extends State<SearchableDropdownField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue ?? '');
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: widget.initialValue,
      validator: widget.validator,
      builder: (state) {
        return LayoutBuilder(
          builder: (ctx, constraints) {
            final width =
                constraints.maxWidth.isFinite ? constraints.maxWidth : 240.0;
            return RawAutocomplete<String>(
              textEditingController: _controller,
              focusNode: _focusNode,
              optionsBuilder: (value) {
                final q = value.text.toLowerCase();
                if (q.isEmpty) return widget.items;
                if (state.value != null && q == state.value!.toLowerCase()) {
                  return widget.items;
                }
                return widget.items
                    .where((e) => e.toLowerCase().contains(q));
              },
              onSelected: (val) {
                state.didChange(val);
                widget.onChanged?.call(val);
                _focusNode.unfocus();
              },
              fieldViewBuilder: (ctx, controller, focusNode, onSubmit) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: widget.enabled,
                  keyboardType: widget.keyboardType,
                  inputFormatters: [
                    if (widget.inputFormatters != null) ...widget.inputFormatters!,
                    _SingleUnitFormatter(widget.items),
                  ],
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    suffixIcon: const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.gray500,
                    ),
                    errorText: state.errorText,
                  ),
                  onChanged: (v) {
                    if (widget.items.contains(v)) {
                      state.didChange(v);
                      widget.onChanged?.call(v);
                    } else if (state.value != null) {
                      state.didChange(null);
                      widget.onChanged?.call(null);
                    }
                  },
                );
              },
              optionsViewBuilder: (ctx, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    clipBehavior: Clip.antiAlias,
                    child: SizedBox(
                      width: width,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 240),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (_, idx) {
                            final option = options.elementAt(idx);
                            return InkWell(
                              onTap: () => onSelected(option),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Text(
                                  option,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _SingleUnitFormatter extends TextInputFormatter {
  final List<String> items;
  _SingleUnitFormatter(this.items);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final wasValid = items.contains(oldValue.text);
    final isValid = items.contains(newValue.text);

    if (wasValid && !isValid) {
      if (newValue.text.length < oldValue.text.length) {
        return const TextEditingValue(
          text: '',
          selection: TextSelection.collapsed(offset: 0),
        );
      } else {
        if (oldValue.selection.start == 0 && oldValue.selection.end == oldValue.text.length) {
           return newValue;
        }
      }
    }
    return newValue;
  }
}
