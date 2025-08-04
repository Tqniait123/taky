import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taqy/config/routes/routes.dart';
import 'package:taqy/core/theme/colors.dart';
import 'package:taqy/features/all/auth/presentation/cubit/auth_cubit.dart';
import 'package:taqy/features/all/auth/presentation/widgets/animated_button.dart';

class OfficeBoyLayout extends StatelessWidget {
  const OfficeBoyLayout({super.key});

  void _handleLogout(BuildContext context) async {
    await context.read<AuthCubit>().signOut();
    if (context.mounted) {
      context.go(Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OfficeBoy Layout')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('OfficeBoy Layout Page', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            BlocListener<AuthCubit, AuthState>(
              listener: (context, state) {
                state.maybeWhen(
                  unauthenticated: () => context.go(Routes.login),
                  error: (failure) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure)));
                  },
                  orElse: () {},
                );
              },
              child: AnimatedButton(
                text: 'Logout',
                onPressed: () => _handleLogout(context),
                backgroundColor: AppColors.primary,
                width: 200,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
