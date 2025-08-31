// import 'dart:io';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:go_router/go_router.dart';
// import 'package:taqy/config/routes/routes.dart';
// import 'package:taqy/core/services/firebase_service.dart';
// import 'package:taqy/core/theme/colors.dart';
// import 'package:taqy/core/utils/dialogs/error_toast.dart';
// import 'package:taqy/features/all/auth/presentation/cubit/auth_cubit.dart';
// import 'package:taqy/features/all/auth/presentation/widgets/animated_button.dart';

// // User Model for Employees and Office Boys
// class AppUser {
//   final String id;
//   final String name;
//   final String email;
//   final String phone;
//   final UserRole role;
//   final String organizationId;
//   final DateTime createdAt;
//   final bool isActive;
//   final String? profilePictureUrl;
//   final String? department;

//   AppUser({
//     required this.id,
//     required this.name,
//     required this.email,
//     required this.phone,
//     required this.role,
//     required this.organizationId,
//     required this.createdAt,
//     this.isActive = true,
//     this.profilePictureUrl,
//     this.department,
//   });

//   factory AppUser.fromFirestore(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;
//     return AppUser(
//       id: doc.id,
//       name: data['name'] ?? '',
//       email: data['email'] ?? '',
//       phone: data['phone'] ?? '',
//       role: UserRole.values.firstWhere(
//         (e) => e.toString().split('.').last == data['role'],
//         orElse: () => UserRole.employee,
//       ),
//       organizationId: data['organizationId'] ?? '',
//       createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
//       isActive: data['isActive'] ?? true,
//       profilePictureUrl: data['profilePictureUrl'],
//       department: data['department'],
//     );
//   }

//   Map<String, dynamic> toFirestore() {
//     return {
//       'name': name,
//       'email': email,
//       'phone': phone,
//       'role': role.toString().split('.').last,
//       'organizationId': organizationId,
//       'createdAt': Timestamp.fromDate(createdAt),
//       'isActive': isActive,
//       'profilePictureUrl': profilePictureUrl,
//       'department': department,
//     };
//   }
// }

// enum UserRole { employee, officeBoy, admin }

// // Enhanced Order Model
// class Order {
//   final String id;
//   final String employeeId;
//   final String employeeName;
//   final String officeBoyId;
//   final String officeBoyName;
//   final String item;
//   final String description;
//   final OrderType type;
//   final OrderStatus status;
//   final DateTime createdAt;
//   final DateTime? completedAt;
//   final double? price;
//   final String organizationId;
//   final String? notes;

//   Order({
//     required this.id,
//     required this.employeeId,
//     required this.employeeName,
//     required this.officeBoyId,
//     required this.officeBoyName,
//     required this.item,
//     required this.description,
//     required this.type,
//     required this.status,
//     required this.createdAt,
//     this.completedAt,
//     this.price,
//     required this.organizationId,
//     this.notes,
//   });

//   factory Order.fromFirestore(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;
//     return Order(
//       id: doc.id,
//       employeeId: data['employeeId'] ?? '',
//       employeeName: data['employeeName'] ?? '',
//       officeBoyId: data['officeBoyId'] ?? '',
//       officeBoyName: data['officeBoyName'] ?? '',
//       item: data['item'] ?? '',
//       description: data['description'] ?? '',
//       type: OrderType.values.firstWhere(
//         (e) => e.toString().split('.').last == data['type'],
//         orElse: () => OrderType.internal,
//       ),
//       status: OrderStatus.values.firstWhere(
//         (e) => e.toString().split('.').last == data['status'],
//         orElse: () => OrderStatus.pending,
//       ),
//       createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
//       completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
//       price: data['price']?.toDouble(),
//       organizationId: data['organizationId'] ?? '',
//       notes: data['notes'],
//     );
//   }

//   Map<String, dynamic> toFirestore() {
//     return {
//       'employeeId': employeeId,
//       'employeeName': employeeName,
//       'officeBoyId': officeBoyId,
//       'officeBoyName': officeBoyName,
//       'item': item,
//       'description': description,
//       'type': type.toString().split('.').last,
//       'status': status.toString().split('.').last,
//       'createdAt': Timestamp.fromDate(createdAt),
//       'completedAt': completedAt != null
//           ? Timestamp.fromDate(completedAt!)
//           : null,
//       'price': price,
//       'organizationId': organizationId,
//       'notes': notes,
//     };
//   }
// }

// // Organization Model
// class Organization {
//   final String id;
//   final String name;
//   final String code;
//   final String? logoUrl;
//   final String primaryColor;
//   final String secondaryColor;
//   final DateTime createdAt;
//   final DateTime updatedAt;
//   final bool isActive;

//   Organization({
//     required this.id,
//     required this.name,
//     required this.code,
//     this.logoUrl,
//     required this.primaryColor,
//     required this.secondaryColor,
//     required this.createdAt,
//     required this.updatedAt,
//     this.isActive = true,
//   });

//   factory Organization.fromFirestore(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;
//     return Organization(
//       id: doc.id,
//       name: data['name'] ?? '',
//       code: data['code'] ?? '',
//       logoUrl: data['logoUrl'],
//       primaryColor: data['primaryColor'] ?? AppColors.primary.value.toString(),
//       secondaryColor:
//           data['secondaryColor'] ?? AppColors.secondary.value.toString(),
//       createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
//       updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
//       isActive: data['isActive'] ?? true,
//     );
//   }

//   Map<String, dynamic> toFirestore() {
//     return {
//       'name': name,
//       'code': code,
//       'logoUrl': logoUrl,
//       'primaryColor': primaryColor,
//       'secondaryColor': secondaryColor,
//       'isActive': isActive,
//     };
//   }

//   Color get primaryColorValue {
//     try {
//       String colorString = primaryColor;
//       if (colorString.startsWith('#')) {
//         colorString = colorString.substring(1);
//       }

//       if (colorString.length == 6 || colorString.length == 8) {
//         return Color(int.parse('FF$colorString', radix: 16));
//       }

//       return Color(int.parse(colorString));
//     } catch (e) {
//       return AppColors.primary;
//     }
//   }

//   Color get secondaryColorValue {
//     try {
//       String colorString = secondaryColor;
//       if (colorString.startsWith('#')) {
//         colorString = colorString.substring(1);
//       }

//       if (colorString.length == 6 || colorString.length == 8) {
//         return Color(int.parse('FF$colorString', radix: 16));
//       }

//       return Color(int.parse(colorString));
//     } catch (e) {
//       return AppColors.secondary;
//     }
//   }
// }

// enum OrderStatus { pending, inProgress, completed, cancelled }

// enum OrderType { internal, external }

// class AdminLayout extends StatefulWidget {
//   const AdminLayout({super.key});

