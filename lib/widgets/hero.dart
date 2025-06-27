import 'package:flutter/material.dart';
import 'dart:async';

class HeroSection extends StatefulWidget {
  const HeroSection({Key? key}) : super(key: key);

  @override
  _HeroSectionState createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> {
  late PageController _pageController;
  late Timer _timer;
  int _currentPage = 0;
  final int _totalPages = 5; 

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 2, milliseconds: 300), (timer) {
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % _totalPages;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Welcome Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.shade200,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fresh Groceries',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Delivered to your doorstep',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/search'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Shop Now'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Promotional Banners with Auto-scroll
          SizedBox(
            height: 120,
            child: PageView.builder(
              controller: _pageController,
              itemCount: null, // Infinite scroll
              itemBuilder: (context, index) {
                final bannerIndex = index % _totalPages;
                return _buildPromoBannerByIndex(bannerIndex);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBannerByIndex(int index) {
    switch (index) {
      case 0:
        return _buildPromoBanner(
          'Fresh Fruits',
          'Up to 30% OFF',
          Colors.orange.shade400,
          Icons.apple,
        );
      case 1:
        return _buildPromoBanner(
          'Vegetables',
          'Farm Fresh Daily',
          Colors.green.shade400,
          Icons.eco,
        );
      case 2:
        return _buildPromoBanner(
          'Dairy Products',
          'Pure & Natural',
          Colors.blue.shade400,
          Icons.local_drink,
        );
      case 3:
        return _buildPromoBanner(
          'Easy Returns',
          'Return up to 6 hours',
          Colors.purple.shade400,
          Icons.refresh,
        );
      case 4:
        return _buildContactBanner();
      default:
        return _buildPromoBanner(
          'Fresh Fruits',
          'Up to 30% OFF',
          Colors.orange.shade400,
          Icons.apple,
        );
    }
  }

  Widget _buildPromoBanner(String title, String subtitle, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: Colors.white),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade400,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.contact_phone, size: 40, color: Colors.white),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Contact Us',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '+91 98765 43210',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                Text(
                  'support@freshgrocery.com',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}