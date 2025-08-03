// lib/features/auth/presentation/widgets/modern_color_picker.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taqy/core/theme/colors.dart';

class ModernColorPicker extends StatefulWidget {
  final String label;
  final Color selectedColor;
  final Function(Color) onColorSelected;
  final String? hint;

  const ModernColorPicker({
    super.key,
    required this.label,
    required this.selectedColor,
    required this.onColorSelected,
    this.hint,
  });

  @override
  State<ModernColorPicker> createState() => _ModernColorPickerState();
}

class _ModernColorPickerState extends State<ModernColorPicker> with SingleTickerProviderStateMixin {
  late TextEditingController _hexController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isValidHex = true;
  bool _showCustomInput = false;

  // Curated modern color palette
  static const List<Color> _modernColors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFFEF4444), // Red
    Color(0xFFF97316), // Orange
    Color(0xFFEAB308), // Amber
    Color(0xFF22C55E), // Green
    Color(0xFF06B6D4), // Cyan
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Purple
    Color(0xFF64748B), // Slate
    Color(0xFF0F172A), // Dark
  ];

  @override
  void initState() {
    super.initState();
    _hexController = TextEditingController(text: _colorToHex(widget.selectedColor));
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.elasticOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    _hexController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label
              Text(
                widget.label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
              ),
              if (widget.hint != null) ...[
                const SizedBox(height: 2),
                Text(
                  widget.hint!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant.withOpacity(0.6)),
                ),
              ],
              const SizedBox(height: 12),

              // Color Picker Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outline.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    // Color Preview with Custom Input Toggle
                    _buildColorPreview(),
                    const SizedBox(height: 20),

                    // Custom Input (Expandable)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _showCustomInput ? _buildCustomInput() : const SizedBox.shrink(),
                    ),

                    if (_showCustomInput) const SizedBox(height: 16),

                    // Color Grid
                    _buildColorGrid(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColorPreview() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showCustomInput = !_showCustomInput;
        });
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: widget.selectedColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: widget.selectedColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                _colorToHex(widget.selectedColor),
                style: TextStyle(
                  color: _getContrastColor(widget.selectedColor),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: AnimatedRotation(
                turns: _showCustomInput ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                child: Icon(Icons.keyboard_arrow_down, color: _getContrastColor(widget.selectedColor), size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _isValidHex ? AppColors.outline.withOpacity(0.2) : Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.palette_outlined, color: _isValidHex ? AppColors.onSurfaceVariant : Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _hexController,
              decoration: InputDecoration(
                hintText: '#FF5722 or FF5722',
                hintStyle: TextStyle(color: AppColors.onSurfaceVariant.withOpacity(0.5), fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                color: AppColors.onSurface,
                fontFamily: 'monospace',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textCapitalization: TextCapitalization.characters,
              onChanged: _onHexChanged,
              onSubmitted: _onHexSubmitted,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _pasteFromClipboard,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(6)),
              child: Icon(Icons.content_paste, color: AppColors.onSurfaceVariant, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: _modernColors.length,
      itemBuilder: (context, index) {
        final color = _modernColors[index];
        final isSelected = color.value == widget.selectedColor.value;

        return GestureDetector(
          onTap: () => _selectColor(color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.onSurface : Colors.transparent,
                width: isSelected ? 2.5 : 0,
              ),
              boxShadow: [
                if (isSelected) BoxShadow(color: color.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4)),
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: AnimatedScale(
              scale: isSelected ? 0.85 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.check, color: _getContrastColor(color), size: 20),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onHexChanged(String value) {
    final color = _hexToColor(value);
    setState(() {
      _isValidHex = color != null || value.isEmpty;
    });

    if (color != null) {
      widget.onColorSelected(color);
    }
  }

  void _onHexSubmitted(String value) {
    final color = _hexToColor(value);
    if (color != null) {
      _selectColor(color);
    }
  }

  void _selectColor(Color color) {
    setState(() {
      _hexController.text = _colorToHex(color);
      _isValidHex = true;
    });
    widget.onColorSelected(color);
    HapticFeedback.selectionClick();
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData('text/plain');
      if (clipboardData?.text != null) {
        _hexController.text = clipboardData!.text!;
        _onHexChanged(clipboardData.text!);
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      // Handle clipboard error silently
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  Color? _hexToColor(String hexCode) {
    try {
      String hex = hexCode.replaceAll('#', '').toUpperCase();

      if (hex.length != 6) return null;
      if (!RegExp(r'^[0-9A-F]+$').hasMatch(hex)) return null;

      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return null;
    }
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
