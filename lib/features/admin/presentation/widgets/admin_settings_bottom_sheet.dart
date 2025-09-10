import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:taqy/core/services/firebase_service.dart';
import 'package:taqy/core/theme/colors.dart';
import 'package:taqy/features/admin/data/models/organization.dart';
import 'package:taqy/features/all/auth/presentation/widgets/animated_button.dart';

class AdminSettingsBottomSheet extends StatefulWidget {
  final AdminOrganization organization;
  final Function(AdminOrganization) onSettingsUpdated;
  final VoidCallback onLogout;

  const AdminSettingsBottomSheet({
    super.key,
    required this.organization,
    required this.onSettingsUpdated,
    required this.onLogout,
  });

  @override
  State<AdminSettingsBottomSheet> createState() =>
      _AdminSettingsBottomSheetState();
}

class _AdminSettingsBottomSheetState extends State<AdminSettingsBottomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late Color _primaryColor;
  late Color _secondaryColor;
  PlatformFile? _logoFile;
  bool _isSaving = false;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.organization.name);
    _codeController = TextEditingController(text: widget.organization.code);
    _primaryColor = widget.organization.primaryColorValue;
    _secondaryColor = widget.organization.secondaryColorValue;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 12),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: AppColors.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(24),
            child: Row(
              children: [
                Text(
                  'Company Settings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Organization Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'ID: ${widget.organization.id}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                            fontFamily: 'monospace',
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Created: ${_formatDate(widget.organization.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Company Logo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        SizedBox(height: 12),
                        GestureDetector(
                          onTap: _pickLogo,
                          child: Container(
                            height: 120,
                            width: 120,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(60),
                              border: Border.all(
                                color: _primaryColor,
                                width: 2,
                              ),
                            ),
                            child: _logoFile != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(58),
                                    child: Image.file(
                                      File(_logoFile!.path!),
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : widget.organization.logoUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(58),
                                    child: Image.network(
                                      widget.organization.logoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                            Icons.business,
                                            color: _primaryColor,
                                            size: 40,
                                          ),
                                    ),
                                  )
                                : Icon(
                                    Icons.add_photo_alternate,
                                    size: 40,
                                    color: _primaryColor,
                                  ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap to change logo',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),

                  _buildTextField(
                    controller: _nameController,
                    label: 'Company Name',
                    hint: 'Enter company name',
                    icon: Icons.business,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Company name is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),

                  _buildTextField(
                    controller: _codeController,
                    label: 'Company Code',
                    hint: 'Enter unique company code',
                    icon: Icons.code,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Company code is required';
                      }
                      if (value.length < 3) {
                        return 'Code must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 32),

                  Text(
                    'Brand Colors',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  SizedBox(height: 16),

                  _buildColorSelector(
                    'Primary Color',
                    _primaryColor,
                    (color) => setState(() => _primaryColor = color),
                  ),
                  SizedBox(height: 16),

                  _buildColorSelector(
                    'Secondary Color',
                    _secondaryColor,
                    (color) => setState(() => _secondaryColor = color),
                  ),
                  SizedBox(height: 32),

                  Text(
                    'Color Preview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryColor, _secondaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.business, color: Colors.white, size: 24),
                        SizedBox(width: 12),
                        Text(
                          _nameController.text.isEmpty
                              ? 'Company Name'
                              : _nameController.text,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),
                ],
              ),
            ),
          ),

          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(top: BorderSide(color: AppColors.outline)),
            ),
            child: Column(
              children: [
                AnimatedButton(
                  text: _isSaving ? 'Saving...' : 'Save Changes',
                  onPressed: _isSaving ? null : _saveSettings,
                  backgroundColor: _primaryColor,
                  width: double.infinity,
                  height: 50,
                ),
                SizedBox(height: 12),

                AnimatedButton(
                  text: 'Logout',
                  onPressed: _isSaving
                      ? null
                      : () {
                          Navigator.pop(context);
                          _showLogoutConfirmation();
                        },
                  backgroundColor: AppColors.error,
                  width: double.infinity,
                  height: 50,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.onSurfaceVariant),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.error, width: 2),
            ),
            filled: true,
            fillColor: AppColors.background,
          ),
        ),
      ],
    );
  }

  Widget _buildColorSelector(
    String label,
    Color selectedColor,
    Function(Color) onColorChanged,
  ) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
      Colors.amber,
      Colors.red,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((color) {
            final isSelected = color.value == selectedColor.value;
            return GestureDetector(
              onTap: () => onColorChanged(color),
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected
                      ? Border.all(color: AppColors.onSurface, width: 3)
                      : Border.all(color: Colors.grey.shade300, width: 1),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _pickLogo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        if (file.size > 5 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File size must be less than 5MB'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }

        setState(() {
          _logoFile = file;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _saveSettings() async {
    if (_nameController.text.trim().isEmpty ||
        _codeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      String? logoUrl = widget.organization.logoUrl;

      if (_logoFile != null) {
        logoUrl = await _firebaseService.uploadOrganizationLogo(
          widget.organization.id,
          _logoFile!.path!,
        );
      }

      final updatedOrganization = AdminOrganization(
        id: widget.organization.id,
        name: _nameController.text.trim(),
        code: _codeController.text.trim().toUpperCase(),
        logoUrl: logoUrl,
        primaryColor: _primaryColor.value.toString(),
        secondaryColor: _secondaryColor.value.toString(),
        createdAt: widget.organization.createdAt,
        updatedAt: DateTime.now(),
        isActive: widget.organization.isActive,
      );

      await _firebaseService.updateDocument(
        'organizations',
        widget.organization.id,
        updatedOrganization.toFirestore(),
      );

      widget.onSettingsUpdated(updatedOrganization);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Settings saved successfully!'),
            ],
          ),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save settings: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.onLogout();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
