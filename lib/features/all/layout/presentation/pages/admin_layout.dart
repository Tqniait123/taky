// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:go_router/go_router.dart';
// import 'package:taqy/config/routes/routes.dart';
// import 'package:taqy/core/services/firebase_service.dart';
// import 'package:taqy/core/theme/colors.dart';
// import 'package:taqy/core/utils/dialogs/error_toast.dart';
// import 'package:taqy/core/utils/widgets/app_images.dart';
// import 'package:taqy/features/admin/data/models/app_user.dart';
// import 'package:taqy/features/admin/data/models/order.dart';
// import 'package:taqy/features/admin/data/models/organization.dart';
// import 'package:taqy/features/admin/presentation/widgets/admin_settings_bottom_sheet.dart';
// import 'package:taqy/features/admin/presentation/widgets/stat_card.dart';
// import 'package:taqy/features/all/auth/presentation/cubit/auth_cubit.dart';
// import 'package:taqy/features/all/splash/presentation/pages/splash.dart';

// class AdminLayout extends StatefulWidget {
//   const AdminLayout({super.key});

//   @override
//   State<AdminLayout> createState() => _AdminLayoutState();
// }

// class _AdminLayoutState extends State<AdminLayout>
//     with TickerProviderStateMixin {
//   late TabController _tabController;
//   late ScrollController _scrollController;
//   final FirebaseService _firebaseService = FirebaseService();

//   AdminOrganization? organization;
//   List<AdminOrder> orders = [];
//   List<AdminAppUser> employees = [];
//   List<AdminAppUser> officeBoys = [];
//   bool isLoading = true;
//   String? errorMessage;
//   OrderStatus? selectedFilter;

//   late AnimationController _backgroundController;

//   int _selectedIndex = 0;

//   // For scroll animation
//   double _scrollOffset = 0.0;
//   bool _isHeaderCollapsed = false;
//   late Animation<double> _backgroundGradient;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 4, vsync: this);
//     _scrollController = ScrollController();
//     _scrollController.addListener(_onScroll);

//     _backgroundController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 2000),
//     );

//     _backgroundGradient = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
//     );
//     _loadData();
//   }

//   void _onScroll() {
//     setState(() {
//       _scrollOffset = _scrollController.offset;
//       _isHeaderCollapsed = _scrollOffset > 100;
//     });
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadData() async {
//     try {
//       setState(() {
//         isLoading = true;
//         errorMessage = null;
//       });

//       final user = _firebaseService.currentUser;
//       if (user == null) {
//         throw Exception('User not authenticated');
//       }

//       final userDoc = await _firebaseService.getDocument('users', user.uid);
//       if (!userDoc.exists) {
//         throw Exception('User data not found');
//       }

//       final userData = userDoc.data() as Map<String, dynamic>;
//       final organizationId = userData['organizationId'] as String;

//       final orgDoc = await _firebaseService.getDocument(
//         'organizations',
//         organizationId,
//       );
//       if (orgDoc.exists) {
//         setState(() {
//           organization = AdminOrganization.fromFirestore(orgDoc);
//         });
//       }

//       _loadOrders(organizationId);
//       _loadUsers(organizationId);
//     } catch (e) {
//       setState(() {
//         errorMessage = e.toString();
//         isLoading = false;
//       });
//     }
//   }

//   void _loadOrders(String organizationId) {
//     _firebaseService
//         .streamOrganizationDocuments('orders', organizationId)
//         .listen(
//           (snapshot) {
//             setState(() {
//               orders = snapshot.docs
//                   .map((doc) => AdminOrder.fromFirestore(doc))
//                   .toList();
//               isLoading = false;
//             });
//           },
//           onError: (error) {
//             setState(() {
//               errorMessage = error.toString();
//               isLoading = false;
//             });
//           },
//         );
//   }

//   void _loadUsers(String organizationId) {
//     _firebaseService
//         .streamOrganizationDocuments('users', organizationId)
//         .listen(
//           (snapshot) {
//             final users = snapshot.docs
//                 .map((doc) => AdminAppUser.fromFirestore(doc))
//                 .toList();

//             setState(() {
//               employees = users
//                   .where((user) => user.role == UserRole.employee)
//                   .toList();
//               officeBoys = users
//                   .where((user) => user.role == UserRole.officeBoy)
//                   .toList();
//             });
//           },
//           onError: (error) {
//             setState(() {
//               errorMessage = error.toString();
//             });
//           },
//         );
//   }

//   void _handleLogout(BuildContext context) async {
//     await context.read<AuthCubit>().signOut();
//     if (context.mounted) {
//       Navigator.pop(context);
//       context.go(Routes.login);
//     }
//   }

//   void _showSettingsBottomSheet(BuildContext context) {
//     if (organization == null) return;

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (buildContext) => Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(24),
//             topRight: Radius.circular(24),
//           ),
//           border: Border(
//             top: BorderSide(
//               color: organization!.secondaryColorValue,
//               width: 4.0,
//             ),
//           ),
//         ),
//         child: AdminSettingsBottomSheet(
//           organization: organization!,
//           onSettingsUpdated: (updatedOrg) async {
//             try {
//               await _firebaseService.updateDocument(
//                 'organizations',
//                 organization!.id,
//                 updatedOrg.toFirestore(),
//               );

//               setState(() {
//                 organization = updatedOrg;
//               });

//               showSuccessToast(context, 'Settings updated successfully!');
//             } catch (e) {
//               showErrorToast(context, 'Failed to update settings: $e');
//             }
//           },
//           onLogout: () => _handleLogout(context),
//         ),
//       ),
//     );
//   }

//   List<AdminOrder> get filteredOrders {
//     if (selectedFilter == null) return orders;
//     return orders.where((order) => order.status == selectedFilter).toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return Scaffold(
//         backgroundColor: AppColors.background,
//         body: Center(
//           child: CircularProgressIndicator(
//             color: organization?.primaryColorValue ?? AppColors.primary,
//           ),
//         ),
//       );
//     }

//     if (errorMessage != null) {
//       return Scaffold(
//         backgroundColor: AppColors.background,
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.error_outline, size: 64, color: AppColors.error),
//               SizedBox(height: 16),
//               Text(
//                 'Error loading data',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               SizedBox(height: 8),
//               Text(errorMessage!),
//               SizedBox(height: 16),
//               ElevatedButton(onPressed: _loadData, child: Text('Retry')),
//             ],
//           ),
//         ),
//       );
//     }

//     if (organization == null) {
//       return Scaffold(
//         backgroundColor: AppColors.background,
//         body: Center(child: Text('Organization not found')),
//       );
//     }

//     return Scaffold(
//       backgroundColor: AppColors.background,
//       body: RefreshIndicator(
//         onRefresh: _loadData,
//         color: organization!.primaryColorValue,
//         strokeWidth: 2,
//         backgroundColor: Colors.white.withOpacity(0.8),
//         elevation: 0,
//         child: SingleChildScrollView(
//           physics: AlwaysScrollableScrollPhysics(),
//           child: Stack(
//             children: [
//               // Main scrollable content

//               // Animated header
//               AnimatedPositioned(
//                 duration: const Duration(milliseconds: 300),
//                 top: _isHeaderCollapsed ? -50 : 0,
//                 left: 0,
//                 right: 0,
//                 child: Container(
//                   height: MediaQuery.of(context).size.height * 0.5,
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [
//                         organization!.primaryColorValue,
//                         organization!.secondaryColorValue,
//                       ],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                   ),
//                   child: SafeArea(
//                     child: Stack(
//                       children: [
//                         // Left icon (refresh)
//                         Positioned.fill(
//                           child: CustomPaint(
//                             painter: ParticlesPainter(
//                               _backgroundGradient.value,
//                             ),
//                           ),
//                         ),
//                         Positioned(
//                           top: 20,
//                           left: 20,
//                           child: Container(
//                             decoration: BoxDecoration(
//                               color: Colors.white.withOpacity(0.2),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: IconButton(
//                               icon: SvgPicture.asset(
//                                 Assets.imagesSvgsNotification,
//                                 color: Colors.white,
//                               ),
//                               onPressed: _loadData,
//                             ),
//                           ),
//                         ),

//                         // Right icon (settings)
//                         Positioned(
//                           top: 20,
//                           right: 20,
//                           child: Container(
//                             decoration: BoxDecoration(
//                               color: Colors.white.withOpacity(0.2),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: IconButton(
//                               icon: SvgPicture.asset(
//                                 Assets.imagesSvgsSetting,
//                                 color: Colors.white,
//                               ),
//                               onPressed: () =>
//                                   _showSettingsBottomSheet(context),
//                             ),
//                           ),
//                         ),

//                         // Center logo and text
//                         Center(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               // Logo container
//                               Container(
//                                 height: 80,
//                                 width: 80,
//                                 decoration: BoxDecoration(
//                                   color: Colors.white.withOpacity(0.2),
//                                   borderRadius: BorderRadius.circular(20),
//                                   border: Border.all(
//                                     color: Colors.white.withOpacity(0.3),
//                                     width: 2,
//                                   ),
//                                 ),
//                                 child: organization!.logoUrl != null
//                                     ? ClipRRect(
//                                         borderRadius: BorderRadius.circular(18),
//                                         child: Image.network(
//                                           organization!.logoUrl!,
//                                           fit: BoxFit.cover,
//                                           errorBuilder:
//                                               (context, error, stackTrace) =>
//                                                   Center(
//                                                     child: SvgPicture.asset(
//                                                       Assets.imagesSvgsCompany,
//                                                       height: 45,
//                                                       width: 45,
//                                                       color: Colors.white,
//                                                     ),
//                                                   ),
//                                         ),
//                                       )
//                                     : Center(
//                                         child: SvgPicture.asset(
//                                           Assets.imagesSvgsCompany,
//                                           height: 45,
//                                           width: 45,
//                                           color: Colors.white,
//                                         ),
//                                       ),
//                               ),
//                               const SizedBox(height: 16),

//                               // Organization name
//                               Text(
//                                 organization!.name,
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 24,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),

