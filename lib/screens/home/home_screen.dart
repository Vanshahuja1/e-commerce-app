import 'package:flutter/material.dart';
import '/models/user_model.dart';
import '/services/auth_service.dart';
import '/services/cart_service.dart';
import '/widgets/header.dart';
import '/widgets/hero.dart';
import '/widgets/category.dart';
import '/widgets/products.dart';
import '/widgets/footer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? _currentUser;
  int _cartItemCount = 0;
  final GlobalKey<ProductsSectionState> _productsKey = GlobalKey<ProductsSectionState>();

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadCartCount();
  }

  Future<void> _loadUser() async {
    _currentUser = await AuthService.getCurrentUser();
    if (mounted) setState(() {});
  }

  Future<void> _loadCartCount() async {
    _cartItemCount = await CartService.getCartItemCount();
    if (mounted) setState(() {});
  }

  // Refresh method that will be called when user pulls to refresh
  Future<void> _onRefresh() async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                const Text('Refreshing...'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 1),
          ),
        );
      }

      // Refresh all data concurrently
      await Future.wait([
        _loadUser(),
        _loadCartCount(),
        _refreshProducts(),
      ]);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 16),
                const Text('Refreshed successfully!'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 16),
                Text('Refresh failed: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Method to refresh products
  Future<void> _refreshProducts() async {
    if (_productsKey.currentState != null) {
      await _productsKey.currentState!.refreshProducts();
    }
  }

  // Add this method to refresh cart count when returning from other screens
  void _refreshCartCount() {
    _loadCartCount();
  }

  void _handleSellerNavigation() {
    if (_currentUser?.userType == UserType.seller) {
      Navigator.pushNamed(context, '/seller-dashboard');
    } else {
      Navigator.pushNamed(context, '/become-seller');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: Header(
        cartItemCount: _cartItemCount,
        currentUser: _currentUser,
        onCartTap: () async {
          await Navigator.pushNamed(context, '/cart');
          // Refresh cart count when returning from cart
          _refreshCartCount();
        },
        onProfileTap: () async {
          await Navigator.pushNamed(context, '/profile');
          // Refresh user data when returning from profile
          _loadUser();
        },
        onSellerTap: _handleSellerNavigation,
        onLogout: () async {
          await AuthService.logout();
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        },
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: Colors.green.shade700,
        backgroundColor: Colors.white,
        strokeWidth: 3,
        displacement: 40,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // This ensures pull-to-refresh works even when content doesn't fill the screen
          child: Column(
            children: [
              const HeroSection(),
              const SizedBox(height: 24),
              const CategorySection(),
              const SizedBox(height: 24),
              ProductsSection(
                key: _productsKey,
                refreshCartCount: _refreshCartCount,
              ),
              const SizedBox(height: 24),
              // Add some extra space at the bottom to ensure smooth scrolling
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Footer(
        currentUser: _currentUser,
        currentIndex: 0,
        onHomeTap: () {},
        onSearchTap: () => Navigator.pushNamed(context, '/search'),
        onCartTap: () async {
          await Navigator.pushNamed(context, '/cart');
          _refreshCartCount();
        },
        onSellerTap: _handleSellerNavigation,
      ),
    );
  }
}