//   @override
//   State<AdminLayout> createState() => _AdminLayoutState();
// }

// class _AdminLayoutState extends State<AdminLayout>
//     with TickerProviderStateMixin {
//   late TabController _tabController;
//   final FirebaseService _firebaseService = FirebaseService();

//   Organization? organization;
//   List<Order> orders = [];
//   List<AppUser> employees = [];
//   List<AppUser> officeBoys = [];
//   bool isLoading = true;
//   String? errorMessage;
//   OrderStatus? selectedFilter;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 5, vsync: this); // Updated to 5 tabs
//     _loadData();
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
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

//       // Get user data to find organization
//       final userDoc = await _firebaseService.getDocument('users', user.uid);
//       if (!userDoc.exists) {
//         throw Exception('User data not found');
//       }

//       final userData = userDoc.data() as Map<String, dynamic>;
//       final organizationId = userData['organizationId'] as String;

//       // Load organization data
//       final orgDoc = await _firebaseService.getDocument(
//         'organizations',
//         organizationId,
//       );
//       if (orgDoc.exists) {
//         setState(() {
//           organization = Organization.fromFirestore(orgDoc);
//         });
//       }

//       // Load orders, employees, and office boys
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
//                   .map((doc) => Order.fromFirestore(doc))
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
//                 .map((doc) => AppUser.fromFirestore(doc))
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
//       builder: (buildContext) => AdminSettingsBottomSheet(
//         organization: organization!,
//         onSettingsUpdated: (updatedOrg) async {
//           try {
//             await _firebaseService.updateDocument(
//               'organizations',
//               organization!.id,
//               updatedOrg.toFirestore(),
//             );

//             setState(() {
//               organization = updatedOrg;
//             });

//             showSuccessToast(context, 'Settings updated successfully!');
//           } catch (e) {
//             showErrorToast(context, 'Failed to update settings: $e');
//           }
//         },
//         onLogout: () => _handleLogout(context),
//       ),
//     );
//   }

