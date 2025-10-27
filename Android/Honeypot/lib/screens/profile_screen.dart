import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  final AuthService authService;
  
  const ProfileScreen({super.key, required this.authService});
  
  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        actions: [
          if (!authService.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.login),
              onPressed: () => authService.signInWithGoogle(),
              tooltip: 'Google Login',
            ),
          if (authService.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => authService.signOut(),
              tooltip: 'Logout',
            ),
        ],
      ),
      body: AnimatedBuilder(
        animation: authService,
        builder: (context, _) {
          if (authService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!authService.isAuthenticated || authService.currentUser == null) {
            return _buildNotLoggedIn(context);
          }
          
          final user = authService.currentUser!;
          final isAdmin = user.role == 'admin';
          return _buildUserProfile(context, user, isAdmin);
        },
      ),
    );
  }
  
  Widget _buildNotLoggedIn(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off, size: 80, color: Colors.grey),
          const SizedBox(height: 24),
          const Text(
            'Nicht angemeldet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => authService.signInWithGoogle(),
            icon: const Icon(Icons.login),
            label: const Text('Mit Google anmelden'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUserProfile(BuildContext context, dynamic user, bool isAdmin) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user.photoUrl != null)
              CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(user.photoUrl!),
              )
            else
              const CircleAvatar(
                radius: 60,
                child: Icon(Icons.person, size: 60),
              ),
            const SizedBox(height: 24),
            Text(
              user.displayName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              user.email,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow(context, Icons.badge, 'Role', _getRoleDisplayName(user.role)),
                    const Divider(height: 24),
                    _buildInfoRow(context, Icons.email, 'E-Mail', user.email),
                    const Divider(height: 24),
                    _buildInfoRow(context, Icons.cloud, 'Cloud Status', 
                      user.cloudBackupEnabled ? 'Aktiv' : 'Inaktiv'),
                  ],
                ),
              ),
            ),
            if (isAdmin) ...[
              const SizedBox(height: 24),
              Card(
                color: Colors.amber[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.admin_panel_settings, color: Colors.amber[800]),
                          const SizedBox(width: 8),
                          Text(
                            'Admin-Bereich',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Als Rolle anzeigen:', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildRoleChip(context, 'standard', 'Standard'),
                          _buildRoleChip(context, 'premium', 'Premium'),
                          _buildRoleChip(context, 'admin', 'Admin'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildRoleChip(BuildContext context, String role, String label) {
    final isSelected = authService.currentUser?.role == role;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          authService.switchRole(role);
        }
      },
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }
  
  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'premium':
        return 'Premium';
      case 'standard':
      default:
        return 'Standard';
    }
  }
}
