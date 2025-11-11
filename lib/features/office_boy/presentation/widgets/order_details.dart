import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:taqy/core/utils/dialogs/error_toast.dart';
import 'package:taqy/core/utils/widgets/app_images.dart';
import 'package:taqy/features/office_boy/data/models/office_order.dart';
import 'package:taqy/features/office_boy/data/models/office_organization.dart';
import 'package:taqy/features/office_boy/data/models/office_user_model.dart';

class OrderDetailsBottomSheet extends StatefulWidget {
  final OfficeOrder order;
  final OfficeOrganization organization;
  final bool isOfficeBoy;
  final Function(OfficeOrder, OrderStatus, {double? finalPrice, String? notes})
  onStatusUpdate;
  final Function(OfficeOrder, int, ItemStatus, String?)? onItemStatusUpdate;
  final VoidCallback? onTransferRequest;
  final List<OfficeUserModel>? otherOfficeBoys;

  const OrderDetailsBottomSheet({
    super.key,
    required this.order,
    required this.organization,
    required this.isOfficeBoy,
    required this.onStatusUpdate,
    this.onItemStatusUpdate,
    this.onTransferRequest,
    this.otherOfficeBoys,
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

  String _getItemStatusText(ItemStatus status, String locale) {
    switch (status) {
      case ItemStatus.pending:
        return locale == 'ar' ? 'جارى التحقق...' : 'Checking...';
      case ItemStatus.available:
        return locale == 'ar' ? 'متاح' : 'Available';
      case ItemStatus.notAvailable:
        return locale == 'ar' ? 'غير متاح' : 'Not Available';
    }
  }

  String _formatDateTime(DateTime dateTime, String locale) {
    final day = dateTime.day;
    final month = dateTime.month;
    final year = dateTime.year;
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');

    if (locale == 'ar') {
      return '$day/$month/$year الساعة $hour:$minute';
    } else {
      return '$day/$month/$year at $hour:$minute';
    }
  }

  Future<void> _updateStatus(OrderStatus status, String locale) async {
    if (status == OrderStatus.completed &&
        widget.order.type == OrderType.external &&
        _priceController.text.trim().isEmpty) {
      showErrorToast(
        context,
        locale == 'ar'
            ? 'يرجى ادخال السعر النهائي للطلبات الخارجية'
            : 'Please enter the final price for external orders',
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
      showErrorToast(
        context,
        locale == 'ar'
            ? 'فشل تحديث حالة الطلب: $e'
            : 'Failed to update order status: $e',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool get _canTransfer {
    return widget.isOfficeBoy &&
        widget.order.status == OrderStatus.pending &&
        widget.order.isSpecificallyAssigned &&
        widget.onTransferRequest != null &&
        widget.otherOfficeBoys != null &&
        widget.otherOfficeBoys!.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
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
                    child: _buildContent(locale),
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

  Widget _buildContent(String locale) {
    return Column(
      children: [
        _buildHeader(locale),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildOrderInfoCard(locale),
                const SizedBox(height: 20),
                _buildItemsList(locale),
                const SizedBox(height: 20),
                _buildOrderInformation(locale),
                const SizedBox(height: 20),
                if (widget.order.type == OrderType.external)
                  _buildPriceSection(locale),
                const SizedBox(height: 20),
                _buildNotesSection(locale),
                const SizedBox(height: 20),
                _buildActionButtons(locale),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String locale) {
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
                        locale == 'ar' ? 'تفاصيل الطلب' : 'Order Details',
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

  Widget _buildOrderInfoCard(String locale) {
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
                          : locale == 'ar'
                          ? '${widget.order.items.length} عناصر'
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
                                ? locale == 'ar'
                                      ? 'داخلي'
                                      : 'Internal'
                                : locale == 'ar'
                                ? 'خارجي'
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
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getOrderStatusColor(widget.order.status),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            _getOrderStatusText(widget.order.status, locale),
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
                                Text(
                                  locale == 'ar' ? 'مخصص' : 'Assigned',
                                  style: const TextStyle(
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

  String _getOrderStatusText(OrderStatus status, String locale) {
    switch (status) {
      case OrderStatus.pending:
        return locale == 'ar' ? 'قيد الانتظار' : 'PENDING';
      case OrderStatus.inProgress:
        return locale == 'ar' ? 'قيد التنفيذ' : 'IN PROGRESS';
      case OrderStatus.completed:
        return locale == 'ar' ? 'مكتمل' : 'COMPLETED';
      case OrderStatus.cancelled:
        return locale == 'ar' ? 'ملغي' : 'CANCELLED';
      case OrderStatus.needsResponse:
        return locale == 'ar' ? 'يحتاج رد' : 'NEEDS RESPONSE';
    }
  }

  Widget _buildItemsList(String locale) {
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
                locale == 'ar' ? 'عناصر الطلب' : 'Order Items',
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
                  '${widget.order.items.length} ${widget.order.items.length == 1 ? (locale == 'ar' ? 'عنصر' : 'Item') : (locale == 'ar' ? 'عناصر' : 'Items')}',
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
          ...widget.order.items.map((item) => _buildOrderItem(item, locale)),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item, String locale) {
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
                    border: Border.all(color: Colors.black.withOpacity(.2)),
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
                      _getItemStatusText(item.status, locale),
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

  Widget _buildOrderInformation(String locale) {
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
                locale == 'ar' ? 'معلومات الطلب' : 'Order Information',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          widget.order.isFromAdmin
              ? _buildInfoRow(
                  Icons.admin_panel_settings,
                  locale == 'ar' ? 'المدير' : 'Admin',
                  widget.order.employeeName,
                  locale,
                )
              : _buildInfoRow(
                  Icons.person_rounded,
                  locale == 'ar' ? 'الموظف' : 'Employee',
                  widget.order.employeeName,
                  locale,
                ),
          if (widget.order.officeBoyName.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.delivery_dining_rounded,
              locale == 'ar' ? 'العامل' : 'Office Boy',
              widget.order.officeBoyName,
              locale,
            ),
          ],
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.schedule_rounded,
            locale == 'ar' ? 'تاريخ الإنشاء' : 'Created',
            _formatDateTime(widget.order.createdAt, locale),
            locale,
          ),
          if (widget.order.completedAt != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.checklist_rounded,
              locale == 'ar' ? 'تاريخ الإكمال' : 'Completed',
              _formatDateTime(widget.order.completedAt!, locale),
              locale,
            ),
          ],
          if (widget.order.isSpecificallyAssigned) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.star_rounded,
              locale == 'ar' ? 'التكليف' : 'Assignment',
              locale == 'ar' ? 'مكلف بشكل خاص' : 'Specifically Assigned',
              locale,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    String locale,
  ) {
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
          child: label == (locale == 'ar' ? 'تاريخ الإكمال' : 'Completed')
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

  Widget _buildPriceSection(String locale) {
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
                locale == 'ar' ? 'معلومات السعر' : 'Price Information',
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
            _buildPriceRow(
              locale == 'ar' ? 'السعر المتوقع' : 'Budget Price',
              widget.order.price!,
              Colors.white,
              locale,
            ),
          if (widget.order.finalPrice != null) ...[
            const SizedBox(height: 12),
            _buildPriceRow(
              locale == 'ar' ? 'السعر النهائي' : 'Final Price',
              widget.order.finalPrice!,
              Colors.greenAccent,
              locale,
            ),
          ],
          if (widget.isOfficeBoy &&
              widget.order.status == OrderStatus.inProgress &&
              widget.order.type == OrderType.external) ...[
            const SizedBox(height: 16),
            Text(
              locale == 'ar' ? 'ادخل السعر النهائي:' : 'Enter Final Price:',
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
                  hintText: locale == 'ar'
                      ? 'ادخل المبلغ الفعلي الذي تم صرفه'
                      : 'Enter actual spent amount',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 14,
                  ),
                  prefixText: locale == 'ar' ? 'ج.م ' : 'EGP ',
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
                    locale == 'ar' ? 'الفرق:' : 'Difference:',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${widget.order.finalPrice! > widget.order.price! ? '+' : ''}${(widget.order.finalPrice! - widget.order.price!).toStringAsFixed(0)} ${locale == 'ar' ? 'ج.م' : 'EGP'}',
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

  Widget _buildPriceRow(
    String label,
    double amount,
    Color color,
    String locale,
  ) {
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
          '${locale == 'ar' ? 'ج.م' : 'EGP'} ${amount.toStringAsFixed(0)}',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection(String locale) {
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
                  locale == 'ar'
                      ? 'اضافة ملاحظات (اختياري)'
                      : 'Add Notes (Optional)',
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
                  hintText: locale == 'ar'
                      ? 'اضف اي ملاحظات اضافية...'
                      : 'Add any additional notes...',
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
                  locale == 'ar' ? 'ملاحظات' : 'Notes',
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

  Widget _buildActionButtons(String locale) {
    if (_canTransfer) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: widget.onTransferRequest,
          icon: const Icon(Icons.swap_horiz_rounded, size: 20),
          label: Text(
            locale == 'ar'
                ? 'تحويل الى عامل آخر'
                : 'Transfer to Another Office Boy',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
                    : () => _updateStatus(OrderStatus.cancelled, locale),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  locale == 'ar' ? 'الغاء' : 'Cancel',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
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
                    : () => _updateStatus(OrderStatus.completed, locale),
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
                    : Text(
                        locale == 'ar' ? 'تحديد كمكتمل' : 'Mark as Completed',
                        style: const TextStyle(
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
                    : () => _updateStatus(OrderStatus.cancelled, locale),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  locale == 'ar' ? 'رفض' : 'Reject',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
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
                    : () => _updateStatus(OrderStatus.inProgress, locale),
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
                    : Text(
                        locale == 'ar' ? 'قبول التكليف' : 'Accept Assignment',
                        style: const TextStyle(
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
