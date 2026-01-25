import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../core/constants/app_constants.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: firestoreService.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allUsers = snapshot.data ?? [];
          
          // Filter out super-admin users (they shouldn't be managed here)
          final users = allUsers.where((user) => user.role != AppConstants.roleSuperAdmin).toList();

          if (users.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              // Safe avatar initial - handle empty names and emails
              String avatarText = '?';
              try {
                final name = user.name.trim();
                final email = user.email.trim();
                if (name.isNotEmpty) {
                  avatarText = name[0].toUpperCase();
                } else if (email.isNotEmpty) {
                  avatarText = email[0].toUpperCase();
                }
              } catch (e) {
                // Fallback to '?' if anything goes wrong
                avatarText = '?';
              }
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(avatarText),
                  ),
                  title: Text(user.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.email),
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(
                          user.role.toUpperCase(),
                          style: const TextStyle(fontSize: 10),
                        ),
                        backgroundColor: _getRoleColor(user.role),
                      ),
                    ],
                  ),
                  trailing: DropdownButton<String>(
                    value: user.role,
                    items: AppConstants.allRoles
                        .where((role) => role != AppConstants.roleSuperAdmin)
                        .map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (newRole) {
                      if (newRole != null && newRole != user.role) {
                        _showConfirmDialog(context, user, newRole, firestoreService);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showConfirmDialog(BuildContext context, UserModel user, String newRole, FirestoreService firestoreService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change User Role'),
        content: Text(
          'Change ${user.name}\'s role from ${user.role.toUpperCase()} to ${newRole.toUpperCase()}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              firestoreService.updateUserRole(user.id, newRole);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${user.name}\'s role updated to ${newRole.toUpperCase()}'),
                ),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case AppConstants.roleAdmin:
        return Colors.blue;
      case AppConstants.roleCustomer:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
