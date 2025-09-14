// lib/features/auth/presentation/screens/register_screen.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taqy/config/routes/routes.dart';
import 'package:taqy/core/theme/colors.dart';
import 'package:taqy/core/translations/locale_keys.g.dart';
import 'package:taqy/core/utils/dialogs/error_toast.dart';
import 'package:taqy/features/all/auth/domain/entities/user.dart' as entities;
import 'package:taqy/features/all/auth/presentation/cubit/auth_cubit.dart';
import 'package:taqy/features/all/auth/presentation/widgets/color_picker_widget.dart';

import '../widgets/animated_button.dart';
import '../widgets/auth_text_field.dart';

// // Your ImagePickerAvatar widget
// class ImagePickerAvatar extends StatelessWidget {
//   final bool? isLarge;
//   final void Function(PlatformFile image) onPick;
//   final double? height;
//   final double? width;
//   final PlatformFile? pickedImage;
//   final String? initialImage;

//   const ImagePickerAvatar({
//     super.key,
//     this.pickedImage,
//     required this.onPick,
//     this.isLarge = false,
//     this.height,
//     this.width,
//     this.initialImage,
//   });

//   @override
//   Widget build(BuildContext context) {
//     bool isLight =
//         Theme.of(context).scaffoldBackgroundColor == AppColors.background;

//     return SizedBox(
//       height: height ?? (isLarge! ? 300 : 100),
//       width: width ?? (isLarge! ? 300 : 100),
//       child: Stack(
//         clipBehavior: Clip.none,
//         children: [
//           Positioned.fill(
//             child: Container(
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(50),
//                 color: pickedImage == null
//                     ? (isLight ? AppColors.background : AppColors.secondary)
//                     : null,
//                 image:
//                     (initialImage != null &&
//                         initialImage!.isNotEmpty &&
//                         pickedImage == null)
//                     ? DecorationImage(
//                         fit: BoxFit.cover,
//                         image: NetworkImage(initialImage!),
//                       )
//                     : pickedImage != null && pickedImage!.path != null
//                     ? DecorationImage(
//                         fit: BoxFit.cover,
//                         image: FileImage(File(pickedImage!.path!)),
//                       )
//                     : null,
//               ),
//             ),
//           ),
//           if (pickedImage == null &&
//               (initialImage == null || initialImage!.isEmpty))
//             Positioned.fill(
//               child: GestureDetector(
//                 onTap: () async {
//                   final result = await FilePicker.platform.pickFiles(
//                     type: FileType.image,
//                     withData: true,
//                     compressionQuality: 0,
//                   );
//                   if (result != null) {
//                     onPick(result.files.first);
//                   }
//                 },
//                 child: Material(
//                   color: Colors.transparent,
//                   child: SizedBox.expand(
//                     child: IconButton(
//                       onPressed: () async {
//                         final result = await FilePicker.platform.pickFiles(
//                           type: FileType.image,
//                           withData: true,
//                           compressionQuality: 0,
//                         );
//                         if (result != null) {
//                           onPick(result.files.first);
//                         }
//                       },
//                       splashRadius: 50,
//                       color: Theme.of(context).colorScheme.primary,
//                       icon: Icon(
//                         Icons.add_photo_alternate_outlined,
//                         size: isLarge! ? 30 : 25.0,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             )
//           else
//             PositionedDirectional(
//               bottom: -10,
//               start: -10,
//               height: 40,
//               width: 40,
//               child: Container(
//                 height: 120,
//                 width: 120,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(60),
//                   color: Colors.white,
//                 ),
//                 padding: const EdgeInsets.all(5),
//                 child: Material(
//                   clipBehavior: Clip.hardEdge,
//                   color: Theme.of(context).colorScheme.primary,
//                   borderRadius: BorderRadius.circular(20),
//                   child: Center(
//                     child: IconButton(
//                       onPressed: () async {
//                         final result = await FilePicker.platform.pickFiles(
//                           type: FileType.image,
//                           withData: true,
//                         );
//                         if (result != null) {
//                           onPick(result.files.first);
//                         }
//                       },
//                       iconSize: 35,
//                       splashRadius: 35,
//                       color: isLight
//                           ? AppColors.background
//                           : AppColors.onSurface,
//                       icon: const Icon(Icons.edit),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

class RegisterScreen extends StatefulWidget {
  final String accountType;

  const RegisterScreen({super.key, required this.accountType});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _orgCodeController = TextEditingController();
  final _orgNameController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Color selection for admin
  Color _selectedPrimaryColor = AppColors.primary;
  Color _selectedSecondaryColor = AppColors.secondary;

