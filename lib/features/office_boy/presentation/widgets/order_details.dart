import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:taqy/core/utils/dialogs/error_toast.dart';
import 'package:taqy/core/utils/widgets/app_images.dart';
import 'package:taqy/features/office_boy/data/models/office_order.dart';
import 'package:taqy/features/office_boy/data/models/office_organization.dart';

class OrderDetailsBottomSheet extends StatefulWidget {
  final OfficeOrder order;
  final OfficeOrganization organization;
  final bool isOfficeBoy;
  final Function(OfficeOrder, OrderStatus, {double? finalPrice, String? notes})
  onStatusUpdate;
  final Function(OfficeOrder, int, ItemStatus, String?)? onItemStatusUpdate;
  final VoidCallback? onTransferRequest;

  const OrderDetailsBottomSheet({
    super.key,
    required this.order,
    required this.organization,
    required this.isOfficeBoy,
    required this.onStatusUpdate,
    this.onItemStatusUpdate,
    this.onTransferRequest,
  });

  @override
  State<OrderDetailsBottomSheet> createState() =>
      _OrderDetailsBottomSheetState();
}

class _OrderDetailsBottomSheetState extends State<OrderDetailsBottomSheet>
    with TickerProviderStateMixin {
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.order.price != null) {
      _priceController.text = widget.order.price!.toStringAsFixed(0);
    }
    if (widget.order.finalPrice != null) {
      _priceController.text = widget.order.finalPrice!.toStringAsFixed(0);
    }
    if (widget.order.notes != null) {
      _notesController.text = widget.order.notes!;
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _particleAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    _notesController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
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

  String _getItemStatusIcon(ItemStatus status) {
    switch (status) {
      case ItemStatus.pending:
        return Assets.imagesSvgsCalendar;
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _updateStatus(OrderStatus status) async {
    if (status == OrderStatus.completed &&
        widget.order.type == OrderType.external &&
        _priceController.text.trim().isEmpty) {
      showErrorToast(
        context,
        'Please enter the final price for external orders',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      double? finalPrice;
      if (status == OrderStatus.completed &&
          widget.order.type == OrderType.external &&
          _priceController.text.trim().isNotEmpty) {
        finalPrice = double.parse(_priceController.text.trim());
      }

      await widget.onStatusUpdate(
        widget.order,
        status,
        finalPrice: finalPrice,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      Navigator.pop(context);
    } catch (e) {
      showErrorToast(context, 'Failed to update order status: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool get _canTransfer {
    return widget.isOfficeBoy &&
        widget.order.status == OrderStatus.pending &&
        widget.order.isSpecificallyAssigned &&
        widget.onTransferRequest != null;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Material(
      color: Colors.transparent,
      child: Container(
        height: screenHeight,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Stack(
          children: [
            // Animated background
            Positioned.fill(child: _buildAnimatedBackground()),

            // Main content with glass morphism
            Positioned.fill(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.15),
                          Colors.white.withOpacity(0.08),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 1.5,
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
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              widget.organization.primaryColorValue.withOpacity(0.12),
              widget.organization.secondaryColorValue.withOpacity(0.08),
              Colors.transparent,
            ],
            stops: const [0.1, 0.5, 1.0],
          ),
        ),
        child: CustomPaint(
          painter: _ParticlesPainter(
            _particleAnimation.value,
            widget.organization.primaryColorValue,
            widget.organization.secondaryColorValue,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildOrderInfoCard(),
                const SizedBox(height: 20),
                _buildItemsList(),
                const SizedBox(height: 20),
                _buildOrderInformation(),
                const SizedBox(height: 20),
                if (widget.order.type == OrderType.external)
                  _buildPriceSection(),
                const SizedBox(height: 20),
                _buildNotesSection(),
                const SizedBox(height: 20),
                _buildActionButtons(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) => Container(
                  width: 60,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(
                          _glowAnimation.value * 0.3,
                        ),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Order Details',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) => Transform.scale(
                        scale: value,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: AnimatedBuilder(
                            animation: _glowController,
                            builder: (context, child) => Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withOpacity(
                                      0.2 + (_glowAnimation.value * 0.1),
                                    ),
                                    Colors.white.withOpacity(0.1),
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
                              child: SvgPicture.asset(
                                Assets.imagesSvgsClose,
                                color: Colors.white.withOpacity(0.9),
                                width: 20,
                                height: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.organization.primaryColorValue,
            widget.organization.secondaryColorValue,
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: widget.organization.primaryColorValue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) => Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SvgPicture.asset(
                      widget.order.type == OrderType.internal
                          ? Assets.imagesSvgsCompany
                          : Assets.imagesSvgsShoppingCart,
                      color: Colors.white,
                      height: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.order.items.length == 1
                          ? widget.order.items.first.name
                          : '${widget.order.items.length} Items Order',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            widget.order.type == OrderType.internal
                                ? 'Internal'
                                : 'External',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            // gradient: LinearGradient(
                            //   colors: [
                            //     _getOrderStatusColor(
                            //       widget.order.status,
                            //     ).withOpacity(0.3),
                            //     _getOrderStatusColor(
                            //       widget.order.status,
                            //     ).withOpacity(0.2),
                            //   ],
                            // ),
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getOrderStatusColor(widget.order.status),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            widget.order.status
                                .toString()
                                .split('.')
                                .last
                                .toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (widget.order.isSpecificallyAssigned)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                                const Text(
                                  'Assigned',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.order.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Text(
                widget.order.description,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.08),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                Assets.imagesSvgsOrder,
                color: Colors.white.withOpacity(0.9),
                height: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Order Items',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.order.items.length} ${widget.order.items.length == 1 ? 'Item' : 'Items'}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...widget.order.items.map((item) => _buildOrderItem(item)),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getItemStatusColor(item.status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) => Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getItemStatusColor(item.status),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getItemStatusColor(
                          item.status,
                        ).withOpacity(_pulseAnimation.value * 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    color: item.status == ItemStatus.notAvailable
                        ? Colors.white.withOpacity(0.5)
                        : Colors.white.withOpacity(0.95),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    decoration: item.status == ItemStatus.notAvailable
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _getItemStatusColor(item.status).withOpacity(0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      _getItemStatusIcon(item.status),
                      height: 12,
                      color: _getItemStatusColor(item.status),
                    ),
                    const SizedBox(width: 4),
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
            ],
          ),
          if (item.notes != null && item.notes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    Assets.imagesSvgsNote,
                    height: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.notes!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderInformation() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.08),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                Assets.imagesSvgsOrder,
                color: Colors.white.withOpacity(0.9),
                height: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Order Information',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.person_rounded,
            'Employee',
            widget.order.employeeName,
          ),
          if (widget.order.officeBoyName.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.delivery_dining_rounded,
              'Office Boy',
              widget.order.officeBoyName,
            ),
          ],
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.schedule_rounded,
            'Created',
            _formatDateTime(widget.order.createdAt),
          ),
          if (widget.order.completedAt != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.checklist_rounded,
              'Completed',
              _formatDateTime(widget.order.completedAt!),
            ),
          ],
          if (widget.order.isSpecificallyAssigned) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.star_rounded,
              'Assignment',
              'Specifically Assigned',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: label == 'Completed'
              ? SvgPicture.asset(
                  Assets.imagesSvgsComplete,
                  color: Colors.white.withOpacity(0.9),
                  height: 18,
                )
              : Icon(icon, color: Colors.white.withOpacity(0.9), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.95),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.25),
            Colors.green.withOpacity(0.15),
          ],
        ),
        border: Border.all(color: Colors.green.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_money_rounded,
                color: Colors.greenAccent,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Price Information',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.order.price != null)
            _buildPriceRow('Budget Price', widget.order.price!, Colors.blue),
          if (widget.order.finalPrice != null) ...[
            const SizedBox(height: 12),
            _buildPriceRow(
              'Final Price',
              widget.order.finalPrice!,
              Colors.greenAccent,
            ),
          ],
          if (widget.isOfficeBoy &&
              widget.order.status == OrderStatus.inProgress &&
              widget.order.type == OrderType.external) ...[
            const SizedBox(height: 16),
            Text(
              'Enter Final Price:',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter actual spent amount',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 14,
                  ),
                  prefixText: 'EGP ',
                  prefixStyle: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ],
          if (widget.order.price != null &&
              widget.order.finalPrice != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.order.finalPrice! <= widget.order.price!
                      ? [
                          Colors.green.withOpacity(0.2),
                          Colors.green.withOpacity(0.1),
                        ]
                      : [
                          Colors.red.withOpacity(0.2),
                          Colors.red.withOpacity(0.1),
                        ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.order.finalPrice! <= widget.order.price!
                      ? Colors.greenAccent.withOpacity(0.4)
                      : Colors.redAccent.withOpacity(0.4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Difference:',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${widget.order.finalPrice! > widget.order.price! ? '+' : ''}${(widget.order.finalPrice! - widget.order.price!).toStringAsFixed(0)} EGP',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: widget.order.finalPrice! <= widget.order.price!
                          ? Colors.greenAccent
                          : Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          'EGP ${amount.toStringAsFixed(0)}',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    if (widget.isOfficeBoy && widget.order.status == OrderStatus.inProgress) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.12),
              Colors.white.withOpacity(0.08),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  Assets.imagesSvgsNote,
                  color: Colors.white.withOpacity(0.9),
                  height: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Add Notes (Optional)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: TextField(
                controller: _notesController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Add any additional notes...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                maxLines: 3,
              ),
            ),
          ],
        ),
      );
    } else if (widget.order.notes != null && widget.order.notes!.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.12),
              Colors.white.withOpacity(0.08),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  Assets.imagesSvgsNote,
                  color: Colors.white.withOpacity(0.9),
                  height: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Notes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Text(
                widget.order.notes!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildActionButtons() {
    if (_canTransfer) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: widget.onTransferRequest,
          icon: const Icon(Icons.swap_horiz_rounded, size: 20),
          label: const Text(
            'Transfer to Another Office Boy',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            shadowColor: Colors.orange.withOpacity(0.4),
          ),
        ),
      );
    }

    if (widget.isOfficeBoy && widget.order.status == OrderStatus.inProgress) {
      return Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () => _updateStatus(OrderStatus.cancelled),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () => _updateStatus(OrderStatus.completed),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Mark as Completed',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ),
        ],
      );
    }

    if (widget.isOfficeBoy &&
        widget.order.status == OrderStatus.pending &&
        widget.order.isSpecificallyAssigned) {
      return Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.red.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () => _updateStatus(OrderStatus.cancelled),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Reject',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () => _updateStatus(OrderStatus.inProgress),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Accept Assignment',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

class _ParticlesPainter extends CustomPainter {
  final double animationValue;
  final Color primaryColor;
  final Color secondaryColor;

  _ParticlesPainter(
    this.animationValue,
    this.primaryColor,
    this.secondaryColor,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 1;

    final particleCount = 15;
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < particleCount; i++) {
      final angle = 2 * math.pi * i / particleCount + animationValue;
      final distance = 50 + 30 * math.sin(animationValue + i);
      final x = center.dx + distance * math.cos(angle);
      final y = center.dy + distance * math.sin(angle);
      final radius = 1 + math.sin(animationValue + i) * 0.5;

      final color = i % 2 == 0 ? primaryColor : secondaryColor;
      paint.color = color.withOpacity(
        0.08 + math.sin(animationValue + i) * 0.04,
      );

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}
