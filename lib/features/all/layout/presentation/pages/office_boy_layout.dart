import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:taqy/config/routes/routes.dart';
import 'package:taqy/core/services/firebase_service.dart';
import 'package:taqy/core/static/app_assets.dart';
import 'package:taqy/core/theme/colors.dart';
import 'package:taqy/core/utils/dialogs/error_toast.dart';
import 'package:taqy/core/utils/widgets/app_images.dart';
import 'package:taqy/features/all/auth/presentation/cubit/auth_cubit.dart';
import 'package:taqy/features/office_boy/data/models/office_order.dart';
import 'package:taqy/features/office_boy/data/models/office_organization.dart';
import 'package:taqy/features/office_boy/data/models/office_user_model.dart';
import 'package:taqy/features/office_boy/presentation/widgets/office_profile.dart';
import 'package:taqy/features/office_boy/presentation/widgets/order_details.dart';

class OfficeBoyLayout extends StatefulWidget {
  const OfficeBoyLayout({super.key});

  @override
  State<OfficeBoyLayout> createState() => _OfficeBoyLayoutState();
}

class _OfficeBoyLayoutState extends State<OfficeBoyLayout>
    with TickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();

  OfficeUserModel? currentUser;
  OfficeOrganization? organization;
  List<OfficeOrder> myOrders = [];
  List<OfficeOrder> availableOrders = [];
  List<OfficeUserModel> otherOfficeBoys = [];
  bool isLoading = true;
  String? errorMessage;

  // Animation Controllers
  late AnimationController _backgroundController;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late AnimationController _shimmerController;

  // Animations
  late Animation<double> _backgroundGradient;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _shimmerAnimation;

  int _selectedIndex = 0;
  double _scrollOffset = 0.0;
  bool _isHeaderCollapsed = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initializeAnimations();
    _loadData();
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _backgroundGradient = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

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
    _scrollController.dispose();
    _backgroundController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      _slideController.reset();
      _fadeController.reset();
      _scaleController.reset();

      final user = _firebaseService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userDoc = await _firebaseService.getDocument('users', user.uid);
      if (!userDoc.exists) throw Exception('User data not found');

      setState(() {
        currentUser = OfficeUserModel.fromFirestore(userDoc);
      });

      final orgDoc = await _firebaseService.getDocument(
        'organizations',
        currentUser!.organizationId,
      );
      if (orgDoc.exists) {
        setState(() {
          organization = OfficeOrganization.fromFirestore(orgDoc);
        });

        ColorManager().updateColors(
          organization!.primaryColorValue,
          organization!.secondaryColorValue,
        );
      }

      await _loadOtherOfficeBoys();
      _loadOrders();

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

  Future<void> _loadOtherOfficeBoys() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('organizationId', isEqualTo: currentUser!.organizationId)
          .where('role', isEqualTo: 'officeBoy')
          .get();

      setState(() {
        otherOfficeBoys = snapshot.docs
            .where((doc) => doc.id != currentUser!.id)
            .map((doc) => OfficeUserModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      print('Error loading other office boys: $e');
    }
  }

  void _loadOrders() {
    FirebaseFirestore.instance
        .collection('orders')
        .where('organizationId', isEqualTo: currentUser!.organizationId)
        .snapshots()
        .listen(
          (snapshot) {
            if (mounted) {
              setState(() {
                final allOrders = snapshot.docs
                    .map((doc) => OfficeOrder.fromFirestore(doc))
                    .toList();

                myOrders =
                    allOrders
                        .where(
                          (order) =>
                              order.officeBoyId == currentUser!.id ||
                              (order.isSpecificallyAssigned &&
                                  order.specificallyAssignedOfficeBoyId ==
                                      currentUser!.id),
                        )
                        .toList()
                      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                availableOrders = allOrders.where((order) {
                  if (order.status != OrderStatus.pending) return false;
                  if (order.isSpecificallyAssigned) {
                    return order.specificallyAssignedOfficeBoyId ==
                            currentUser!.id &&
                        order.officeBoyId != currentUser!.id;
                  }
                  return order.officeBoyId != currentUser!.id;
                }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                isLoading = false;
              });
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                errorMessage = error.toString();
                isLoading = false;
              });
            }
          },
        );
  }

  Future<void> _acceptOrder(OfficeOrder order) async {
    try {
      if (order.isSpecificallyAssigned &&
          order.specificallyAssignedOfficeBoyId != currentUser!.id) {
        showErrorToast(
          context,
          'This order is specifically assigned to another office boy',
        );
        return;
      }

      final updatedOrder = order.copyWith(
        status: OrderStatus.inProgress,
        officeBoyId: currentUser!.id,
        officeBoyName: currentUser!.name,
      );

      await _firebaseService.updateDocument(
        'orders',
        order.id,
        updatedOrder.toFirestore(),
      );

      showSuccessToast(context, 'Order accepted successfully!');
    } catch (e) {
      showErrorToast(context, 'Failed to accept order: $e');
    }
  }

  Future<void> _rejectSpecificallyAssignedOrder(OfficeOrder order) async {
    try {
      final updatedOrder = order.copyWith(
        isSpecificallyAssigned: false,
        specificallyAssignedOfficeBoyId: null,
      );

      await _firebaseService.updateDocument(
        'orders',
        order.id,
        updatedOrder.toFirestore(),
      );

      showSuccessToast(context, 'Order rejected and made available for others');
    } catch (e) {
      showErrorToast(context, 'Failed to reject order: $e');
    }
  }

  Future<void> _transferOrder(
    OfficeOrder order,
    String newOfficeBoyId,
    String newOfficeBoyName,
  ) async {
    try {
      final updatedOrder = order.copyWith(
        isSpecificallyAssigned: true,
        specificallyAssignedOfficeBoyId: newOfficeBoyId,
        officeBoyId: '',
        officeBoyName: '',
      );

      await _firebaseService.updateDocument(
        'orders',
        order.id,
        updatedOrder.toFirestore(),
      );

      showSuccessToast(context, 'Order transferred to $newOfficeBoyName');
    } catch (e) {
      showErrorToast(context, 'Failed to transfer order: $e');
    }
  }

  void _showTransferDialog(OfficeOrder order) {
    if (otherOfficeBoys.isEmpty) {
      showErrorToast(context, 'No other office boys available for transfer');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Transfer Order'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: otherOfficeBoys.length,
            itemBuilder: (context, index) {
              final officeBoy = otherOfficeBoys[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      organization?.primaryColorValue ?? Colors.blue,
                  child: Text(
                    officeBoy.name[0].toUpperCase(),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(officeBoy.name),
                subtitle: Text(officeBoy.email),
                onTap: () {
                  Navigator.pop(context);
                  _showTransferConfirmation(order, officeBoy);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showTransferConfirmation(
    OfficeOrder order,
    OfficeUserModel newOfficeBoy,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Transfer Order?'),
        content: Text(
          'This order will be specifically assigned to ${newOfficeBoy.name}. They will need to accept it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _transferOrder(order, newOfficeBoy.id, newOfficeBoy.name);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Transfer'),
          ),
        ],
      ),
    );
  }

  void _showSpecificallyAssignedActions(OfficeOrder order) {
    if (order.isSpecificallyAssigned &&
        order.specificallyAssignedOfficeBoyId == currentUser!.id &&
        order.status == OrderStatus.pending) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Order Assignment'),
          content: Text(
            'This order was specifically assigned to you. Do you want to accept or reject it?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _rejectSpecificallyAssignedOrder(order);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Reject'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _acceptOrder(order);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('Accept'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _updateItemStatus(
    OfficeOrder order,
    int itemIndex,
    ItemStatus newStatus,
    String? notes,
  ) async {
    try {
      final updatedItems = List<OrderItem>.from(order.items);
      updatedItems[itemIndex] = updatedItems[itemIndex].copyWith(
        status: newStatus,
        notes: notes?.trim().isNotEmpty == true ? notes!.trim() : null,
      );

      final updateData = <String, dynamic>{
        'items': updatedItems.map((item) => item.toMap()).toList(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      final bool allItemsProcessed = updatedItems.every(
        (item) => item.status != ItemStatus.pending,
      );
      final bool hasUnavailableItems = updatedItems.any(
        (item) => item.status == ItemStatus.notAvailable,
      );

      if (allItemsProcessed &&
          hasUnavailableItems &&
          order.status == OrderStatus.inProgress) {
        updateData['status'] = OrderStatus.needsResponse
            .toString()
            .split('.')
            .last;
      }

      await _firebaseService.updateDocument('orders', order.id, updateData);
      showSuccessToast(context, 'Item status updated successfully');
    } catch (e) {
      showErrorToast(context, 'Failed to update item status: $e');
    }
  }

  Future<void> _updateOrderWithNotes(
    OfficeOrder order,
    OrderStatus status, {
    double? finalPrice,
    String? notes,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (status == OrderStatus.completed) {
        updateData['completedAt'] = Timestamp.fromDate(DateTime.now());
        if (finalPrice != null && order.type == OrderType.external) {
          updateData['final_price'] = finalPrice;
        }
      }

      if (notes != null && notes.isNotEmpty) {
        updateData['notes'] = notes;
      }

      await _firebaseService.updateDocument('orders', order.id, updateData);
      showSuccessToast(context, 'Order ${status.toString().split('.').last}!');
    } catch (e) {
      showErrorToast(context, 'Failed to update order: $e');
    }
  }

  void _showItemStatusDialog(OfficeOrder order, int itemIndex) {
    final item = order.items[itemIndex];
    final TextEditingController notesController = TextEditingController(
      text: item.notes ?? '',
    );
    ItemStatus selectedStatus = item.status;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Update Item Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Item: ${item.name}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('Status:'),
              SizedBox(height: 8),
              ...ItemStatus.values.map(
                (status) => RadioListTile<ItemStatus>(
                  title: Row(
                    children: [
                      Icon(
                        _getItemStatusIcon(status),
                        color: _getItemStatusColor(status),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(_getItemStatusText(status)),
                    ],
                  ),
                  value: status,
                  groupValue: selectedStatus,
                  onChanged: (value) {
                    setDialogState(() {
                      selectedStatus = value!;
                    });
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Add notes about availability...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _updateItemStatus(
                  order,
                  itemIndex,
                  selectedStatus,
                  notesController.text.trim(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _getItemStatusColor(selectedStatus),
              ),
              child: Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Color _getItemStatusColor(ItemStatus status) {
    switch (status) {
      case ItemStatus.pending:
        return Colors.orange;
      case ItemStatus.available:
        return Colors.green;
      case ItemStatus.notAvailable:
        return Colors.red;
    }
  }

  IconData _getItemStatusIcon(ItemStatus status) {
    switch (status) {
      case ItemStatus.pending:
        return Icons.hourglass_empty;
      case ItemStatus.available:
        return Icons.check_circle;
      case ItemStatus.notAvailable:
        return Icons.cancel;
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

  void _showStatusChangeDialog(OfficeOrder order, OrderStatus newStatus) {
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${newStatus.toString().split('.').last.toUpperCase()} Order',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to ${newStatus.toString().split('.').last} this order?',
            ),
            SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: 'Add notes (optional)',
                hintText:
                    'Reason for ${newStatus.toString().split('.').last}...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateOrderWithNotes(
                order,
                newStatus,
                notes: notesController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == OrderStatus.cancelled
                  ? Colors.red
                  : Colors.green,
            ),
            child: Text(
              newStatus.toString().split('.').last.toUpperCase(),
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog(OfficeOrder order) {
    final TextEditingController priceController = TextEditingController();
    final TextEditingController notesController = TextEditingController();

    if (order.price != null) {
      priceController.text = order.price!.toStringAsFixed(0);
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Complete Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mark this order as completed?'),
              SizedBox(height: 16),
              if (order.type == OrderType.external) ...[
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Final Price (EGP) *',
                    hintText: 'Enter the actual price',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                SizedBox(height: 12),
              ],
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: 'Completion notes (optional)',
                  hintText: 'Any additional details...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (order.type == OrderType.external &&
                    priceController.text.trim().isEmpty) {
                  showErrorToast(context, 'Please enter the final price');

                  return;
                }

                double? finalPrice;
                if (order.type == OrderType.external &&
                    priceController.text.trim().isNotEmpty) {
                  try {
                    finalPrice = double.parse(priceController.text.trim());
                  } catch (e) {
                    showErrorToast(context, 'Please enter a valid price');

                    return;
                  }
                }

                Navigator.pop(context);
                await _updateOrderWithNotes(
                  order,
                  OrderStatus.completed,
                  finalPrice: finalPrice,
                  notes: notesController.text.trim(),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text(
                'Complete Order',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatusActions(OfficeOrder order) {
    final bool canTransfer =
        order.status == OrderStatus.pending &&
        order.isSpecificallyAssigned &&
        order.specificallyAssignedOfficeBoyId == currentUser!.id;

    if (order.status == OrderStatus.completed ||
        order.status == OrderStatus.cancelled) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(top: 12),
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (canTransfer)
            Container(
              margin: EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showTransferDialog(order),
                  icon: Icon(Icons.swap_horiz, size: 16),
                  label: Text('Transfer to Another Office Boy'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          Row(
            children: [
              if (order.status == OrderStatus.pending) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _showStatusChangeDialog(order, OrderStatus.cancelled),
                    icon: Icon(Icons.cancel, size: 18),
                    label: Text('Cancel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[100],
                      foregroundColor: Colors.red[700],
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _showStatusChangeDialog(order, OrderStatus.inProgress),
                    icon: Icon(Icons.time_to_leave, size: 18),
                    label: Text('Accept & Start'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[100],
                      foregroundColor: Colors.blue[700],
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
              if (order.status == OrderStatus.inProgress) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _showStatusChangeDialog(order, OrderStatus.cancelled),
                    icon: Icon(Icons.cancel, size: 18),
                    label: Text('Cancel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[100],
                      foregroundColor: Colors.red[700],
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _showCompletionDialog(order),
                    icon: Icon(Icons.check_circle, size: 18),
                    label: Text('Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[100],
                      foregroundColor: Colors.green[700],
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showProfileBottomSheet() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return OfficeBoyProfileBottomSheet(
            user: currentUser!,
            organization: organization!,
            onLogout: () => _handleLogout(),
            onProfileUpdated: (updatedUser) {
              setState(() {
                currentUser = updatedUser;
              });
            },
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          var scaleAnimation = Tween<double>(
            begin: 0.9,
            end: 1.0,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

          var fadeAnimation = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

          return Stack(
            children: [
              FadeTransition(
                opacity: fadeAnimation,
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),
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

  void _showOrderDetailsBottomSheet(OfficeOrder order) {
    final bool canTransfer =
        order.status == OrderStatus.pending &&
        order.isSpecificallyAssigned &&
        order.specificallyAssignedOfficeBoyId == currentUser!.id;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderDetailsBottomSheet(
        order: order,
        organization: organization!,
        isOfficeBoy: true,
        onStatusUpdate: _updateOrderWithNotes,
        onTransferRequest: canTransfer
            ? () {
                Navigator.pop(context);
                _showTransferDialog(order);
              }
            : null,
      ),
    );
  }

  void _handleLogout() async {
    try {
      await context.read<AuthCubit>().signOut();
      if (mounted) {
        context.go(Routes.login);
      }
    } catch (e) {
      showErrorToast(context, 'Failed to logout: $e');
    }
  }

  Color _getOrderTypeColor(OrderType type) {
    switch (type) {
      case OrderType.internal:
        return organization?.secondaryColorValue ?? Colors.blue;
      case OrderType.external:
        return organization?.primaryColorValue ?? Colors.orange;
    }
  }

  Color _getOrderStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.inProgress:
        return Colors.blue;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.needsResponse:
        return Colors.purple;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildAnimatedHeader() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            organization?.primaryColorValue ?? AppColors.primary,
            organization?.secondaryColorValue ?? AppColors.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
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
                      onPressed: _showProfileBottomSheet,
                    ),
                  ),
                ),
              ),
            ),
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
                            child: organization?.logoUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Image.network(
                                      organization!.logoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Center(
                                                child: Icon(
                                                  Icons.delivery_dining,
                                                  color: Colors.white,
                                                  size: 40,
                                                ),
                                              ),
                                    ),
                                  )
                                : Center(
                                    child: Icon(
                                      Icons.delivery_dining,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 50.0, end: 0.0),
                        duration: Duration(milliseconds: 1000),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) => Transform.translate(
                          offset: Offset(0, value),
                          child: Text(
                            'Welcome, ${currentUser?.name ?? ''}',
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
      {'title': 'Available', 'icon': Assets.imagesSvgsPending},
      {'title': 'My Orders', 'icon': Assets.imagesSvgsOrder},
      {'title': 'Statistics', 'icon': Icons.analytics},
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

  Widget _buildItemManagementSection(OfficeOrder order) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: organization?.secondaryColorValue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: organization!.secondaryColorValue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.checklist,
                color: organization!.secondaryColorValue,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Item Availability Check',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...order.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getItemStatusColor(item.status).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        if (item.notes != null && item.notes!.isNotEmpty) ...[
                          SizedBox(height: 4),
                          Text(
                            item.notes!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getItemStatusColor(item.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getItemStatusIcon(item.status),
                          size: 14,
                          color: _getItemStatusColor(item.status),
                        ),
                        SizedBox(width: 4),
                        Text(
                          _getItemStatusText(item.status),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getItemStatusColor(item.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  InkWell(
                    onTap: () => _showItemStatusDialog(order, index),
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAnimatedEmptyState(String message, IconData icon) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 1000),
      curve: Curves.elasticOut,
      builder: (context, value, child) => Center(
        child: Column(
          children: [
            Lottie.asset(
              'assets/images/lottie/Package Delivery.json',
              fit: BoxFit.contain,
              repeat: true,
              animate: true,
            ),
          ],
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

    if (errorMessage != null || currentUser == null || organization == null) {
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
                  Text(errorMessage ?? 'Unknown error'),
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
        return _buildAvailableOrdersTab();
      case 1:
        return _buildMyOrdersTab();
      case 2:
        return _buildStatsTab();
      default:
        return _buildAvailableOrdersTab();
    }
  }

  Widget _buildAvailableOrdersTab() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Available',
                  availableOrders.length.toString(),
                  Assets.imagesSvgsPending,
                  organization!.primaryColorValue,
                  organization!.secondaryColorValue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'My Active',
                  myOrders
                      .where((o) => o.status != OrderStatus.completed)
                      .length
                      .toString(),
                  Assets.imagesSvgsCoffee,
                  organization!.primaryColorValue,
                  organization!.secondaryColorValue,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          if (availableOrders.isEmpty)
            _buildAnimatedEmptyState('No available orders', Icons.inbox)
          else
            ...availableOrders.asMap().entries.map(
              (entry) => _buildAvailableOrderCard(entry.value, entry.key),
            ),
        ],
      ),
    );
  }

  Widget _buildMyOrdersTab() {
    final todayMyOrders = myOrders
        .where(
          (o) =>
              o.createdAt.day == DateTime.now().day &&
              o.createdAt.month == DateTime.now().month &&
              o.createdAt.year == DateTime.now().year,
        )
        .toList();

    final todayBudgetPrice = todayMyOrders
        .where((o) => o.price != null)
        .fold<double>(0.0, (sum, o) => sum + o.price!);

    final todayFinalPrice = todayMyOrders
        .where((o) => o.finalPrice != null)
        .fold<double>(0.0, (sum, o) => sum + o.finalPrice!);

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[400]!, Colors.blue[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'EGP ${todayBudgetPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Today\'s Budget',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[400]!, Colors.green[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.monetization_on,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'EGP ${todayFinalPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Today\'s Spent',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'In Progress',
                  myOrders
                      .where((o) => o.status == OrderStatus.inProgress)
                      .length
                      .toString(),
                  Assets.imagesSvgsPending,
                  organization!.primaryColorValue,
                  organization!.secondaryColorValue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Completed',
                  myOrders
                      .where((o) => o.status == OrderStatus.completed)
                      .length
                      .toString(),
                  Assets.imagesSvgsComplete,
                  organization!.primaryColorValue,
                  organization!.secondaryColorValue,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Text(
            'My Orders',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 16),
          if (myOrders.isEmpty)
            _buildAnimatedEmptyState('No orders assigned', Icons.assignment)
          else
            ...myOrders.asMap().entries.map(
              (entry) => Column(
                children: [
                  _buildMyOrderCard(entry.value, entry.key),
                  if (entry.value.status == OrderStatus.inProgress)
                    _buildItemManagementSection(entry.value),
                  _buildQuickStatusActions(entry.value),
                  SizedBox(height: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    final totalOrders = myOrders.length;
    final completedOrders = myOrders
        .where((o) => o.status == OrderStatus.completed)
        .length;
    final inProgressOrders = myOrders
        .where((o) => o.status == OrderStatus.inProgress)
        .length;
    final cancelledOrders = myOrders
        .where((o) => o.status == OrderStatus.cancelled)
        .length;
    final needsResponseOrders = myOrders
        .where((o) => o.status == OrderStatus.needsResponse)
        .length;

    final todayOrders = myOrders
        .where(
          (o) =>
              o.createdAt.day == DateTime.now().day &&
              o.createdAt.month == DateTime.now().month &&
              o.createdAt.year == DateTime.now().year,
        )
        .toList();

    final todayBudgetPrice = todayOrders
        .where((o) => o.price != null)
        .fold<double>(0.0, (sum, o) => sum + o.price!);

    final todayFinalPrice = todayOrders
        .where((o) => o.finalPrice != null)
        .fold<double>(0.0, (sum, o) => sum + o.finalPrice!);

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Statistics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[400]!, Colors.blue[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'EGP ${todayBudgetPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Today\'s Budget',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[400]!, Colors.green[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.monetization_on,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'EGP ${todayFinalPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Today\'s Spent',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(
                'Total Orders',
                totalOrders.toString(),
                Assets.imagesSvgsOrder,
                organization!.primaryColorValue,
                organization!.secondaryColorValue,
              ),
              _buildStatCard(
                'Today\'s Orders',
                todayOrders.length.toString(),
                Assets.imagesSvgsCalendar,
                organization!.primaryColorValue,
                organization!.secondaryColorValue,
              ),
              _buildStatCard(
                'Completed',
                completedOrders.toString(),
                Assets.imagesSvgsComplete,
                organization!.primaryColorValue,
                organization!.secondaryColorValue,
              ),
              _buildStatCard(
                'In Progress',
                inProgressOrders.toString(),
                Assets.imagesSvgsPending,
                organization!.primaryColorValue,
                organization!.secondaryColorValue,
              ),
              _buildStatCard(
                'Needs Response',
                needsResponseOrders.toString(),
                Assets.imagesSvgsNote,
                organization!.primaryColorValue,
                organization!.secondaryColorValue,
              ),
              _buildStatCard(
                'Cancelled',
                cancelledOrders.toString(),
                Assets.imagesSvgsCancell,
                organization!.primaryColorValue,
                organization!.secondaryColorValue,
              ),
            ],
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAvailableOrderCard(OfficeOrder order, int index) {
    final isSpecificallyAssignedToMe =
        order.isSpecificallyAssigned &&
        order.specificallyAssignedOfficeBoyId == currentUser!.id;

    final isSpecificallyAssignedToOther =
        order.isSpecificallyAssigned &&
        order.specificallyAssignedOfficeBoyId != currentUser!.id;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(50 * (1 - value), 0),
        child: Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: isSpecificallyAssignedToMe
                ? Border.all(color: Colors.orange, width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
            image: DecorationImage(
              image: AssetImage(AppImages.homePattern),
              fit: BoxFit.fill,
              colorFilter: ColorFilter.mode(
                organization!.secondaryColorValue.withOpacity(.5),
                BlendMode.modulate,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSpecificallyAssignedToMe)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 12, color: Colors.orange),
                      SizedBox(width: 4),
                      Text(
                        'Assigned to you',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              if (!isSpecificallyAssignedToOther) ...[
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getOrderTypeColor(order.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        order.type == OrderType.internal
                            ? 'Internal'
                            : 'External',
                        style: TextStyle(
                          color: _getOrderTypeColor(order.type),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (order.items.length > 1) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${order.items.length} items',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    Spacer(),
                    Text(
                      _formatTime(order.createdAt),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: _getOrderTypeColor(order.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: SvgPicture.asset(
                        order.type == OrderType.internal
                            ? Assets.imagesSvgsCompany
                            : Assets.imagesSvgsShoppingCart,
                        color: _getOrderTypeColor(order.type),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.items.length == 1
                                ? order.items.first.name
                                : '${order.items.first.name} + ${order.items.length - 1} more',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (order.description.isNotEmpty)
                            Text(
                              order.description,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 4),
                              Text(
                                order.employeeName,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              if (order.price != null) ...[
                                Spacer(),
                                Text(
                                  'EGP ${order.price!.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSpecificallyAssignedToMe
                        ? () => _showSpecificallyAssignedActions(order)
                        : () => _acceptOrder(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: organization!.primaryColorValue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.all(12),
                    ),
                    child: Text(
                      isSpecificallyAssignedToMe
                          ? 'Accept Assignment'
                          : 'Accept Order',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ] else
                Center(
                  child: Text(
                    'This order is specifically assigned to another office boy',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyOrderCard(OfficeOrder order, int index) {
    final bool canTransfer =
        order.status == OrderStatus.pending &&
        order.isSpecificallyAssigned &&
        order.specificallyAssignedOfficeBoyId == currentUser!.id;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(50 * (1 - value), 0),
        child: GestureDetector(
          onTap: () => _showOrderDetailsBottomSheet(order),
          child: Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: canTransfer
                  ? Border.all(color: Colors.orange.withOpacity(0.5), width: 1)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
              image: DecorationImage(
                image: AssetImage(AppImages.homePattern),
                fit: BoxFit.fill,
                colorFilter: ColorFilter.mode(
                  organization!.secondaryColorValue.withOpacity(.5),
                  BlendMode.modulate,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getOrderStatusColor(
                          order.status,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        order.status.toString().split('.').last.toUpperCase(),
                        style: TextStyle(
                          color: _getOrderStatusColor(order.status),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getOrderTypeColor(order.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        order.type == OrderType.internal
                            ? 'Internal'
                            : 'External',
                        style: TextStyle(
                          color: _getOrderTypeColor(order.type),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (canTransfer) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.swap_horiz,
                              size: 12,
                              color: Colors.orange,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Can Transfer',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Spacer(),
                    Text(
                      _formatTime(order.createdAt),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: _getOrderStatusColor(
                          order.status,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: SvgPicture.asset(
                        order.status == OrderStatus.completed
                            ? Assets.imagesSvgsComplete
                            : order.status == OrderStatus.needsResponse
                            ? Assets.imagesSvgsNote
                            : order.type == OrderType.internal
                            ? Assets.imagesSvgsCompany
                            : Assets.imagesSvgsShoppingCart,
                        color: _getOrderStatusColor(order.status),

                        fit: BoxFit.scaleDown,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.items.length == 1
                                ? order.items.first.name
                                : '${order.items.first.name} + ${order.items.length - 1} more',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (order.description.isNotEmpty)
                            Text(
                              order.description,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 4),
                              Text(
                                order.employeeName,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              if (order.price != null ||
                                  order.finalPrice != null) ...[
                                Spacer(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (order.price != null)
                                      Text(
                                        'Budget: EGP ${order.price!.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontSize: 11,
                                        ),
                                      ),
                                    if (order.finalPrice != null)
                                      Text(
                                        'Spent: EGP ${order.finalPrice!.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String icon,
    Color color,
    Color textColor,
  ) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) => Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius:
                  8 + (math.sin(_pulseController.value * 2 * math.pi) * 2),
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
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Transform.rotate(
                    angle: math.sin(_pulseController.value * 2 * math.pi) * 0.1,
                    child: SvgPicture.asset(icon, color: color, height: 20),
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
    );
  }
}

// Particle Painter
class AnimatedParticlesPainter extends CustomPainter {
  final double animationValue;
  final double rotationValue;

  AnimatedParticlesPainter(this.animationValue, this.rotationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

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

// Shimmer Loading
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