//   List<Order> get filteredOrders {
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
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         title: Row(
//           children: [
//             Container(
//               height: 40,
//               width: 40,
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [
//                     organization!.primaryColorValue,
//                     organization!.secondaryColorValue,
//                   ],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: organization!.logoUrl != null
//                   ? ClipRRect(
//                       borderRadius: BorderRadius.circular(10),
//                       child: Image.network(
//                         organization!.logoUrl!,
//                         fit: BoxFit.cover,
//                         errorBuilder: (context, error, stackTrace) =>
//                             Icon(Icons.business, color: Colors.white, size: 20),
//                       ),
//                     )
//                   : Icon(Icons.business, color: Colors.white, size: 20),
//             ),
//             SizedBox(width: 12),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   organization!.name,
//                   style: TextStyle(
//                     color: AppColors.onSurface,
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Text(
//                   'Admin Dashboard',
//                   style: TextStyle(
//                     color: AppColors.onSurfaceVariant,
//                     fontSize: 12,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh, color: AppColors.onSurface),
//             onPressed: _loadData,
//           ),
//           IconButton(
//             icon: Icon(Icons.settings, color: AppColors.onSurface),
//             onPressed: () => _showSettingsBottomSheet(context),
//           ),
//         ],
//         bottom: TabBar(
//           controller: _tabController,
//           indicatorColor: organization!.primaryColorValue,
//           labelColor: organization!.primaryColorValue,
//           unselectedLabelColor: AppColors.onSurfaceVariant,
//           isScrollable: true,
//           tabs: [
//             Tab(text: 'Overview'),
//             Tab(text: 'Orders'),
//             Tab(text: 'Employees'),
//             Tab(text: 'Office Boys'),
//             Tab(text: 'Analytics'),
//           ],
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           _buildOverviewTab(),
//           _buildOrdersTab(),
//           _buildEmployeesTab(),
//           _buildOfficeBoysTab(),
//           _buildAnalyticsTab(),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmployeesTab() {
//     return Column(
//       children: [
//         // Header Section
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

//         // Employees List
//         Expanded(
//           child: RefreshIndicator(
//             onRefresh: _loadData,
//             child: employees.isEmpty
//                 ? _buildEmptyState('No employees found', Icons.people)
//                 : ListView.builder(
//                     padding: EdgeInsets.all(16),
//                     itemCount: employees.length,
//                     itemBuilder: (context, index) {
//                       return _buildUserCard(employees[index]);
//                     },
//                   ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildOfficeBoysTab() {
//     return Column(
//       children: [
//         // Header Section
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

//         // Office Boys List
//         Expanded(
//           child: RefreshIndicator(
//             onRefresh: _loadData,
//             child: officeBoys.isEmpty
//                 ? _buildEmptyState(
//                     'No office boys found',
//                     Icons.delivery_dining,
//                   )
//                 : ListView.builder(
//                     padding: EdgeInsets.all(16),
//                     itemCount: officeBoys.length,
//                     itemBuilder: (context, index) {
//                       return _buildUserCard(officeBoys[index]);
//                     },
//                   ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildUserCard(AppUser user) {
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
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: Offset(0, 4),
//           ),
//         ],
//         border: !user.isActive
//             ? Border.all(color: AppColors.error.withOpacity(0.3))
//             : null,
//       ),
//       child: Row(
//         children: [
//           // Profile Picture
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

//           // User Info
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
//                     Icon(
//                       Icons.email,
//                       size: 14,
//                       color: AppColors.onSurfaceVariant,
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
//                     Icon(
//                       Icons.phone,
//                       size: 14,
//                       color: AppColors.onSurfaceVariant,
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
//                       Icon(
//                         Icons.business_center,
//                         size: 14,
//                         color: AppColors.onSurfaceVariant,
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

//           // Stats
//           Column(
//             children: [
//               Text(
//                 '$userOrders',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 18,
//                   color: user.role == UserRole.employee
//                       ? organization!.primaryColorValue
//                       : organization!.secondaryColorValue,
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

//     return RefreshIndicator(
//       onRefresh: _loadData,
//       child: SingleChildScrollView(
//         physics: AlwaysScrollableScrollPhysics(),
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Quick Stats
//             Text(
//               'Quick Stats',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: AppColors.onSurface,
//               ),
//             ),
//             SizedBox(height: 16),

//             // Stats Grid
//             GridView.count(
//               crossAxisCount: 2,
//               crossAxisSpacing: 12,
//               mainAxisSpacing: 12,
//               childAspectRatio: 1.3,
//               shrinkWrap: true,
//               physics: NeverScrollableScrollPhysics(),
//               children: [
//                 _buildStatCard(
//                   'Total Orders',
//                   totalOrders.toString(),
//                   Icons.receipt_long,
//                   organization!.primaryColorValue,
//                 ),
//                 _buildStatCard(
//                   'Today\'s Orders',
//                   todayOrders.toString(),
//                   Icons.today,
//                   Colors.blue,
//                 ),
//                 _buildStatCard(
//                   'Employees',
//                   employees.length.toString(),
//                   Icons.people,
//                   organization!.primaryColorValue,
//                 ),
//                 _buildStatCard(
//                   'Office Boys',
//                   officeBoys.length.toString(),
//                   Icons.delivery_dining,
//                   organization!.secondaryColorValue,
//                 ),
//                 _buildStatCard(
//                   'Internal Orders',
//                   internalOrders.toString(),
//                   Icons.coffee,
//                   Colors.brown,
//                 ),
//                 _buildStatCard(
//                   'External Orders',
//                   externalOrders.toString(),
//                   Icons.attach_money,
//                   Colors.green,
//                 ),
//                 _buildStatCard(
//                   'Pending',
//                   pendingOrders.toString(),
//                   Icons.pending_actions,
//                   Colors.orange,
//                 ),
//                 _buildStatCard(
//                   'Completed',
//                   completedOrders.toString(),
//                   Icons.check_circle,
//                   AppColors.success,
//                 ),
//               ],
//             ),

//             SizedBox(height: 24),

//             // Recent Orders
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'Recent Orders',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: AppColors.onSurface,
//                   ),
//                 ),
//                 TextButton(
//                   onPressed: () => _tabController.animateTo(1),
//                   child: Text('View All'),
//                 ),
//               ],
//             ),
//             SizedBox(height: 16),

//             if (orders.isEmpty)
//               _buildEmptyState('No orders yet', Icons.receipt_long)
//             else
//               ...orders.take(5).map((order) => _buildOrderCard(order)),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildOrdersTab() {
//     return Column(
//       children: [
//         // Filter Section
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

//         // Orders List
//         Expanded(
//           child: RefreshIndicator(
//             onRefresh: _loadData,
//             child: filteredOrders.isEmpty
//                 ? _buildEmptyState('No orders found', Icons.search_off)
//                 : ListView.builder(
//                     padding: EdgeInsets.all(16),
//                     itemCount: filteredOrders.length,
//                     itemBuilder: (context, index) {
//                       return _buildDetailedOrderCard(filteredOrders[index]);
//                     },
//                   ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildAnalyticsTab() {
//     final totalRevenue = orders
//         .where((o) => o.price != null && o.status == OrderStatus.completed)
//         .fold(0.0, (sum, order) => sum + order.price!);

//     final mostActiveEmployee = _getMostActiveEmployee();
//     final mostActiveOfficeBoy = _getMostActiveOfficeBoy();
//     final popularItem = _getPopularItem();

//     return RefreshIndicator(
//       onRefresh: _loadData,
//       child: SingleChildScrollView(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Analytics Overview',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: AppColors.onSurface,
//               ),
//             ),
//             SizedBox(height: 16),

//             // Analytics Cards
//             _buildAnalyticsCard(
//               'Most Active Employee',
//               mostActiveEmployee['name'] ?? 'N/A',
//               '${mostActiveEmployee['count']} orders',
//               Icons.person_pin,
//               organization!.primaryColorValue,
//             ),
//             SizedBox(height: 12),
//             _buildAnalyticsCard(
//               'Most Active Office Boy',
//               mostActiveOfficeBoy['name'] ?? 'N/A',
//               '${mostActiveOfficeBoy['count']} deliveries',
//               Icons.delivery_dining,
//               organization!.secondaryColorValue,
//             ),
//             SizedBox(height: 12),
//             _buildAnalyticsCard(
//               'Popular Item',
//               popularItem['item'] ?? 'N/A',
//               'Ordered ${popularItem['count']} times',
//               Icons.local_cafe,
//               Colors.brown,
//             ),
//             SizedBox(height: 12),
//             _buildAnalyticsCard(
//               'Total Revenue',
//               'EGP ${totalRevenue.toStringAsFixed(0)}',
//               'From external orders',
//               Icons.attach_money,
//               AppColors.success,
//             ),

//             SizedBox(height: 24),

//             // Team Performance
//             Text(
//               'Team Performance',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: AppColors.onSurface,
//               ),
//             ),
//             SizedBox(height: 16),
//             _buildTeamPerformance(),

//             SizedBox(height: 24),

//             // Order Status Distribution
//             Text(
//               'Order Status Distribution',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: AppColors.onSurface,
//               ),
//             ),
//             SizedBox(height: 16),
//             _buildStatusDistribution(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTeamPerformance() {
//     return Container(
//       padding: EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: Column(
//                   children: [
//                     Text(
//                       '${employees.where((e) => e.isActive).length}',
//                       style: TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                         color: organization!.primaryColorValue,
//                       ),
//                     ),
//                     Text(
//                       'Active Employees',
//                       style: TextStyle(
//                         color: AppColors.onSurfaceVariant,
//                         fontSize: 12,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Container(width: 1, height: 40, color: AppColors.outline),
//               Expanded(
//                 child: Column(
//                   children: [
//                     Text(
//                       '${officeBoys.where((o) => o.isActive).length}',
//                       style: TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                         color: organization!.secondaryColorValue,
//                       ),
//                     ),
//                     Text(
//                       'Active Office Boys',
//                       style: TextStyle(
//                         color: AppColors.onSurfaceVariant,
//                         fontSize: 12,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 16),
//           Divider(color: AppColors.outline),
//           SizedBox(height: 16),
//           Row(
//             children: [
//               Expanded(
//                 child: Column(
//                   children: [
//                     Text(
//                       (employees.isEmpty ? 0 : orders.length / employees.length)
//                           .toStringAsFixed(1),
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: AppColors.onSurface,
//                       ),
//                     ),
//                     Text(
//                       'Avg Orders/Employee',
//                       style: TextStyle(
//                         color: AppColors.onSurfaceVariant,
//                         fontSize: 12,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),
//               ),
//               Expanded(
//                 child: Column(
//                   children: [
//                     Text(
//                       (officeBoys.isEmpty
//                               ? 0
//                               : orders.length / officeBoys.length)
//                           .toStringAsFixed(1),
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: AppColors.onSurface,
//                       ),
//                     ),
//                     Text(
//                       'Avg Deliveries/Office Boy',
//                       style: TextStyle(
//                         color: AppColors.onSurfaceVariant,
//                         fontSize: 12,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatCard(
//     String title,
//     String value,
//     IconData icon,
//     Color color,
//   ) {
//     return Container(
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Icon(icon, color: color, size: 24),
//               Text(
//                 value,
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: color,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 8),
//           Text(
//             title,
//             style: TextStyle(
//               color: AppColors.onSurfaceVariant,
//               fontSize: 14,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildOrderCard(Order order) {
//     return Container(
//       margin: EdgeInsets.only(bottom: 12),
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             height: 50,
//             width: 50,
//             decoration: BoxDecoration(
//               color: _getOrderTypeColor(order.type).withOpacity(0.1),
//               borderRadius: BorderRadius.circular(25),
//             ),
//             child: Icon(
//               order.type == OrderType.internal ? Icons.home : Icons.store,
//               color: _getOrderTypeColor(order.type),
//             ),
//           ),
//           SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   order.item,
//                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                 ),
//                 Text(
//                   'by ${order.employeeName}',
//                   style: TextStyle(
//                     color: AppColors.onSurfaceVariant,
//                     fontSize: 14,
//                   ),
//                 ),
//                 Text(
//                   _formatTime(order.createdAt),
//                   style: TextStyle(
//                     color: AppColors.onSurfaceVariant,
//                     fontSize: 12,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           _buildStatusChip(order.status),
//         ],
//       ),
//     );
//   }

//   Widget _buildDetailedOrderCard(Order order) {
//     return Container(
//       margin: EdgeInsets.only(bottom: 16),
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: Offset(0, 4),
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

//           // Order Item
//           Row(
//             children: [
//               Icon(
//                 order.type == OrderType.internal ? Icons.home : Icons.store,
//                 color: _getOrderTypeColor(order.type),
//                 size: 20,
//               ),
//               SizedBox(width: 8),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       order.item,
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     if (order.description.isNotEmpty)
//                       Text(
//                         order.description,
//                         style: TextStyle(
//                           color: AppColors.onSurfaceVariant,
//                           fontSize: 14,
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//               if (order.price != null)
//                 Text(
//                   'EGP ${order.price!.toStringAsFixed(0)}',
//                   style: TextStyle(
//                     color: AppColors.success,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//             ],
//           ),
//           SizedBox(height: 12),

//           // Employee and Office Boy
//           Row(
//             children: [
//               Expanded(
//                 child: Row(
//                   children: [
//                     Icon(
//                       Icons.person,
//                       color: AppColors.onSurfaceVariant,
//                       size: 16,
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
//                       Icons.delivery_dining,
//                       color: AppColors.onSurfaceVariant,
//                       size: 16,
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

//           // Time and Notes
//           Row(
//             children: [
//               Icon(
//                 Icons.access_time,
//                 color: AppColors.onSurfaceVariant,
//                 size: 16,
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
//                 Icon(Icons.note, color: AppColors.onSurfaceVariant, size: 16),
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
//         ],
//       ),
//     );
//   }

//   Widget _buildAnalyticsCard(
//     String title,
//     String value,
//     String subtitle,
//     IconData icon,
//     Color color,
//   ) {
//     return Container(
//       padding: EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             height: 60,
//             width: 60,
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(30),
//             ),
//             child: Icon(icon, color: color, size: 30),
//           ),
//           SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: TextStyle(
//                     color: AppColors.onSurfaceVariant,
//                     fontSize: 14,
//                   ),
//                 ),
//                 Text(
//                   value,
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 20,
//                     color: AppColors.onSurface,
//                   ),
//                 ),
//                 Text(
//                   subtitle,
//                   style: TextStyle(
//                     color: AppColors.onSurfaceVariant,
//                     fontSize: 12,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

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

//   Widget _buildFilterChip(String label, bool isSelected) {
//     return Container(
//       margin: EdgeInsets.only(right: 8),
//       child: FilterChip(
//         label: Text(label),
//         selected: isSelected,
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
//         labelStyle: TextStyle(
//           color: isSelected
//               ? organization!.primaryColorValue
//               : AppColors.onSurfaceVariant,
//           fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusDistribution() {
//     final statusCounts = <OrderStatus, int>{};
//     for (final status in OrderStatus.values) {
//       statusCounts[status] = orders.where((o) => o.status == status).length;
//     }

//     return Container(
//       padding: EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         children: statusCounts.entries.map((entry) {
//           final percentage = orders.isEmpty
//               ? 0.0
//               : (entry.value / orders.length);
//           return Padding(
//             padding: EdgeInsets.symmetric(vertical: 8),
//             child: Row(
//               children: [
//                 Container(
//                   width: 12,
//                   height: 12,
//                   decoration: BoxDecoration(
//                     color: _getStatusColor(entry.key),
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                 ),
//                 SizedBox(width: 12),
//                 Text(
//                   entry.key.toString().split('.').last.toUpperCase(),
//                   style: TextStyle(fontWeight: FontWeight.w600),
//                 ),
//                 Spacer(),
//                 Text('${entry.value}'),
//                 SizedBox(width: 8),
//                 Text(
//                   '(${(percentage * 100).toStringAsFixed(1)}%)',
//                   style: TextStyle(color: AppColors.onSurfaceVariant),
//                 ),
//               ],
//             ),
//           );
//         }).toList(),
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

//   Color _getStatusColor(OrderStatus status) {
//     switch (status) {
//       case OrderStatus.pending:
//         return Colors.orange;
//       case OrderStatus.inProgress:
//         return Colors.blue;
//       case OrderStatus.completed:
//         return AppColors.success;
//       case OrderStatus.cancelled:
//         return AppColors.error;
//     }
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

//   Map<String, dynamic> _getMostActiveEmployee() {
//     if (orders.isEmpty) return {'name': null, 'count': 0};

//     final employeeCounts = <String, int>{};
//     final employeeNames = <String, String>{};

//     for (final order in orders) {
//       employeeCounts[order.employeeId] =
//           (employeeCounts[order.employeeId] ?? 0) + 1;
//       employeeNames[order.employeeId] = order.employeeName;
//     }

//     final topEmployee = employeeCounts.entries.reduce(
//       (a, b) => a.value > b.value ? a : b,
//     );

//     return {'name': employeeNames[topEmployee.key], 'count': topEmployee.value};
//   }

//   Map<String, dynamic> _getMostActiveOfficeBoy() {
//     if (orders.isEmpty) return {'name': null, 'count': 0};

//     final officeBoysCounts = <String, int>{};
//     final officeBoysNames = <String, String>{};

//     for (final order in orders) {
//       officeBoysCounts[order.officeBoyId] =
//           (officeBoysCounts[order.officeBoyId] ?? 0) + 1;
//       officeBoysNames[order.officeBoyId] = order.officeBoyName;
//     }

//     final topOfficeBoy = officeBoysCounts.entries.reduce(
//       (a, b) => a.value > b.value ? a : b,
//     );

//     return {
//       'name': officeBoysNames[topOfficeBoy.key],
//       'count': topOfficeBoy.value,
//     };
//   }

//   Map<String, dynamic> _getPopularItem() {
//     if (orders.isEmpty) return {'item': null, 'count': 0};

//     final itemCounts = <String, int>{};

//     for (final order in orders) {
//       itemCounts[order.item] = (itemCounts[order.item] ?? 0) + 1;
//     }

//     final topItem = itemCounts.entries.reduce(
//       (a, b) => a.value > b.value ? a : b,
//     );

//     return {'item': topItem.key, 'count': topItem.value};
//   }
// }

// class AdminSettingsBottomSheet extends StatefulWidget {
//   final Organization organization;
//   final Function(Organization) onSettingsUpdated;
//   final VoidCallback onLogout;

//   const AdminSettingsBottomSheet({
//     super.key,
//     required this.organization,
//     required this.onSettingsUpdated,
//     required this.onLogout,
//   });

//   @override
//   State<AdminSettingsBottomSheet> createState() =>
//       _AdminSettingsBottomSheetState();
// }

// class _AdminSettingsBottomSheetState extends State<AdminSettingsBottomSheet> {
//   late TextEditingController _nameController;
//   late TextEditingController _codeController;
//   late Color _primaryColor;
//   late Color _secondaryColor;
//   PlatformFile? _logoFile;
//   bool _isSaving = false;
//   final FirebaseService _firebaseService = FirebaseService();

//   @override
//   void initState() {
//     super.initState();
//     _nameController = TextEditingController(text: widget.organization.name);
//     _codeController = TextEditingController(text: widget.organization.code);
//     _primaryColor = widget.organization.primaryColorValue;
//     _secondaryColor = widget.organization.secondaryColorValue;
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _codeController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: MediaQuery.of(context).size.height * 0.9,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(24),
//           topRight: Radius.circular(24),
//         ),
//       ),
//       child: Column(
//         children: [
//           // Handle
//           Container(
//             margin: EdgeInsets.only(top: 12),
//             height: 4,
//             width: 40,
//             decoration: BoxDecoration(
//               color: AppColors.outline,
//               borderRadius: BorderRadius.circular(2),
//             ),
//           ),

//           // Header
//           Padding(
//             padding: EdgeInsets.all(24),
//             child: Row(
//               children: [
//                 Text(
//                   'Company Settings',
//                   style: TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     color: AppColors.onSurface,
//                   ),
//                 ),
//                 Spacer(),
//                 IconButton(
//                   onPressed: () => Navigator.pop(context),
//                   icon: Icon(Icons.close),
//                 ),
//               ],
//             ),
//           ),

//           // Content
//           Expanded(
//             child: SingleChildScrollView(
//               padding: EdgeInsets.symmetric(horizontal: 24),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Organization Info Card
//                   Container(
//                     padding: EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       color: AppColors.background,
//                       borderRadius: BorderRadius.circular(16),
//                       border: Border.all(color: AppColors.outline),
//                     ),
//                     child: Column(
//                       children: [
//                         Text(
//                           'Organization Information',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                             color: AppColors.onSurface,
//                           ),
//                         ),
//                         SizedBox(height: 8),
//                         Text(
//                           'ID: ${widget.organization.id}',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: AppColors.onSurfaceVariant,
//                             fontFamily: 'monospace',
//                           ),
//                         ),
//                         SizedBox(height: 4),
//                         Text(
//                           'Created: ${_formatDate(widget.organization.createdAt)}',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: AppColors.onSurfaceVariant,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   SizedBox(height: 24),

//                   // Logo Section
//                   Center(
//                     child: Column(
//                       children: [
//                         Text(
//                           'Company Logo',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                             color: AppColors.onSurface,
//                           ),
//                         ),
//                         SizedBox(height: 12),
//                         GestureDetector(
//                           onTap: _pickLogo,
//                           child: Container(
//                             height: 120,
//                             width: 120,
//                             decoration: BoxDecoration(
//                               color: AppColors.background,
//                               borderRadius: BorderRadius.circular(60),
//                               border: Border.all(
//                                 color: _primaryColor,
//                                 width: 2,
//                               ),
//                             ),
//                             child: _logoFile != null
//                                 ? ClipRRect(
//                                     borderRadius: BorderRadius.circular(58),
//                                     child: Image.file(
//                                       File(_logoFile!.path!),
//                                       fit: BoxFit.cover,
//                                     ),
//                                   )
//                                 : widget.organization.logoUrl != null
//                                 ? ClipRRect(
//                                     borderRadius: BorderRadius.circular(58),
//                                     child: Image.network(
//                                       widget.organization.logoUrl!,
//                                       fit: BoxFit.cover,
//                                       errorBuilder:
//                                           (context, error, stackTrace) => Icon(
//                                             Icons.business,
//                                             color: _primaryColor,
//                                             size: 40,
//                                           ),
//                                     ),
//                                   )
//                                 : Icon(
//                                     Icons.add_photo_alternate,
//                                     size: 40,
//                                     color: _primaryColor,
//                                   ),
//                           ),
//                         ),
//                         SizedBox(height: 8),
//                         Text(
//                           'Tap to change logo',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: AppColors.onSurfaceVariant,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   SizedBox(height: 32),

//                   // Company Name
//                   _buildTextField(
//                     controller: _nameController,
//                     label: 'Company Name',
//                     hint: 'Enter company name',
//                     icon: Icons.business,
//                     validator: (value) {
//                       if (value == null || value.trim().isEmpty) {
//                         return 'Company name is required';
//                       }
//                       return null;
//                     },
//                   ),
//                   SizedBox(height: 20),

//                   // Company Code
//                   _buildTextField(
//                     controller: _codeController,
//                     label: 'Company Code',
//                     hint: 'Enter unique company code',
//                     icon: Icons.code,
//                     validator: (value) {
//                       if (value == null || value.trim().isEmpty) {
//                         return 'Company code is required';
//                       }
//                       if (value.length < 3) {
//                         return 'Code must be at least 3 characters';
//                       }
//                       return null;
//                     },
//                   ),
//                   SizedBox(height: 32),

//                   // Color Selection
//                   Text(
//                     'Brand Colors',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: AppColors.onSurface,
//                     ),
//                   ),
//                   SizedBox(height: 16),

//                   // Primary Color
//                   _buildColorSelector(
//                     'Primary Color',
//                     _primaryColor,
//                     (color) => setState(() => _primaryColor = color),
//                   ),
//                   SizedBox(height: 16),

//                   // Secondary Color
//                   _buildColorSelector(
//                     'Secondary Color',
//                     _secondaryColor,
//                     (color) => setState(() => _secondaryColor = color),
//                   ),
//                   SizedBox(height: 32),

//                   // Preview Section
//                   Text(
//                     'Color Preview',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                       color: AppColors.onSurface,
//                     ),
//                   ),
//                   SizedBox(height: 12),
//                   Container(
//                     padding: EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [_primaryColor, _secondaryColor],
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                       ),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(Icons.business, color: Colors.white, size: 24),
//                         SizedBox(width: 12),
//                         Text(
//                           _nameController.text.isEmpty
//                               ? 'Company Name'
//                               : _nameController.text,
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   SizedBox(height: 32),
//                 ],
//               ),
//             ),
//           ),

