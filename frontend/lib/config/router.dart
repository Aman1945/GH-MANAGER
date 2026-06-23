import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/admin/admin_shell.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/admin_leads.dart';
import '../screens/admin/admin_create_lead.dart';
import '../screens/admin/admin_bookings.dart';
import '../screens/admin/admin_rooms.dart';
import '../screens/admin/admin_more.dart';
import '../screens/admin/admin_sessions.dart';
import '../screens/booking_manager/bm_shell.dart';
import '../screens/booking_manager/bm_dashboard.dart';
import '../screens/booking_manager/bm_approvals.dart';
import '../screens/booking_manager/bm_bookings.dart';
import '../screens/gh_manager/ghm_shell.dart';
import '../screens/gh_manager/ghm_dashboard.dart';
import '../screens/gh_manager/ghm_rooms.dart';
import '../screens/maintenance_screen.dart';
import '../screens/room_occupation_screen.dart';

class AuthStateListenable extends ChangeNotifier {
  AuthStateListenable(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = AuthStateListenable(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: listenable,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.token != null && authState.user != null;
      final isLoginPage = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginPage) return '/login';
      if (isLoggedIn && isLoginPage) {
        final role = authState.user?.role;
        return switch (role) {
          'ADMIN' => '/admin/dashboard',
          'BOOKING_MANAGER' => '/bm/dashboard',
          'GH_MANAGER' => '/ghm/dashboard',
          _ => '/login',
        };
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Admin shell
      ShellRoute(
        builder: (context, state, child) =>
            AdminShell(child: child, location: state.matchedLocation),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            builder: (context, state) => const AdminDashboard(),
          ),
          GoRoute(
            path: '/admin/leads',
            builder: (context, state) => const AdminLeads(),
          ),
          GoRoute(
            path: '/admin/create-lead',
            builder: (context, state) => const AdminCreateLead(),
          ),
          GoRoute(
            path: '/admin/bookings',
            builder: (context, state) => const AdminBookings(),
          ),
          GoRoute(
            path: '/admin/rooms',
            builder: (context, state) => const AdminRooms(),
          ),
          GoRoute(
            path: '/admin/room-live',
            builder: (context, state) => const RoomOccupationScreen(),
          ),
          GoRoute(
            path: '/admin/reports',
            builder: (context, state) => const MaintenanceScreen(),
          ),
          GoRoute(
            path: '/admin/more',
            builder: (context, state) => const AdminMore(),
          ),
          GoRoute(
            path: '/admin/sessions',
            builder: (context, state) => const AdminSessions(),
          ),
        ],
      ),

      // Booking Manager shell
      ShellRoute(
        builder: (context, state, child) =>
            BMShell(child: child, location: state.matchedLocation),
        routes: [
          GoRoute(
            path: '/bm/dashboard',
            builder: (context, state) => const BMDashboard(),
          ),
          GoRoute(
            path: '/bm/approvals',
            builder: (context, state) => const BMApprovals(),
          ),
          GoRoute(
            path: '/bm/bookings',
            builder: (context, state) => const BMBookings(),
          ),
          GoRoute(
            path: '/bm/room-live',
            builder: (context, state) => const RoomOccupationScreen(),
          ),
          GoRoute(
            path: '/bm/reports',
            builder: (context, state) => const MaintenanceScreen(),
          ),
        ],
      ),

      // GH Manager shell
      ShellRoute(
        builder: (context, state, child) =>
            GHMShell(child: child, location: state.matchedLocation),
        routes: [
          GoRoute(
            path: '/ghm/dashboard',
            builder: (context, state) => const GHMDashboard(),
          ),
          GoRoute(
            path: '/ghm/rooms',
            builder: (context, state) => const GHMRooms(),
          ),
          GoRoute(
            path: '/ghm/room-live',
            builder: (context, state) => const RoomOccupationScreen(),
          ),
          GoRoute(
            path: '/ghm/reports',
            builder: (context, state) => const MaintenanceScreen(),
          ),
        ],
      ),
    ],
  );
});