//                               // Subtitle
//                               Text(
//                                 'Admin Dashboard',
//                                 style: TextStyle(
//                                   color: Colors.white.withOpacity(0.8),
//                                   fontSize: 16,
//                                 ),
//                               ),

//                               _buildNavigationBar(),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               Column(
//                 children: [
//                   // Header space
//                   SizedBox(height: MediaQuery.of(context).size.height * 0.42),
//                   // Tab content area
//                   Container(
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: const BorderRadius.only(
//                         topLeft: Radius.circular(24),
//                         topRight: Radius.circular(24),
//                       ),
//                     ),
//                     child: Column(
//                       children: [
//                         // Tab bar container
//                         SizedBox(height: 16),
//                         // Tab content
//                         _buildSelectedContent(),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildNavigationBar() {
//     final navItems = [
//       {'title': 'Overview', 'icon': Assets.imagesSvgsOverview},
//       {'title': 'Orders', 'icon': Assets.imagesSvgsOrder},
//       {'title': 'Employees', 'icon': Assets.imagesSvgsUsers},
//       {'title': 'Office Boys', 'icon': Icons.delivery_dining},
//     ];

//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//       padding: EdgeInsets.all(4),
//       decoration: BoxDecoration(
//         color: AppColors.glass,
//         borderRadius: BorderRadius.circular(25),
//         border: Border.all(color: AppColors.glassStroke, width: 1),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 20,
//             offset: Offset(0, 8),
//           ),
//         ],
//       ),
//       child: Row(
//         children: navItems.asMap().entries.map((entry) {
//           final index = entry.key;
//           final item = entry.value;
//           final isSelected = _selectedIndex == index;

//           return Expanded(
//             child: GestureDetector(
//               onTap: () => setState(() => _selectedIndex = index),
//               child: AnimatedContainer(
//                 duration: Duration(milliseconds: 300),
//                 curve: Curves.easeInOutCubic,
//                 margin: EdgeInsets.all(2),
//                 padding: EdgeInsets.symmetric(vertical: 12),
//                 decoration: BoxDecoration(
//                   gradient: isSelected
//                       ? LinearGradient(
//                           colors: [
//                             Colors.white.withOpacity(.1),
//                             Colors.white.withOpacity(.2),
//                             Colors.white.withOpacity(.3),
//                           ],
//                         )
//                       : null,
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     navItems[index]['icon'] is String
//                         ? SvgPicture.asset(
//                             item['icon'] as String,
//                             color: isSelected
//                                 ? Colors.white
//                                 : Colors.white.withOpacity(0.7),
//                           )
//                         : Icon(
//                             item['icon'] as IconData,
//                             color: isSelected
//                                 ? Colors.white
//                                 : Colors.white.withOpacity(0.7),
//                           ),
//                     SizedBox(height: 4),
//                     Text(
//                       item['title'] as String,
//                       style: TextStyle(
//                         color: isSelected
//                             ? Colors.white
//                             : Colors.white.withOpacity(0.7),
//                         fontWeight: isSelected
//                             ? FontWeight.w600
//                             : FontWeight.w400,
//                         fontSize: 11,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }

//   Widget _buildSelectedContent() {
//     switch (_selectedIndex) {
//       case 0:
//         return _buildOverviewTab();
//       case 1:
//         return _buildOrdersTab();
//       case 2:
//         return _buildEmployeesTab();
//       case 3:
//         return _buildOfficeBoysTab();
//       default:
//         return _buildOverviewTab();
//     }
//   }

//   Widget _buildEmployeesTab() {
//     return Column(
//       children: [
//         Container(
//           padding: EdgeInsets.all(16),
//           color: Colors.white,
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Employees',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: AppColors.onSurface,
//                     ),
//                   ),
//                   Text(
//                     '${employees.length} total employees',
//                     style: TextStyle(
//                       color: AppColors.onSurfaceVariant,
//                       fontSize: 14,
//                     ),
//                   ),
//                 ],
//               ),
//               Container(
//                 padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: organization!.primaryColorValue.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Text(
//                   '${employees.where((e) => e.isActive).length} Active',
//                   style: TextStyle(
//                     color: organization!.primaryColorValue,
//                     fontSize: 12,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),

//         employees.isEmpty
//             ? _buildEmptyState('No employees found', Icons.people)
//             : ListView.builder(
//                 padding: EdgeInsets.all(16),
//                 itemCount: employees.length,
//                 shrinkWrap: true,
//                 physics: NeverScrollableScrollPhysics(),
//                 itemBuilder: (context, index) {
//                   return _buildUserCard(employees[index]);
//                 },
//               ),
//       ],
//     );
//   }

//   Widget _buildOfficeBoysTab() {
//     return Column(
//       children: [
//         Container(
//           padding: EdgeInsets.all(16),
//           color: Colors.white,
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Office Boys',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: AppColors.onSurface,
//                     ),
//                   ),
//                   Text(
//                     '${officeBoys.length} total office boys',
//                     style: TextStyle(
//                       color: AppColors.onSurfaceVariant,
//                       fontSize: 14,
//                     ),
//                   ),
//                 ],
//               ),
//               Container(
//                 padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: organization!.secondaryColorValue.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Text(
//                   '${officeBoys.where((o) => o.isActive).length} Active',
//                   style: TextStyle(
//                     color: organization!.secondaryColorValue,
//                     fontSize: 12,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),

//         officeBoys.isEmpty
//             ? _buildEmptyState('No office boys found', Icons.delivery_dining)
//             : ListView.builder(
//                 padding: EdgeInsets.all(16),
//                 itemCount: officeBoys.length,
//                 shrinkWrap: true,
//                 physics: NeverScrollableScrollPhysics(),
//                 itemBuilder: (context, index) {
//                   return _buildUserCard(officeBoys[index]);
//                 },
//               ),
//       ],
//     );
//   }

//   Widget _buildUserCard(AdminAppUser user) {
//     final userOrders = orders
//         .where(
//           (order) =>
//               order.employeeId == user.id || order.officeBoyId == user.id,
//         )
//         .length;

//     final completedOrders = orders
//         .where(
//           (order) =>
//               (order.employeeId == user.id || order.officeBoyId == user.id) &&
//               order.status == OrderStatus.completed,
//         )
//         .length;

//     return Container(
//       margin: EdgeInsets.only(bottom: 16),
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 8,
//             offset: Offset(0, 2),
//           ),
//         ],
//         border: !user.isActive
//             ? Border.all(color: AppColors.error.withOpacity(0.3))
//             : null,
//       ),
//       child: Row(
//         children: [
//           Container(
//             height: 60,
//             width: 60,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(30),
//               gradient: LinearGradient(
//                 colors: user.role == UserRole.employee
//                     ? [
//                         organization!.primaryColorValue,
//                         organization!.secondaryColorValue,
//                       ]
//                     : [
//                         organization!.secondaryColorValue,
//                         organization!.primaryColorValue,
//                       ],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//             child: user.profilePictureUrl != null
//                 ? ClipRRect(
//                     borderRadius: BorderRadius.circular(30),
//                     child: Image.network(
//                       user.profilePictureUrl!,
//                       fit: BoxFit.cover,
//                       errorBuilder: (context, error, stackTrace) => Icon(
//                         user.role == UserRole.employee
//                             ? Icons.person
//                             : Icons.delivery_dining,
//                         color: Colors.white,
//                         size: 30,
//                       ),
//                     ),
//                   )
//                 : Icon(
//                     user.role == UserRole.employee
//                         ? Icons.person
//                         : Icons.delivery_dining,
//                     color: Colors.white,
//                     size: 30,
//                   ),
//           ),
//           SizedBox(width: 16),

//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Text(
//                         user.name,
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                           color: !user.isActive
//                               ? AppColors.onSurfaceVariant
//                               : AppColors.onSurface,
//                         ),
//                       ),
//                     ),
//                     if (!user.isActive)
//                       Container(
//                         padding: EdgeInsets.symmetric(
//                           horizontal: 8,
//                           vertical: 4,
//                         ),
//                         decoration: BoxDecoration(
//                           color: AppColors.error.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Text(
//                           'Inactive',
//                           style: TextStyle(
//                             color: AppColors.error,
//                             fontSize: 10,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//                 SizedBox(height: 4),
//                 Row(
//                   children: [
//                     SvgPicture.asset(
//                       Assets.imagesSvgsMail,
//                       height: 16,
//                       width: 16,
//                       color: organization!.primaryColorValue,
//                     ),
//                     SizedBox(width: 4),
//                     Expanded(
//                       child: Text(
//                         user.email,
//                         style: TextStyle(
//                           color: AppColors.onSurfaceVariant,
//                           fontSize: 12,
//                         ),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 2),
//                 Row(
//                   children: [
//                     SvgPicture.asset(
//                       Assets.imagesSvgsPhone,
//                       height: 16,
//                       width: 16,
//                       color: organization!.primaryColorValue,
//                     ),
//                     SizedBox(width: 4),
//                     Text(
//                       user.phone,
//                       style: TextStyle(
//                         color: AppColors.onSurfaceVariant,
//                         fontSize: 12,
//                       ),
//                     ),
//                   ],
//                 ),
//                 if (user.department != null) ...[
//                   SizedBox(height: 2),
//                   Row(
//                     children: [
//                       SvgPicture.asset(
//                         Assets.imagesSvgsCompany,
//                         height: 16,
//                         width: 16,
//                         color: organization!.primaryColorValue,
//                       ),
//                       SizedBox(width: 4),
//                       Text(
//                         user.department!,
//                         style: TextStyle(
//                           color: AppColors.onSurfaceVariant,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ],
//             ),
//           ),

//           Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Text(
//                 '$userOrders',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 18,
//                   color: organization!.secondaryColorValue,
//                 ),
//               ),
//               Text(
//                 user.role == UserRole.employee ? 'Orders' : 'Deliveries',
//                 style: TextStyle(
//                   color: AppColors.onSurfaceVariant,
//                   fontSize: 12,
//                 ),
//               ),
//               SizedBox(height: 4),
//               Text(
//                 '$completedOrders completed',
//                 style: TextStyle(
//                   color: AppColors.success,
//                   fontSize: 10,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildOverviewTab() {
//     final totalOrders = orders.length;
//     final pendingOrders = orders
//         .where((o) => o.status == OrderStatus.pending)
//         .length;
//     final completedOrders = orders
//         .where((o) => o.status == OrderStatus.completed)
//         .length;
//     final internalOrders = orders
//         .where((o) => o.type == OrderType.internal)
//         .length;
//     final externalOrders = orders
//         .where((o) => o.type == OrderType.external)
//         .length;
//     final todayOrders = orders
//         .where(
//           (o) =>
//               o.createdAt.day == DateTime.now().day &&
//               o.createdAt.month == DateTime.now().month &&
//               o.createdAt.year == DateTime.now().year,
//         )
//         .length;

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           GridView.count(
//             crossAxisCount: 2,
//             crossAxisSpacing: 12,
//             mainAxisSpacing: 12,
//             childAspectRatio: 1.7,
//             shrinkWrap: true,
//             padding: EdgeInsets.all(0),
//             physics: NeverScrollableScrollPhysics(),
//             children: [
//               StatCard(
//                 title: 'Total Orders',
//                 value: totalOrders.toString(),
//                 icon: Assets.imagesSvgsOrder,
//                 color: organization!.primaryColorValue,
//                 textColor: organization!.secondaryColorValue,
//               ),
//               StatCard(
//                 title: 'Today\'s Orders',
//                 value: todayOrders.toString(),
//                 icon: Assets.imagesSvgsCalendar,
//                 color: organization!.primaryColorValue,
//                 textColor: organization!.secondaryColorValue,
//               ),
//               StatCard(
//                 title: 'Employees',
//                 value: employees.length.toString(),
//                 icon: Assets.imagesSvgsUsers,
//                 color: organization!.primaryColorValue,
//                 textColor: organization!.secondaryColorValue,
//               ),
//               StatCard(
//                 title: 'Office Boys',
//                 value: officeBoys.length.toString(),
//                 iconData: Icons.delivery_dining,
//                 color: organization!.primaryColorValue,
//                 textColor: organization!.secondaryColorValue,
//               ),
//               StatCard(
//                 title: 'Internal Orders',
//                 value: internalOrders.toString(),
//                 icon: Assets.imagesSvgsCoffee,
//                 color: organization!.primaryColorValue,
//                 textColor: organization!.secondaryColorValue,
//               ),
//               StatCard(
//                 title: 'External Orders',
//                 value: externalOrders.toString(),
//                 icon: Assets.imagesSvgsMoney,
//                 color: organization!.primaryColorValue,
//                 textColor: organization!.secondaryColorValue,
//               ),
//               StatCard(
//                 title: 'Pending',
//                 value: pendingOrders.toString(),
//                 icon: Assets.imagesSvgsPending,
//                 color: organization!.primaryColorValue,
//                 textColor: organization!.secondaryColorValue,
//               ),
//               StatCard(
//                 title: 'Completed',
//                 value: completedOrders.toString(),
//                 icon: Assets.imagesSvgsComplete,
//                 color: organization!.primaryColorValue,
//                 textColor: organization!.secondaryColorValue,
//                 isComplete: true,
//               ),
//               StatCard(
//                 title: 'Cancelled',
//                 value: orders
//                     .where((o) => o.status == OrderStatus.cancelled)
//                     .length
//                     .toString(),
//                 icon: Assets.imagesSvgsCancell,
//                 color: organization!.primaryColorValue,
//                 textColor: organization!.secondaryColorValue,
//               ),
//             ],
//           ),

//           SizedBox(height: 24),
//         ],
//       ),
//     );
//   }

//   Widget _buildOrdersTab() {
//     return Column(
//       children: [
//         Container(
//           padding: EdgeInsets.all(16),
//           color: Colors.white,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Filter Orders',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                   color: AppColors.onSurface,
//                 ),
//               ),
//               SizedBox(height: 12),
//               SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 child: Row(
//                   children: [
//                     _buildFilterChip('All', selectedFilter == null),
//                     _buildFilterChip(
//                       'Pending',
//                       selectedFilter == OrderStatus.pending,
//                     ),
//                     _buildFilterChip(
//                       'In Progress',
//                       selectedFilter == OrderStatus.inProgress,
//                     ),
//                     _buildFilterChip(
//                       'Completed',
//                       selectedFilter == OrderStatus.completed,
//                     ),
//                     _buildFilterChip(
//                       'Cancelled',
//                       selectedFilter == OrderStatus.cancelled,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),

//         filteredOrders.isEmpty
//             ? _buildEmptyState('No orders found', Icons.search_off)
//             : ListView.builder(
//                 padding: EdgeInsets.all(16),
//                 shrinkWrap: true,
//                 physics: NeverScrollableScrollPhysics(),
//                 itemCount: filteredOrders.length,
//                 itemBuilder: (context, index) {
//                   return _buildDetailedOrderCard(filteredOrders[index]);
//                 },
//               ),
//       ],
//     );
//   }

//   Widget _buildDetailedOrderCard(AdminOrder order) {
//     // Calculate display price (finalPrice if available, otherwise price)
//     final displayPrice = order.finalPrice ?? order.price;
//     final hasPriceChange =
//         order.finalPrice != null &&
//         order.price != null &&
//         order.finalPrice != order.price;

//     return Container(
//       margin: EdgeInsets.only(bottom: 16),
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 8,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Order #${order.id.substring(0, 8)}',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                   color: AppColors.onSurface,
//                 ),
//               ),
//               _buildStatusChip(order.status),
//             ],
//           ),
//           SizedBox(height: 12),

//           // Display items (support multiple items)
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   SvgPicture.asset(
//                     order.type == OrderType.internal
//                         ? Assets.imagesSvgsCompany
//                         : Assets.imagesSvgsShoppingCart,
//                     color: _getOrderTypeColor(order.type),
//                     height: 20,
//                     width: 20,
//                   ),
//                   SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       'Items (${order.items.length}):',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                         color: AppColors.onSurfaceVariant,
//                       ),
//                     ),
//                   ),
//                   if (displayPrice != null)
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       children: [
//                         if (hasPriceChange) ...[
//                           Text(
//                             'EGP ${order.price!.toStringAsFixed(0)}',
//                             style: TextStyle(
//                               color: AppColors.onSurfaceVariant,
//                               fontSize: 12,
//                               decoration: TextDecoration.lineThrough,
//                             ),
//                           ),
//                           Text(
//                             'EGP ${order.finalPrice!.toStringAsFixed(0)}',
//                             style: TextStyle(
//                               color: AppColors.success,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 14,
//                             ),
//                           ),
//                         ] else
//                           Text(
//                             'EGP ${displayPrice.toStringAsFixed(0)}',
//                             style: TextStyle(
//                               color: AppColors.success,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                       ],
//                     ),
//                 ],
//               ),
//               SizedBox(height: 8),

//               // Display each item with its status
//               ...order.items.map(
//                 (item) => Padding(
//                   padding: EdgeInsets.only(left: 28, bottom: 4),
//                   child: Row(
//                     children: [
//                       Container(
//                         width: 8,
//                         height: 8,
//                         decoration: BoxDecoration(
//                           color: _getItemStatusColor(item.status),
//                           borderRadius: BorderRadius.circular(4),
//                         ),
//                       ),
//                       SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           item.name,
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: item.status == ItemStatus.notAvailable
//                                 ? AppColors.onSurfaceVariant
//                                 : AppColors.onSurface,
//                             decoration: item.status == ItemStatus.notAvailable
//                                 ? TextDecoration.lineThrough
//                                 : null,
//                           ),
//                         ),
//                       ),
//                       if (item.notes != null && item.notes!.isNotEmpty)
//                         Text(
//                           item.notes!,
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: AppColors.onSurfaceVariant,
//                             fontStyle: FontStyle.italic,
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ),

//               if (order.description.isNotEmpty) ...[
//                 SizedBox(height: 8),
//                 Padding(
//                   padding: EdgeInsets.only(left: 28),
//                   child: Text(
//                     order.description,
//                     style: TextStyle(
//                       color: AppColors.onSurfaceVariant,
//                       fontSize: 14,
//                       fontStyle: FontStyle.italic,
//                     ),
//                   ),
//                 ),
//               ],
//             ],
//           ),
//           SizedBox(height: 12),

//           Row(
//             children: [
//               Expanded(
//                 child: Row(
//                   children: [
//                     SvgPicture.asset(
//                       Assets.imagesSvgsUser,
//                       color: organization!.primaryColorValue,
//                       height: 16,
//                       width: 16,
//                     ),
//                     SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         order.employeeName,
//                         style: TextStyle(color: AppColors.onSurfaceVariant),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Expanded(
//                 child: Row(
//                   children: [
//                     Icon(
//                       Icons.delivery_dining_rounded,
//                       color: organization!.primaryColorValue,
//                       size: 20,
//                     ),
//                     SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         order.officeBoyName,
//                         style: TextStyle(color: AppColors.onSurfaceVariant),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 8),

//           Row(
//             children: [
//               SvgPicture.asset(
//                 Assets.imagesSvgsClock,
//                 color: organization!.primaryColorValue,
//                 height: 16,
//                 width: 16,
//               ),
//               SizedBox(width: 8),
//               Text(
//                 _formatTime(order.createdAt),
//                 style: TextStyle(
//                   color: AppColors.onSurfaceVariant,
//                   fontSize: 12,
//                 ),
//               ),
//               if (order.notes != null && order.notes!.isNotEmpty) ...[
//                 SizedBox(width: 16),
//                 SvgPicture.asset(
//                   Assets.imagesSvgsOrder,
//                   color: organization!.primaryColorValue,
//                   height: 16,
//                   width: 16,
//                 ),
//                 SizedBox(width: 4),
//                 Expanded(
//                   child: Text(
//                     order.notes!,
//                     style: TextStyle(
//                       color: AppColors.onSurfaceVariant,
//                       fontSize: 12,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
//             ],
//           ),

//           // Show employee response if available
//           if (order.employeeResponse != null &&
//               order.employeeResponse!.isNotEmpty) ...[
//             SizedBox(height: 8),
//             Container(
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.blue.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Row(
//                 children: [
//                   Icon(Icons.chat_bubble_outline, color: Colors.blue, size: 16),
//                   SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       'Employee Response: ${order.employeeResponse}',
//                       style: TextStyle(
//                         color: Colors.blue.shade700,
//                         fontSize: 12,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Color _getItemStatusColor(ItemStatus status) {
//     switch (status) {
//       case ItemStatus.pending:
//         return Colors.orange;
//       case ItemStatus.available:
//         return AppColors.success;
//       case ItemStatus.notAvailable:
//         return AppColors.error;
//     }
//   }

//   Widget _buildFilterChip(String label, bool isSelected) {
//     return Container(
//       margin: EdgeInsets.only(right: 8),
//       child: FilterChip(
//         label: Text(label),
//         selected: isSelected,
//         side: BorderSide(
//           color: isSelected
//               ? organization!.primaryColorValue
//               : Colors.grey[300]!,
//         ),
//         onSelected: (bool value) {
//           setState(() {
//             if (label == 'All') {
//               selectedFilter = null;
//             } else if (label == 'Pending') {
//               selectedFilter = value ? OrderStatus.pending : null;
//             } else if (label == 'In Progress') {
//               selectedFilter = value ? OrderStatus.inProgress : null;
//             } else if (label == 'Completed') {
//               selectedFilter = value ? OrderStatus.completed : null;
//             } else if (label == 'Cancelled') {
//               selectedFilter = value ? OrderStatus.cancelled : null;
//             }
//           });
//         },
//         selectedColor: organization!.primaryColorValue.withOpacity(0.2),
//         checkmarkColor: organization!.primaryColorValue,
//         backgroundColor: Colors.white,

//         labelStyle: TextStyle(
//           color: isSelected
//               ? organization!.primaryColorValue
//               : AppColors.onSurfaceVariant,
//           fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//         ),
//       ),
//     );
//   }

//   Widget _buildEmptyState(String message, IconData icon) {
//     return Container(
//       padding: EdgeInsets.all(32),
//       child: Center(
//         child: Column(
//           children: [
//             Icon(
//               icon,
//               size: 64,
//               color: AppColors.onSurfaceVariant.withOpacity(0.5),
//             ),
//             SizedBox(height: 16),
//             Text(
//               message,
//               style: TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Color _getOrderTypeColor(OrderType type) {
//     return type == OrderType.internal
//         ? organization!.secondaryColorValue
//         : organization!.primaryColorValue;
//   }

//   String _formatTime(DateTime dateTime) {
//     final now = DateTime.now();
//     final difference = now.difference(dateTime);

//     if (difference.inMinutes < 60) {
//       return '${difference.inMinutes}m ago';
//     } else if (difference.inHours < 24) {
//       return '${difference.inHours}h ago';
//     } else {
//       return '${difference.inDays}d ago';
//     }
//   }

//   //

//   Widget _buildStatusChip(OrderStatus status) {
//     Color color;
//     String text;

//     switch (status) {
//       case OrderStatus.pending:
//         color = Colors.orange;
//         text = 'Pending';
//         break;
//       case OrderStatus.inProgress:
//         color = Colors.blue;
//         text = 'In Progress';
//         break;
//       case OrderStatus.completed:
//         color = AppColors.success;
//         text = 'Completed';
//         break;
//       case OrderStatus.cancelled:
//         color = AppColors.error;
//         text = 'Cancelled';
//         break;
//       case OrderStatus.needsResponse:
//         color = Colors.purple;
//         text = 'Need Response';
//         break;
//     }

//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Text(
//         text,
//         style: TextStyle(
//           color: color,
//           fontSize: 12,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//     );
//   }
// }

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:taqy/core/services/firebase_service.dart';
import 'package:taqy/core/static/app_assets.dart';
import 'package:taqy/core/theme/colors.dart';
import 'package:taqy/core/utils/dialogs/error_toast.dart';
import 'package:taqy/core/utils/widgets/app_images.dart';
import 'package:taqy/features/admin/data/models/app_user.dart';
import 'package:taqy/features/admin/data/models/order.dart';
import 'package:taqy/features/admin/data/models/organization.dart';
import 'package:taqy/features/admin/presentation/widgets/admin_settings_bottom_sheet.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  final FirebaseService _firebaseService = FirebaseService();

  AdminOrganization? organization;
  List<AdminOrder> orders = [];
  List<AdminAppUser> employees = [];
  List<AdminAppUser> officeBoys = [];
  bool isLoading = true;
  String? errorMessage;
  OrderStatus? selectedFilter;

  // Animation Controllers
  late AnimationController _backgroundController;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late AnimationController _shimmerController;
  late AnimationController _glowController;

  // Animations
  late Animation<double> _backgroundGradient;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _glowAnimation;

  int _selectedIndex = 0;
  double _scrollOffset = 0.0;
  bool _isHeaderCollapsed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _initializeAnimations();
    _loadData();
  }

  void _initializeAnimations() {
    // Background animation controller
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _backgroundGradient = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    // Pulse animation for active elements
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Slide animation for content
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    // Fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    // Scale animation
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Rotation animation
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Shimmer effect
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Start continuous animations
    _backgroundController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
    _shimmerController.repeat();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
      _isHeaderCollapsed = _scrollOffset > 100;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _backgroundController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    _glowController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Start entrance animations
      _slideController.reset();
      _fadeController.reset();
      _scaleController.reset();

      final user = _firebaseService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final userDoc = await _firebaseService.getDocument('users', user.uid);
      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final organizationId = userData['organizationId'] as String;

      final orgDoc = await _firebaseService.getDocument(
        'organizations',
        organizationId,
      );
      if (orgDoc.exists) {
        setState(() {
          organization = AdminOrganization.fromFirestore(orgDoc);
        });
      }

      _loadOrders(organizationId);
      _loadUsers(organizationId);

      // Trigger entrance animations
      _slideController.forward();
      _fadeController.forward();
      _scaleController.forward();
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _loadOrders(String organizationId) {
    _firebaseService
        .streamOrganizationDocuments('orders', organizationId)
        .listen(
          (snapshot) {
            setState(() {
              orders = snapshot.docs
                  .map((doc) => AdminOrder.fromFirestore(doc))
                  .toList();
              isLoading = false;
            });
          },
          onError: (error) {
            setState(() {
              errorMessage = error.toString();
              isLoading = false;
            });
          },
        );
  }

  void _loadUsers(String organizationId) {
    _firebaseService
        .streamOrganizationDocuments('users', organizationId)
        .listen(
          (snapshot) {
            final users = snapshot.docs
                .map((doc) => AdminAppUser.fromFirestore(doc))
                .toList();

            setState(() {
              employees = users
                  .where((user) => user.role == UserRole.employee)
                  .toList();
              officeBoys = users
                  .where((user) => user.role == UserRole.officeBoy)
                  .toList();
            });
          },
          onError: (error) {
            setState(() {
              errorMessage = error.toString();
            });
          },
        );
  }

  // void _handleLogout(BuildContext context) async {
  //   await context.read<AuthCubit>().signOut();
  //   if (context.mounted) {
  //     Navigator.pop(context);
  //     context.go(Routes.login);
  //   }
  // }

  void _showSettingsBottomSheet(BuildContext context) {
    if (organization == null) return;

    // Create a custom page route for smooth animation
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return AdminSettingsBottomSheet(
            organization: organization!,
            onSettingsUpdated: (updatedOrg) async {
              try {
                await _firebaseService.updateDocument(
                  'organizations',
                  organization!.id,
                  updatedOrg.toFirestore(),
                );

                setState(() {
                  organization = updatedOrg;
                });

                showSuccessToast(context, 'Settings updated successfully!');
              } catch (e) {
                showErrorToast(context, 'Failed to update settings: $e');
              }
            },
            // onLogout: () => _handleLogout(context),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide up animation
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          // Scale animation for backdrop
          var scaleAnimation = Tween<double>(
            begin: 0.9,
            end: 1.0,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

          // Fade animation for backdrop
          var fadeAnimation = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

          return Stack(
            children: [
              // Animated backdrop
              FadeTransition(
                opacity: fadeAnimation,
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),

              // Animated bottom sheet
              SlideTransition(
                position: animation.drive(tween),
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: ScaleTransition(
                    scale: scaleAnimation,
                    alignment: Alignment.bottomCenter,
                    child: child,
                  ),
                ),
              ),
            ],
          );
        },
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.transparent,
      ),
    );
  }

  List<AdminOrder> get filteredOrders {
    if (selectedFilter == null) return orders;
    return orders.where((order) => order.status == selectedFilter).toList();
  }

  Widget _buildAnimatedUserHeader(
    String title,
    List<AdminAppUser> users,
    Color color,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => FadeTransition(
        opacity: AlwaysStoppedAnimation(value.clamp(0.0, 1.0)),
        child: Transform.translate(
          offset: Offset(0, -30 * (1 - value)),
          child: Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '${users.length} total ${title.toLowerCase()}',
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                AnimatedContainer(
                  duration: Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    // boxShadow: [
                    //   BoxShadow(
                    //     color: color.withOpacity(0.2),
                    //     blurRadius: 8,
                    //     offset: Offset(0, 2),
                    //   ),
                    // ],
                  ),
                  child: Text(
                    '${users.where((u) => u.isActive).length} Active',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedEmptyState(String message, IconData icon) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 1000),
      curve: Curves.elasticOut,
      builder: (context, value, child) => Transform.scale(
        scale: value.clamp(0.1, 1.0),
        child: Container(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) => Transform.scale(
                    scale: _pulseAnimation.value.clamp(0.5, 1.5),
                    child: Icon(
                      icon,
                      size: 64,
                      color: AppColors.onSurfaceVariant.withOpacity(0.5),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                FadeTransition(
                  opacity: AlwaysStoppedAnimation(
                    _fadeAnimation.value.clamp(0.0, 1.0),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) => ShimmerLoading(
              shimmerAnimation: _shimmerAnimation,
              primaryColor:
                  organization?.primaryColorValue ?? AppColors.primary,
            ),
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.elasticOut,
          builder: (context, value, child) => Transform.scale(
            scale: value.clamp(0.1, 1.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) => Transform.scale(
                      scale: _pulseAnimation.value.clamp(0.5, 1.5),
                      child: Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Error loading data',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(errorMessage!),
                  SizedBox(height: 16),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: ElevatedButton(
                      onPressed: _loadData,
                      child: Text('Retry'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (organization == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Organization not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: organization!.primaryColorValue,
        strokeWidth: 2,
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          controller: _scrollController,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _fadeController,
              _slideController,
              _scaleController,
            ]),
            builder: (context, child) => FadeTransition(
              opacity: AlwaysStoppedAnimation(
                _fadeAnimation.value.clamp(0.0, 1.0),
              ),
              child: SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: AlwaysStoppedAnimation(
                    _scaleAnimation.value.clamp(0.1, 1.0),
                  ),
                  child: Stack(
                    children: [
                      // Animated header
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        top: _isHeaderCollapsed ? -50 : 0,
                        left: 0,
                        right: 0,
                        child: _buildAnimatedHeader(),
                      ),
                      Column(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.42,
                          ),
                          AnimatedContainer(
                            duration: Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: Offset(0, -5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                SizedBox(height: 16),
                                _buildSelectedContent(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedOverviewTab() {
    final totalOrders = orders.length;
    final pendingOrders = orders
        .where((o) => o.status == OrderStatus.pending)
        .length;
    final completedOrders = orders
        .where((o) => o.status == OrderStatus.completed)
        .length;
    final internalOrders = orders
        .where((o) => o.type == OrderType.internal)
        .length;
    final externalOrders = orders
        .where((o) => o.type == OrderType.external)
        .length;
    final todayOrders = orders
        .where(
          (o) =>
              o.createdAt.day == DateTime.now().day &&
              o.createdAt.month == DateTime.now().month &&
              o.createdAt.year == DateTime.now().year,
        )
        .length;

    final statData = [
      {
        'title': 'Total Orders',
        'value': totalOrders.toString(),
        'icon': Assets.imagesSvgsOrder,
      },
      {
        'title': 'Today\'s Orders',
        'value': todayOrders.toString(),
        'icon': Assets.imagesSvgsCalendar,
      },
      {
        'title': 'Employees',
        'value': employees.length.toString(),
        'icon': Assets.imagesSvgsUsers,
      },
      {
        'title': 'Office Boys',
        'value': officeBoys.length.toString(),
        'iconData': Icons.delivery_dining,
      },
      {
        'title': 'Internal Orders',
        'value': internalOrders.toString(),
        'icon': Assets.imagesSvgsCoffee,
      },
      {
        'title': 'External Orders',
        'value': externalOrders.toString(),
        'icon': Assets.imagesSvgsMoney,
      },
      {
        'title': 'Pending',
        'value': pendingOrders.toString(),
        'icon': Assets.imagesSvgsPending,
      },
      {
        'title': 'Completed',
        'value': completedOrders.toString(),
        'icon': Assets.imagesSvgsComplete,
        'isComplete': true,
      },
      {
        'title': 'Cancelled',
        'value': orders
            .where((o) => o.status == OrderStatus.cancelled)
            .length
            .toString(),
        'icon': Assets.imagesSvgsCancell,
      },
    ];

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16, bottom: 32),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.7,
        ),
        shrinkWrap: true,
        padding: EdgeInsets.all(0),
        physics: NeverScrollableScrollPhysics(),
        itemCount: statData.length,
        itemBuilder: (context, index) {
          final stat = statData[index];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 600 + (index * 100)),
            curve: Curves.elasticOut,
            builder: (context, value, child) => Transform.scale(
              scale: value.clamp(0.1, 1.0),
              child: AnimatedStatCard(
                title: stat['title'] as String,
                value: stat['value'] as String,
                icon: stat['icon'] as String? ?? '',
                iconData: stat['iconData'] as IconData?,
                color: organization!.primaryColorValue,
                textColor: organization!.secondaryColorValue,
                isComplete: stat['isComplete'] as bool? ?? false,
                animationController: _pulseController,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            organization!.primaryColorValue,
            organization!.secondaryColorValue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Animated particles background
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _backgroundController,
                builder: (context, child) => CustomPaint(
                  painter: AnimatedParticlesPainter(
                    _backgroundGradient.value,
                    _rotationAnimation.value,
                  ),
                ),
              ),
            ),

            // Animated top icons
            Positioned(
              top: 20,
              left: 20,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, value, child) => Transform.scale(
                  scale: value,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) => Transform.scale(
                          scale: _pulseAnimation.value,
                          child: SvgPicture.asset(
                            Assets.imagesSvgsNotification,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      onPressed: _loadData,
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              top: 20,
              right: 20,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                builder: (context, value, child) => Transform.scale(
                  scale: value,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: AnimatedBuilder(
                        animation: _rotationController,
                        builder: (context, child) => Transform.rotate(
                          angle: _rotationAnimation.value * 0.1,
                          child: SvgPicture.asset(
                            Assets.imagesSvgsSetting,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      onPressed: () => _showSettingsBottomSheet(context),
                    ),
                  ),
                ),
              ),
            ),

            // Animated center content
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 1200),
                curve: Curves.elasticOut,
                builder: (context, value, child) => Transform.scale(
                  scale: value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated logo
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) => Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: organization!.logoUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Image.network(
                                      organization!.logoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Center(
                                                child: SvgPicture.asset(
                                                  Assets.imagesSvgsCompany,
                                                  height: 45,
                                                  width: 45,
                                                  color: Colors.white,
                                                ),
                                              ),
                                    ),
                                  )
                                : Center(
                                    child: SvgPicture.asset(
                                      Assets.imagesSvgsCompany,
                                      height: 45,
                                      width: 45,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Animated text
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: -50.0, end: 0.0),
                        duration: Duration(milliseconds: 800),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) => Transform.translate(
                          offset: Offset(0, value),
                          child: Text(
                            organization!.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),

                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 50.0, end: 0.0),
                        duration: Duration(milliseconds: 1000),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) => Transform.translate(
                          offset: Offset(0, value),
                          child: Text(
                            'Admin Dashboard',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),

                      _buildAnimatedNavigationBar(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedNavigationBar() {
    final navItems = [
      {'title': 'Overview', 'icon': Assets.imagesSvgsOverview},
      {'title': 'Orders', 'icon': Assets.imagesSvgsOrder},
      {'title': 'Employees', 'icon': Assets.imagesSvgsUsers},
      {'title': 'Office Boys', 'icon': Icons.delivery_dining},
    ];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 1400),
      curve: Curves.elasticOut,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.glass,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: AppColors.glassStroke, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: navItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = _selectedIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    // Trigger content animation
                    // _slideController.reset();
                    // _fadeController.reset();
                    _slideController.forward();
                    _fadeController.forward();
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 400),
                    curve: Curves.easeInOutCubic,
                    margin: EdgeInsets.all(2),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                Colors.white.withOpacity(.1),
                                Colors.white.withOpacity(.2),
                                Colors.white.withOpacity(.3),
                              ],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.2),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedScale(
                          scale: isSelected ? 1.2 : 1.0,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.elasticOut,
                          child: navItems[index]['icon'] is String
                              ? SvgPicture.asset(
                                  item['icon'] as String,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.7),
                                )
                              : Icon(
                                  item['icon'] as IconData,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.7),
                                ),
                        ),
                        SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: Duration(milliseconds: 300),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.7),
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            fontSize: 11,
                          ),
                          child: Text(item['title'] as String),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedContent() {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 600),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.3, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(_selectedIndex),
        child: _getSelectedContent(),
      ),
    );
  }

  Widget _getSelectedContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildAnimatedOverviewTab();
      case 1:
        return _buildAnimatedOrdersTab();
      case 2:
        return _buildAnimatedEmployeesTab();
      case 3:
        return _buildAnimatedOfficeBoysTab();
      default:
        return _buildAnimatedOverviewTab();
    }
  }

  Widget _buildAnimatedOrdersTab() {
    return Column(
      children: [
        AnimatedContainer(
          duration: Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: -30.0, end: 0.0),
                duration: Duration(milliseconds: 800),
                curve: Curves.easeOutBack,
                builder: (context, value, child) => Transform.translate(
                  offset: Offset(0, value),
                  child: Text(
                    'Filter Orders',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildAnimatedFilterChip(
                          'All',
                          selectedFilter == null,
                          0,
                        ),
                        _buildAnimatedFilterChip(
                          'Pending',
                          selectedFilter == OrderStatus.pending,
                          1,
                        ),
                        _buildAnimatedFilterChip(
                          'In Progress',
                          selectedFilter == OrderStatus.inProgress,
                          2,
                        ),
                        _buildAnimatedFilterChip(
                          'Completed',
                          selectedFilter == OrderStatus.completed,
                          3,
                        ),
                        _buildAnimatedFilterChip(
                          'Cancelled',
                          selectedFilter == OrderStatus.cancelled,
                          4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        filteredOrders.isEmpty
            ? _buildAnimatedEmptyState('No orders found', Icons.search_off)
            : _buildAnimatedOrdersList(),
      ],
    );
  }

  // Widget _buildAnimatedFilterChip(String label, bool isSelected, int index) {
  //   return TweenAnimationBuilder<double>(
  //     tween: Tween(begin: 0.0, end: 1.0),
  //     duration: Duration(milliseconds: 400 + (index * 100)),
  //     curve: Curves.elasticOut,
  //     builder: (context, value, child) => Transform.scale(
  //       scale: value,
  //       child: Container(
  //         margin: EdgeInsets.only(right: 8),

  //         child: AnimatedContainer(
  //           duration: Duration(milliseconds: 300),

  //           curve: Curves.easeInOut,
  //           child: FilterChip(
  //             label: Text(label),
  //             selected: isSelected,
  //             side: BorderSide(color: Colors.transparent),
  //             onSelected: (bool value) {
  //               setState(() {
  //                 if (label == 'All') {
  //                   selectedFilter = null;
  //                 } else if (label == 'Pending') {
  //                   selectedFilter = value ? OrderStatus.pending : null;
  //                 } else if (label == 'In Progress') {
  //                   selectedFilter = value ? OrderStatus.inProgress : null;
  //                 } else if (label == 'Completed') {
  //                   selectedFilter = value ? OrderStatus.completed : null;
  //                 } else if (label == 'Cancelled') {
  //                   selectedFilter = value ? OrderStatus.cancelled : null;
  //                 }
  //               });
  //             },
  //             selectedColor: organization!.primaryColorValue.withOpacity(0.2),
  //             checkmarkColor: organization!.primaryColorValue,
  //             backgroundColor: Colors.white,
  //             elevation: isSelected ? 4 : 0,
  //             labelStyle: TextStyle(
  //               color: isSelected
  //                   ? organization!.primaryColorValue
  //                   : AppColors.onSurfaceVariant,
  //               fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildAnimatedFilterChip(String label, bool isSelected, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.elasticOut,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: Container(
          margin: EdgeInsets.only(right: 12, bottom: 8),
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (label == 'All') {
                  selectedFilter = null;
                } else if (label == 'Pending') {
                  selectedFilter = selectedFilter == OrderStatus.pending
                      ? null
                      : OrderStatus.pending;
                } else if (label == 'In Progress') {
                  selectedFilter = selectedFilter == OrderStatus.inProgress
                      ? null
                      : OrderStatus.inProgress;
                } else if (label == 'Completed') {
                  selectedFilter = selectedFilter == OrderStatus.completed
                      ? null
                      : OrderStatus.completed;
                } else if (label == 'Cancelled') {
                  selectedFilter = selectedFilter == OrderStatus.cancelled
                      ? null
                      : OrderStatus.cancelled;
                }
              });
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          organization!.primaryColorValue.withOpacity(0.3),
                          organization!.secondaryColorValue.withOpacity(0.2),
                          organization!.primaryColorValue.withOpacity(0.1),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          organization!.secondaryColorValue,
                          organization!.secondaryColorValue.withOpacity(0.8),
                        ],
                      ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected
                      ? organization!.primaryColorValue.withOpacity(0.4)
                      : Colors.white.withOpacity(0.3),
                  width: isSelected ? 1.5 : 1,
                ),
                // boxShadow: [
                //   if (isSelected) ...[
                //     BoxShadow(
                //       color: organization!.primaryColorValue.withOpacity(0.2),
                //       blurRadius: 12,
                //       spreadRadius: 1,
                //       offset: Offset(0, 4),
                //     ),
                //     BoxShadow(
                //       color: organization!.primaryColorValue.withOpacity(0.1),
                //       blurRadius: 20,
                //       spreadRadius: 2,
                //       offset: Offset(0, 8),
                //     ),
                //   ] else ...[
                //     BoxShadow(
                //       color: Colors.black.withOpacity(0.05),
                //       blurRadius: 8,
                //       offset: Offset(0, 2),
                //     ),
                //   ],
                // ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: isSelected ? 15 : 10,
                    sigmaY: isSelected ? 15 : 10,
                  ),
                  child: Container(
                    // decoration: BoxDecoration(
                    //   gradient: isSelected
                    //       ? LinearGradient(
                    //           colors: [
                    //             Colors.white.withOpacity(0.15),
                    //             Colors.white.withOpacity(0.05),
                    //           ],
                    //         )
                    //       : LinearGradient(
                    //           colors: [
                    //             Colors.white.withOpacity(0.1),
                    //             Colors.white.withOpacity(0.05),
                    //           ],
                    //         ),
                    // ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated checkmark/dot indicator
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          width: isSelected ? 8 : 0,
                          height: isSelected ? 8 : 0,
                          margin: EdgeInsets.only(right: isSelected ? 8 : 0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                organization!.primaryColorValue,
                                organization!.secondaryColorValue,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            // boxShadow: [
                            //   BoxShadow(
                            //     color: organization!.primaryColorValue
                            //         .withOpacity(0.4),
                            //     blurRadius: 4,
                            //     spreadRadius: 1,
                            //   ),
                            // ],
                          ),
                        ),

                        AnimatedBuilder(
                          animation: _shimmerController,
                          builder: (context, child) => ShaderMask(
                            shaderCallback: (bounds) {
                              if (isSelected) {
                                return LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    organization!.primaryColorValue,
                                    organization!.secondaryColorValue,
                                    organization!.primaryColorValue,
                                  ],
                                  stops: [
                                    (_shimmerAnimation.value - 0.5).clamp(
                                      0.0,
                                      1.0,
                                    ),
                                    _shimmerAnimation.value.clamp(0.0, 1.0),
                                    (_shimmerAnimation.value + 0.5).clamp(
                                      0.0,
                                      1.0,
                                    ),
                                  ],
                                ).createShader(bounds);
                              } else {
                                return LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.8),
                                    Colors.white.withOpacity(0.7),
                                  ],
                                ).createShader(bounds);
                              }
                            },
                            child: AnimatedDefaultTextStyle(
                              duration: Duration(milliseconds: 300),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                letterSpacing: isSelected ? 0.5 : 0.3,
                              ),
                              child: Text(label),
                            ),
                          ),
                        ),

                        // Animated glow effect for selected state
                        if (isSelected)
                          AnimatedBuilder(
                            animation: _glowController,
                            builder: (context, child) => Container(
                              margin: EdgeInsets.only(left: 8),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [
                                    organization!.primaryColorValue.withOpacity(
                                      0.6 + (_glowAnimation.value * 0.4),
                                    ),
                                    Colors.transparent,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(3),
                                boxShadow: [
                                  BoxShadow(
                                    color: organization!.primaryColorValue
                                        .withOpacity(
                                          _glowAnimation.value * 0.5,
                                        ),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedOrdersList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 50)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Transform.translate(
            offset: Offset(50 * (1 - value), 0),
            child: _buildDetailedOrderCard(filteredOrders[index], index),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedEmployeesTab() {
    return Column(
      children: [
        _buildAnimatedUserHeader(
          'Employees',
          employees,
          organization!.primaryColorValue,
        ),
        employees.isEmpty
            ? _buildAnimatedEmptyState('No employees found', Icons.people)
            : _buildAnimatedUsersList(employees),
      ],
    );
  }

  Widget _buildAnimatedOfficeBoysTab() {
    return Column(
      children: [
        _buildAnimatedUserHeader(
          'Office Boys',
          officeBoys,
          organization!.secondaryColorValue,
        ),
        officeBoys.isEmpty
            ? _buildAnimatedEmptyState(
                'No office boys found',
                Icons.delivery_dining,
              )
            : _buildAnimatedUsersList(officeBoys),
      ],
    );
  }

  Widget _buildAnimatedUsersList(List<AdminAppUser> users) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: users.length,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 600 + (index * 100)),
          curve: Curves.elasticOut,
          builder: (context, value, child) => Transform.scale(
            scale: value,
            child: _buildAnimatedUserCard(users[index], index),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedUserCard(AdminAppUser user, int index) {
    final userOrders = orders
        .where(
          (order) =>
              order.employeeId == user.id || order.officeBoyId == user.id,
        )
        .length;

    final completedOrders = orders
        .where(
          (order) =>
              (order.employeeId == user.id || order.officeBoyId == user.id) &&
              order.status == OrderStatus.completed,
        )
        .length;

    return AnimatedContainer(
      duration: Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppImages.homePattern),
          fit: BoxFit.fill,
          colorFilter: ColorFilter.mode(
            organization!.secondaryColorValue.withOpacity(.7),
            BlendMode.modulate,
          ),
        ),
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
        border: !user.isActive
            ? Border.all(color: AppColors.error.withOpacity(0.3))
            : null,
      ),
      child: Row(
        children: [
          // Animated avatar
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) => Transform.scale(
              scale: user.isActive ? _pulseAnimation.value : 1.0,
              child: Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    colors: user.role == UserRole.employee
                        ? [
                            organization!.primaryColorValue,
                            organization!.secondaryColorValue,
                          ]
                        : [
                            organization!.secondaryColorValue,
                            organization!.primaryColorValue,
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (user.role == UserRole.employee
                                  ? organization!.primaryColorValue
                                  : organization!.secondaryColorValue)
                              .withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: user.profilePictureUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.network(
                          user.profilePictureUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            user.role == UserRole.employee
                                ? Icons.person
                                : Icons.delivery_dining,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      )
                    : Icon(
                        user.role == UserRole.employee
                            ? Icons.person
                            : Icons.delivery_dining,
                        color: Colors.white,
                        size: 30,
                      ),
              ),
            ),
          ),
          SizedBox(width: 16),

          // User info with staggered animations
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: -20.0, end: 0.0),
                  duration: Duration(milliseconds: 600 + (index * 50)),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) => Transform.translate(
                    offset: Offset(value, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: !user.isActive
                                  ? AppColors.onSurfaceVariant
                                  : AppColors.onSurface,
                            ),
                          ),
                        ),
                        if (!user.isActive)
                          AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Inactive',
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 4),

                // Contact info with delayed animations
                ...List.generate(3, (infoIndex) {
                  Widget info;
                  switch (infoIndex) {
                    case 0:
                      info = Row(
                        children: [
                          SvgPicture.asset(
                            Assets.imagesSvgsMail,
                            height: 16,
                            width: 16,
                            color: organization!.primaryColorValue,
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              user.email,
                              style: TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                      break;
                    case 1:
                      info = Row(
                        children: [
                          SvgPicture.asset(
                            Assets.imagesSvgsPhone,
                            height: 16,
                            width: 16,
                            color: organization!.primaryColorValue,
                          ),
                          SizedBox(width: 4),
                          Text(
                            user.phone,
                            style: TextStyle(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                      break;
                    case 2:
                      if (user.department == null) return Container();
                      info = Row(
                        children: [
                          SvgPicture.asset(
                            Assets.imagesSvgsCompany,
                            height: 16,
                            width: 16,
                            color: organization!.primaryColorValue,
                          ),
                          SizedBox(width: 4),
                          Text(
                            user.department!,
                            style: TextStyle(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                      break;
                    default:
                      return Container();
                  }

                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 30.0, end: 0.0),
                    duration: Duration(milliseconds: 800 + (infoIndex * 100)),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) => Transform.translate(
                      offset: Offset(value, 0),
                      child: Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: info,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Statistics with bounce animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 1000 + (index * 50)),
            curve: Curves.elasticOut,
            builder: (context, value, child) => Transform.scale(
              scale: value,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) => Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Text(
                        '$userOrders',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: organization!.secondaryColorValue,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    user.role == UserRole.employee ? 'Orders' : 'Deliveries',
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '$completedOrders completed',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedOrderCard(AdminOrder order, int index) {
    final displayPrice = order.finalPrice ?? order.price;
    final hasPriceChange =
        order.finalPrice != null &&
        order.price != null &&
        order.finalPrice != order.price;

    return AnimatedContainer(
      duration: Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppImages.homePattern),
          fit: BoxFit.fill,
          colorFilter: ColorFilter.mode(
            organization!.secondaryColorValue.withOpacity(.5),
            BlendMode.modulate,
          ),
        ),
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: -50.0, end: 0.0),
            duration: Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (context, value, child) => Transform.translate(
              offset: Offset(value, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id.substring(0, 8)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.onSurface,
                    ),
                  ),
                  _buildAnimatedStatusChip(order.status),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),

          // Items section with staggered animation
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Row(
                    children: [
                      AnimatedBuilder(
                        animation: _rotationController,
                        builder: (context, child) => Transform.rotate(
                          angle: _rotationAnimation.value * 0.05,
                          child: SvgPicture.asset(
                            order.type == OrderType.internal
                                ? Assets.imagesSvgsCompany
                                : Assets.imagesSvgsShoppingCart,
                            color: _getOrderTypeColor(order.type),
                            height: 20,
                            width: 20,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Items (${order.items.length}):',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (displayPrice != null)
                        _buildAnimatedPrice(
                          displayPrice,
                          order.price,
                          hasPriceChange,
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 8),

              // Items list with staggered animations
              ...order.items.asMap().entries.map((entry) {
                final itemIndex = entry.key;
                final item = entry.value;

                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 600 + (itemIndex * 100)),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) => Transform.translate(
                    offset: Offset(30 * (1 - value), 0),
                    child: Padding(
                      padding: EdgeInsets.only(left: 28, bottom: 4),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getItemStatusColor(item.status),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 14,
                                color: item.status == ItemStatus.notAvailable
                                    ? AppColors.onSurfaceVariant
                                    : AppColors.onSurface,
                                decoration:
                                    item.status == ItemStatus.notAvailable
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          if (item.notes != null && item.notes!.isNotEmpty)
                            Text(
                              item.notes!,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              if (order.description.isNotEmpty)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Padding(
                      padding: EdgeInsets.only(left: 28, top: 8),
                      child: Text(
                        order.description,
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: 12),

          // User info with slide animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 50.0, end: 0.0),
            duration: Duration(milliseconds: 800),
            curve: Curves.easeOutBack,
            builder: (context, value, child) => Transform.translate(
              offset: Offset(0, value),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          Assets.imagesSvgsUser,
                          color: organization!.primaryColorValue,
                          height: 16,
                          width: 16,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.employeeName,
                            style: TextStyle(color: AppColors.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.delivery_dining_rounded,
                          color: organization!.primaryColorValue,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.officeBoyName,
                            style: TextStyle(color: AppColors.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 8),

          // Bottom info with fade animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 1200),
            curve: Curves.easeOut,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Row(
                children: [
                  SvgPicture.asset(
                    Assets.imagesSvgsClock,
                    color: organization!.primaryColorValue,
                    height: 16,
                    width: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    _formatTime(order.createdAt),
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  if (order.notes != null && order.notes!.isNotEmpty) ...[
                    SizedBox(width: 16),
                    SvgPicture.asset(
                      Assets.imagesSvgsOrder,
                      color: organization!.primaryColorValue,
                      height: 16,
                      width: 16,
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order.notes!,
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Employee response with special animation
          if (order.employeeResponse != null &&
              order.employeeResponse!.isNotEmpty)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 1400),
              curve: Curves.elasticOut,
              builder: (context, value, child) => Transform.scale(
                scale: value,
                child: Container(
                  margin: EdgeInsets.only(top: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) => Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.blue,
                            size: 16,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Employee Response: ${order.employeeResponse}',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getItemStatusColor(ItemStatus status) {
    switch (status) {
      case ItemStatus.pending:
        return Colors.orange;
      case ItemStatus.available:
        return AppColors.success;
      case ItemStatus.notAvailable:
        return AppColors.error;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildAnimatedPrice(
    double displayPrice,
    double? originalPrice,
    bool hasPriceChange,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (hasPriceChange) ...[
              Text(
                'EGP ${originalPrice!.toStringAsFixed(0)}',
                style: TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              // Complete the _buildAnimatedPrice method (line where your code cuts off)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) => Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Text(
                    'EGP ${displayPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ] else
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) => Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Text(
                    'EGP ${displayPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Add missing _buildAnimatedStatusChip method
  Widget _buildAnimatedStatusChip(OrderStatus status) {
    Color color;
    String text;

    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case OrderStatus.inProgress:
        color = Colors.blue;
        text = 'In Progress';
        break;
      case OrderStatus.completed:
        color = AppColors.success;
        text = 'Completed';
        break;
      case OrderStatus.cancelled:
        color = AppColors.error;
        text = 'Cancelled';
        break;
      case OrderStatus.needsResponse:
        color = Colors.purple;
        text = 'Need Response';
        break;
    }

    return AnimatedBuilder(
      animation: _scaleController,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: AnimatedDefaultTextStyle(
            duration: Duration(milliseconds: 200),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            child: Text(text),
          ),
        ),
      ),
    );
  }

  // Fix _getOrderTypeColor method to use organization parameter
  Color _getOrderTypeColor(OrderType type) {
    return type == OrderType.internal
        ? organization!.secondaryColorValue
        : organization!.primaryColorValue;
  }

  // Close the main class
}

// Add missing AnimatedStatCard class
class AnimatedStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String icon;
  final IconData? iconData;
  final Color color;
  final Color textColor;
  final bool isComplete;
  final AnimationController animationController;

  const AnimatedStatCard({
    super.key,
    required this.title,
    required this.value,
    this.icon = '',
    this.iconData,
    required this.color,
    required this.textColor,
    this.isComplete = false,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) => Transform.scale(
        scale: 1.0 + (math.sin(animationController.value * 2 * math.pi) * 0.02),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius:
                    8 + (math.sin(animationController.value * 2 * math.pi) * 2),
                spreadRadius: 1,
                offset: Offset(0, 2),
              ),
            ],
            image: DecorationImage(
              image: AssetImage(AppImages.pattern),
              colorFilter: ColorFilter.mode(
                textColor.withOpacity(.5),
                BlendMode.modulate,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: textColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Transform.rotate(
                        angle:
                            math.sin(animationController.value * 2 * math.pi) *
                            0.1,
                        child: Row(
                          children: [
                            if (iconData != null)
                              Icon(iconData, color: color, size: 20),
                            if (icon != '')
                              SvgPicture.asset(
                                icon,
                                color: color,
                                height: 20,
                                width: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [textColor, color],
                    ).createShader(bounds),
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Add missing AnimatedParticlesPainter
class AnimatedParticlesPainter extends CustomPainter {
  final double animationValue;
  final double rotationValue;

  AnimatedParticlesPainter(this.animationValue, this.rotationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Create animated particles
    for (int i = 0; i < 15; i++) {
      final x =
          (size.width * 0.2) +
          (i * size.width * 0.05) +
          (math.sin(animationValue * 2 * math.pi + i) * 20);
      final y =
          (size.height * 0.3) +
          (math.cos(animationValue * 2 * math.pi + i * 0.5) * 30);
      final radius = 2 + math.sin(animationValue * 2 * math.pi + i) * 1.5;

      canvas.drawCircle(Offset(x, y), radius.abs(), paint);
    }

    // Add flowing gradient lines
    final gradient = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 2;

    for (int i = 0; i < 3; i++) {
      final path = Path();
      final startY = size.height * (0.2 + i * 0.15);

      path.moveTo(-50, startY);

      for (double x = -50; x <= size.width + 50; x += 10) {
        final y =
            startY +
            math.sin((x * 0.01) + (animationValue * 2 * math.pi) + (i * 2)) *
                15;
        path.lineTo(x, y);
      }

      canvas.drawPath(path, gradient);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Add missing ShimmerLoading widget
class ShimmerLoading extends StatelessWidget {
  final Animation<double> shimmerAnimation;
  final Color primaryColor;

  const ShimmerLoading({
    super.key,
    required this.shimmerAnimation,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!],
              stops: [
                (shimmerAnimation.value - 1).clamp(0.0, 1.0),
                shimmerAnimation.value.clamp(0.0, 1.0),
                (shimmerAnimation.value + 1).clamp(0.0, 1.0),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        SizedBox(height: 16),
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          width: 120,
          height: 16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!],
              stops: [
                (shimmerAnimation.value - 1).clamp(0.0, 1.0),
                shimmerAnimation.value.clamp(0.0, 1.0),
                (shimmerAnimation.value + 1).clamp(0.0, 1.0),
              ],
            ),
          ),
        ),
        SizedBox(height: 24),
        CircularProgressIndicator(color: primaryColor, strokeWidth: 3),
      ],
    );
  }
}