//           // Bottom Actions
//           Container(
//             padding: EdgeInsets.all(24),
//             decoration: BoxDecoration(
//               color: AppColors.background,
//               border: Border(top: BorderSide(color: AppColors.outline)),
//             ),
//             child: Column(
//               children: [
//                 // Save Button
//                 AnimatedButton(
//                   text: _isSaving ? 'Saving...' : 'Save Changes',
//                   onPressed: _isSaving ? null : _saveSettings,
//                   backgroundColor: _primaryColor,
//                   width: double.infinity,
//                   height: 50,
//                 ),
//                 SizedBox(height: 12),

//                 // Logout Button
//                 AnimatedButton(
//                   text: 'Logout',
//                   onPressed: _isSaving
//                       ? null
//                       : () {
//                           Navigator.pop(context);
//                           _showLogoutConfirmation();
//                         },
//                   backgroundColor: AppColors.error,
//                   width: double.infinity,
//                   height: 50,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required String hint,
//     required IconData icon,
//     String? Function(String?)? validator,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w600,
//             color: AppColors.onSurface,
//           ),
//         ),
//         SizedBox(height: 8),
//         TextFormField(
//           controller: controller,
//           validator: validator,
//           decoration: InputDecoration(
//             hintText: hint,
//             prefixIcon: Icon(icon, color: AppColors.onSurfaceVariant),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(color: AppColors.outline),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(color: _primaryColor, width: 2),
//             ),
//             errorBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(color: AppColors.error, width: 2),
//             ),
//             filled: true,
//             fillColor: AppColors.background,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildColorSelector(
//     String label,
//     Color selectedColor,
//     Function(Color) onColorChanged,
//   ) {
//     final colors = [
//       AppColors.primary,
//       AppColors.secondary,
//       Colors.blue,
//       Colors.green,
//       Colors.purple,
//       Colors.orange,
//       Colors.teal,
//       Colors.indigo,
//       Colors.pink,
//       Colors.cyan,
//       Colors.amber,
//       Colors.red,
//     ];

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w600,
//             color: AppColors.onSurface,
//           ),
//         ),
//         SizedBox(height: 12),
//         Wrap(
//           spacing: 12,
//           runSpacing: 12,
//           children: colors.map((color) {
//             final isSelected = color.value == selectedColor.value;
//             return GestureDetector(
//               onTap: () => onColorChanged(color),
//               child: Container(
//                 height: 40,
//                 width: 40,
//                 decoration: BoxDecoration(
//                   color: color,
//                   borderRadius: BorderRadius.circular(20),
//                   border: isSelected
//                       ? Border.all(color: AppColors.onSurface, width: 3)
//                       : Border.all(color: Colors.grey.shade300, width: 1),
//                   boxShadow: isSelected
//                       ? [
//                           BoxShadow(
//                             color: color.withOpacity(0.3),
//                             blurRadius: 8,
//                             offset: Offset(0, 4),
//                           ),
//                         ]
//                       : null,
//                 ),
//                 child: isSelected
//                     ? Icon(Icons.check, color: Colors.white, size: 20)
//                     : null,
//               ),
//             );
//           }).toList(),
//         ),
//       ],
//     );
//   }

