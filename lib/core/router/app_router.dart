
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/customers/presentation/screens/customers_screen.dart';
import '../../features/customers/presentation/screens/customer_detail_screen.dart';
import '../../features/customers/presentation/screens/add_edit_customer_screen.dart';
import '../../features/debts/presentation/screens/debts_screen.dart';
import '../../features/debts/presentation/screens/add_debt_screen.dart';
import '../../features/debts/presentation/screens/debt_detail_screen.dart';
import '../../features/installments/presentation/screens/installments_screen.dart';
import '../../features/subscriptions/presentation/screens/subscriptions_screen.dart';
import '../../features/subscriptions/presentation/screens/add_subscription_screen.dart';
import '../../features/payments/presentation/screens/payments_screen.dart';
import '../../features/payments/presentation/screens/add_payment_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../widgets/main_scaffold.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);
  return GoRouter(
    initialLocation: '/splash',
    redirect: (ctx, state) {
      final loggedIn = auth.value != null;
      final isAuth = state.matchedLocation.startsWith('/auth') || state.matchedLocation == '/splash';
      if (!loggedIn && !isAuth) return '/auth/login';
      if (loggedIn && state.matchedLocation == '/auth/login') return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
      ShellRoute(
        builder: (_, __, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/customers', builder: (_, __) => const CustomersScreen(), routes: [
            GoRoute(path: 'add', builder: (_, __) => const AddEditCustomerScreen()),
            GoRoute(path: ':id', builder: (_, s) => CustomerDetailScreen(customerId: s.pathParameters['id']!), routes: [
              GoRoute(path: 'edit', builder: (_, s) => AddEditCustomerScreen(customerId: s.pathParameters['id'])),
            ]),
          ]),
          GoRoute(path: '/debts', builder: (_, __) => const DebtsScreen(), routes: [
            GoRoute(path: 'add', builder: (_, s) => AddDebtScreen(customerId: s.uri.queryParameters['customerId'])),
            GoRoute(path: ':id', builder: (_, s) => DebtDetailScreen(debtId: s.pathParameters['id']!)),
          ]),
          GoRoute(path: '/installments', builder: (_, __) => const InstallmentsScreen()),
          GoRoute(path: '/subscriptions', builder: (_, __) => const SubscriptionsScreen(), routes: [
            GoRoute(path: 'add', builder: (_, s) => AddSubscriptionScreen(customerId: s.uri.queryParameters['customerId'])),
          ]),
          GoRoute(path: '/payments', builder: (_, __) => const PaymentsScreen(), routes: [
            GoRoute(path: 'add', builder: (_, s) => AddPaymentScreen(
              debtId: s.uri.queryParameters['debtId'],
              installmentId: s.uri.queryParameters['installmentId'],
            )),
          ]),
          GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
          GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        ],
      ),
    ],
  );
});
