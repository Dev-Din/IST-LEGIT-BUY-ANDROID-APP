import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../services/admin_user_service.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_constants.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AdminUserService _adminUserService = AdminUserService();

  double _scale(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return (width / 360).clamp(0.85, 1.25);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<AuthProvider>(context, listen: false).user?.id;
    final scale = _scale(context);
    final titleSize = 16.0 * scale;
    final bodySize = 14.0 * scale;
    final captionSize = 12.0 * scale;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Users',
          style: TextStyle(fontSize: 18 * scale),
        ),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: _firestoreService.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(fontSize: bodySize),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final allUsers = snapshot.data ?? [];
          final users = allUsers
              .where((user) => user.role != AppConstants.roleSuperAdmin)
              .toList();

          if (users.isEmpty) {
            return Center(
              child: Text(
                'No users found',
                style: TextStyle(fontSize: bodySize),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
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
                avatarText = '?';
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      avatarText,
                      style: TextStyle(fontSize: titleSize),
                    ),
                  ),
                  title: Text(
                    user.name,
                    style: TextStyle(fontSize: titleSize),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user.email,
                        style: TextStyle(fontSize: bodySize),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(
                          user.role.toUpperCase(),
                          style: TextStyle(fontSize: captionSize),
                        ),
                        backgroundColor: _getRoleColor(user.role),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButton<String>(
                        value: user.role,
                        items: AppConstants.allRoles
                            .where((role) => role != AppConstants.roleSuperAdmin)
                            .map((role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(
                                    role.toUpperCase(),
                                    style: TextStyle(fontSize: captionSize),
                                  ),
                                ))
                            .toList(),
                        onChanged: (newRole) {
                          if (newRole != null && newRole != user.role) {
                            _showRoleConfirmDialog(context, user, newRole);
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditNameDialog(context, user),
                        tooltip: 'Edit name',
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: user.id == currentUserId ? Colors.grey : Colors.red,
                        ),
                        onPressed: user.id == currentUserId
                            ? null
                            : () => _showDeleteConfirmDialog(context, user),
                        tooltip: user.id == currentUserId
                            ? 'You cannot delete your own account'
                            : 'Delete user',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateUserDialog(context),
        tooltip: 'Add User',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showRoleConfirmDialog(BuildContext context, UserModel user, String newRole) {
    showDialog(
      context: context,
      builder: (ctx) {
        final scale = _scale(ctx);
        final titleSize = 18.0 * scale;
        final bodySize = 14.0 * scale;
        return AlertDialog(
          title: Text(
            'Change User Role',
            style: TextStyle(fontSize: titleSize),
          ),
          content: Text(
            'Change ${user.name}\'s role from ${user.role.toUpperCase()} to ${newRole.toUpperCase()}?',
            style: TextStyle(fontSize: bodySize),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(fontSize: bodySize)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _firestoreService.updateUserRole(user.id, newRole);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${user.name}\'s role updated to ${newRole.toUpperCase()}'),
                    ),
                  );
                }
              },
              child: Text('Confirm', style: TextStyle(fontSize: bodySize)),
            ),
          ],
        );
      },
    );
  }

  void _showEditNameDialog(BuildContext context, UserModel user) {
    final controller = TextEditingController(text: user.name);
    showDialog(
      context: context,
      builder: (ctx) {
        final scale = _scale(ctx);
        final titleSize = 18.0 * scale;
        final bodySize = 14.0 * scale;
        return AlertDialog(
          title: Text(
            'Edit Name',
            style: TextStyle(fontSize: titleSize),
          ),
          content: TextField(
            controller: controller,
            style: TextStyle(fontSize: bodySize),
            decoration: InputDecoration(
              labelText: 'Name',
              labelStyle: TextStyle(fontSize: bodySize),
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(fontSize: bodySize)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = controller.text.trim();
                Navigator.pop(ctx);
                if (newName.isEmpty) return;
                if (newName == user.name) return;
                await _firestoreService.updateUser(user.id, {'name': newName});
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name updated')),
                  );
                }
              },
              child: Text('Save', style: TextStyle(fontSize: bodySize)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) {
        final scale = _scale(ctx);
        final titleSize = 18.0 * scale;
        final bodySize = 14.0 * scale;
        return AlertDialog(
          title: Text(
            'Delete User',
            style: TextStyle(fontSize: titleSize),
          ),
          content: Text(
            'Permanently delete ${user.name} (${user.email})? This will remove their account and Firestore data.',
            style: TextStyle(fontSize: bodySize),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(fontSize: bodySize)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
              final currentUserId = Provider.of<AuthProvider>(ctx, listen: false).user?.id;
              if (currentUserId != null && user.id == currentUserId) {
                Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You cannot delete your own account'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                return;
              }
              Navigator.pop(ctx);
              try {
                await _adminUserService.deleteUser(user.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text('Delete', style: TextStyle(fontSize: bodySize)),
          ),
        ],
      );
      },
    );
  }

  void _showCreateUserDialog(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    String selectedRole = AppConstants.roleCustomer;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final scale = _scale(ctx);
          final titleSize = 18.0 * scale;
          final bodySize = 14.0 * scale;
          return AlertDialog(
            title: Text(
              'Add User',
              style: TextStyle(fontSize: titleSize),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    style: TextStyle(fontSize: bodySize),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(fontSize: bodySize),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    style: TextStyle(fontSize: bodySize),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(fontSize: bodySize),
                      border: const OutlineInputBorder(),
                    ),
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    style: TextStyle(fontSize: bodySize),
                    decoration: InputDecoration(
                      labelText: 'Name',
                      labelStyle: TextStyle(fontSize: bodySize),
                      border: const OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    style: TextStyle(fontSize: bodySize),
                    decoration: InputDecoration(
                      labelText: 'Role',
                      labelStyle: TextStyle(fontSize: bodySize),
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      AppConstants.roleCustomer,
                      AppConstants.roleAdmin,
                    ]
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r.toUpperCase(), style: TextStyle(fontSize: bodySize)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setDialogState(() => selectedRole = value);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: TextStyle(fontSize: bodySize)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final email = emailController.text.trim();
                  final password = passwordController.text;
                  final name = nameController.text.trim();
                  if (email.isEmpty || password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Email and password are required'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  if (password.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password must be at least 6 characters'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  try {
                    await _adminUserService.createUserByAdmin(
                      email: email,
                      password: password,
                      name: name.isEmpty ? email.split('@').first : name,
                      role: selectedRole,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User created')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Text('Create', style: TextStyle(fontSize: bodySize)),
              ),
            ],
          );
        },
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