//   void _pickLogo() async {
//     try {
//       final result = await FilePicker.platform.pickFiles(
//         type: FileType.image,
//         withData: true,
//       );

//       if (result != null && result.files.isNotEmpty) {
//         final file = result.files.first;

//         // Check file size (max 5MB)
//         if (file.size > 5 * 1024 * 1024) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('File size must be less than 5MB'),
//               backgroundColor: AppColors.error,
//             ),
//           );
//           return;
//         }

//         setState(() {
//           _logoFile = file;
//         });
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to pick image: $e'),
//           backgroundColor: AppColors.error,
//         ),
//       );
//     }
//   }

//   void _saveSettings() async {
//     if (_nameController.text.trim().isEmpty ||
//         _codeController.text.trim().isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Please fill in all required fields'),
//           backgroundColor: AppColors.error,
//         ),
//       );
//       return;
//     }

//     setState(() {
//       _isSaving = true;
//     });

//     try {
//       String? logoUrl = widget.organization.logoUrl;

//       // Upload new logo if selected
//       if (_logoFile != null) {
//         logoUrl = await _firebaseService.uploadOrganizationLogo(
//           widget.organization.id,
//           _logoFile!.path!,
//         );
//       }

//       // Create updated organization
//       final updatedOrganization = Organization(
//         id: widget.organization.id,
//         name: _nameController.text.trim(),
//         code: _codeController.text.trim().toUpperCase(),
//         logoUrl: logoUrl,
//         primaryColor: _primaryColor.value.toString(),
//         secondaryColor: _secondaryColor.value.toString(),
//         createdAt: widget.organization.createdAt,
//         updatedAt: DateTime.now(),
//         isActive: widget.organization.isActive,
//       );

