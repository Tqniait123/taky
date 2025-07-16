// lib/features/auth/presentation/screens/account_type_selection_screen.dart
import 'package:flutter/material.dart';

class AccountTypeSelectionScreen extends StatefulWidget {
  const AccountTypeSelectionScreen({super.key});

  @override
  State<AccountTypeSelectionScreen> createState() => _AccountTypeSelectionScreenState();
}

class _AccountTypeSelectionScreenState extends State<AccountTypeSelectionScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Header
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                        child: Icon(Icons.business_center_outlined, size: 48, color: Colors.blue.shade600),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Welcome to TaQy',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[800]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose your account type to get started',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 48),

                      // Account Type Cards
                      Expanded(
                        child: Column(
                          children: [
                            _buildAccountTypeCard(
                              context,
                              title: 'Organization Admin',
                              description: 'Create and manage your organization',
                              icon: Icons.admin_panel_settings,
                              color: Colors.purple,
                              onTap: () => _navigateToRegister(context, 'admin'),
                            ),
                            const SizedBox(height: 16),
                            _buildAccountTypeCard(
                              context,
                              title: 'Employee',
                              description: 'Submit requests and track orders',
                              icon: Icons.person,
                              color: Colors.blue,
                              onTap: () => _navigateToRegister(context, 'employee'),
                            ),
                            const SizedBox(height: 16),
                            _buildAccountTypeCard(
                              context,
                              title: 'Office Boy',
                              description: 'Receive and fulfill requests',
                              icon: Icons.delivery_dining,
                              color: Colors.green,
                              onTap: () => _navigateToRegister(context, 'office_boy'),
                            ),
                          ],
                        ),
                      ),

                      // Footer
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Already have an account? ', style: TextStyle(color: Colors.grey[600])),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/login'),
                            child: Text(
                              'Sign In',
                              style: TextStyle(color: Colors.blue.shade600, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAccountTypeCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 4),
                  Text(description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  void _navigateToRegister(BuildContext context, String accountType) {
    Navigator.pushNamed(context, '/register', arguments: accountType);
  }
}
