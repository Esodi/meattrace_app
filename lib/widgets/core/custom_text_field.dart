import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';

/// MeatTrace Pro - Custom Text Field Components
/// Reusable input widgets with consistent styling

enum TextFieldVariant {
  outlined, // Outlined border
  filled, // Filled background
  underline, // Underline only (Material Design default)
}

class CustomTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final TextFieldVariant variant;
  final FocusNode? focusNode;
  final AutovalidateMode? autovalidateMode;

  const CustomTextField({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.inputFormatters,
    this.variant = TextFieldVariant.underline,
    this.focusNode,
    this.autovalidateMode,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  void didUpdateWidget(CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.obscureText != oldWidget.obscureText) {
      _obscureText = widget.obscureText;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    InputBorder? border;
    Color? fillColor;
    bool filled = false;

    switch (widget.variant) {
      case TextFieldVariant.outlined:
        border = OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
            width: 1,
          ),
        );
        break;
      case TextFieldVariant.filled:
        border = OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide.none,
        );
        fillColor = isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.backgroundGray;
        filled = true;
        break;
      case TextFieldVariant.underline:
        border = UnderlineInputBorder(
          borderSide: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
            width: 1,
          ),
        );
        break;
    }

    // Build suffix icon with password visibility toggle if needed
    Widget? suffixIcon = widget.suffixIcon;
    if (widget.obscureText) {
      suffixIcon = IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          size: AppTheme.iconSmall,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }

    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: _obscureText,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      onTap: widget.onTap,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
      inputFormatters: widget.inputFormatters,
      autovalidateMode: widget.autovalidateMode,
      style: AppTypography.bodyLarge(color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        helperText: widget.helperText,
        errorText: widget.errorText,
        prefixIcon: widget.prefixIcon,
        suffixIcon: suffixIcon,
        filled: filled,
        fillColor: fillColor,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        errorBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        disabledBorder: border.copyWith(
          borderSide: BorderSide(
            color: isDark ? AppColors.darkTextTertiary : AppColors.textDisabled,
            width: 1,
          ),
        ),
        contentPadding: widget.variant == TextFieldVariant.underline
            ? const EdgeInsets.symmetric(vertical: AppTheme.space8)
            : const EdgeInsets.all(AppTheme.space16),
        counterText: widget.maxLength != null ? null : '',
      ),
    );
  }
}

/// Search Text Field - Specialized field for search
class SearchTextField extends StatelessWidget {
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;

  const SearchTextField({
    super.key,
    this.hint,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      hint: hint ?? 'Search...',
      variant: TextFieldVariant.filled,
      prefixIcon: const Icon(Icons.search, size: AppTheme.iconMedium),
      suffixIcon: controller?.text.isNotEmpty == true
          ? IconButton(
              icon: const Icon(Icons.clear, size: AppTheme.iconSmall),
              onPressed: () {
                controller?.clear();
                onClear?.call();
              },
            )
          : null,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
    );
  }
}

/// Dropdown Field - Custom dropdown with consistent styling
class CustomDropdownField<T> extends StatelessWidget {
  final String? label;
  final String? hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final bool enabled;
  final TextFieldVariant variant;

  const CustomDropdownField({
    super.key,
    this.label,
    this.hint,
    this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.variant = TextFieldVariant.underline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    InputBorder? border;
    Color? fillColor;
    bool filled = false;

    switch (variant) {
      case TextFieldVariant.outlined:
        border = OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
            width: 1,
          ),
        );
        break;
      case TextFieldVariant.filled:
        border = OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide.none,
        );
        fillColor = isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.backgroundGray;
        filled = true;
        break;
      case TextFieldVariant.underline:
        border = UnderlineInputBorder(
          borderSide: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
            width: 1,
          ),
        );
        break;
    }

    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: filled,
        fillColor: fillColor,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        errorBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        contentPadding: variant == TextFieldVariant.underline
            ? const EdgeInsets.symmetric(vertical: AppTheme.space8)
            : const EdgeInsets.all(AppTheme.space16),
      ),
      style: AppTypography.bodyLarge(color: theme.colorScheme.onSurface),
      dropdownColor: theme.colorScheme.surface,
      icon: const Icon(Icons.arrow_drop_down, size: AppTheme.iconMedium),
    );
  }
}

/// Number Input Field - Field optimized for numeric input
class NumberTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool allowDecimals;
  final bool allowNegative;
  final int? maxLength;
  final String? suffix;
  final String? prefix;

  const NumberTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.onChanged,
    this.validator,
    this.allowDecimals = false,
    this.allowNegative = false,
    this.maxLength,
    this.suffix,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: label,
      hint: hint,
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(
        decimal: allowDecimals,
        signed: allowNegative,
      ),
      inputFormatters: [
        if (!allowDecimals && !allowNegative)
          FilteringTextInputFormatter.digitsOnly,
        if (allowDecimals && !allowNegative)
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        if (allowNegative)
          FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
      ],
      onChanged: onChanged,
      validator: validator,
      maxLength: maxLength,
      suffixIcon: suffix != null
          ? Padding(
              padding: const EdgeInsets.only(right: AppTheme.space12),
              child: Center(
                widthFactor: 1,
                child: Text(
                  suffix!,
                  style: AppTypography.bodyMedium(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            )
          : null,
      prefixIcon: prefix != null
          ? Padding(
              padding: const EdgeInsets.only(left: AppTheme.space12),
              child: Center(
                widthFactor: 1,
                child: Text(
                  prefix!,
                  style: AppTypography.bodyMedium(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

/// Date Picker Field - Field with date picker integration
class DatePickerField extends StatelessWidget {
  final String? label;
  final String? hint;
  final DateTime? selectedDate;
  final ValueChanged<DateTime>? onDateSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final FormFieldValidator<DateTime>? validator;
  final TextFieldVariant variant;

  const DatePickerField({
    super.key,
    this.label,
    this.hint,
    this.selectedDate,
    this.onDateSelected,
    this.firstDate,
    this.lastDate,
    this.validator,
    this.variant = TextFieldVariant.underline,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(
      text: selectedDate != null
          ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
          : '',
    );

    return CustomTextField(
      label: label,
      hint: hint,
      controller: controller,
      variant: variant,
      readOnly: true,
      suffixIcon: const Icon(Icons.calendar_today, size: AppTheme.iconSmall),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: firstDate ?? DateTime(1900),
          lastDate: lastDate ?? DateTime(2100),
        );

        if (picked != null && onDateSelected != null) {
          onDateSelected!(picked);
        }
      },
    );
  }
}
