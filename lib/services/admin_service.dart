import 'dart:io';

class AdminResult {
  final bool isAdmin;
  final String? adminLevel; // admin1, admin2, admin3
  final String message;

  AdminResult({
    required this.isAdmin,
    this.adminLevel,
    this.message = '',
  });
}

class AdminService {
  // Admin credentials from environment variables
  static final Map<String, String> _adminCredentials = {
    Platform.environment['ADMIN1_EMAIL'] ?? '': Platform.environment['ADMIN1_PASSWORD'] ?? '',
    Platform.environment['ADMIN2_EMAIL'] ?? '': Platform.environment['ADMIN2_PASSWORD'] ?? '',
    Platform.environment['ADMIN3_EMAIL'] ?? '': Platform.environment['ADMIN3_PASSWORD'] ?? '',
  };

  // Map to identify admin levels
  static final Map<String, String> _adminLevels = {
    Platform.environment['ADMIN1_EMAIL'] ?? '': 'admin1',
    Platform.environment['ADMIN2_EMAIL'] ?? '': 'admin2',
    Platform.environment['ADMIN3_EMAIL'] ?? '': 'admin3',
  };

  /// Check if the provided email and password match any admin credentials
  static Future<AdminResult> checkAdminLogin(String email, String password) async {
    try {
      // Remove empty keys that might exist due to missing env variables
      final validCredentials = Map<String, String>.from(_adminCredentials)
        ..removeWhere((key, value) => key.isEmpty || value.isEmpty);

      if (validCredentials.containsKey(email)) {
        if (validCredentials[email] == password) {
          final adminLevel = _adminLevels[email];
          return AdminResult(
            isAdmin: true,
            adminLevel: adminLevel,
            message: 'Admin authentication successful',
          );
        } else {
          return AdminResult(
            isAdmin: false,
            message: 'Invalid admin password',
          );
        }
      }

      // Not an admin email
      return AdminResult(
        isAdmin: false,
        message: 'Not an admin account',
      );
    } catch (e) {
      return AdminResult(
        isAdmin: false,
        message: 'Admin authentication error: ${e.toString()}',
      );
    }
  }

  /// Check if current user is admin (for route protection)
  static bool isCurrentUserAdmin() {
    // You might want to store admin state in shared preferences
    // or some other persistent storage
    // This is a basic implementation
    return false;
  }

  /// Get all configured admin emails (for debugging purposes)
  static List<String> getConfiguredAdmins() {
    return _adminCredentials.keys
        .where((email) => email.isNotEmpty && _adminCredentials[email]!.isNotEmpty)
        .toList();
  }

  /// Validate environment variables are properly set
  static bool validateAdminConfiguration() {
    final validAdmins = getConfiguredAdmins();
    return validAdmins.isNotEmpty;
  }
}