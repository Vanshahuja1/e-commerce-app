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
  static const String _userIdKey = 'user_id'; // Add this key
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
    // Original login logic
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

  /// Register new user (MODIFIED for OTP verification)
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
        // DON'T save user data and token yet - wait for OTP verification
        return AuthResult(
          success: true,
          message: data['message'] ?? 'Account created! Please verify your email with the OTP sent.',
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

  /// Verify OTP after signup (NEW METHOD)
  static Future<AuthResult> verifyOTP(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        final userModel = UserModel.fromJson(data['user']);

        // NOW save user data and token after successful verification
        await _saveUserData(userModel);
        await _saveToken(data['token']);

        return AuthResult(
          success: true,
          message: data['message'] ?? 'Email verified successfully!',
          user: userModel,
        );
      } else {
        return AuthResult(
          success: false,
          message: data['message'] ?? 'Invalid OTP. Please try again.',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Resend OTP (NEW METHOD)
  static Future<AuthResult> resendOTP(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/resend-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return AuthResult(
          success: true,
          message: data['message'] ?? 'OTP sent successfully!',
        );
      } else {
        return AuthResult(
          success: false,
          message: data['message'] ?? 'Failed to resend OTP. Please try again.',
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

  /// Save user data to local storage - MODIFIED to also save user ID separately
  static Future<void> _saveUserData(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    await prefs.setString(_userIdKey, user.id); // Save user ID separately
    await prefs.setBool(_isLoggedInKey, true);
  }

  /// Save token to local storage
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Logout user - MODIFIED to also clear user ID
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    // Clear all auth data
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_userIdKey); // Clear user ID as well
    await prefs.setBool(_isLoggedInKey, false);
  }

  /// Get auth token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Get user ID - NEW METHOD
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
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
