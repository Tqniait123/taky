
// OFFICE BOY PROFILE BOTTOM SHEET
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:taqy/core/services/firebase_service.dart';
import 'package:taqy/features/office_boy/data/models/office_organization.dart';
import 'package:taqy/features/office_boy/data/models/office_user_model.dart';

class OfficeBoyProfileBottomSheet extends StatefulWidget {
  final OfficeUserModel user;
  final OfficeOrganization organization;
  final VoidCallback onLogout;
  final Function(OfficeUserModel) onProfileUpdated;

  const OfficeBoyProfileBottomSheet({
    super.key,
    required this.user,
    required this.organization,
    required this.onLogout,
    required this.onProfileUpdated,
  });

  @override
  State<OfficeBoyProfileBottomSheet> createState() =>
      _OfficeBoyProfileBottomSheetState();
}

class _OfficeBoyProfileBottomSheetState
    extends State<OfficeBoyProfileBottomSheet> {
  final FirebaseService _firebaseService = FirebaseService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.name;
    _phoneController.text = widget.user.phone ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showErrorToast('Name cannot be empty');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updateData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      await _firebaseService.updateDocument(
        'users',
        widget.user.id,
        updateData,
      );

      // Get updated user data
      final userDoc = await _firebaseService.getDocument(
        'users',
        widget.user.id,
      );
      final updatedUser = OfficeUserModel.fromFirestore(userDoc);

      widget.onProfileUpdated(updatedUser);

      setState(() => _isEditing = false);
      _showSuccessToast('Profile updated successfully');
    } catch (e) {
      _showErrorToast('Failed to update profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              widget.onLogout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Profile',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                if (_isEditing)
                  TextButton(
                    onPressed: () => setState(() => _isEditing = false),
                    child: Text('Cancel'),
                  )
                else
                  TextButton.icon(
                    onPressed: () => setState(() => _isEditing = true),
                    icon: Icon(Icons.edit),
                    label: Text('Edit'),
                  ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Profile Picture
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.organization.primaryColorValue,
                          widget.organization.secondaryColorValue,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.user.name.isNotEmpty
                            ? widget.user.name[0].toUpperCase()
                            : 'O',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // User Info Cards
                  _buildInfoCard(
                    'Name',
                    _isEditing ? null : widget.user.name,
                    Icons.person,
                    controller: _isEditing ? _nameController : null,
                  ),

                  _buildInfoCard(
                    'Email',
                    widget.user.email,
                    Icons.email,
                    readOnly: true,
                  ),

                  _buildInfoCard(
                    'Phone',
                    _isEditing ? null : (widget.user.phone ?? 'Not provided'),
                    Icons.phone,
                    controller: _isEditing ? _phoneController : null,
                  ),

                  _buildInfoCard(
                    'Role',
                    'Office Boy',
                    Icons.badge,
                    readOnly: true,
                  ),

                  _buildInfoCard(
                    'Organization',
                    widget.organization.name,
                    Icons.business,
                    readOnly: true,
                  ),

                  SizedBox(height: 24),

                  // Action Buttons
                  if (_isEditing) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              widget.organization.primaryColorValue,
                          padding: EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Save Changes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _showLogoutDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String label,
    String? value,
    IconData icon, {
    TextEditingController? controller,
    bool readOnly = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.organization.primaryColorValue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: widget.organization.primaryColorValue,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                if (controller != null)
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  )
                else
                  Text(
                    value ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: readOnly ? Colors.grey[600] : Colors.black87,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}