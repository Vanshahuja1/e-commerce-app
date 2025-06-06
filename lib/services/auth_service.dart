import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '/models/user_model.dart';

class AuthService {
  // Replace with your correct IP and port
  static const String _baseUrl = 'https://backend-ecommerce-app-co1r.onrender.com/api';
  // Change to your server URL
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  /// Get current user from local storage
  static Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userKey);

    if (userString != null) {
      final userMap = jsonDecode(userString);
      return UserModel.fromJson(userMap);
    }

    return null;
  }

  /// Get current user from server
  static Future<AuthResult> getCurrentUserFromServer() async {
    try {
      final token = await getToken();
      if (token == null) {
        return AuthResult(
          success: false,
          message: 'No authentication token found',
        );
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        final userModel = UserModel.fromJson(data['user']);
        await _saveUserData(userModel);

        return AuthResult(
          success: true,
          message: 'User data retrieved successfully',
          user: userModel,
        );
      } else {
        return AuthResult(
          success: false,
          message: data['message'] ?? 'Failed to get user data',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Login user with temporary bypass option
  static Future<AuthResult> login(String emailOrPhone, String password) async {
    // Temporary bypass credentials
    // Temporary bypass credentials
//     const tempEmail = 'temp@example.com';
//     const tempPassword = 'temp1234';
//
// // Check for temporary credentials first
//     if (emailOrPhone == tempEmail && password == tempPassword) {
//       // Create a dummy UserModel for temp access
//       final tempUser = UserModel(
//         id: 'temp_id',
//         name: 'Temporary User',
//         email: tempEmail,
//         phone: '0000000000',
//         userType: UserType.buyer,      // Assuming temp user is a buyer, you can change this
//         profileImage: null,
//         createdAt: DateTime.now(),
//       );
//
//       // Save dummy user data locally, and set logged in
//       await _saveUserData(tempUser);
//       // Save a dummy token as well
//       await _saveToken('temp_token');
//
//       return AuthResult(
//         success: true,
//         message: 'Temporary login successful',
//         user: tempUser,
//       );
//     }

    // Original login logic below
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'emailOrPhone': emailOrPhone,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        final userModel = UserModel.fromJson(data['user']);

        // Save user data and token
        await _saveUserData(userModel);
        await _saveToken(data['token']);

        return AuthResult(
          success: true,
          message: data['message'],
          user: userModel,
        );
      } else {
        return AuthResult(
          success: false,
          message: data['message'] ?? 'Login failed',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Register new user
  static Future<AuthResult> signup(String name, String email, String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success']) {
        final userModel = UserModel.fromJson(data['user']);

        // Save user data and token
        await _saveUserData(userModel);
        await _saveToken(data['token']);

        return AuthResult(
          success: true,
          message: data['message'],
          user: userModel,
        );
      } else {
        return AuthResult(
          success: false,
          message: data['message'] ?? 'Signup failed',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Become a seller
  static Future<AuthResult> becomeSeller({
    required String storeName,
    required String storeAddress,
    String? businessLicense,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return AuthResult(
          success: false,
          message: 'Authentication required',
        );
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/become-seller'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'storeName': storeName,
          'storeAddress': storeAddress,
          'businessLicense': businessLicense,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        final userModel = UserModel.fromJson(data['user']);
        await _saveUserData(userModel);

        return AuthResult(
          success: true,
          message: data['message'],
          user: userModel,
        );
      } else {
        return AuthResult(
          success: false,
          message: data['message'] ?? 'Failed to become seller',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Save user data to local storage
  static Future<void> _saveUserData(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    await prefs.setBool(_isLoggedInKey, true);
  }

  /// Save token to local storage
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Logout user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    // Clear all auth data
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  /// Get auth token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Update user type (deprecated - use becomeSeller instead)
  @deprecated
  static Future<AuthResult> updateUserType(UserType userType) async {
    if (userType == UserType.seller) {
      return AuthResult(
        success: false,
        message: 'Use becomeSeller method to become a seller',
      );
    }

    return AuthResult(
      success: false,
      message: 'User type update not supported directly',
    );
  }
}

class AuthResult {
  final bool success;
  final String message;
  final UserModel? user;

  const AuthResult({
    required this.success,
    required this.message,
    this.user,
  });
}
