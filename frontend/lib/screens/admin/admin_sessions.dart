import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../services/api_service.dart';

class AdminSessions extends ConsumerStatefulWidget {
  const AdminSessions({super.key});

  @override
  ConsumerState<AdminSessions> createState() => _AdminSessionsState();
}

class _AdminSessionsState extends ConsumerState<AdminSessions> {
  late Future<List<Map<String, dynamic>>> _sessionsFuture;
  bool _showStats = false;

  @override
  void initState() {
    super.initState();
    _sessionsFuture = _loadSessions();
  }

  Future<List<Map<String, dynamic>>> _loadSessions() async {
    try {
      final response = await ApiService().getSessions();
      if (response['success'] != false && response['data'] != null) {
        return List<Map<String, dynamic>>.from(response['data'] as List);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load sessions');
    }
  }

  Future<void> _logoutUser(String sessionId, String userName) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Logout User',
      message: 'Logout $userName from this device?',
      confirmLabel: 'Logout',
    );
    if (confirmed != true) return;

    try {
      await ApiService().logoutSession(sessionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User logged out'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _sessionsFuture = _loadSessions());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Active Sessions'),
        centerTitle: false,
        actions: [
          // Hidden feature: stats button (triple tap to activate)
          GestureDetector(
            onLongPress: () => setState(() => _showStats = !_showStats),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  _showStats ? '📊' : '⚙️',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _showStats ? _buildStatsView() : _buildSessionsView(),
    );
  }

  Widget _buildSessionsView() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _sessionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                Text(snapshot.error.toString()),
              ],
            ),
          );
        }

        final sessions = snapshot.data ?? [];
        if (sessions.isEmpty) {
          return const EmptyState(
            icon: Icons.devices_other,
            title: 'No active sessions',
            subtitle: 'All users are logged out',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() => _sessionsFuture = _loadSessions()),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final session = sessions[i];
              return _SessionCard(
                name: session['name'] ?? 'Unknown',
                email: session['email'] ?? '',
                role: session['role'] ?? '',
                device: session['device'] ?? 'Web',
                loginTime: session['loginTime'] ?? '',
                onLogout: () => _logoutUser(session['id'], session['name']),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStatsView() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading stats'));
        }

        final stats = snapshot.data ?? {};
        final emailStats = List.from(stats['emailDeviceStats'] ?? []);
        final limits = Map<String, dynamic>.from(stats['loginLimits'] ?? {});

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Login Limits', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 12),
              ...limits.entries.map((e) => _LimitCard(
                role: e.key,
                limit: e.value['limit'] ?? 0,
                used: e.value['used'] ?? 0,
              )),
              const SizedBox(height: 24),
              Text('Devices per Email', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 12),
              ...emailStats.map((stat) => _DeviceStatsCard(
                email: stat['_id'] ?? 'Unknown',
                deviceCount: stat['totalDevices'] ?? 0,
              )),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadStats() async {
    try {
      final response = await ApiService().getLoginStats();
      if (response['success'] != false && response['data'] != null) {
        return response['data'] as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      throw Exception('Failed to load stats');
    }
  }
}

class _SessionCard extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final String device;
  final String loginTime;
  final VoidCallback onLogout;

  const _SessionCard({
    required this.name,
    required this.email,
    required this.role,
    required this.device,
    required this.loginTime,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 4),
                    Text(email, style: AppTextStyles.bodySmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(role, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.infoLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(device, style: const TextStyle(fontSize: 11, color: AppColors.info, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: onLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Logout', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LimitCard extends StatelessWidget {
  final String role;
  final int limit;
  final int used;

  const _LimitCard({
    required this.role,
    required this.limit,
    required this.used,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (used / limit * 100).toInt();
    final color = percentage > 80 ? AppColors.error : (percentage > 50 ? AppColors.warning : AppColors.success);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(role, style: AppTextStyles.cardTitle),
              Text('$used/$limit', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: used / limit,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceStatsCard extends StatelessWidget {
  final String email;
  final int deviceCount;

  const _DeviceStatsCard({
    required this.email,
    required this.deviceCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(email, style: AppTextStyles.bodySmall, overflow: TextOverflow.ellipsis),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$deviceCount device${deviceCount == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 12, color: AppColors.info, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
