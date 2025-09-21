// import 'dart:math' as math;
// import 'dart:ui';

// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:taqy/core/utils/dialogs/error_toast.dart';
// import 'package:taqy/core/utils/widgets/app_images.dart';
// import 'package:taqy/features/employee/data/models/order_model.dart';
// import 'package:taqy/features/employee/data/models/organization_model.dart';

// class OrderResponseBottomSheet extends StatefulWidget {
//   final EmployeeOrder order;
//   final EmployeeOrganization organization;
//   final Function(String orderId, String response, OrderStatus newStatus)
//   onResponse;

//   const OrderResponseBottomSheet({
//     super.key,
//     required this.order,
//     required this.organization,
//     required this.onResponse,
//   });

//   @override
//   State<OrderResponseBottomSheet> createState() =>
//       _OrderResponseBottomSheetState();
// }

// class _OrderResponseBottomSheetState extends State<OrderResponseBottomSheet>
//     with TickerProviderStateMixin {
//   final TextEditingController _responseController = TextEditingController();
//   bool _isLoading = false;
//   OrderStatus _selectedAction = OrderStatus.inProgress;

//   // Animation Controllers
//   late AnimationController _slideController;
//   late AnimationController _fadeController;
//   late AnimationController _scaleController;
//   late AnimationController _glowController;
//   late AnimationController _particleController;
//   late AnimationController _shimmerController;

//   // Animations
//   late Animation<double> _slideAnimation;
//   late Animation<double> _fadeAnimation;
//   late Animation<double> _scaleAnimation;
//   late Animation<double> _glowAnimation;
//   late Animation<double> _particleAnimation;
//   // late Animation<double> _shimmerAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _initializeAnimations();
//     _startAnimations();
//   }

//   void _initializeAnimations() {
//     // Slide animation for content entrance
//     _slideController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 800),
//     );
//     _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
//       CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
//     );

//     // Fade animation
//     _fadeController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 600),
//     );
//     _fadeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

//     // Scale animation for cards
//     _scaleController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 500),
//     );
//     _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
//       CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
//     );

//     // Glow animation for interactive elements
//     _glowController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 2),
//     );
//     _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
//     );

//     // Particle animation for background
//     _particleController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 10),
//     );
//     _particleAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
//       CurvedAnimation(parent: _particleController, curve: Curves.linear),
//     );

//     // Shimmer effect
//     _shimmerController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 3),
//     );
//     // _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
//     //   CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
//     // );
//   }

//   void _startAnimations() {
//     _slideController.forward();
//     _fadeController.forward();
//     _scaleController.forward();
//     _glowController.repeat(reverse: true);
//     _particleController.repeat();
//     _shimmerController.repeat(reverse: true);
//   }

//   @override
//   void dispose() {
//     _responseController.dispose();
//     _slideController.dispose();
//     _fadeController.dispose();
//     _scaleController.dispose();
//     _glowController.dispose();
//     _particleController.dispose();
//     _shimmerController.dispose();
//     super.dispose();
//   }

//   String _getItemStatusIcon(ItemStatus status) {
//     switch (status) {
//       case ItemStatus.pending:
//         return Assets.imagesSvgsPending;
//       case ItemStatus.available:
//         return Assets.imagesSvgsComplete;
//       case ItemStatus.notAvailable:
//         return Assets.imagesSvgsCancell;
//     }
//   }

//   String _getItemStatusText(ItemStatus status) {
//     switch (status) {
//       case ItemStatus.pending:
//         return 'Checking...';
//       case ItemStatus.available:
//         return 'Available';
//       case ItemStatus.notAvailable:
//         return 'Not Available';
//     }
//   }

//   Future<void> _submitResponse() async {
//     if (_responseController.text.trim().isEmpty) {
//       showErrorToast(context, 'Please provide a response');
//       return;
//     }

//     setState(() => _isLoading = true);

