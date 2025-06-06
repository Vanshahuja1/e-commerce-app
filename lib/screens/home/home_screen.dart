import 'package:flutter/material.dart';

import '/models/user_model.dart';
import '/services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? _currentUser;
  int _cartItemCount = 0;

  @override


  Future<void> _loadUser() async {
    _currentUser = await AuthService.getCurrentUser();
    if (mounted) {
      setState(() {});
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Header (AppBar)
      appBar: AppBar(
        title: const Text('FreshMart'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Cart Icon
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/cart');
                },
                icon: const Icon(Icons.shopping_cart),
              ),
              if (_cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_cartItemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // Profile/Menu
          PopupMenuButton(
            icon: const Icon(Icons.person),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Profile'),
                onTap: () {
                  Navigator.pushNamed(context, '/profile');
                },
              ),
              if (_currentUser?.userType == UserType.seller)
                PopupMenuItem(
                  child: const Text('Seller Dashboard'),
                  onTap: () {
                    Navigator.pushNamed(context, '/seller-dashboard');
                  },
                ),
              if (_currentUser?.userType == UserType.buyer)
                PopupMenuItem(
                  child: const Text('Become a Seller'),
                  onTap: () {
                    Navigator.pushNamed(context, '/become-seller');
                  },
                ),
              PopupMenuItem(
                child: const Text('Logout'),
                onTap: () async {
                  await AuthService.logout();
                  if (mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
              ),
            ],
          ),
        ],
      ),

      // Body (Empty/Minimal content)
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade50,
              Colors.white,
            ],
          ),
        ),
        child: const Center(
          child: Text(
            'Welcome to FreshMart',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ),
      ),

      // Footer (Bottom Navigation Bar)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFooterItem(
                  icon: Icons.home,
                  label: 'Home',
                  isActive: true,
                  onTap: () {},
                ),
                _buildFooterItem(
                  icon: Icons.search,
                  label: 'Search',
                  onTap: () {
                    // Navigate to search
                  },
                ),
                _buildFooterItem(
                  icon: Icons.shopping_cart,
                  label: 'Cart',
                  onTap: () {
                    Navigator.pushNamed(context, '/cart');
                  },
                ),
                _buildFooterItem(
                  icon: Icons.person,
                  label: 'Seller',
                  onTap: () {
                    Navigator.pushNamed(context, '/become-seller');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterItem({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.green.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.green : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? Colors.green : Colors.grey.shade600,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}