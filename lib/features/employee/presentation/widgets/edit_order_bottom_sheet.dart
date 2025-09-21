import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taqy/core/utils/dialogs/error_toast.dart';
import 'package:taqy/core/utils/widgets/app_images.dart';
import 'package:taqy/features/employee/data/models/order_model.dart';
import 'package:taqy/features/employee/data/models/organization_model.dart';
import 'package:taqy/features/employee/data/models/user_model.dart';

class EditOrderBottomSheet extends StatefulWidget {
  final EmployeeOrder order;
  final EmployeeOrganization organization;
  final List<EmployeeUserModel> officeBoys;
  final Function(EmployeeOrder) onOrderUpdated;
  final Function(String) onOrderDeleted;

  const EditOrderBottomSheet({
    super.key,
    required this.order,
    required this.organization,
    required this.officeBoys,
    required this.onOrderUpdated,
    required this.onOrderDeleted,
  });

  @override
  State<EditOrderBottomSheet> createState() => _EditOrderBottomSheetState();
}

class _EditOrderBottomSheetState extends State<EditOrderBottomSheet>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _itemController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  late OrderType _selectedType;
  EmployeeUserModel? _selectedOfficeBoy;
  bool _isSubmitting = false;
  bool _isDeleting = false;

  final List<String> _selectedItems = [];

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
  // late Animation<double> _shimmerAnimation;

  // Predefined items
  final Map<OrderType, List<String>> _predefinedItems = {
    OrderType.internal: ['Tea', 'Coffee', 'Water', 'Other'],
    OrderType.external: ['Breakfast', 'Lunch', 'Drinks', 'Other'],
  };

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeForm() {
    // Initialize existing order items
    if (widget.order.items.isNotEmpty) {
      _selectedItems.addAll(widget.order.items.map((item) => item.name));
    } else if (widget.order.item.isNotEmpty) {
      // For backward compatibility with single item orders
      _selectedItems.add(widget.order.item);
    }

    _descriptionController.text = widget.order.description;
    _priceController.text = widget.order.price?.toString() ?? '';
    _notesController.text = widget.order.notes ?? '';
    _selectedType = widget.order.type;
    _selectedOfficeBoy = widget.officeBoys.firstWhere(
      (officeBoy) => officeBoy.id == widget.order.officeBoyId,
      // orElse: () => widget.officeBoys.isNotEmpty ? widget.officeBoys.first : null,
    );
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
    // _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
    //   CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    // );
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
    _itemController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _addCustomItem() {
    final itemName = _itemController.text.trim();
    if (itemName.isNotEmpty && !_selectedItems.contains(itemName)) {
      setState(() {
        _selectedItems.add(itemName);
        _itemController.clear();
      });
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

                  // Glass morphism container
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.25),
                                Colors.white.withOpacity(0.1),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(32),
                              topRight: Radius.circular(32),
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Form(key: _formKey, child: _buildContent()),
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
              widget.organization.primaryColorValue.withOpacity(0.1),
              widget.organization.secondaryColorValue.withOpacity(0.1),
              widget.organization.primaryColorValue.withOpacity(0.05),
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
                _buildOrderTypeSelection(),
                SizedBox(height: 24),
                _buildItemSelection(),
                SizedBox(height: 24),
                _buildSelectedItemsDisplay(),
                SizedBox(height: 24),
                _buildPredefinedItems(),
                SizedBox(height: 24),
                _buildGlassTextField(
                  controller: _descriptionController,
                  label: 'Description (Optional)',
                  hint: 'Any specific details or preferences...',
                  icon: Assets.imagesSvgsOrder,
                  delay: 200,
                  maxLines: 3,
                ),
                if (_selectedType == OrderType.external) ...[
                  SizedBox(height: 24),
                  _buildGlassTextField(
                    controller: _priceController,
                    label: 'Estimated Price (EGP)',
                    hint: 'Enter estimated price',
                    icon: Assets.imagesSvgsMoney,
                    delay: 300,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (_selectedType == OrderType.external &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Please enter estimated price for external orders';
                      }
                      if (value != null && value.isNotEmpty) {
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return 'Please enter a valid price';
                        }
                      }
                      return null;
                    },
                  ),
                ],
                SizedBox(height: 24),
                _buildOfficeBoySelection(),
                SizedBox(height: 24),
                _buildGlassTextField(
                  controller: _notesController,
                  label: 'Additional Notes (Optional)',
                  hint: 'Any special instructions...',
                  icon: Assets.imagesSvgsNote,
                  delay: 400,
                  maxLines: 2,
                ),
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
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.1),
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
                          0.3 + (_glowAnimation.value * 0.4),
                        ),
                        Colors.white.withOpacity(
                          0.3 + (_glowAnimation.value * 0.4),
                        ),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: widget.organization.primaryColorValue
                            .withOpacity(_glowAnimation.value * 0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),

              Row(
                children: [
                  // Animated title with shimmer effect
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedBuilder(
                          animation: _shimmerController,
                          builder: (context, child) => Row(
                            children: [
                              Text(
                                'Edit Order',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Order #${widget.order.id.substring(0, 8)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Animated close button
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
                            child: Icon(
                              Icons.close,
                              color: Colors.white.withOpacity(0.9),
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

  Widget _buildOrderTypeSelection() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
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
                    'Order Type',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildGlassTypeCard(
                          'Internal',
                          'Tea, Coffee, Water',
                          Assets.imagesSvgsCompany,
                          OrderType.internal,
                          widget.organization.secondaryColorValue,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildGlassTypeCard(
                          'External',
                          'Food, Meals, Delivery',
                          Assets.imagesSvgsShoppingCart,
                          OrderType.external,
                          widget.organization.secondaryColorValue,
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
    );
  }

  Widget _buildGlassTypeCard(
    String title,
    String subtitle,
    String icon,
    OrderType type,
    Color color,
  ) {
    final isSelected = _selectedType == type;

    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) => GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
            // Clear price if changing from external to internal
            if (type == OrderType.internal) {
              _priceController.clear();
            }
          });
        },
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      color.withOpacity(0.4),
                      color.withOpacity(0.3),
                      color.withOpacity(.2),
                    ],
                  )
                : LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? color.withOpacity(0.5)
                  : Colors.white.withOpacity(0.2),
              width: isSelected ? 3 : 1,
            ),
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
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      color.withOpacity(isSelected ? 0.3 : 0.2),
                      color.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: color.withOpacity(0.3), width: 1),
                ),
                child: SvgPicture.asset(
                  icon,
                  color: Colors.white,
                  fit: BoxFit.scaleDown,
                ),
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.8),
                ),
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemSelection() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(100 * (1 - value), 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Custom Item',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.white.withOpacity(0.1),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
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
                          controller: _itemController,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter item name...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                            ),
                            prefixIcon: SvgPicture.asset(
                              _selectedType == OrderType.internal
                                  ? Assets.imagesSvgsCoffee
                                  : Assets.imagesSvgsShoppingCart,
                              color: Colors.white,
                              fit: BoxFit.scaleDown,
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
                ),
                SizedBox(width: 12),
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) => Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          widget.organization.primaryColorValue,
                          widget.organization.secondaryColorValue,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.organization.primaryColorValue
                              .withOpacity(0.3 + (_glowAnimation.value * 0.3)),
                          blurRadius: 20 + (_glowAnimation.value * 10),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _addCustomItem,
                        child: Container(
                          padding: EdgeInsets.all(16),
                          child: Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 24,
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
    );
  }

  Widget _buildSelectedItemsDisplay() {
    if (_selectedItems.isEmpty) return SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: Container(
          padding: EdgeInsets.all(20),

          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.organization.secondaryColorValue.withOpacity(0.2),
                widget.organization.secondaryColorValue.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.organization.secondaryColorValue.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.organization.secondaryColorValue.withOpacity(0.2),
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
                  Text(
                    'Selected Items (${_selectedItems.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedItems.map((item) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.2),
                              Colors.white.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 6),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedItems.remove(item);
                                });
                              },
                              child: SvgPicture.asset(
                                Assets.imagesSvgsClose,
                                height: 18,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPredefinedItems() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(50 * (1 - value), 0),
        child: Container(
          padding: EdgeInsets.all(24),
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
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
                    'Quick Select',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _predefinedItems[_selectedType]!.map((item) {
                      final isSelected = _selectedItems.contains(item);
                      return AnimatedBuilder(
                        animation: _glowController,
                        builder: (context, child) => GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedItems.remove(item);
                              } else {
                                _selectedItems.add(item);
                              }
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isSelected
                                    ? [
                                        widget.organization.primaryColorValue
                                            .withOpacity(0.3),
                                        widget.organization.secondaryColorValue
                                            .withOpacity(0.2),
                                      ]
                                    : [
                                        Colors.white.withOpacity(0.15),
                                        Colors.white.withOpacity(0.05),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? widget.organization.primaryColorValue
                                          .withOpacity(0.5)
                                    : Colors.white.withOpacity(0.3),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: widget
                                            .organization
                                            .primaryColorValue
                                            .withOpacity(
                                              0.3 +
                                                  (_glowAnimation.value * 0.2),
                                            ),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                        offset: Offset(0, 4),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 5,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Text(
                              item,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.8),
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOfficeBoySelection() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + 300),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(100 * (1 - value), 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Office Boy',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: DropdownButton<EmployeeUserModel>(
                      value: _selectedOfficeBoy,
                      isExpanded: true,
                      underline: SizedBox(),
                      dropdownColor: Colors.transparent,
                      icon: Icon(
                        Icons.arrow_drop_down_rounded,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      items: widget.officeBoys.map((officeBoy) {
                        return DropdownMenuItem<EmployeeUserModel>(
                          value: officeBoy,
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      widget.organization.primaryColorValue
                                          .withOpacity(0.3),
                                      widget.organization.secondaryColorValue
                                          .withOpacity(0.2),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.delivery_dining_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                officeBoy.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (EmployeeUserModel? newValue) {
                        setState(() {
                          _selectedOfficeBoy = newValue;
                        });
                      },
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

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String icon,
    required int delay,
    TextInputType? keyboardType,
    int? maxLines,
    String? Function(String?)? validator,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(100 * (1 - value), 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
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
                    controller: controller,
                    keyboardType: keyboardType,
                    maxLines: maxLines ?? 1,
                    validator: validator,
                    onTapOutside: (event) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SvgPicture.asset(
                          icon,
                          color: Colors.white,
                          fit: BoxFit.scaleDown,
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
      duration: Duration(milliseconds: 1200),
      curve: Curves.elasticOut,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 100 * (1 - value)),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
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
              child: Column(
                children: [
                  // Update Order Button
                  AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, child) => Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.organization.primaryColorValue,
                            widget.organization.secondaryColorValue,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: widget.organization.primaryColorValue
                                .withOpacity(
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
                          onTap:
                              (_isSubmitting ||
                                  _isDeleting ||
                                  _selectedItems.isEmpty)
                              ? null
                              : _updateOrder,
                          child: Container(
                            alignment: Alignment.center,
                            child: _isSubmitting
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                        'Updating Order...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    'Update Order (${_selectedItems.length} items)',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),

                  // Delete Order Button
                  AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, child) => Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.withOpacity(0.8),
                            Colors.red.withOpacity(0.9),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(
                              0.3 + (_glowAnimation.value * 0.2),
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
                          onTap: _isSubmitting || _isDeleting
                              ? null
                              : _showDeleteConfirmation,
                          child: Container(
                            alignment: Alignment.center,
                            child: _isDeleting
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                        'Deleting Order...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    'Delete Order',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
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

  void _updateOrder() async {
    if (_selectedItems.isEmpty) {
      showErrorToast(context, 'Please select at least one item');
      return;
    }

    if (_selectedOfficeBoy == null) {
      showErrorToast(context, 'Please select an office boy');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final items = _selectedItems
          .map((itemName) => OrderItem(name: itemName))
          .toList();

      final updatedOrder = widget.order.copyWith(
        items: items,
        description: _descriptionController.text.trim(),
        type: _selectedType,
        officeBoyId: _selectedOfficeBoy!.id,
        officeBoyName: _selectedOfficeBoy!.name,
        price: _priceController.text.isNotEmpty
            ? double.tryParse(_priceController.text)
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      widget.onOrderUpdated(updatedOrder);
      Navigator.pop(context);
    } catch (e) {
      showErrorToast(context, 'Failed to update order: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
            content: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.25),
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.red.withOpacity(0.3),
                          Colors.red.withOpacity(0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.red.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.delete_forever_rounded,
                      color: Colors.red,
                      size: 32,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Delete Order',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Are you sure you want to delete this order? This action cannot be undone.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.2),
                                Colors.white.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                alignment: Alignment.center,
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.withOpacity(0.8),
                                Colors.red.withOpacity(0.9),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(
                                  0.3 + (_glowAnimation.value * 0.2),
                                ),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.pop(context);
                                _deleteOrder();
                              },
                              child: Container(
                                alignment: Alignment.center,
                                child: Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
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
        ),
      ),
    );
  }

  void _deleteOrder() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      widget.onOrderDeleted(widget.order.id);
      Navigator.pop(context);
    } catch (e) {
      showErrorToast(context, 'Failed to delete order: $e');
    } finally {
      setState(() {
        _isDeleting = false;
      });
    }
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

    // Draw floating particles
    for (int i = 0; i < 20; i++) {
      final progress = (animationValue + i * 0.1) % 1.0;
      final x =
          (i % 4) * size.width / 4 +
          math.sin(animationValue * 2 * math.pi + i) * 30;
      final y = size.height * progress;
      final opacity = math.sin(progress * math.pi) * 0.3;

      paint.color = (i % 2 == 0 ? primaryColor : secondaryColor).withOpacity(
        opacity,
      );

      final radius = 2 + math.sin(animationValue * 4 * math.pi + i) * 1;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Draw flowing waves
    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < 3; i++) {
      final path = Path();
      final waveHeight = 20 + i * 10;
      final waveLength = size.width / 4;
      final waveOffset = animationValue * 2 * math.pi;

      wavePaint.color = (i % 2 == 0 ? primaryColor : secondaryColor)
          .withOpacity(0.1);

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

    // Draw gradient orbs
    for (int i = 0; i < 5; i++) {
      final centerX = (i + 0.5) * size.width / 5;
      final centerY =
          size.height * 0.5 +
          math.sin(animationValue * 2 * math.pi + i * 1.2) * 100;
      final radius = 40 + math.sin(animationValue * 3 * math.pi + i) * 20;

      final gradient = RadialGradient(
        colors: [
          (i % 2 == 0 ? primaryColor : secondaryColor).withOpacity(0.1),
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