//     try {
//       await widget.onResponse(
//         widget.order.id,
//         _responseController.text.trim(),
//         _selectedAction,
//       );
//       Navigator.pop(context);
//     } catch (e) {
//       showErrorToast(context, 'Failed to submit response: $e');
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: Listenable.merge([
//         _slideController,
//         _fadeController,
//         _scaleController,
//       ]),
//       builder: (context, child) => Transform.translate(
//         offset: Offset(
//           0,
//           MediaQuery.of(context).size.height * 0.1 * _slideAnimation.value,
//         ),
//         child: FadeTransition(
//           opacity: _fadeAnimation,
//           child: ScaleTransition(
//             scale: _scaleAnimation,
//             child: Container(
//               height: MediaQuery.of(context).size.height,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.only(
//                   topLeft: Radius.circular(32),
//                   topRight: Radius.circular(32),
//                 ),
//               ),
//               child: Stack(
//                 children: [
//                   // Animated background with particles
//                   Positioned.fill(child: _buildAnimatedBackground()),

//                   // Glass morphism container
//                   Positioned.fill(
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.only(
//                         topLeft: Radius.circular(32),
//                         topRight: Radius.circular(32),
//                       ),
//                       child: BackdropFilter(
//                         filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
//                         child: Container(
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               begin: Alignment.topLeft,
//                               end: Alignment.bottomRight,
//                               colors: [
//                                 Colors.white.withOpacity(0.25),
//                                 Colors.white.withOpacity(0.1),
//                                 Colors.white.withOpacity(0.05),
//                               ],
//                             ),
//                             borderRadius: BorderRadius.only(
//                               topLeft: Radius.circular(32),
//                               topRight: Radius.circular(32),
//                             ),
//                             border: Border.all(
//                               color: Colors.white.withOpacity(0.2),
//                               width: 1,
//                             ),
//                           ),
//                           child: _buildContent(),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildAnimatedBackground() {
//     return AnimatedBuilder(
//       animation: Listenable.merge([_particleController, _shimmerController]),
//       builder: (context, child) => Container(
//         decoration: BoxDecoration(
//           // gradient: LinearGradient(
//           //   begin: Alignment.topLeft,
//           //   end: Alignment.bottomRight,
//           //   colors: [
//           //     widget.organization.primaryColorValue.withOpacity(0.1),
//           //     widget.organization.secondaryColorValue.withOpacity(0.1),
//           //     widget.organization.primaryColorValue.withOpacity(0.05),
//           //   ],
//           // ),
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(32),
//             topRight: Radius.circular(32),
//           ),
//         ),
//         child: CustomPaint(
//           painter: ParticlesPainter(
//             _particleAnimation.value,
//             widget.organization.primaryColorValue,
//             widget.organization.secondaryColorValue,
//           ),
//           size: Size.infinite,
//         ),
//       ),
//     );
//   }

//   Widget _buildContent() {
//     final availableItems = widget.order.items
//         .where((item) => item.status == ItemStatus.available)
//         .toList();
//     final unavailableItems = widget.order.items
//         .where((item) => item.status == ItemStatus.notAvailable)
//         .toList();
//     final hasAvailableItems = availableItems.isNotEmpty;

//     return Column(
//       children: [
//         _buildGlassHeader(),
//         Expanded(
//           child: SingleChildScrollView(
//             physics: BouncingScrollPhysics(),
//             padding: EdgeInsets.symmetric(horizontal: 24),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 SizedBox(height: 20),
//                 _buildOrderSummary(),
//                 SizedBox(height: 24),
//                 _buildAvailabilityStatus(availableItems, unavailableItems),
//                 SizedBox(height: 24),
//                 _buildActionSelection(hasAvailableItems, availableItems.length),
//                 SizedBox(height: 24),
//                 _buildResponseMessage(),
//                 SizedBox(height: 32),
//               ],
//             ),
//           ),
//         ),
//         _buildGlassBottomActions(),
//       ],
//     );
//   }

//   Widget _buildGlassHeader() {
//     return TweenAnimationBuilder<double>(
//       tween: Tween(begin: 0.0, end: 1.0),
//       duration: Duration(milliseconds: 800),
//       curve: Curves.elasticOut,
//       builder: (context, value, child) => Transform.translate(
//         offset: Offset(0, -50 * (1 - value)),
//         child: Container(
//           padding: EdgeInsets.fromLTRB(24, 20, 24, 16),
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 Colors.white.withOpacity(0.2),
//                 Colors.white.withOpacity(0.1),
//               ],
//             ),
//             border: Border(
//               bottom: BorderSide(
//                 color: Colors.white.withOpacity(0.1),
//                 width: 1,
//               ),
//             ),
//           ),
//           child: Column(
//             children: [
//               // Handle bar with glow effect
//               AnimatedBuilder(
//                 animation: _glowController,
//                 builder: (context, child) => Container(
//                   margin: EdgeInsets.only(bottom: 20),
//                   height: 5,
//                   width: 50,
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [
//                         Colors.white.withOpacity(
//                           0.3 + (_glowAnimation.value * 0.4),
//                         ),
//                         Colors.white.withOpacity(
//                           0.3 + (_glowAnimation.value * 0.4),
//                         ),
//                       ],
//                     ),
//                     borderRadius: BorderRadius.circular(3),
//                     boxShadow: [
//                       BoxShadow(
//                         color: widget.organization.primaryColorValue
//                             .withOpacity(_glowAnimation.value * 0.3),
//                         blurRadius: 10,
//                         spreadRadius: 2,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               Row(
//                 children: [
//                   // Animated title with shimmer effect
//                   Expanded(
//                     child: AnimatedBuilder(
//                       animation: _shimmerController,
//                       builder: (context, child) => Text(
//                         'Order Response',
//                         style: TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                           letterSpacing: 0.5,
//                         ),
//                       ),
//                     ),
//                   ),

//                   SizedBox(width: 12),

//                   // Animated close button
//                   TweenAnimationBuilder<double>(
//                     tween: Tween(begin: 0.0, end: 1.0),
//                     duration: Duration(milliseconds: 600),
//                     curve: Curves.elasticOut,
//                     builder: (context, value, child) => Transform.scale(
//                       scale: value,
//                       child: GestureDetector(
//                         onTap: () => Navigator.pop(context),
//                         child: AnimatedBuilder(
//                           animation: _glowController,
//                           builder: (context, child) => Container(
//                             padding: EdgeInsets.all(12),
//                             decoration: BoxDecoration(
//                               gradient: RadialGradient(
//                                 colors: [
//                                   Colors.white.withOpacity(
//                                     0.2 + (_glowAnimation.value * 0.1),
//                                   ),
//                                   Colors.white.withOpacity(0.1),
//                                 ],
//                               ),
//                               borderRadius: BorderRadius.circular(16),
//                               border: Border.all(
//                                 color: Colors.white.withOpacity(0.3),
//                                 width: 1,
//                               ),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.white.withOpacity(
//                                     _glowAnimation.value * 0.2,
//                                   ),
//                                   blurRadius: 15,
//                                   spreadRadius: 1,
//                                 ),
//                               ],
//                             ),
//                             child: Icon(
//                               Icons.close,
//                               color: Colors.white.withOpacity(0.9),
//                               size: 20,
//                             ),
//                           ),
//                         ),
//                       ),
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

//   Widget _buildOrderSummary() {
//     return TweenAnimationBuilder<double>(
//       tween: Tween(begin: 0.0, end: 1.0),
//       duration: Duration(milliseconds: 600),
//       curve: Curves.easeOutBack,
//       builder: (context, value, child) => Transform.scale(
//         scale: value,
//         child: Container(
//           padding: EdgeInsets.all(24),
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 widget.organization.primaryColorValue.withOpacity(0.7),
//                 widget.organization.secondaryColorValue.withOpacity(0.5),
//               ],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
//             boxShadow: [
//               BoxShadow(
//                 color: widget.organization.primaryColorValue.withOpacity(0.3),
//                 blurRadius: 20,
//                 offset: Offset(0, 8),
//               ),
//             ],
//           ),
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(20),
//             child: BackdropFilter(
//               filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//               child: Row(
//                 children: [
//                   Container(
//                     padding: EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       gradient: RadialGradient(
//                         colors: [
//                           Colors.white.withOpacity(0.3),
//                           Colors.white.withOpacity(0.1),
//                         ],
//                       ),
//                       border: Border.all(
//                         color: Colors.white.withOpacity(0.4),
//                         width: 1,
//                       ),
//                     ),
//                     child: SvgPicture.asset(
//                       widget.order.type == OrderType.internal
//                           ? Assets.imagesSvgsCompany
//                           : Assets.imagesSvgsShoppingCart,
//                       color: Colors.white,
//                       height: 28,
//                       width: 28,
//                     ),
//                   ),
//                   SizedBox(width: 16),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           widget.order.items.length == 1
//                               ? widget.order.items.first.name
//                               : '${widget.order.items.length} Items Order',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             letterSpacing: 0.5,
//                           ),
//                         ),
//                         if (widget.order.description.isNotEmpty) ...[
//                           SizedBox(height: 8),
//                           Text(
//                             widget.order.description,
//                             style: TextStyle(
//                               color: Colors.white.withOpacity(0.9),
//                               fontSize: 14,
//                               letterSpacing: 0.3,
//                             ),
//                           ),
//                         ],
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildAvailabilityStatus(
//     List<OrderItem> availableItems,
//     List<OrderItem> unavailableItems,
//   ) {
//     return TweenAnimationBuilder<double>(
//       tween: Tween(begin: 0.0, end: 1.0),
//       duration: Duration(milliseconds: 800),
//       curve: Curves.easeOutBack,
//       builder: (context, value, child) => Transform.translate(
//         offset: Offset(50 * (1 - value), 0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Item Availability Status',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//                 letterSpacing: 0.5,
//               ),
//             ),
//             SizedBox(height: 16),

//             // Available Items
//             if (availableItems.isNotEmpty) ...[
//               _buildStatusContainer(
//                 availableItems,
//                 'Available Items',
//                 widget.organization.primaryColorValue,
//                 Assets.imagesSvgsComplete,
//               ),
//               SizedBox(height: 16),
//             ],

//             // Unavailable Items
//             if (unavailableItems.isNotEmpty) ...[
//               _buildStatusContainer(
//                 unavailableItems,
//                 'Unavailable Items',
//                 Colors.red,
//                 Assets.imagesSvgsCancell,
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusContainer(
//     List<OrderItem> items,
//     String title,
//     Color statusColor,
//     String statusIcon,
//   ) {
//     return Container(
//       padding: EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             Colors.white.withOpacity(0.4),
//             Colors.white.withOpacity(0.3),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: statusColor.withOpacity(0.3), width: 4),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.white.withOpacity(0.05),
//             blurRadius: 15,
//             offset: Offset(0, 8),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(16),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Container(
//                     padding: EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       gradient: RadialGradient(
//                         colors: [
//                           statusColor.withOpacity(0.2),
//                           statusColor.withOpacity(0.1),
//                         ],
//                       ),
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(
//                         color: statusColor.withOpacity(0.4),
//                         width: 1,
//                       ),
//                     ),
//                     child: SvgPicture.asset(
//                       statusIcon,
//                       color: statusColor,
//                       height: 20,
//                     ),
//                   ),
//                   SizedBox(width: 12),
//                   Text(
//                     '$title (${items.length})',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                       fontSize: 16,
//                       letterSpacing: 0.3,
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 16),
//               ...items.map((item) => _buildGlassItemRow(item, statusColor)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildGlassItemRow(OrderItem item, Color statusColor) {
//     return Container(
//       margin: EdgeInsets.only(bottom: 12),
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             Colors.black.withOpacity(0.2),
//             Colors.black.withOpacity(0.1),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.white.withOpacity(0.05),
//             blurRadius: 10,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(12),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Container(
//                     padding: EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       gradient: RadialGradient(
//                         colors: [
//                           statusColor.withOpacity(0.2),
//                           statusColor.withOpacity(0.1),
//                         ],
//                       ),
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(
//                         color: statusColor.withOpacity(0.4),
//                         width: 1,
//                       ),
//                     ),
//                     child: SvgPicture.asset(
//                       _getItemStatusIcon(item.status),
//                       color: Colors.white,
//                       height: 18,
//                       width: 18,
//                     ),
//                   ),
//                   SizedBox(width: 12),
//                   Expanded(
//                     child: Text(
//                       item.name,
//                       style: TextStyle(
//                         fontWeight: FontWeight.w600,
//                         fontSize: 14,
//                         color: Colors.white,
//                         letterSpacing: 0.3,
//                       ),
//                     ),
//                   ),
//                   Container(
//                     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [
//                           statusColor.withOpacity(0.3),
//                           statusColor.withOpacity(0.2),
//                         ],
//                       ),
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(
//                         color: statusColor.withOpacity(0.2),
//                         width: 1,
//                       ),
//                     ),
//                     child: Text(
//                       _getItemStatusText(item.status),
//                       style: TextStyle(
//                         fontSize: 10,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.white,
//                         letterSpacing: 0.2,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               if (item.notes != null && item.notes!.isNotEmpty) ...[
//                 SizedBox(height: 12),
//                 Container(
//                   padding: EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [
//                         Colors.white.withOpacity(0.15),
//                         Colors.white.withOpacity(0.05),
//                       ],
//                     ),
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(
//                       color: Colors.white.withOpacity(0.2),
//                       width: 1,
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       SvgPicture.asset(
//                         Assets.imagesSvgsNote,
//                         height: 16,
//                         width: 16,
//                         color: Colors.white.withOpacity(0.8),
//                       ),
//                       SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           item.notes!,
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.white.withOpacity(0.8),
//                             fontStyle: FontStyle.italic,
//                             letterSpacing: 0.2,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildActionSelection(bool hasAvailableItems, int availableCount) {
//     return TweenAnimationBuilder<double>(
//       tween: Tween(begin: 0.0, end: 1.0),
//       duration: Duration(milliseconds: 1000),
//       curve: Curves.easeOutBack,
//       builder: (context, value, child) => Transform.translate(
//         offset: Offset(100 * (1 - value), 0),
//         child: Container(
//           padding: EdgeInsets.all(24),
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 Colors.white.withOpacity(0.2),
//                 Colors.white.withOpacity(0.1),
//               ],
//             ),
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 20,
//                 offset: Offset(0, 8),
//               ),
//             ],
//           ),
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(20),
//             child: BackdropFilter(
//               filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Your Decision',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                       letterSpacing: 0.5,
//                     ),
//                   ),
//                   SizedBox(height: 20),

//                   // Continue option
//                   if (hasAvailableItems) ...[
//                     _buildGlassRadioOption(
//                       OrderStatus.inProgress,
//                       'Continue with available items',
//                       'Proceed with $availableCount available item${availableCount == 1 ? '' : 's'}',
//                       Assets.imagesSvgsComplete,
//                       widget.organization.primaryColorValue,
//                     ),
//                     SizedBox(height: 16),
//                   ],

//                   // Cancel option
//                   _buildGlassRadioOption(
//                     OrderStatus.cancelled,
//                     'Cancel the entire order',
//                     'Cancel due to unavailable items',
//                     Assets.imagesSvgsCancell,
//                     Colors.red,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildGlassRadioOption(
//     OrderStatus value,
//     String title,
//     String subtitle,
//     String icon,
//     Color color,
//   ) {
//     final isSelected = _selectedAction == value;

//     return AnimatedBuilder(
//       animation: _glowController,
//       builder: (context, child) => GestureDetector(
//         onTap: () {
//           setState(() {
//             _selectedAction = value;
//           });
//         },
//         child: Container(
//           padding: EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: isSelected
//                   ? [color.withOpacity(0.3), color.withOpacity(0.1)]
//                   : [
//                       Colors.white.withOpacity(0.15),
//                       Colors.white.withOpacity(0.05),
//                     ],
//             ),
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(
//               color: isSelected
//                   ? color.withOpacity(0.5)
//                   : Colors.white.withOpacity(0.2),
//               width: isSelected ? 2 : 1,
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.05),
//                 blurRadius: 8,
//                 offset: Offset(0, 4),
//               ),
//             ],
//           ),
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(16),
//             child: BackdropFilter(
//               filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
//               child: Row(
//                 children: [
//                   Container(
//                     padding: EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       gradient: RadialGradient(
//                         colors: [
//                           color.withOpacity(isSelected ? 0.3 : 0.2),
//                           color.withOpacity(0.1),
//                         ],
//                       ),
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(
//                         color: color.withOpacity(isSelected ? 0.5 : 0.3),
//                         width: 1,
//                       ),
//                     ),
//                     child: SvgPicture.asset(
//                       icon,
//                       color: isSelected ? Colors.white : color,
//                       height: 20,
//                       width: 20,
//                     ),
//                   ),
//                   SizedBox(width: 16),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           title,
//                           style: TextStyle(
//                             color: isSelected
//                                 ? Colors.white
//                                 : Colors.white.withOpacity(0.9),
//                             fontWeight: FontWeight.bold,
//                             fontSize: 16,
//                             letterSpacing: 0.3,
//                           ),
//                         ),
//                         SizedBox(height: 4),
//                         Text(
//                           subtitle,
//                           style: TextStyle(
//                             color: Colors.white.withOpacity(0.7),
//                             fontSize: 12,
//                             letterSpacing: 0.2,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Container(
//                     width: 24,
//                     height: 24,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       gradient: isSelected
//                           ? LinearGradient(
//                               colors: [color, color.withOpacity(0.7)],
//                             )
//                           : null,
//                       border: Border.all(
//                         color: isSelected
//                             ? Colors.white
//                             : Colors.white.withOpacity(0.5),
//                         width: 2,
//                       ),
//                     ),
//                     child: isSelected
//                         ? Icon(Icons.check, color: Colors.white, size: 16)
//                         : null,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildResponseMessage() {
//     return TweenAnimationBuilder<double>(
//       tween: Tween(begin: 0.0, end: 1.0),
//       duration: Duration(milliseconds: 1200),
//       curve: Curves.easeOutBack,
//       builder: (context, value, child) => Transform.translate(
//         offset: Offset(150 * (1 - value), 0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Your Message',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//                 letterSpacing: 0.5,
//               ),
//             ),
//             SizedBox(height: 12),
//             Container(
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(16),
//                 gradient: LinearGradient(
//                   colors: [
//                     Colors.white.withOpacity(0.2),
//                     Colors.white.withOpacity(0.1),
//                   ],
//                 ),
//                 border: Border.all(
//                   color: Colors.white.withOpacity(0.2),
//                   width: 1,
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 20,
//                     offset: Offset(0, 8),
//                   ),
//                 ],
//               ),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(16),
//                 child: BackdropFilter(
//                   filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//                   child: TextFormField(
//                     controller: _responseController,
//                     onTapOutside: (event) =>
//                         FocusManager.instance.primaryFocus?.unfocus(),
//                     maxLines: 4,
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                     decoration: InputDecoration(
//                       hintText: _selectedAction == OrderStatus.inProgress
//                           ? 'Any special instructions or notes...'
//                           : 'Reason for cancellation...',
//                       hintStyle: TextStyle(
//                         color: Colors.white.withOpacity(0.6),
//                         fontSize: 14,
//                       ),

//                       prefixIcon: Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: SvgPicture.asset(
//                           Assets.imagesSvgsMessage,
//                           color: Colors.white,
//                           height: 24,
//                           width: 24,
//                         ),
//                       ),
//                       border: InputBorder.none,
//                       contentPadding: EdgeInsets.symmetric(
//                         horizontal: 20,
//                         vertical: 20,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildGlassBottomActions() {
//     return TweenAnimationBuilder<double>(
//       tween: Tween(begin: 0.0, end: 1.0),
//       duration: Duration(milliseconds: 1400),
//       curve: Curves.elasticOut,
//       builder: (context, value, child) => Transform.translate(
//         offset: Offset(0, 100 * (1 - value)),
//         child: Container(
//           padding: EdgeInsets.all(24),
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 Colors.white.withOpacity(0.2),
//                 Colors.white.withOpacity(0.1),
//               ],
//             ),
//             border: Border(
//               top: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
//             ),
//           ),
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(20),
//             child: BackdropFilter(
//               filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//               child: Row(
//                 children: [
//                   // Cancel Button
//                   Expanded(
//                     child: Container(
//                       height: 56,
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [
//                             Colors.white.withOpacity(0.2),
//                             Colors.white.withOpacity(0.1),
//                           ],
//                         ),
//                         borderRadius: BorderRadius.circular(16),
//                         border: Border.all(
//                           color: Colors.white.withOpacity(0.3),
//                           width: 1,
//                         ),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.1),
//                             blurRadius: 10,
//                             offset: Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: Material(
//                         color: Colors.transparent,
//                         child: InkWell(
//                           borderRadius: BorderRadius.circular(16),
//                           onTap: _isLoading
//                               ? null
//                               : () => Navigator.pop(context),
//                           child: Container(
//                             alignment: Alignment.center,
//                             child: Text(
//                               'Cancel',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                                 letterSpacing: 0.5,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),

//                   SizedBox(width: 16),

//                   // Action Button
//                   Expanded(
//                     flex: 2,
//                     child: AnimatedBuilder(
//                       animation: _glowController,
//                       builder: (context, child) {
//                         final actionColor =
//                             _selectedAction == OrderStatus.cancelled
//                             ? Colors.red
//                             : widget.organization.primaryColorValue;

//                         return Container(
//                           height: 56,
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: [
//                                 actionColor,
//                                 actionColor.withOpacity(0.8),
//                               ],
//                             ),
//                             borderRadius: BorderRadius.circular(16),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: actionColor.withOpacity(
//                                   0.4 + (_glowAnimation.value * 0.2),
//                                 ),
//                                 blurRadius: 15 + (_glowAnimation.value * 5),
//                                 spreadRadius: 1,
//                                 offset: Offset(0, 6),
//                               ),
//                             ],
//                           ),
//                           child: Material(
//                             color: Colors.transparent,
//                             child: InkWell(
//                               borderRadius: BorderRadius.circular(16),
//                               onTap: _isLoading ? null : _submitResponse,
//                               child: Container(
//                                 alignment: Alignment.center,
//                                 child: _isLoading
//                                     ? Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.center,
//                                         children: [
//                                           SizedBox(
//                                             width: 20,
//                                             height: 20,
//                                             child: CircularProgressIndicator(
//                                               color: Colors.white,
//                                               strokeWidth: 2,
//                                             ),
//                                           ),
//                                           SizedBox(width: 12),
//                                           Text(
//                                             'Submitting...',
//                                             style: TextStyle(
//                                               color: Colors.white,
//                                               fontSize: 16,
//                                               fontWeight: FontWeight.bold,
//                                             ),
//                                           ),
//                                         ],
//                                       )
//                                     : Text(
//                                         _selectedAction == OrderStatus.cancelled
//                                             ? 'Cancel Order'
//                                             : 'Continue Order',
//                                         style: TextStyle(
//                                           color: Colors.white,
//                                           fontSize: 16,
//                                           fontWeight: FontWeight.bold,
//                                           letterSpacing: 0.5,
//                                         ),
//                                       ),
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // Custom painter for animated particles background
// class ParticlesPainter extends CustomPainter {
//   final double animationValue;
//   final Color primaryColor;
//   final Color secondaryColor;

//   ParticlesPainter(this.animationValue, this.primaryColor, this.secondaryColor);

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()..style = PaintingStyle.fill;

//     // Draw floating particles
//     for (int i = 0; i < 20; i++) {
//       final progress = (animationValue + i * 0.1) % 1.0;
//       final x =
//           (i % 4) * size.width / 4 +
//           math.sin(animationValue * 2 * math.pi + i) * 30;
//       final y = size.height * progress;
//       final opacity = math.sin(progress * math.pi) * 0.3;

//       paint.color = (i % 2 == 0 ? primaryColor : secondaryColor).withOpacity(
//         opacity,
//       );

//       final radius = 2 + math.sin(animationValue * 4 * math.pi + i) * 1;
//       canvas.drawCircle(Offset(x, y), radius, paint);
//     }

//     // Draw flowing waves
//     final wavePaint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2;

//     for (int i = 0; i < 3; i++) {
//       final path = Path();
//       final waveHeight = 20 + i * 10;
//       final waveLength = size.width / 4;
//       final waveOffset = animationValue * 2 * math.pi;

//       wavePaint.color = (i % 2 == 0 ? primaryColor : secondaryColor)
//           .withOpacity(0.1);

//       path.moveTo(0, size.height * 0.3 + i * size.height * 0.2);

//       for (double x = 0; x <= size.width; x += 5) {
//         final y =
//             size.height * 0.3 +
//             i * size.height * 0.2 +
//             math.sin((x / waveLength + waveOffset + i) * 2 * math.pi) *
//                 waveHeight;
//         path.lineTo(x, y);
//       }

//       canvas.drawPath(path, wavePaint);
//     }

//     // Draw gradient orbs
//     for (int i = 0; i < 5; i++) {
//       final centerX = (i + 0.5) * size.width / 5;
//       final centerY =
//           size.height * 0.5 +
//           math.sin(animationValue * 2 * math.pi + i * 1.2) * 100;
//       final radius = 40 + math.sin(animationValue * 3 * math.pi + i) * 20;

//       final gradient = RadialGradient(
//         colors: [
//           (i % 2 == 0 ? primaryColor : secondaryColor).withOpacity(0.1),
//           Colors.transparent,
//         ],
//       );

//       final rect = Rect.fromCircle(
//         center: Offset(centerX, centerY),
//         radius: radius,
//       );
//       paint.shader = gradient.createShader(rect);
//       canvas.drawCircle(Offset(centerX, centerY), radius, paint);
//     }
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taqy/core/utils/dialogs/error_toast.dart';
import 'package:taqy/core/utils/widgets/app_images.dart';
import 'package:taqy/features/employee/data/models/order_model.dart';
import 'package:taqy/features/employee/data/models/organization_model.dart';

class OrderResponseBottomSheet extends StatefulWidget {
  final EmployeeOrder order;
  final EmployeeOrganization organization;
  final Function(String orderId, String response, OrderStatus newStatus)
  onResponse;

  const OrderResponseBottomSheet({
    super.key,
    required this.order,
    required this.organization,
    required this.onResponse,
  });

  @override
  State<OrderResponseBottomSheet> createState() =>
      _OrderResponseBottomSheetState();
}

class _OrderResponseBottomSheetState extends State<OrderResponseBottomSheet>
    with TickerProviderStateMixin {
  final TextEditingController _responseController = TextEditingController();
  bool _isLoading = false;
  OrderStatus _selectedAction = OrderStatus.inProgress;

  // Animation Controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late AnimationController _shimmerController;

  // Animations
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Slide animation for content entrance
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    // Fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    // Scale animation for cards
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Glow animation for interactive elements
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Particle animation for background
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _particleAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.linear),
    );

    // Shimmer effect
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  void _startAnimations() {
    _slideController.forward();
    _fadeController.forward();
    _scaleController.forward();
    _glowController.repeat(reverse: true);
    _particleController.repeat();
    _shimmerController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _responseController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  String _getItemStatusIcon(ItemStatus status) {
    switch (status) {
      case ItemStatus.pending:
        return Assets.imagesSvgsPending;
      case ItemStatus.available:
        return Assets.imagesSvgsComplete;
      case ItemStatus.notAvailable:
        return Assets.imagesSvgsCancell;
    }
  }

  String _getItemStatusText(ItemStatus status) {
    switch (status) {
      case ItemStatus.pending:
        return 'Checking...';
      case ItemStatus.available:
        return 'Available';
      case ItemStatus.notAvailable:
        return 'Not Available';
    }
  }

  Future<void> _submitResponse() async {
    if (_responseController.text.trim().isEmpty) {
      showErrorToast(context, 'Please provide a response');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.onResponse(
        widget.order.id,
        _responseController.text.trim(),
        _selectedAction,
      );
      Navigator.pop(context);
    } catch (e) {
      showErrorToast(context, 'Failed to submit response: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _slideController,
        _fadeController,
        _scaleController,
      ]),
      builder: (context, child) => Transform.translate(
        offset: Offset(
          0,
          MediaQuery.of(context).size.height * 0.1 * _slideAnimation.value,
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Stack(
                children: [
                  // Animated background with particles
                  Positioned.fill(child: _buildAnimatedBackground()),

                  // Glass morphism container with improved contrast
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                // Increased opacity for better readability
                                Colors.black.withOpacity(0.4),
                                Colors.black.withOpacity(0.3),
                                Colors.black.withOpacity(0.25),
                              ],
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(32),
                              topRight: Radius.circular(32),
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                              width: 1,
                            ),
                          ),
                          child: _buildContent(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: Listenable.merge([_particleController, _shimmerController]),
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.organization.primaryColorValue.withOpacity(0.15),
              widget.organization.secondaryColorValue.withOpacity(0.15),
              widget.organization.primaryColorValue.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: CustomPaint(
          painter: ParticlesPainter(
            _particleAnimation.value,
            widget.organization.primaryColorValue,
            widget.organization.secondaryColorValue,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }

  Widget _buildContent() {
    final availableItems = widget.order.items
        .where((item) => item.status == ItemStatus.available)
        .toList();
    final unavailableItems = widget.order.items
        .where((item) => item.status == ItemStatus.notAvailable)
        .toList();
    final hasAvailableItems = availableItems.isNotEmpty;

    return Column(
      children: [
        _buildGlassHeader(),
        Expanded(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                _buildOrderSummary(),
                SizedBox(height: 24),
                _buildAvailabilityStatus(availableItems, unavailableItems),
                SizedBox(height: 24),
                _buildActionSelection(hasAvailableItems, availableItems.length),
                SizedBox(height: 24),
                _buildResponseMessage(),
                SizedBox(height: 32),
              ],
            ),
          ),
        ),
        _buildGlassBottomActions(),
      ],
    );
  }

  Widget _buildGlassHeader() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, -50 * (1 - value)),
        child: Container(
          padding: EdgeInsets.fromLTRB(24, 20, 24, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                // Darker background for better contrast
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.2),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // Handle bar with glow effect
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) => Container(
                  margin: EdgeInsets.only(bottom: 20),
                  height: 5,
                  width: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(
                          0.5 + (_glowAnimation.value * 0.3),
                        ),
                        Colors.white.withOpacity(
                          0.5 + (_glowAnimation.value * 0.3),
                        ),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: widget.organization.primaryColorValue
                            .withOpacity(_glowAnimation.value * 0.4),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),

              Row(
                children: [
                  // Animated title with better contrast
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, child) => Text(
                        'Order Response',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 3,
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 12),

                  // Animated close button with better visibility
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) => Transform.scale(
                      scale: value,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: AnimatedBuilder(
                          animation: _glowController,
                          builder: (context, child) => Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  Colors.black.withOpacity(
                                    0.4 + (_glowAnimation.value * 0.1),
                                  ),
                                  Colors.black.withOpacity(0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(
                                    _glowAnimation.value * 0.2,
                                  ),
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.organization.primaryColorValue.withOpacity(0.6),
                widget.organization.secondaryColorValue.withOpacity(0.4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: widget.organization.primaryColorValue.withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.1),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: SvgPicture.asset(
                      widget.order.type == OrderType.internal
                          ? Assets.imagesSvgsCompany
                          : Assets.imagesSvgsShoppingCart,
                      color: Colors.white,
                      height: 28,
                      width: 28,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.order.items.length == 1
                              ? widget.order.items.first.name
                              : '${widget.order.items.length} Items Order',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 3,
                                color: Colors.black.withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),
                        if (widget.order.description.isNotEmpty) ...[
                          SizedBox(height: 8),
                          Text(
                            widget.order.description,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              letterSpacing: 0.3,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                  color: Colors.black.withOpacity(0.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilityStatus(
    List<OrderItem> availableItems,
    List<OrderItem> unavailableItems,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(50 * (1 - value), 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Item Availability Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 3,
                    color: Colors.black.withOpacity(0.5),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Available Items
            if (availableItems.isNotEmpty) ...[
              _buildStatusContainer(
                availableItems,
                'Available Items',
                widget.organization.primaryColorValue,
                Assets.imagesSvgsComplete,
              ),
              SizedBox(height: 16),
            ],

            // Unavailable Items
            if (unavailableItems.isNotEmpty) ...[
              _buildStatusContainer(
                unavailableItems,
                'Unavailable Items',
                Colors.red,
                Assets.imagesSvgsCancell,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusContainer(
    List<OrderItem> items,
    String title,
    Color statusColor,
    String statusIcon,
  ) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.4),
            Colors.black.withOpacity(0.25),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.2),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          statusColor.withOpacity(0.3),
                          statusColor.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withOpacity(0.6),
                        width: 1,
                      ),
                    ),
                    child: SvgPicture.asset(
                      statusIcon,
                      color: statusColor,
                      height: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    '$title (${items.length})',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                      letterSpacing: 0.3,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ...items.map((item) => _buildGlassItemRow(item, statusColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassItemRow(OrderItem item, Color statusColor) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          statusColor.withOpacity(0.3),
                          statusColor.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withOpacity(0.6),
                        width: 1,
                      ),
                    ),
                    child: SvgPicture.asset(
                      _getItemStatusIcon(item.status),
                      color: statusColor,
                      height: 18,
                      width: 18,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.white,
                        letterSpacing: 0.3,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 2,
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor.withOpacity(0.4),
                          statusColor.withOpacity(0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getItemStatusText(item.status),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.2,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 2,
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (item.notes != null && item.notes!.isNotEmpty) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        Assets.imagesSvgsNote,
                        height: 16,
                        width: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.notes!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                            fontStyle: FontStyle.italic,
                            letterSpacing: 0.2,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 2,
                                color: Colors.black.withOpacity(0.3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionSelection(bool hasAvailableItems, int availableCount) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 1000),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(100 * (1 - value), 0),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.4),
                Colors.black.withOpacity(0.25),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Decision',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  // Continue option
                  if (hasAvailableItems) ...[
                    _buildGlassRadioOption(
                      OrderStatus.inProgress,
                      'Continue with available items',
                      'Proceed with $availableCount available item${availableCount == 1 ? '' : 's'}',
                      Assets.imagesSvgsComplete,
                      widget.organization.primaryColorValue,
                    ),
                    SizedBox(height: 16),
                  ],

                  // Cancel option
                  _buildGlassRadioOption(
                    OrderStatus.cancelled,
                    'Cancel the entire order',
                    'Cancel due to unavailable items',
                    Assets.imagesSvgsCancell,
                    Colors.red,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassRadioOption(
    OrderStatus value,
    String title,
    String subtitle,
    String icon,
    Color color,
  ) {
    final isSelected = _selectedAction == value;

    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) => GestureDetector(
        onTap: () {
          setState(() {
            _selectedAction = value;
          });
        },
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isSelected
                  ? [color.withOpacity(0.4), color.withOpacity(0.2)]
                  : [
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.25),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? color.withOpacity(0.6)
                  : Colors.white.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          color.withOpacity(isSelected ? 0.4 : 0.3),
                          color.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: color.withOpacity(isSelected ? 0.7 : 0.5),
                        width: 1,
                      ),
                    ),
                    child: SvgPicture.asset(
                      icon,
                      color: isSelected ? Colors.white : color,
                      height: 20,
                      width: 20,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 0.3,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 3,
                                color: Colors.black.withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            letterSpacing: 0.2,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 2,
                                color: Colors.black.withOpacity(0.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [color, color.withOpacity(0.7)],
                            )
                          : null,
                      border: Border.all(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponseMessage() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 1200),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(150 * (1 - value), 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Message',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 3,
                    color: Colors.black.withOpacity(0.5),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.25),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: TextFormField(
                    controller: _responseController,
                    onTapOutside: (event) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    maxLines: 4,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 2,
                          color: Colors.black.withOpacity(0.3),
                        ),
                      ],
                    ),
                    decoration: InputDecoration(
                      hintText: _selectedAction == OrderStatus.inProgress
                          ? 'Any special instructions or notes...'
                          : 'Reason for cancellation...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SvgPicture.asset(
                          Assets.imagesSvgsMessage,
                          color: Colors.white,
                          height: 24,
                          width: 24,
                        ),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassBottomActions() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 1400),
      curve: Curves.elasticOut,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 100 * (1 - value)),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.4),
                Colors.black.withOpacity(0.3),
              ],
            ),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.4),
                            Colors.black.withOpacity(0.25),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _isLoading
                              ? null
                              : () => Navigator.pop(context),
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 3,
                                    color: Colors.black.withOpacity(0.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 16),

                  // Action Button
                  Expanded(
                    flex: 2,
                    child: AnimatedBuilder(
                      animation: _glowController,
                      builder: (context, child) {
                        final actionColor =
                            _selectedAction == OrderStatus.cancelled
                            ? Colors.red
                            : widget.organization.primaryColorValue;

                        return Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                actionColor,
                                actionColor.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: actionColor.withOpacity(
                                  0.4 + (_glowAnimation.value * 0.2),
                                ),
                                blurRadius: 15 + (_glowAnimation.value * 5),
                                spreadRadius: 1,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _isLoading ? null : _submitResponse,
                              child: Container(
                                alignment: Alignment.center,
                                child: _isLoading
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Submitting...',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              shadows: [
                                                Shadow(
                                                  offset: Offset(0, 1),
                                                  blurRadius: 3,
                                                  color: Colors.black
                                                      .withOpacity(0.5),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        _selectedAction == OrderStatus.cancelled
                                            ? 'Cancel Order'
                                            : 'Continue Order',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                          shadows: [
                                            Shadow(
                                              offset: Offset(0, 1),
                                              blurRadius: 3,
                                              color: Colors.black.withOpacity(
                                                0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Custom painter for animated particles background
class ParticlesPainter extends CustomPainter {
  final double animationValue;
  final Color primaryColor;
  final Color secondaryColor;

  ParticlesPainter(this.animationValue, this.primaryColor, this.secondaryColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw floating particles with reduced opacity for better readability
    for (int i = 0; i < 15; i++) {
      final progress = (animationValue + i * 0.1) % 1.0;
      final x =
          (i % 4) * size.width / 4 +
          math.sin(animationValue * 2 * math.pi + i) * 30;
      final y = size.height * progress;
      final opacity = math.sin(progress * math.pi) * 0.15; // Reduced from 0.3

      paint.color = (i % 2 == 0 ? primaryColor : secondaryColor).withOpacity(
        opacity,
      );

      final radius = 2 + math.sin(animationValue * 4 * math.pi + i) * 1;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Draw flowing waves with reduced opacity
    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5; // Reduced from 2

    for (int i = 0; i < 3; i++) {
      final path = Path();
      final waveHeight = 15 + i * 8; // Reduced wave height
      final waveLength = size.width / 4;
      final waveOffset = animationValue * 2 * math.pi;

      wavePaint.color = (i % 2 == 0 ? primaryColor : secondaryColor)
          .withOpacity(0.06); // Reduced from 0.1

      path.moveTo(0, size.height * 0.3 + i * size.height * 0.2);

      for (double x = 0; x <= size.width; x += 5) {
        final y =
            size.height * 0.3 +
            i * size.height * 0.2 +
            math.sin((x / waveLength + waveOffset + i) * 2 * math.pi) *
                waveHeight;
        path.lineTo(x, y);
      }

      canvas.drawPath(path, wavePaint);
    }

    // Draw gradient orbs with reduced opacity
    for (int i = 0; i < 3; i++) {
      // Reduced from 5
      final centerX = (i + 1) * size.width / 4;
      final centerY =
          size.height * 0.5 +
          math.sin(animationValue * 2 * math.pi + i * 1.2) *
              80; // Reduced movement
      final radius =
          30 + math.sin(animationValue * 3 * math.pi + i) * 15; // Reduced size

      final gradient = RadialGradient(
        colors: [
          (i % 2 == 0 ? primaryColor : secondaryColor).withOpacity(
            0.05,
          ), // Reduced from 0.1
          Colors.transparent,
        ],
      );

      final rect = Rect.fromCircle(
        center: Offset(centerX, centerY),
        radius: radius,
      );
      paint.shader = gradient.createShader(rect);
      canvas.drawCircle(Offset(centerX, centerY), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
