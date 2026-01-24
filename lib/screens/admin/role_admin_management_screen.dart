import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../core/constants/app_constants.dart';

class RoleAdminManagementScreen extends StatefulWidget {
  const RoleAdminManagementScreen({super.key});

  @override
  State<RoleAdminManagementScreen> createState() => _RoleAdminManagementScreenState();
}

class _RoleAdminManagementScreenState extends State<RoleAdminManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _selectedRoleFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Role-Based Admins'),
        actions: [
          // Filter by role
          DropdownButton<String>(
            value: _selectedRoleFilter,
            hint: const Text('Filter'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Roles')),
              ...AppConstants.allRoles.map((role) => DropdownMenuItem(
                value: role,
                child: Text(role.toUpperCase()),
              )),
            ],
            onChanged: (value) {
              setState(() {
                _selectedRoleFilter = value;
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: _firestoreService.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allUsers = snapshot.data ?? [];
          
          // Filter users (exclude super-admin from list, apply role filter)
          final users = allUsers.where((user) {
            if (user.role == AppConstants.roleSuperAdmin) return false;
            if (_selectedRoleFilter != null) {
              return user.role == _selectedRoleFilter;
            }
            return true;
          }).toList();

          if (users.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(user.name[0].toUpperCase()),
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
                        _showConfirmDialog(context, user, newRole);
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

  void _showConfirmDialog(BuildContext context, UserModel user, String newRole) {
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
              _firestoreService.updateUserRole(user.id, newRole);
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
