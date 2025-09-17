// ORDER DETAILS BOTTOM SHEET - UPDATED
import 'package:flutter/material.dart';
import 'package:taqy/features/office_boy/data/models/office_order.dart';
import 'package:taqy/features/office_boy/data/models/office_organization.dart';

class OrderDetailsBottomSheet extends StatefulWidget {
  final OfficeOrder order;
  final OfficeOrganization organization;
  final bool isOfficeBoy;
  final Function(OfficeOrder, OrderStatus, {double? finalPrice, String? notes})
  onStatusUpdate;
  final Function(OfficeOrder, int, ItemStatus, String?)? onItemStatusUpdate;

  const OrderDetailsBottomSheet({
    super.key,
    required this.order,
    required this.organization,
    required this.isOfficeBoy,
    required this.onStatusUpdate,
    this.onItemStatusUpdate,
  });

  @override
  State<OrderDetailsBottomSheet> createState() =>
      _OrderDetailsBottomSheetState();
}

class _OrderDetailsBottomSheetState extends State<OrderDetailsBottomSheet> {
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

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
  }

  @override
  void dispose() {
    _priceController.dispose();
    _notesController.dispose();
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

  // Color _getOrderTypeColor(OrderType type) {
  //   switch (type) {
  //     case OrderType.internal:
  //       return Colors.blue;
  //     case OrderType.external:
  //       return Colors.orange;
  //   }
  // }

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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _updateStatus(OrderStatus status) async {
    if (status == OrderStatus.completed &&
        widget.order.type == OrderType.external &&
        _priceController.text.trim().isEmpty) {
      _showErrorToast('Please enter the final price for external orders');
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
      _showErrorToast('Failed to update order status: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
                  'Order Details',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getOrderStatusColor(
                      widget.order.status,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.order.status
                        .toString()
                        .split('.')
                        .last
                        .toUpperCase(),
                    style: TextStyle(
                      color: _getOrderStatusColor(widget.order.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Info Card
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.organization.primaryColorValue,
                          widget.organization.secondaryColorValue,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                widget.order.type == OrderType.internal
                                    ? Icons.home
                                    : Icons.store,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 12),
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
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          widget.order.type ==
                                                  OrderType.internal
                                              ? 'Internal Order'
                                              : 'External Order',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          '${widget.order.items.length} ${widget.order.items.length == 1 ? 'Item' : 'Items'}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
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
                          SizedBox(height: 16),
                          Text(
                            'Description',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            widget.order.description,
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Items List
                  Text(
                    'Order Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 12),
                  ...widget.order.items.asMap().entries.map((entry) {
                    // final index = entry.key;
                    final item = entry.value;
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getItemStatusColor(
                            item.status,
                          ).withOpacity(0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getItemStatusColor(
                                    item.status,
                                  ).withOpacity(0.1),
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
                            ],
                          ),
                          // if (item.description != null && item.description!.isNotEmpty) ...[
                          //   SizedBox(height: 8),
                          //   Text(
                          //     item.description!,
                          //     style: TextStyle(
                          //       color: Colors.grey[600],
                          //       fontSize: 14,
                          //     ),
                          //   ),
                          // ],
                          if (item.notes != null && item.notes!.isNotEmpty) ...[
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.note,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.notes!,
                                      style: TextStyle(
                                        color: Colors.grey[700],
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
                  }),

                  SizedBox(height: 24),

                  // Details
                  Text(
                    'Order Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 12),

                  _buildDetailRow(
                    'Employee',
                    widget.order.employeeName,
                    Icons.person,
                  ),
                  if (widget.order.officeBoyName.isNotEmpty)
                    _buildDetailRow(
                      'Office Boy',
                      widget.order.officeBoyName,
                      Icons.delivery_dining,
                    ),
                  _buildDetailRow(
                    'Created',
                    _formatDateTime(widget.order.createdAt),
                    Icons.schedule,
                  ),
                  if (widget.order.completedAt != null)
                    _buildDetailRow(
                      'Completed',
                      _formatDateTime(widget.order.completedAt!),
                      Icons.check_circle,
                    ),

                  SizedBox(height: 16),

                  // Price Section
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[50]!, Colors.green[100]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.attach_money, color: Colors.green[700]),
                            SizedBox(width: 8),
                            Text(
                              'Price Information',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),

                        if (widget.order.price != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Budget Price:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                'EGP ${widget.order.price!.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),

                        if (widget.order.finalPrice != null) ...[
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Final Price:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                'EGP ${widget.order.finalPrice!.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Price input for office boys during in-progress external orders
                        if (widget.isOfficeBoy &&
                            widget.order.status == OrderStatus.inProgress &&
                            widget.order.type == OrderType.external) ...[
                          SizedBox(height: 12),
                          Text(
                            'Enter Final Price:',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Enter actual spent amount',
                              prefixText: 'EGP ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              isDense: true,
                            ),
                          ),
                        ],

                        // Price difference indicator
                        if (widget.order.price != null &&
                            widget.order.finalPrice != null) ...[
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  widget.order.finalPrice! <=
                                      widget.order.price!
                                  ? Colors.green[50]
                                  : Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Difference:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${widget.order.finalPrice! > widget.order.price! ? '+' : ''}${(widget.order.finalPrice! - widget.order.price!).toStringAsFixed(0)} EGP',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        widget.order.finalPrice! <=
                                            widget.order.price!
                                        ? Colors.green[700]
                                        : Colors.red[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Notes Section
                  if (widget.isOfficeBoy &&
                      widget.order.status == OrderStatus.inProgress) ...[
                    SizedBox(height: 16),
                    Text(
                      'Add Notes (Optional)',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        hintText: 'Add any additional notes...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      maxLines: 3,
                    ),
                  ] else if (widget.order.notes != null &&
                      widget.order.notes!.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.note,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Notes',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            widget.order.notes!,
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: 32),

                  // Action Buttons
                  if (widget.isOfficeBoy &&
                      widget.order.status == OrderStatus.inProgress) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () => _updateStatus(OrderStatus.cancelled),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel Order',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () => _updateStatus(OrderStatus.completed),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  )
                                : Text(
                                    'Mark as Completed',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
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

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
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
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
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
