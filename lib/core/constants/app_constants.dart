class AppConstants {
  // App Info
  static const String appName = 'LegitBuy';
  
  // Collections
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String ordersCollection = 'orders';
  
  // User Roles
  static const String roleSuperAdmin = 'superadmin';
  static const String roleAdmin = 'admin';
  static const String roleCustomer = 'customer';
  
  // Get all available roles
  static List<String> get allRoles => [
    roleSuperAdmin,
    roleAdmin,
    roleCustomer,
  ];
  
  // Hardcoded Super-Admin Credentials (for initial setup only)
  static const String superAdminEmail = 'superadmin@legitbuy.com';
  static const String superAdminPassword = 'SuperAdmin@2024!'; // Change this before production!
  static const String superAdminName = 'Super Administrator';
  
  // Order Status
  static const String orderStatusPending = 'pending';
  static const String orderStatusProcessing = 'processing';
  static const String orderStatusCompleted = 'completed';
  static const String orderStatusCancelled = 'cancelled';
  
  // Payment Status
  static const String paymentStatusPending = 'pending';
  static const String paymentStatusProcessing = 'processing';
  static const String paymentStatusPaid = 'paid';
  static const String paymentStatusFailed = 'failed';
  static const String paymentStatusCancelled = 'cancelled';
  
  // Payment Method
  static const String paymentMethodMpesa = 'mpesa';
  
  // M-Pesa Configuration
  static const Duration mpesaCallbackTimeout = Duration(minutes: 5);
}
