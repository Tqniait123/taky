// New Order Bottom Sheet
import 'package:flutter/material.dart';
import 'package:taqy/features/employee/data/models/order_model.dart';
import 'package:taqy/features/employee/data/models/organization_model.dart';
import 'package:taqy/features/employee/data/models/user_model.dart';

class NewOrderBottomSheet extends StatefulWidget {
  final EmployeeUserModel employee;
  final EmployeeOrganization organization;
  final List<EmployeeUserModel> officeBoys;
  final Function(EmployeeOrder) onOrderCreated;

  const NewOrderBottomSheet({
    super.key,
    required this.employee,
    required this.organization,
    required this.officeBoys,
    required this.onOrderCreated,
  });

  @override
  State<NewOrderBottomSheet> createState() => _NewOrderBottomSheetState();
}

class _NewOrderBottomSheetState extends State<NewOrderBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _itemController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  OrderType _selectedType = OrderType.internal;
  EmployeeUserModel? _selectedOfficeBoy;
  bool _isSubmitting = false;

  final List<String> _selectedItems = [];

  // Predefined items
  final Map<OrderType, List<String>> _predefinedItems = {
    OrderType.internal: [
      'Tea',
      'Coffee',
      'Water',
      'Juice',
      'Snacks',
      'Biscuits',
      'Other',
    ],
    OrderType.external: [
      'Breakfast',
      'Lunch',
      'Dinner',
      'Fast Food',
      'Dessert',
      'Drinks',
      'Other',
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedOfficeBoy = widget.officeBoys.isNotEmpty
        ? widget.officeBoys.first
        : null;
  }

  @override
  void dispose() {
    _itemController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addCustomItem() {
    final itemName = _itemController.text.trim();
    if (itemName.isNotEmpty && !_selectedItems.contains(itemName)) {
      setState(() {
        _selectedItems.add(itemName);
        _itemController.clear();
      });
    } else if (_selectedItems.contains(itemName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item "$itemName" is already added'),
          backgroundColor: Colors.orange,
        ),
      );
    }
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
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: 12),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.all(24),
              child: Row(
                children: [
                  Text(
                    'New Order',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
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

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Type Selection
                    Text(
                      'Order Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTypeCard(
                            'Internal',
                            'Tea, Coffee, Water',
                            Icons.home,
                            OrderType.internal,
                            widget.organization.secondaryColorValue,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildTypeCard(
                            'External',
                            'Food, Meals, Delivery',
                            Icons.store,
                            OrderType.external,
                            widget.organization.primaryColorValue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),

                    // Item Selection
                    Text(
                      'What would you like to order?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Select multiple items or add custom items',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 12),

                    // Custom Item Input with Add Button
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _itemController,
                            decoration: InputDecoration(
                              labelText: 'Add Custom Item',
                              hintText: 'Enter item name and tap add',
                              prefixIcon: Icon(
                                _selectedType == OrderType.internal
                                    ? Icons.local_cafe
                                    : Icons.restaurant,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: widget.organization.primaryColorValue,
                                  width: 2,
                                ),
                              ),
                            ),
                            
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addCustomItem,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.organization.primaryColorValue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.all(16),
                          ),
                          child: Icon(
                            Icons.add,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Selected Items Display
                    if (_selectedItems.isNotEmpty) ...[
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected Items (${_selectedItems.length}):',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.green[700],
                              ),
                            ),
                            SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: _selectedItems.map((item) {
                                return Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        item,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedItems.remove(item);
                                          });
                                        },
                                        child: Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.green[700],
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
                      SizedBox(height: 16),
                    ],

                    // Predefined Items Section
                    Text(
                      'Quick Select:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _predefinedItems[_selectedType]!.map((item) {
                        final isSelected = _selectedItems.contains(item);
                        return GestureDetector(
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
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? widget.organization.primaryColorValue
                                        .withOpacity(0.1)
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? widget.organization.primaryColorValue
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Text(
                              item,
                              style: TextStyle(
                                color: isSelected
                                    ? widget.organization.primaryColorValue
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 20),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Any specific details or preferences...',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: widget.organization.primaryColorValue,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Price (for external orders)
                    if (_selectedType == OrderType.external) ...[
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Estimated Price (EGP)',
                          hintText: 'Enter estimated price',
                          prefixIcon: Icon(Icons.attach_money),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: widget.organization.primaryColorValue,
                              width: 2,
                            ),
                          ),
                        ),
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
                      SizedBox(height: 20),
                    ],

                    // Office Boy Selection
                    Text(
                      'Select Office Boy',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<EmployeeUserModel>(
                        value: _selectedOfficeBoy,
                        isExpanded: true,
                        underline: SizedBox(),
                        icon: Icon(Icons.arrow_drop_down),
                        items: widget.officeBoys.map((officeBoy) {
                          return DropdownMenuItem<EmployeeUserModel>(
                            value: officeBoy,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: widget
                                      .organization
                                      .primaryColorValue
                                      .withOpacity(0.1),
                                  backgroundImage:
                                      officeBoy.profileImageUrl != null
                                      ? NetworkImage(officeBoy.profileImageUrl!)
                                      : null,
                                  child: officeBoy.profileImageUrl == null
                                      ? Icon(
                                          Icons.delivery_dining,
                                          color: widget
                                              .organization
                                              .primaryColorValue,
                                          size: 16,
                                        )
                                      : null,
                                ),
                                SizedBox(width: 12),
                                Text(officeBoy.name),
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
                    SizedBox(height: 20),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Additional Notes (Optional)',
                        hintText: 'Any special instructions...',
                        prefixIcon: Icon(Icons.note),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: widget.organization.primaryColorValue,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Bottom Action
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isSubmitting || _selectedItems.isEmpty)
                      ? null
                      : _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.organization.primaryColorValue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isSubmitting
                        ? 'Placing Order...'
                        : 'Place Order (${_selectedItems.length} items)',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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

  Widget _buildTypeCard(
    String title,
    String subtitle,
    IconData icon,
    OrderType type,
    Color color,
  ) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          _selectedItems.clear(); // Clear items when changing type
        });
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(isSelected ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.black87,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _submitOrder() async {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one item'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedOfficeBoy == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an office boy'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Convert selected items to OrderItem objects
      final items = _selectedItems
          .map((itemName) => OrderItem(name: itemName))
          .toList();

      final order = EmployeeOrder(
        id: '', // Will be set by Firestore
        employeeId: widget.employee.id,
        employeeName: widget.employee.name,
        officeBoyId: _selectedOfficeBoy!.id,
        officeBoyName: _selectedOfficeBoy!.name,
        items: items, // Now using list of items
        description: _descriptionController.text.trim(),
        type: _selectedType,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
        price: _priceController.text.isNotEmpty
            ? double.tryParse(_priceController.text)
            : null,
        organizationId: widget.organization.id,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      widget.onOrderCreated(order);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}