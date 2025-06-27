import 'package:flutter/material.dart';
import '/models/user_model.dart';
import '/services/auth_service.dart';
import '/services/cart_service.dart';

class Header extends StatefulWidget implements PreferredSizeWidget {
  final int cartItemCount;
  final UserModel? currentUser;
  final VoidCallback onCartTap;
  final VoidCallback onProfileTap;
  final VoidCallback onSellerTap;
  final VoidCallback onLogout;

  const Header({
    Key? key,
    required this.cartItemCount,
    this.currentUser,
    required this.onCartTap,
    required this.onProfileTap,
    required this.onSellerTap,
    required this.onLogout,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  int _realTimeCartCount = 0;
  bool _isLoadingCart = false;

  @override
  void initState() {
    super.initState();
    _loadRealTimeCartCount();
  }

  @override
  void didUpdateWidget(Header oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update real-time count when widget updates
    if (oldWidget.cartItemCount != widget.cartItemCount) {
      _loadRealTimeCartCount();
    }
  }

  Future<void> _loadRealTimeCartCount() async {
    if (_isLoadingCart) return;
    
    setState(() {
      _isLoadingCart = true;
    });

    try {
      final count = await CartService.getCartItemCount();
      if (mounted) {
        setState(() {
          _realTimeCartCount = count;
          _isLoadingCart = false;
        });
      }
    } catch (e) {
      print('Error loading cart count: $e');
      if (mounted) {
        setState(() {
          _realTimeCartCount = widget.cartItemCount; // Fallback to passed count
          _isLoadingCart = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;
    final isMobile = screenWidth < 768;

    return AppBar(
      backgroundColor: Colors.green.shade700,
      elevation: 0,
      automaticallyImplyLeading: isMobile, // Show hamburger menu only on mobile
      title: _buildTitle(isDesktop, isTablet, isMobile),
      actions: _buildActions(isDesktop, isTablet, isMobile, context),
      centerTitle: false, // Center title on mobile
    );
  }

  Widget _buildTitle(bool isDesktop, bool isTablet, bool isMobile) {
    // Responsive icon and text sizes
    double iconSize = isDesktop ? 36 : (isTablet ? 32 : 28);
    double fontSize = isDesktop ? 32 : (isTablet ? 28 : 24);
    double spacing = isDesktop ? 12 : (isTablet ? 10 : 8);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.spa, color: Colors.white, size: iconSize),
        SizedBox(width: spacing),
        Flexible(
          child: Text(
            'FreshCart',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
              letterSpacing: isMobile ? 0.8 : 1.2,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActions(bool isDesktop, bool isTablet, bool isMobile, BuildContext context) {
    List<Widget> actions = [];

    if (isDesktop) {
      // Desktop: Show all actions in the app bar
      actions.addAll([
        _buildSearchButton(context),
        const SizedBox(width: 8),
        _buildCartButton(),
        const SizedBox(width: 8),
        _buildProfileMenu(context),
        const SizedBox(width: 16),
      ]);
    } else if (isTablet) {
      // Tablet: Show essential actions, group some in menu
      actions.addAll([
        _buildSearchButton(context),
        const SizedBox(width: 4),
        _buildCartButton(),
        const SizedBox(width: 4),
        _buildProfileMenu(context),
        const SizedBox(width: 8),
      ]);
    } else {
      // Mobile: Minimal actions, most in drawer/menu
      actions.addAll([
        _buildCartButton(),
        const SizedBox(width: 4),
        _buildMobileMenu(context),
        const SizedBox(width: 8),
      ]);
    }

    return actions;
  }

  Widget _buildSearchButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.search),
      color: Colors.white,
      onPressed: () => Navigator.pushNamed(context, '/search'),
      tooltip: 'Search',
    );
  }

  Widget _buildCartButton() {
    // Use real-time count if available, otherwise fallback to passed count
    final displayCount = _realTimeCartCount > 0 ? _realTimeCartCount : widget.cartItemCount;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart),
          color: Colors.white,
          onPressed: () {
            widget.onCartTap();
            // Refresh cart count when cart is accessed
            _loadRealTimeCartCount();
          },
          tooltip: 'Cart',
          iconSize: 28,
        ),
        if (displayCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1),
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: _isLoadingCart
                  ? SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 1,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      displayCount > 99 ? '99+' : '$displayCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileMenu(BuildContext context) {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.person, color: Colors.white),
      color: Colors.white,
      elevation: 8,
      onSelected: (value) async {
        switch (value) {
          case 0:
            widget.onProfileTap();
            break;
          case 1:
            widget.onSellerTap();
            break;
          case 2:
            widget.onLogout();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<int>(
          value: 0,
          child: ListTile(
            leading: Icon(Icons.account_circle),
            title: Text('Profile'),
            dense: true,
          ),
        ),
        PopupMenuItem<int>(
          value: 1,
          child: ListTile(
            leading: Icon(
              widget.currentUser?.userType == UserType.seller
                  ? Icons.dashboard
                  : Icons.store,
            ),
            title: Text(
              widget.currentUser?.userType == UserType.seller
                  ? 'Seller Dashboard'
                  : 'Become a Seller',
            ),
            dense: true,
          ),
        ),
        const PopupMenuItem<int>(
          value: 2,
          child: ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            dense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileMenu(BuildContext context) {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      color: Colors.white,
      elevation: 8,
      onSelected: (value) async {
        switch (value) {
          case 0:
            Navigator.pushNamed(context, '/search');
            break;
          case 1:
            widget.onProfileTap();
            break;
          case 2:
            widget.onSellerTap();
            break;
          case 3:
            widget.onLogout();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<int>(
          value: 0,
          child: ListTile(
            leading: Icon(Icons.search),
            title: Text('Search'),
            dense: true,
          ),
        ),
        const PopupMenuItem<int>(
          value: 1,
          child: ListTile(
            leading: Icon(Icons.account_circle),
            title: Text('Profile'),
            dense: true,
          ),
        ),
        PopupMenuItem<int>(
          value: 2,
          child: ListTile(
            leading: Icon(
              widget.currentUser?.userType == UserType.seller
                  ? Icons.dashboard
                  : Icons.store,
            ),
            title: Text(
              widget.currentUser?.userType == UserType.seller
                  ? 'Seller Dashboard'
                  : 'Become a Seller',
            ),
            dense: true,
          ),
        ),
        const PopupMenuItem<int>(
          value: 3,
          child: ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            dense: true,
          ),
        ),
      ],
    );
  }
}
