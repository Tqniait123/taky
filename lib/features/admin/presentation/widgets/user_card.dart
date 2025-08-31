import 'package:flutter/material.dart';
import 'package:taqy/core/theme/colors.dart';
import 'package:taqy/features/admin/data/models/app_user.dart';
import 'package:taqy/features/admin/data/models/order.dart';

import '../../data/models/organization.dart';

class UserCard extends StatelessWidget {
  final AppUser user;
  final List<Order> orders;
  final Organization organization;

  const UserCard({
    super.key,
    required this.user,
    required this.orders,
    required this.organization,
  });

  @override
  Widget build(BuildContext context) {
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
                        organization.primaryColorValue,
                        organization.secondaryColorValue,
                      ]
                    : [
                        organization.secondaryColorValue,
                        organization.primaryColorValue,
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
                      ? organization.primaryColorValue
                      : organization.secondaryColorValue,
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
}