//       // Update in Firebase
//       await _firebaseService.updateDocument(
//         'organizations',
//         widget.organization.id,
//         updatedOrganization.toFirestore(),
//       );

//       widget.onSettingsUpdated(updatedOrganization);

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Row(
//             children: [
//               Icon(Icons.check_circle, color: Colors.white),
//               SizedBox(width: 8),
//               Text('Settings saved successfully!'),
//             ],
//           ),
//           backgroundColor: AppColors.success,
//         ),
//       );

//       Navigator.pop(context);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to save settings: $e'),
//           backgroundColor: AppColors.error,
//         ),
//       );
//     } finally {
//       setState(() {
//         _isSaving = false;
//       });
//     }
//   }

//   void _showLogoutConfirmation() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Confirm Logout'),
//         content: Text('Are you sure you want to logout?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               widget.onLogout();
//             },
//             style: TextButton.styleFrom(foregroundColor: AppColors.error),
//             child: Text('Logout'),
//           ),
//         ],
//       ),
//     );
//   }

//   String _formatDate(DateTime date) {
//     return '${date.day}/${date.month}/${date.year}';
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taqy/config/routes/routes.dart';
import 'package:taqy/core/services/firebase_service.dart';
import 'package:taqy/core/theme/colors.dart';
import 'package:taqy/core/utils/dialogs/error_toast.dart';
import 'package:taqy/features/admin/data/models/app_user.dart';
import 'package:taqy/features/admin/data/models/order.dart';
import 'package:taqy/features/admin/data/models/organization.dart';
import 'package:taqy/features/admin/presentation/widgets/admin_settings_bottom_sheet.dart';
import 'package:taqy/features/admin/presentation/widgets/order_card.dart';
import 'package:taqy/features/admin/presentation/widgets/stat_card.dart';
import 'package:taqy/features/all/auth/presentation/cubit/auth_cubit.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseService _firebaseService = FirebaseService();

  Organization? organization;
  List<Order> orders = [];
  List<AppUser> employees = [];
  List<AppUser> officeBoys = [];
  bool isLoading = true;
  String? errorMessage;
  OrderStatus? selectedFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

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
          organization = Organization.fromFirestore(orgDoc);
        });
      }

      _loadOrders(organizationId);
      _loadUsers(organizationId);
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
                  .map((doc) => Order.fromFirestore(doc))
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
                .map((doc) => AppUser.fromFirestore(doc))
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

  void _handleLogout(BuildContext context) async {
    await context.read<AuthCubit>().signOut();
    if (context.mounted) {
      Navigator.pop(context);
      context.go(Routes.login);
    }
  }

  void _showSettingsBottomSheet(BuildContext context) {
    if (organization == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (buildContext) => AdminSettingsBottomSheet(
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
        onLogout: () => _handleLogout(context),
      ),
    );
  }

  List<Order> get filteredOrders {
    if (selectedFilter == null) return orders;
    return orders.where((order) => order.status == selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: organization?.primaryColorValue ?? AppColors.primary,
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              SizedBox(height: 16),
              Text(
                'Error loading data',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(errorMessage!),
              SizedBox(height: 16),
              ElevatedButton(onPressed: _loadData, child: Text('Retry')),
            ],
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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    organization!.primaryColorValue,
                    organization!.secondaryColorValue,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: organization!.logoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        organization!.logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.business, color: Colors.white, size: 20),
                      ),
                    )
                  : Icon(Icons.business, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  organization!.name,
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.onSurface),
            onPressed: _loadData,
          ),
          IconButton(
            icon: Icon(Icons.settings, color: AppColors.onSurface),
            onPressed: () => _showSettingsBottomSheet(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: organization!.primaryColorValue,
          labelColor: organization!.primaryColorValue,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          isScrollable: true,
          tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Orders'),
            Tab(text: 'Employees'),
            Tab(text: 'Office Boys'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildOrdersTab(),
          _buildEmployeesTab(),
          _buildOfficeBoysTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildEmployeesTab() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Employees',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    '${employees.length} total employees',
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: organization!.primaryColorValue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${employees.where((e) => e.isActive).length} Active',
                  style: TextStyle(
                    color: organization!.primaryColorValue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: employees.isEmpty
                ? _buildEmptyState('No employees found', Icons.people)
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: employees.length,
                    itemBuilder: (context, index) {
                      return _buildUserCard(employees[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildOfficeBoysTab() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Office Boys',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    '${officeBoys.length} total office boys',
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: organization!.secondaryColorValue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${officeBoys.where((o) => o.isActive).length} Active',
                  style: TextStyle(
                    color: organization!.secondaryColorValue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: officeBoys.isEmpty
                ? _buildEmptyState(
                    'No office boys found',
                    Icons.delivery_dining,
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: officeBoys.length,
                    itemBuilder: (context, index) {
                      return _buildUserCard(officeBoys[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(AppUser user) {
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

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: !user.isActive
            ? Border.all(color: AppColors.error.withOpacity(0.3))
            : null,
      ),
      child: Row(
        children: [
          Container(
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
          SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                      Container(
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
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.email,
                      size: 14,
                      color: AppColors.onSurfaceVariant,
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
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.phone,
                      size: 14,
                      color: AppColors.onSurfaceVariant,
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
                ),
                if (user.department != null) ...[
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.business_center,
                        size: 14,
                        color: AppColors.onSurfaceVariant,
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
                  ),
                ],
              ],
            ),
          ),

          Column(
            children: [
              Text(
                '$userOrders',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: user.role == UserRole.employee
                      ? organization!.primaryColorValue
                      : organization!.secondaryColorValue,
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
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
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

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Stats',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            SizedBox(height: 16),

            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              children: [
                StatCard(
                  title: 'Total Orders',
                  value: totalOrders.toString(),
                  icon: Icons.receipt_long,
                  color: organization!.primaryColorValue,
                ),
                StatCard(
                  title: 'Today\'s Orders',
                  value: todayOrders.toString(),
                  icon: Icons.today,
                  color: Colors.blue,
                ),
                StatCard(
                  title: 'Employees',
                  value: employees.length.toString(),
                  icon: Icons.people,
                  color: organization!.primaryColorValue,
                ),
                StatCard(
                  title: 'Office Boys',
                  value: officeBoys.length.toString(),
                  icon: Icons.delivery_dining,
                  color: organization!.secondaryColorValue,
                ),
                StatCard(
                  title: 'Internal Orders',
                  value: internalOrders.toString(),
                  icon: Icons.coffee,
                  color: Colors.brown,
                ),
                StatCard(
                  title: 'External Orders',
                  value: externalOrders.toString(),
                  icon: Icons.attach_money,
                  color: Colors.green,
                ),
                StatCard(
                  title: 'Pending',
                  value: pendingOrders.toString(),
                  icon: Icons.pending_actions,
                  color: Colors.orange,
                ),
                StatCard(
                  title: 'Completed',
                  value: completedOrders.toString(),
                  icon: Icons.check_circle,
                  color: AppColors.success,
                ),
              ],
            ),

            SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Orders',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: Text('View All'),
                ),
              ],
            ),
            SizedBox(height: 16),

            if (orders.isEmpty)
              _buildEmptyState('No orders yet', Icons.receipt_long)
            else
              ...orders
                  .take(5)
                  .map(
                    (order) =>
                        OrderCard(order: order, organization: organization!),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Orders',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', selectedFilter == null),
                    _buildFilterChip(
                      'Pending',
                      selectedFilter == OrderStatus.pending,
                    ),
                    _buildFilterChip(
                      'In Progress',
                      selectedFilter == OrderStatus.inProgress,
                    ),
                    _buildFilterChip(
                      'Completed',
                      selectedFilter == OrderStatus.completed,
                    ),
                    _buildFilterChip(
                      'Cancelled',
                      selectedFilter == OrderStatus.cancelled,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: filteredOrders.isEmpty
                ? _buildEmptyState('No orders found', Icons.search_off)
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      return _buildDetailedOrderCard(filteredOrders[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    final totalRevenue = orders
        .where((o) => o.price != null && o.status == OrderStatus.completed)
        .fold(0.0, (sum, order) => sum + order.price!);

    final mostActiveEmployee = _getMostActiveEmployee();
    final mostActiveOfficeBoy = _getMostActiveOfficeBoy();
    final popularItem = _getPopularItem();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            SizedBox(height: 16),

            _buildAnalyticsCard(
              'Most Active Employee',
              mostActiveEmployee['name'] ?? 'N/A',
              '${mostActiveEmployee['count']} orders',
              Icons.person_pin,
              organization!.primaryColorValue,
            ),
            SizedBox(height: 12),
            _buildAnalyticsCard(
              'Most Active Office Boy',
              mostActiveOfficeBoy['name'] ?? 'N/A',
              '${mostActiveOfficeBoy['count']} deliveries',
              Icons.delivery_dining,
              organization!.secondaryColorValue,
            ),
            SizedBox(height: 12),
            _buildAnalyticsCard(
              'Popular Item',
              popularItem['item'] ?? 'N/A',
              'Ordered ${popularItem['count']} times',
              Icons.local_cafe,
              Colors.brown,
            ),
            SizedBox(height: 12),
            _buildAnalyticsCard(
              'Total Revenue',
              'EGP ${totalRevenue.toStringAsFixed(0)}',
              'From external orders',
              Icons.attach_money,
              AppColors.success,
            ),

            SizedBox(height: 24),

            Text(
              'Team Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            SizedBox(height: 16),
            _buildTeamPerformance(),

            SizedBox(height: 24),

            Text(
              'Order Status Distribution',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            SizedBox(height: 16),
            _buildStatusDistribution(),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamPerformance() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${employees.where((e) => e.isActive).length}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: organization!.primaryColorValue,
                      ),
                    ),
                    Text(
                      'Active Employees',
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.outline),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${officeBoys.where((o) => o.isActive).length}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: organization!.secondaryColorValue,
                      ),
                    ),
                    Text(
                      'Active Office Boys',
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Divider(color: AppColors.outline),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      (employees.isEmpty ? 0 : orders.length / employees.length)
                          .toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      'Avg Orders/Employee',
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      (officeBoys.isEmpty
                              ? 0
                              : orders.length / officeBoys.length)
                          .toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      'Avg Deliveries/Office Boy',
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedOrderCard(Order order) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              _buildStatusChip(order.status),
            ],
          ),
          SizedBox(height: 12),

          Row(
            children: [
              Icon(
                order.type == OrderType.internal ? Icons.home : Icons.store,
                color: _getOrderTypeColor(order.type),
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.item,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (order.description.isNotEmpty)
                      Text(
                        order.description,
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              if (order.price != null)
                Text(
                  'EGP ${order.price!.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: AppColors.onSurfaceVariant,
                      size: 16,
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
                      Icons.delivery_dining,
                      color: AppColors.onSurfaceVariant,
                      size: 16,
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
          SizedBox(height: 8),

          Row(
            children: [
              Icon(
                Icons.access_time,
                color: AppColors.onSurfaceVariant,
                size: 16,
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
                Icon(Icons.note, color: AppColors.onSurfaceVariant, size: 16),
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
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool value) {
          setState(() {
            if (label == 'All') {
              selectedFilter = null;
            } else if (label == 'Pending') {
              selectedFilter = value ? OrderStatus.pending : null;
            } else if (label == 'In Progress') {
              selectedFilter = value ? OrderStatus.inProgress : null;
            } else if (label == 'Completed') {
              selectedFilter = value ? OrderStatus.completed : null;
            } else if (label == 'Cancelled') {
              selectedFilter = value ? OrderStatus.cancelled : null;
            }
          });
        },
        selectedColor: organization!.primaryColorValue.withOpacity(0.2),
        checkmarkColor: organization!.primaryColorValue,
        labelStyle: TextStyle(
          color: isSelected
              ? organization!.primaryColorValue
              : AppColors.onSurfaceVariant,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildStatusDistribution() {
    final statusCounts = <OrderStatus, int>{};
    for (final status in OrderStatus.values) {
      statusCounts[status] = orders.where((o) => o.status == status).length;
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: statusCounts.entries.map((entry) {
          final percentage = orders.isEmpty
              ? 0.0
              : (entry.value / orders.length);
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getStatusColor(entry.key),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  entry.key.toString().split('.').last.toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Spacer(),
                Text('${entry.value}'),
                SizedBox(width: 8),
                Text(
                  '(${(percentage * 100).toStringAsFixed(1)}%)',
                  style: TextStyle(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.onSurfaceVariant.withOpacity(0.5),
            ),
            SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Color _getOrderTypeColor(OrderType type) {
    return type == OrderType.internal
        ? organization!.secondaryColorValue
        : organization!.primaryColorValue;
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.inProgress:
        return Colors.blue;
      case OrderStatus.completed:
        return AppColors.success;
      case OrderStatus.cancelled:
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

  Map<String, dynamic> _getMostActiveEmployee() {
    if (orders.isEmpty) return {'name': null, 'count': 0};

    final employeeCounts = <String, int>{};
    final employeeNames = <String, String>{};

    for (final order in orders) {
      employeeCounts[order.employeeId] =
          (employeeCounts[order.employeeId] ?? 0) + 1;
      employeeNames[order.employeeId] = order.employeeName;
    }

    final topEmployee = employeeCounts.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    return {'name': employeeNames[topEmployee.key], 'count': topEmployee.value};
  }

  Map<String, dynamic> _getMostActiveOfficeBoy() {
    if (orders.isEmpty) return {'name': null, 'count': 0};

    final officeBoysCounts = <String, int>{};
    final officeBoysNames = <String, String>{};

    for (final order in orders) {
      officeBoysCounts[order.officeBoyId] =
          (officeBoysCounts[order.officeBoyId] ?? 0) + 1;
      officeBoysNames[order.officeBoyId] = order.officeBoyName;
    }

    final topOfficeBoy = officeBoysCounts.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    return {
      'name': officeBoysNames[topOfficeBoy.key],
      'count': topOfficeBoy.value,
    };
  }

  Map<String, dynamic> _getPopularItem() {
    if (orders.isEmpty) return {'item': null, 'count': 0};

    final itemCounts = <String, int>{};

    for (final order in orders) {
      itemCounts[order.item] = (itemCounts[order.item] ?? 0) + 1;
    }

    final topItem = itemCounts.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    return {'item': topItem.key, 'count': topItem.value};
  }

  Widget _buildStatusChip(OrderStatus status) {
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
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
