import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Legacy sidebar widget — kept for reference but no longer used in app UI.
/// The app now uses bottom tab navigation via role-specific shells.

class SidebarItem {
  final String label;
  final IconData icon;
  final String route;

  const SidebarItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}

class AppSidebar extends StatelessWidget {
  final String role;
  final String currentRoute;
  final String userName;
  final String userEmail;
  final void Function(String route) onNavigate;
  final VoidCallback onLogout;

  const AppSidebar({
    super.key,
    required this.role,
    required this.currentRoute,
    required this.userName,
    required this.userEmail,
    required this.onNavigate,
    required this.onLogout,
  });

  // Dark sidebar colors (nav-dark palette)
  static const Color _bg = Color(0xFF0D1B2A);
  static const Color _activeText = Colors.white;
  static const Color _mutedText = Color(0xFF6B7B8D);
  static const Color _accent = Color(0xFF14315E);
  static const Color _itemHover = Color(0xFF1E2D3D);

  List<SidebarItem> _itemsForRole() {
    switch (role) {
      case 'ADMIN':
        return const [
          SidebarItem(label: 'Dashboard', icon: Icons.dashboard_rounded, route: '/admin/dashboard'),
          SidebarItem(label: 'Leads', icon: Icons.person_add_rounded, route: '/admin/leads'),
          SidebarItem(label: 'Bookings', icon: Icons.calendar_month_rounded, route: '/admin/bookings'),
          SidebarItem(label: 'Rooms', icon: Icons.meeting_room_rounded, route: '/admin/rooms'),
          SidebarItem(label: 'Live Rooms', icon: Icons.grid_view_rounded, route: '/admin/room-live'),
          SidebarItem(label: 'Room Reports', icon: Icons.report_problem_outlined, route: '/admin/reports'),
        ];
      case 'BOOKING_MANAGER':
        return const [
          SidebarItem(label: 'Dashboard', icon: Icons.dashboard_rounded, route: '/bm/dashboard'),
          SidebarItem(label: 'Approvals', icon: Icons.fact_check_rounded, route: '/bm/approvals'),
          SidebarItem(label: 'Bookings', icon: Icons.calendar_month_rounded, route: '/bm/bookings'),
          SidebarItem(label: 'Live Rooms', icon: Icons.grid_view_rounded, route: '/bm/room-live'),
          SidebarItem(label: 'Room Reports', icon: Icons.report_problem_outlined, route: '/bm/reports'),
        ];
      case 'GH_MANAGER':
        return const [
          SidebarItem(label: 'Dashboard', icon: Icons.dashboard_rounded, route: '/ghm/dashboard'),
          SidebarItem(label: 'Room Status', icon: Icons.meeting_room_rounded, route: '/ghm/rooms'),
          SidebarItem(label: 'Live Rooms', icon: Icons.grid_view_rounded, route: '/ghm/room-live'),
          SidebarItem(label: 'Room Reports', icon: Icons.report_problem_outlined, route: '/ghm/reports'),
        ];
      default:
        return [];
    }
  }

  String _roleLabel() {
    switch (role) {
      case 'ADMIN': return 'Admin';
      case 'BOOKING_MANAGER': return 'Booking Manager';
      case 'GH_MANAGER': return 'GH Manager';
      default: return role;
    }
  }

  String _initials() {
    final parts = userName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    final items = _itemsForRole();

    return Container(
      width: 260,
      color: _bg,
      child: SafeArea(
        child: Column(
          children: [
            // Logo section
            Container(
              height: 72,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: _itemHover, width: 1)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.eco_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('GH Manager',
                          style: AppTextStyles.cardTitle.copyWith(color: _activeText, fontSize: 16)),
                      Text('v2.0',
                          style: AppTextStyles.caption.copyWith(color: _mutedText, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),

            // User card
            Container(
              margin: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _itemHover,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary,
                    child: Text(_initials(),
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName,
                            style: AppTextStyles.cardTitle.copyWith(color: _activeText, fontSize: 13),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4B5563),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(_roleLabel(),
                              style: const TextStyle(
                                  color: Color(0xFF6EE7B7), fontSize: 10, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Nav section label
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('NAVIGATION',
                    style: AppTextStyles.caption.copyWith(
                      color: _mutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    )),
              ),
            ),

            // Nav items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                children: items.map((item) {
                  final isActive = currentRoute.startsWith(item.route);
                  return _NavItem(
                    item: item,
                    isActive: isActive,
                    onTap: () => onNavigate(item.route),
                    activeText: _activeText,
                    mutedText: _mutedText,
                    accent: _accent,
                    hoverBg: _itemHover,
                  );
                }).toList(),
              ),
            ),

            // Logout
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: _itemHover, width: 1)),
              ),
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: _LogoutButton(onLogout: onLogout, mutedText: _mutedText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final SidebarItem item;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeText;
  final Color mutedText;
  final Color accent;
  final Color hoverBg;

  const _NavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
    required this.activeText,
    required this.mutedText,
    required this.accent,
    required this.hoverBg,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;
    final hovered = _hovered && !active;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: active || hovered ? widget.hoverBg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: active
                ? Border(left: BorderSide(color: widget.accent, width: 3))
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: EdgeInsets.only(
                  left: active ? 9 : 12,
                  right: 12,
                  top: 11,
                  bottom: 11,
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.item.icon,
                      size: 18,
                      color: active || hovered ? widget.activeText : widget.mutedText,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.item.label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: active || hovered ? widget.activeText : widget.mutedText,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatefulWidget {
  final VoidCallback onLogout;
  final Color mutedText;

  const _LogoutButton({required this.onLogout, required this.mutedText});

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.error.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onLogout,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
                  const SizedBox(width: 10),
                  Text('Logout',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
