// RESPONSE BOTTOM SHEET FOR NEEDS RESPONSE ORDERS
import 'package:flutter/material.dart';
import 'package:taqy/features/employee/data/models/order_model.dart';
import 'package:taqy/features/employee/data/models/organization_model.dart';

class OrderResponseBottomSheet extends StatefulWidget {
  final EmployeeOrder order;
  final EmployeeOrganization organization;
  final Function(String orderId, String response, OrderStatus newStatus) onResponse;

  const OrderResponseBottomSheet({
    super.key,
    required this.order,
    required this.organization,
    required this.onResponse,
  });

  @override
  State<OrderResponseBottomSheet> createState() => _OrderResponseBottomSheetState();
}

class _OrderResponseBottomSheetState extends State<OrderResponseBottomSheet> {
  final TextEditingController _responseController = TextEditingController();
  bool _isLoading = false;
  OrderStatus _selectedAction = OrderStatus.inProgress; // Default to continue

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
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

  Future<void> _submitResponse() async {
    if (_responseController.text.trim().isEmpty) {
      _showErrorToast('Please provide a response');
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
      _showErrorToast('Failed to submit response: $e');
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
    final availableItems = widget.order.items.where((item) => item.status == ItemStatus.available).toList();
    final unavailableItems = widget.order.items.where((item) => item.status == ItemStatus.notAvailable).toList();
    final hasAvailableItems = availableItems.isNotEmpty;
    final hasUnavailableItems = unavailableItems.isNotEmpty;

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
                  'Order Response Required',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'NEEDS RESPONSE',
                    style: TextStyle(
                      color: Colors.purple,
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
                  // Order Summary
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.organization.primaryColorValue,
                          widget.organization.secondaryColorValue,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              widget.order.type == OrderType.internal 
                                  ? Icons.home 
                                  : Icons.store,
                              color: Colors.white,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.order.items.length == 1
                                    ? widget.order.items.first.name
                                    : '${widget.order.items.length} Items Order',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (widget.order.description.isNotEmpty) ...[
                          SizedBox(height: 8),
                          Text(
                            widget.order.description,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Availability Status
                  Text(
                    'Item Availability Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 12),

                  // Available Items
                  if (hasAvailableItems) ...[
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
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Available Items (${availableItems.length})',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          ...availableItems.map((item) => _buildItemRow(item)),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                  ],

                  // Unavailable Items
                  if (hasUnavailableItems) ...[
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.cancel, color: Colors.red[700], size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Unavailable Items (${unavailableItems.length})',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          ...unavailableItems.map((item) => _buildItemRow(item)),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                  ],

                  // Action Selection
                  Text(
                    'Your Decision',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 12),

                  // Action Options
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        if (hasAvailableItems) ...[
                          RadioListTile<OrderStatus>(
                            title: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 20),
                                SizedBox(width: 8),
                                Text('Continue with available items'),
                              ],
                            ),
                            subtitle: Text(
                              'Proceed with ${availableItems.length} available item${availableItems.length == 1 ? '' : 's'}',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: OrderStatus.inProgress,
                            groupValue: _selectedAction,
                            onChanged: (value) {
                              setState(() {
                                _selectedAction = value!;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                        RadioListTile<OrderStatus>(
                          title: Row(
                            children: [
                              Icon(Icons.cancel, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text('Cancel the entire order'),
                            ],
                          ),
                          subtitle: Text(
                            'Cancel due to unavailable items',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: OrderStatus.cancelled,
                          groupValue: _selectedAction,
                          onChanged: (value) {
                            setState(() {
                              _selectedAction = value!;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Response Message
                  Text(
                    'Your Message',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _responseController,
                    decoration: InputDecoration(
                      hintText: _selectedAction == OrderStatus.inProgress
                          ? 'Any special instructions or notes...'
                          : 'Reason for cancellation...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: EdgeInsets.all(16),
                    ),
                    maxLines: 4,
                  ),

                  SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Action Buttons
          Container(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Cancel'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitResponse,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedAction == OrderStatus.cancelled
                          ? Colors.red
                          : Colors.green,
                      padding: EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : Text(
                            _selectedAction == OrderStatus.cancelled
                                ? 'Cancel Order'
                                : 'Continue Order',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(OrderItem item) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getItemStatusIcon(item.status),
                color: _getItemStatusColor(item.status),
                size: 16,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getItemStatusColor(item.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getItemStatusText(item.status),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getItemStatusColor(item.status),
                  ),
                ),
              ),
            ],
          ),
          if (item.notes != null && item.notes!.isNotEmpty) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.note,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.notes!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
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
}