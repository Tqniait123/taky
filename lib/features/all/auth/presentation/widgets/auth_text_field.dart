// lib/features/auth/presentation/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taqy/core/utils/widgets/app_images.dart';

// lib/features/auth/presentation/widgets/auth_text_field.dart
class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String prefixIcon;
  final TextInputType keyboardType;
  final Color focusColor;
  final String? Function(String?)? validator;
  final bool isPassword;
  final bool isPasswordVisible;
  final VoidCallback? onTogglePassword;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.prefixIcon = '',
    this.keyboardType = TextInputType.text,
    required this.focusColor,
    this.validator,
    this.isPassword = false,
    this.isPasswordVisible = false,
    this.onTogglePassword,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isFocused
                  ? widget.focusColor
                  : Colors.grey.withOpacity(0.3),
              width: _isFocused ? 2 : 1,
            ),
            // boxShadow: _isFocused
            //     ? [
            //         BoxShadow(
            //           color: widget.focusColor.withOpacity(0.1),
            //           blurRadius: 8,
            //           offset: const Offset(0, 2),
            //         ),
            //       ]
            //     : null,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            obscureText: widget.isPassword && !widget.isPasswordVisible,
            validator: widget.validator,

            decoration: InputDecoration(
              // labelText: widget.label,
              // labelStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              hintText: widget.hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: widget.prefixIcon != ''
                  ? SvgPicture.asset(
                      widget.prefixIcon,
                      // color: _isFocused ? widget.focusColor : Colors.grey[400],
                    )
                  : null,
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: SvgPicture.asset(
                        widget.isPasswordVisible
                            ? Assets.imagesSvgsEyeDash
                            : Assets.imagesSvgsEye,

                        // color: _isFocused
                        //     ? AppColors.primary
                        //     : Colors.grey[400],
                      ),
                      onPressed: widget.onTogglePassword,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              errorStyle: const TextStyle(fontSize: 12, height: 1.2),
            ),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
            onTapOutside: (event) => FocusScope.of(context).unfocus(),
          ),
        ),
      ],
    );
  }
}