  // Image picker for profile and organization logo
  // PlatformFile? _profileImage;
  // PlatformFile? _organizationLogo;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _orgCodeController.dispose();
    _orgNameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            state.when(
              initial: () {},
              loading: () {},
              authenticated: (user) {
                // Show success message
                showSuccessToast(
                  context,
                  LocaleKeys.accountCreatedSuccessfully.tr(),
                );

                // Navigate based on account type
                context.go(Routes.login);
              },
              unauthenticated: () {},
              error: (failure) {
                showErrorToast(context, failure);
              },
              passwordResetSent: () {},
              checkingOrganizationCode: () {},
              organizationCodeChecked: (exists) {
                if (!exists) {
                  showErrorToast(
                    context,
                    LocaleKeys.organizationCodeNotFound.tr(),
                  );
                }
              },
            );
          },
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: Offset(
                    0,
                    _slideAnimation.value.dy *
                        MediaQuery.of(context).size.height,
                  ),
                  child: child,
                ),
              );
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const SizedBox(height: 20),
                  _buildHeader(context),
                  const SizedBox(height: 32),

                  // Form Card
                  _buildFormCard(context),
                  const SizedBox(height: 32),

                  // Sign In Link
                  _buildSignInLink(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back_ios,
              color: AppColors.onSurfaceVariant,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleKeys.createAccount.tr(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getAccountTypeTitle(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Profile Image Picker
            // _buildImageSection(
            //   label: LocaleKeys.profileImage.tr(),
            //   image: _profileImage,
            //   onPick: (image) {
            //     setState(() {
            //       _profileImage = image;
            //     });
            //   },
            // ),
            // const SizedBox(height: 24),

            // Name Field
            AuthTextField(
              controller: _nameController,
              label: LocaleKeys.fullName.tr(),
              hint: LocaleKeys.enterFullName.tr(),
              prefixIcon: Icons.person_outline,
              focusColor: _getAccountTypeColor(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return LocaleKeys.pleaseEnterName.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Email Field
            AuthTextField(
              controller: _emailController,
              label: LocaleKeys.email.tr(),
              hint: LocaleKeys.enterEmail.tr(),
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              focusColor: _getAccountTypeColor(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return LocaleKeys.pleaseEnterEmail.tr();
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return LocaleKeys.pleaseEnterValidEmail.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Phone Field
            AuthTextField(
              controller: _phoneController,
              label: LocaleKeys.phoneNumber.tr(),
              hint: LocaleKeys.enterPhoneNumber.tr(),
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              focusColor: _getAccountTypeColor(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return LocaleKeys.pleaseEnterPhoneNumber.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Organization fields
            ..._buildOrganizationFields(),

            // Password Field
            AuthTextField(
              controller: _passwordController,
              label: LocaleKeys.password.tr(),
              hint: LocaleKeys.createPassword.tr(),
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              isPasswordVisible: _isPasswordVisible,
              focusColor: _getAccountTypeColor(),
              onTogglePassword: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return LocaleKeys.pleaseEnterPassword.tr();
                }
                if (value.length < 6) {
                  return LocaleKeys.passwordMinLength.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Confirm Password Field
            AuthTextField(
              controller: _confirmPasswordController,
              label: LocaleKeys.confirmPassword.tr(),
              hint: LocaleKeys.confirmYourPassword.tr(),
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              isPasswordVisible: _isConfirmPasswordVisible,
              focusColor: _getAccountTypeColor(),
              onTogglePassword: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return LocaleKeys.pleaseConfirmPassword.tr();
                }
                if (value != _passwordController.text) {
                  return LocaleKeys.passwordsDoNotMatch.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Register Button
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                final isLoading = state is AuthLoading;
                return AnimatedButton(
                  text: LocaleKeys.createAccount.tr(),
                  onPressed: isLoading ? null : _handleRegister,
                  isLoading: isLoading,
                  backgroundColor: AppColors.primary,
                  width: double.infinity,
                  height: 56,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildImageSection({
  //   required String label,
  //   required PlatformFile? image,
  //   required Function(PlatformFile) onPick,
  //   bool isLarge = false,
  // }) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.center,
  //     children: [
  //       Text(
  //         label,
  //         style: Theme.of(context).textTheme.labelMedium?.copyWith(
  //           color: AppColors.onSurfaceVariant,
  //           fontWeight: FontWeight.w600,
  //         ),
  //       ),
  //       const SizedBox(height: 12),
  //       ImagePickerAvatar(
  //         pickedImage: image,
  //         onPick: onPick,
  //         isLarge: isLarge,
  //         height: isLarge ? 150 : 100,
  //         width: isLarge ? 150 : 100,
  //       ),
  //     ],
  //   );
  // }

  List<Widget> _buildOrganizationFields() {
    List<Widget> fields = [];

    if (widget.accountType != 'admin') {
      // Organization code for Employee and Office Boy
      fields.addAll([
        AuthTextField(
          controller: _orgCodeController,
          label: LocaleKeys.organizationCode.tr(),
          hint: LocaleKeys.enterOrganizationCode.tr(),
          prefixIcon: Icons.business_outlined,
          focusColor: _getAccountTypeColor(),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return LocaleKeys.pleaseEnterOrganizationCode.tr();
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
      ]);
    } else {
      // Organization name and color selection for Admin
      fields.addAll([
        AuthTextField(
          controller: _orgCodeController,
          label: LocaleKeys.organizationCode.tr(),
          hint: LocaleKeys.enterOrganizationCode.tr(),
          prefixIcon: Icons.business_outlined,
          focusColor: _getAccountTypeColor(),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return LocaleKeys.pleaseEnterOrganizationCode.tr();
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        AuthTextField(
          controller: _orgNameController,
          label: LocaleKeys.organizationName.tr(),
          hint: LocaleKeys.enterOrganizationName.tr(),
          prefixIcon: Icons.business_outlined,
          focusColor: _getAccountTypeColor(),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return LocaleKeys.pleaseEnterOrganizationName.tr();
            }
            return null;
          },
        ),
        // const SizedBox(height: 24),

        // // Organization Logo Picker for Admin
        // _buildImageSection(
        //   label: LocaleKeys.organizationLogo.tr(),
        //   image: _organizationLogo,
        //   onPick: (image) {
        //     setState(() {
        //       _organizationLogo = image;
        //     });
        //   },
        //   isLarge: true,
        // ),
        const SizedBox(height: 24),

        // Primary Color Selection
        ModernColorPicker(
          label: LocaleKeys.primary_color.tr(),
          selectedColor: _selectedPrimaryColor,
          hint: LocaleKeys.choose_your_organizations_main.tr(),
          onColorSelected: (color) {
            setState(() {
              _selectedPrimaryColor = color;
            });
          },
        ),
        const SizedBox(height: 24),

        // Secondary Color Selection
        ModernColorPicker(
          label: LocaleKeys.secondary_color.tr(),
          selectedColor: _selectedSecondaryColor,
          hint: LocaleKeys.choose_your_organization_secon.tr(),
          onColorSelected: (color) {
            setState(() {
              _selectedSecondaryColor = color;
            });
          },
        ),
        const SizedBox(height: 24),
      ]);
    }

    return fields;
  }

  Widget _buildSignInLink(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            LocaleKeys.alreadyHaveAccount.tr(),
            style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 16),
          ),
          TextButton(
            onPressed: () => context.go(Routes.login),
            child: Text(
              LocaleKeys.signIn.tr(),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getAccountTypeTitle() {
    switch (widget.accountType) {
      case 'admin':
        return LocaleKeys.organizationAdministrator.tr();
      case 'employee':
        return LocaleKeys.employeeAccount.tr();
      case 'office_boy':
        return LocaleKeys.officeBoyAccount.tr();
      default:
        return LocaleKeys.createAccount.tr();
    }
  }

  Color _getAccountTypeColor() {
    // switch (widget.accountType) {
    // case 'admin':
    //   return _selectedPrimaryColor;
    // case 'employee':
    //   return AppColors.secondary;
    // case 'office_boy':
    //   return Colors.teal;
    // default:
    return AppColors.secondary;
    // }
  }

  entities.UserRole _getAccountTypeRole() {
    switch (widget.accountType) {
      case 'admin':
        return entities.UserRole.admin;
      case 'employee':
        return entities.UserRole.employee;
      case 'office_boy':
        return entities.UserRole.officeBoy;
      default:
        return entities.UserRole.employee;
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  // Helper method to convert PlatformFile to XFile for compatibility
  // XFile? _platformFileToXFile(PlatformFile? platformFile) {
  //   if (platformFile?.path == null) return null;
  //   return XFile(platformFile!.path!);
  // }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    // For non-admin users, check organization code first
    if (widget.accountType != 'admin' && _orgCodeController.text.isNotEmpty) {
      context.read<AuthCubit>().checkOrganizationCode(_orgCodeController.text);

      // Wait for organization code check to complete
      await Future.delayed(const Duration(milliseconds: 500));

      final currentState = context.read<AuthCubit>().state;
      if (currentState is AuthOrganizationCodeChecked && !currentState.exists) {
        return; // Don't proceed if organization code doesn't exist
      }
    }

    // Proceed with registration
    context.read<AuthCubit>().signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      role: _getAccountTypeRole(),
      phone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      // profileImage: _platformFileToXFile(_profileImage),
      organizationName: _orgNameController.text.trim().isNotEmpty
          ? _orgNameController.text.trim()
          : null,
      organizationCode: _orgCodeController.text.trim().isNotEmpty
          ? _orgCodeController.text.trim()
          : null,
      // organizationLogo: _platformFileToXFile(_organizationLogo),
      primaryColor: widget.accountType == 'admin'
          ? _colorToHex(_selectedPrimaryColor)
          : null,
      secondaryColor: widget.accountType == 'admin'
          ? _colorToHex(_selectedSecondaryColor)
          : null,
    );
  }
}
