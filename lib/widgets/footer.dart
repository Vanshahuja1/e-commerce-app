import 'package:flutter/material.dart';
import '/models/user_model.dart';

class Footer extends StatelessWidget {
  final UserModel? currentUser;
  final VoidCallback onHomeTap;
  final VoidCallback onSearchTap;
  final VoidCallback onCartTap;
  final VoidCallback onSellerTap;
  final VoidCallback? onAdminTap; // New: callback for admin tap
  final int currentIndex;

  const Footer({
    Key? key,
    this.currentUser,
    required this.onHomeTap,
    required this.onSearchTap,
    required this.onCartTap,
    required this.onSellerTap,
    this.onAdminTap, // New: admin tap
    this.currentIndex = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade100.withOpacity(0.5),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final iconSize = constraints.maxWidth > 600 ? 30.0 : 24.0;
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth > 600 ? 40 : 16,
                vertical: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildFooterItem(
                    icon: Icons.home,
                    label: 'Home',
                    isActive: currentIndex == 0,
                    iconSize: iconSize,
                    onTap: onHomeTap,
                  ),
                  _buildFooterItem(
                    icon: Icons.search,
                    label: 'Search',
                    isActive: currentIndex == 1,
                    iconSize: iconSize,
                    onTap: onSearchTap,
                  ),
                  _buildFooterItem(
                    icon: Icons.shopping_cart,
                    label: 'Cart',
                    isActive: currentIndex == 2,
                    iconSize: iconSize,
                    onTap: onCartTap,
                  ),
                  // Show Admin if userType is admin
                  if (currentUser?.userType == UserType.admin)
                    _buildFooterItem(
                      icon: Icons.admin_panel_settings,
                      label: 'Admin',
                      isActive: currentIndex == 3,
                      iconSize: iconSize,
                      onTap: onAdminTap ??
                          () {
                            Navigator.of(context).pushNamed('/admin');
                          },
                      highlight: true,
                    )
                  // Otherwise show Seller (only if not admin)
                  else
                    _buildFooterItem(
                      icon: Icons.storefront,
                      label: currentUser?.userType == UserType.seller
                          ? 'Dashboard'
                          : 'Seller',
                      isActive: currentIndex == 3,
                      iconSize: iconSize,
                      onTap: onSellerTap,
                      highlight: currentUser?.userType == UserType.seller,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFooterItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    bool highlight = false,
    double iconSize = 24.0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
        decoration: BoxDecoration(
          color: isActive || highlight
              ? Colors.green.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color:
                  isActive || highlight ? Colors.green.shade700 : Colors.grey.shade600,
              size: iconSize,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isActive || highlight
                    ? Colors.green.shade700
                    : Colors.grey.shade600,
                fontWeight: isActive || highlight
                    ? FontWeight.bold
                    : FontWeight.normal,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}