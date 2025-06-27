import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ----------- MODELS -----------

class SellerRequest {
  final String id;
  final String userName;
  final String userEmail;
  final String storeName;
  final String storeAddress;
  final String? businessLicense;
  final String status;
  final DateTime requestedAt;

  SellerRequest({
    required this.id,
    required this.userName,
    required this.userEmail,
    required this.storeName,
    required this.storeAddress,
    this.businessLicense,
    required this.status,
    required this.requestedAt,
  });

  factory SellerRequest.fromJson(Map<String, dynamic> json) {
    return SellerRequest(
      id: json['_id'] ?? '',
      userName: json['userName'] ?? json['userId']?['name'] ?? '',
      userEmail: json['userEmail'] ?? json['userId']?['email'] ?? '',
      storeName: json['storeName'] ?? '',
      storeAddress: json['storeAddress'] ?? '',
      businessLicense: json['businessLicense'],
      status: json['status'] ?? 'pending',
      requestedAt: DateTime.tryParse(json['requestedAt'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool isActive;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'user',
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class Seller {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String storeName;
  final String storeAddress;
  final bool isActive;
  final DateTime createdAt;

  Seller({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.storeName,
    required this.storeAddress,
    required this.isActive,
    required this.createdAt,
  });

  factory Seller.fromJson(Map<String, dynamic> json) {
    return Seller(
      id: json['_id'] ?? '',
      name: json['name'] ?? json['userId']?['name'] ?? '',
      email: json['email'] ?? json['userId']?['email'] ?? '',
      phone: json['phone'] ?? json['userId']?['phone'] ?? '',
      storeName: json['storeName'] ?? '',
      storeAddress: json['storeAddress'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String? imageUrl;
  final bool isAvailable;
  final String sellerId;
  final String? sellerName;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imageUrl,
    required this.isAvailable,
    required this.sellerId,
    this.sellerName,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      category: json['category'] ?? '',
      imageUrl: json['imageUrl'] ?? json['images']?[0],
      isAvailable: json['isAvailable'] ?? true,
      sellerId: json['sellerId'] ?? json['seller']?['_id'] ?? '',
      sellerName: json['seller']?['storeName'] ?? json['sellerName'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? category,
    String? imageUrl,
    bool? isAvailable,
    String? sellerId,
    String? sellerName,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// ----------- MAIN DASHBOARD WIDGET -----------

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with TickerProviderStateMixin {
  // API BASE URL
  static const String _baseUrl = "https://backend-ecommerce-app-co1r.onrender.com/api";

  // Dashboard stats
  int _totalUsers = 0;
  int _totalSellers = 0;
  int _totalProducts = 0;
  int _availableProducts = 0;
  int _hiddenProducts = 0;

  // Seller Requests
  List<SellerRequest> _pendingRequests = [];

  // Users
  List<User> _users = [];
  String _userSearchQuery = '';

  // Sellers
  List<Seller> _sellers = [];
  String _sellerSearchQuery = '';

  // Products
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  String _productSearchQuery = '';
  String _productFilter = 'all';

  // UI State
  bool _isLoading = true;
  int _tabIndex = 0;
  bool _isSidebarExpanded = true;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _userSearchController = TextEditingController();
  final TextEditingController _sellerSearchController = TextEditingController();
  final TextEditingController _productSearchController = TextEditingController();

  // --- INIT ---
  @override
  void initState() {
    super.initState();
    _loadAllData();
    _userSearchController.addListener(() {
      setState(() {
        _userSearchQuery = _userSearchController.text;
        _fetchUsers();
      });
    });
    _sellerSearchController.addListener(() {
      setState(() {
        _sellerSearchQuery = _sellerSearchController.text;
        _fetchSellers();
      });
    });
    
    _productSearchController.addListener(() {
      setState(() {
        _productSearchQuery = _productSearchController.text;
        _filterProducts();
      });
    });
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // --- FIXED API CALLS ---

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchProducts(), // Fetch products first to calculate stats
      _fetchSellerRequests(),
      _fetchUsers(),
      _fetchSellers(),
    ]);
    setState(() => _isLoading = false);
  }

  // FIXED: Calculate stats from actual data instead of separate API call
  void _calculateStats() {
    setState(() {
      _totalProducts = _products.length;
      _availableProducts = _products.where((p) => p.isAvailable).length;
      _hiddenProducts = _products.where((p) => !p.isAvailable).length;
      _totalUsers = _users.length;
      _totalSellers = _sellers.length;
    });
  }

  Future<void> _fetchSellerRequests() async {
    final token = await _getToken();
    if (token == null) return;
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/admin/seller-requests?status=pending&limit=100'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _pendingRequests = (data['requests'] as List)
              .map((e) => SellerRequest.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching seller requests: $e');
    }
  }

  Future<void> _fetchUsers() async {
    final token = await _getToken();
    if (token == null) return;
    try {
      String url = '$_baseUrl/admin/users?limit=100';
      if (_userSearchQuery.isNotEmpty) {
        url += '&search=${Uri.encodeComponent(_userSearchQuery)}';
      }
      final res = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _users = (data['users'] as List)
              .map((e) => User.fromJson(e as Map<String, dynamic>))
              .toList();
        });
        _calculateStats();
      }
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  Future<void> _fetchSellers() async {
    final token = await _getToken();
    if (token == null) return;
    try {
      String url = '$_baseUrl/admin/sellers?limit=100';
      if (_sellerSearchQuery.isNotEmpty) {
        url += '&search=${Uri.encodeComponent(_sellerSearchQuery)}';
      }
      final res = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _sellers = (data['sellers'] as List)
              .map((e) => Seller.fromJson(e as Map<String, dynamic>))
              .toList();
        });
        _calculateStats();
      }
    } catch (e) {
      print('Error fetching sellers: $e');
    }
  }

  // FIXED: Use correct API endpoint and better error handling
  Future<void> _fetchProducts() async {
    final token = await _getToken();
    if (token == null) {
      print('No auth token found');
      return;
    }
    
    try {
      print('Fetching products from API...');
      
      // Use the correct endpoint from your API documentation
      final res = await http.get(
        Uri.parse('$_baseUrl/items?limit=1000'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      print('Products API Response Status: ${res.statusCode}');
      print('Products API Response Body: ${res.body}');
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        
        // Handle different possible response structures
        List<dynamic> itemsList = [];
        if (data is Map<String, dynamic>) {
          itemsList = data['items'] ?? data['products'] ?? data['data'] ?? [];
        } else if (data is List) {
          itemsList = data;
        }
        
        print('Found ${itemsList.length} products');
        
        setState(() {
          _products = itemsList
              .map((e) => Product.fromJson(e as Map<String, dynamic>))
              .toList();
          
          print('Parsed ${_products.length} products successfully');
          
          // Calculate stats immediately after fetching
          _totalProducts = _products.length;
          _availableProducts = _products.where((p) => p.isAvailable).length;
          _hiddenProducts = _products.where((p) => !p.isAvailable).length;
          
          print('Stats - Total: $_totalProducts, Available: $_availableProducts, Hidden: $_hiddenProducts');
          
          _filterProducts();
        });
      } else if (res.statusCode == 401) {
        print('Unauthorized - token may be invalid');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication failed. Please login again.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        print('Failed to fetch products: ${res.statusCode} - ${res.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load products: ${res.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error fetching products: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _products.where((product) {
        bool matchesSearch = _productSearchQuery.isEmpty ||
            product.name.toLowerCase().contains(_productSearchQuery.toLowerCase()) ||
            product.category.toLowerCase().contains(_productSearchQuery.toLowerCase()) ||
            (product.sellerName?.toLowerCase().contains(_productSearchQuery.toLowerCase()) ?? false);
        
        bool matchesFilter = _productFilter == 'all' ||
            (_productFilter == 'available' && product.isAvailable) ||
            (_productFilter == 'hidden' && !product.isAvailable);

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  Future<void> _approveSellerRequest(String requestId) async {
    final token = await _getToken();
    if (token == null) return;
    final res = await http.post(
      Uri.parse('$_baseUrl/admin/seller-requests/$requestId/approve'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (res.statusCode == 200) {
      await _loadAllData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seller request approved')),
      );
    }
  }

  Future<void> _rejectSellerRequest(String requestId, String reason) async {
    final token = await _getToken();
    if (token == null) return;
    final res = await http.post(
      Uri.parse('$_baseUrl/admin/seller-requests/$requestId/reject'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'reason': reason}),
    );
    if (res.statusCode == 200) {
      await _loadAllData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seller request rejected')),
      );
    }
  }

  Future<void> _toggleUserStatus(String userId, bool isActive) async {
    final token = await _getToken();
    if (token == null) return;
    try {
      final res = await http.patch(
        Uri.parse('$_baseUrl/admin/users/$userId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'isActive': isActive}),
      );
      if (res.statusCode == 200) {
        await _fetchUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ${isActive ? 'activated' : 'deactivated'} successfully')),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update user status')),
      );
    }
  }

  Future<void> _toggleSellerStatus(String sellerId, bool isActive) async {
    final token = await _getToken();
    if (token == null) return;
    try {
      final res = await http.patch(
        Uri.parse('$_baseUrl/admin/sellers/$sellerId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'isActive': isActive}),
      );
      if (res.statusCode == 200) {
        await _fetchSellers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Seller ${isActive ? 'activated' : 'deactivated'} successfully')),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update seller status')),
      );
    }
  }

  // FIXED: Use correct API endpoint for toggling product availability
  Future<void> _toggleProductAvailability(String productId, bool isAvailable) async {
    final token = await _getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication token not found')),
      );
      return;
    }

    try {
      print('Toggling product $productId to ${isAvailable ? 'available' : 'unavailable'}');
      
      // Use the correct endpoint from your API documentation
      final res = await http.patch(
        Uri.parse('$_baseUrl/admin/items/$productId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'isAvailable': isAvailable}),
      );
      
      print('Toggle response status: ${res.statusCode}');
      print('Toggle response body: ${res.body}');
      
      if (res.statusCode == 200) {
        // Update the product in the local list immediately
        setState(() {
          final productIndex = _products.indexWhere((p) => p.id == productId);
          if (productIndex != -1) {
            _products[productIndex] = _products[productIndex].copyWith(isAvailable: isAvailable);
            
            // Recalculate stats
            _availableProducts = _products.where((p) => p.isAvailable).length;
            _hiddenProducts = _products.where((p) => !p.isAvailable).length;
            
            // Reapply filters
            _filterProducts();
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product ${isAvailable ? 'made visible to customers' : 'hidden from customers'} successfully'),
            backgroundColor: isAvailable ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('API request failed with status ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      print('Error in _toggleProductAvailability: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update product status: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // --- UI BUILD (keeping the same UI code) ---

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF151A24),
        cardColor: const Color(0xFF23293A),
        dividerColor: Colors.grey[700],
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colors.blueAccent,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF23293A),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        key: _scaffoldKey,
        body: Padding(
          padding: const EdgeInsets.only(top: 40.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final sidebarWidth = constraints.maxWidth < 768
                  ? 60.0
                  : (_isSidebarExpanded ? 250.0 : 70.0);

              return Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: sidebarWidth,
                    child: _buildSidebar(constraints.maxWidth < 768),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        _buildTopBar(),
                        Expanded(
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : IndexedStack(
                            index: _tabIndex,
                            children: [
                              _buildOverviewTab(),
                              _buildRequestsTab(),
                              _buildSellersTab(),
                              _buildUsersTab(),
                              _buildProductsTab(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF23293A),
        border: Border(
          bottom: BorderSide(color: Color(0xFF151A24), width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isSidebarExpanded ? Icons.menu_open : Icons.menu,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isSidebarExpanded = !_isSidebarExpanded;
              });
            },
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              "Admin Dashboard",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Add refresh button for debugging
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _loadAllData();
            },
            tooltip: "Refresh Data",
          ),
          IconButton(
            icon: const Icon(Icons.home_rounded, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacementNamed(context, "/home");
            },
            tooltip: "Go to Home",
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(bool isSmallScreen) {
    final bool showExpanded = !isSmallScreen && _isSidebarExpanded;

    return Container(
      color: const Color(0xFF23293A),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showExpanded) ...[
            const Row(
              children: [
                Icon(Icons.shopping_cart, color: Colors.blueAccent, size: 28),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "GroceryAdmin",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ] else ...[
            const Center(
              child: Icon(Icons.shopping_cart, color: Colors.blueAccent, size: 28),
            ),
            const SizedBox(height: 40),
          ],
          _sidebarNavItem(Icons.dashboard, "Dashboard", 0, showExpanded),
          _sidebarNavItem(Icons.pending_actions, "Seller Requests", 1, showExpanded),
          _sidebarNavItem(Icons.store, "Sellers", 2, showExpanded),
          _sidebarNavItem(Icons.people, "Users", 3, showExpanded),
          _sidebarNavItem(Icons.inventory, "Products", 4, showExpanded),
        ],
      ),
    );
  }

  Widget _sidebarNavItem(IconData icon, String text, int index, bool showText) {
    final bool selected = _tabIndex == index;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        setState(() {
          _tabIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.blueAccent.withOpacity(0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? Colors.blueAccent : Colors.grey[400],
            ),
            if (showText) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: selected ? Colors.blueAccent : Colors.grey[300],
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- TABS (keeping the same UI code for brevity) ---

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "Overview",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
              const Spacer(),
              // Debug info
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Text(
                  'Last updated: ${DateTime.now().toString().substring(11, 19)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 30),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 1200) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _statCard("No. of Users", _totalUsers.toString(), Icons.people)),
                        const SizedBox(width: 20),
                        Expanded(child: _statCard("No. of Sellers", _totalSellers.toString(), Icons.store_rounded)),
                        const SizedBox(width: 20),
                        Expanded(child: _statCard("Total Products", _totalProducts.toString(), Icons.inventory)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _statCard("Available Products", _availableProducts.toString(), Icons.visibility, Colors.green)),
                        const SizedBox(width: 20),
                        Expanded(child: _statCard("Hidden Products", _hiddenProducts.toString(), Icons.visibility_off, Colors.orange)),
                        const SizedBox(width: 20),
                        Expanded(child: Container()),
                      ],
                    ),
                  ],
                );
              } else if (constraints.maxWidth > 900) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _statCard("No. of Users", _totalUsers.toString(), Icons.people)),
                        const SizedBox(width: 20),
                        Expanded(child: _statCard("No. of Sellers", _totalSellers.toString(), Icons.store_rounded)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _statCard("Total Products", _totalProducts.toString(), Icons.inventory)),
                        const SizedBox(width: 20),
                        Expanded(child: _statCard("Available Products", _availableProducts.toString(), Icons.visibility, Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _statCard("Hidden Products", _hiddenProducts.toString(), Icons.visibility_off, Colors.orange),
                  ],
                );
              } else if (constraints.maxWidth > 600) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _statCard("No. of Users", _totalUsers.toString(), Icons.people)),
                        const SizedBox(width: 20),
                        Expanded(child: _statCard("No. of Sellers", _totalSellers.toString(), Icons.store_rounded)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _statCard("Total Products", _totalProducts.toString(), Icons.inventory),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _statCard("Available", _availableProducts.toString(), Icons.visibility, Colors.green)),
                        const SizedBox(width: 20),
                        Expanded(child: _statCard("Hidden", _hiddenProducts.toString(), Icons.visibility_off, Colors.orange)),
                      ],
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _statCard("No. of Users", _totalUsers.toString(), Icons.people),
                    const SizedBox(height: 20),
                    _statCard("No. of Sellers", _totalSellers.toString(), Icons.store_rounded),
                    const SizedBox(height: 20),
                    _statCard("Total Products", _totalProducts.toString(), Icons.inventory),
                    const SizedBox(height: 20),
                    _statCard("Available Products", _availableProducts.toString(), Icons.visibility, Colors.green),
                    const SizedBox(height: 20),
                    _statCard("Hidden Products", _hiddenProducts.toString(), Icons.visibility_off, Colors.orange),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, [Color? iconColor]) {
    return Container(
      padding: const EdgeInsets.all(24),
      constraints: const BoxConstraints(minHeight: 120),
      decoration: BoxDecoration(
        color: const Color(0xFF23293A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 36, color: iconColor ?? Colors.blueAccent),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Keep all other UI methods the same...
  Widget _buildRequestsTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Pending Seller Requests",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _pendingRequests.isEmpty
                ? const Center(
                child: Text(
                  "No pending seller requests.",
                  style: TextStyle(color: Colors.grey),
                ))
                : ListView.builder(
              itemCount: _pendingRequests.length,
              itemBuilder: (context, index) {
                return _sellerRequestCard(_pendingRequests[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sellerRequestCard(SellerRequest req) {
    return Card(
      color: const Color(0xFF23293A),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              req.storeName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Text(
              'Owner: ${req.userName} (${req.userEmail})',
              style: const TextStyle(color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Address: ${req.storeAddress}',
              style: const TextStyle(color: Colors.grey),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            if (req.businessLicense != null) ...[
              const SizedBox(height: 4),
              Text(
                'Business License: ${req.businessLicense}',
                style: const TextStyle(color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 400) {
                  return Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text("Approve"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: () => _approveSellerRequest(req.id),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text("Reject"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => _showRejectDialog(req.id),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text("Approve"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: () => _approveSellerRequest(req.id),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text("Reject"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => _showRejectDialog(req.id),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRejectDialog(String requestId) async {
    String? reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: const Color(0xFF23293A),
          title: const Text(
            'Reason for rejection',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Enter reason',
              hintStyle: TextStyle(color: Colors.grey),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text("Reject"),
            ),
          ],
        );
      },
    );
    if (reason != null && reason.trim().isNotEmpty) {
      await _rejectSellerRequest(requestId, reason.trim());
    }
  }

  Widget _buildSellersTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Sellers",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 20),
          _sellerSearchBar(),
          const SizedBox(height: 20),
          Expanded(
            child: _sellers.isEmpty
                ? const Center(
                child: Text(
                  "No sellers found.",
                  style: TextStyle(color: Colors.grey),
                ))
                : ListView.builder(
              itemCount: _sellers.length,
              itemBuilder: (context, index) {
                return _sellerCard(_sellers[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sellerSearchBar() {
    return TextField(
      controller: _sellerSearchController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF151A24),
        hintText: 'Search sellers...',
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _sellerCard(Seller seller) {
    return Card(
        color: const Color(0xFF23293A),
    margin: const EdgeInsets.only(bottom: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
    padding: const EdgeInsets.all(16),
    child: LayoutBuilder(
    builder: (context, constraints) {
    if (constraints.maxWidth > 500) {
    return Row(
    children: [
    CircleAvatar(
    radius: 24,
    backgroundColor: seller.isActive ? Colors.green : Colors.red,
    child: Icon(
    Icons.store,
    color: Colors.white,
    size: 24,
    ),
    ),
    const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              seller.storeName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${seller.name} (${seller.email})',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              seller.storeAddress,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
      const SizedBox(width: 16),
      Switch(
        value: seller.isActive,
        onChanged: (value) => _toggleSellerStatus(seller.id, value),
        activeColor: Colors.green,
      ),
    ],
    );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: seller.isActive ? Colors.green : Colors.red,
                child: Icon(
                  Icons.store,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  seller.storeName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Switch(
                value: seller.isActive,
                onChanged: (value) => _toggleSellerStatus(seller.id, value),
                activeColor: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${seller.name} (${seller.email})',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            seller.storeAddress,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      );
    }
    },
    ),
    ),
    );
  }

  Widget _buildUsersTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Users",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 20),
          _userSearchBar(),
          const SizedBox(height: 20),
          Expanded(
            child: _users.isEmpty
                ? const Center(
                    child: Text(
                      "No users found.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      return _userCard(_users[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _userSearchBar() {
    return TextField(
      controller: _userSearchController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF151A24),
        hintText: 'Search users...',
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _userCard(User user) {
    return Card(
      color: const Color(0xFF23293A),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 500) {
              return Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: user.isActive ? Colors.green : Colors.red,
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.phone,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Role: ${user.role}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Switch(
                    value: user.isActive,
                    onChanged: (value) => _toggleUserStatus(user.id, value),
                    activeColor: Colors.green,
                  ),
                ],
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: user.isActive ? Colors.green : Colors.red,
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          user.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Switch(
                        value: user.isActive,
                        onChanged: (value) => _toggleUserStatus(user.id, value),
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.phone,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Role: ${user.role}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildProductsTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "Products",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Showing ${_filteredProducts.length} of ${_totalProducts}',
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(child: _productSearchBar()),
              const SizedBox(width: 16),
              _productFilterDropdown(),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              _filterChip('All', 'all', _totalProducts),
              const SizedBox(width: 8),
              _filterChip('Available', 'available', _availableProducts, Colors.green),
              const SizedBox(width: 8),
              _filterChip('Hidden', 'hidden', _hiddenProducts, Colors.orange),
            ],
          ),
          
          const SizedBox(height: 20),
          
          Expanded(
            child: _filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _productFilter == 'all' ? Icons.inventory_2_outlined : 
                          _productFilter == 'available' ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 64,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _productFilter == 'all' ? "No products found." :
                          _productFilter == 'available' ? "No available products found." : "No hidden products found.",
                          style: const TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total products in database: $_totalProducts',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      return _productCard(_filteredProducts[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, int count, [Color? color]) {
    final isSelected = _productFilter == value;
    return InkWell(
      onTap: () {
        setState(() {
          _productFilter = value;
          _filterProducts();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? (color ?? Colors.blueAccent).withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? (color ?? Colors.blueAccent)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            color: isSelected 
                ? (color ?? Colors.blueAccent)
                : Colors.grey[300],
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _productFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151A24),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: _productFilter,
        dropdownColor: const Color(0xFF23293A),
        underline: Container(),
        icon: const Icon(Icons.filter_list, color: Colors.grey, size: 20),
        items: [
          DropdownMenuItem(value: 'all', child: Text('All Products ($_totalProducts)', style: const TextStyle(color: Colors.white))),
          DropdownMenuItem(value: 'available', child: Text('Available ($_availableProducts)', style: const TextStyle(color: Colors.green))),
          DropdownMenuItem(value: 'hidden', child: Text('Hidden ($_hiddenProducts)', style: const TextStyle(color: Colors.orange))),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _productFilter = value;
              _filterProducts();
            });
          }
        },
      ),
    );
  }

  Widget _productSearchBar() {
    return TextField(
      controller: _productSearchController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF151A24),
        hintText: 'Search products by name, category, or seller...',
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _productCard(Product product) {
    return Card(
      color: const Color(0xFF23293A),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: product.isAvailable ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[800],
                          ),
                          child: product.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    product.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.inventory,
                                        color: Colors.grey[400],
                                        size: 40,
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  Icons.inventory,
                                  color: Colors.grey[400],
                                  size: 40,
                                ),
                        ),
                        if (!product.isAvailable)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.black.withOpacity(0.7),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.visibility_off,
                                  color: Colors.orange,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  product.name,
                                  style: TextStyle(
                                    color: product.isAvailable ? Colors.white : Colors.grey[400],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    decoration: product.isAvailable ? null : TextDecoration.lineThrough,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: product.isAvailable ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      product.isAvailable ? Icons.visibility : Icons.visibility_off,
                                      size: 12,
                                      color: product.isAvailable ? Colors.green : Colors.orange,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      product.isAvailable ? 'VISIBLE' : 'HIDDEN',
                                      style: TextStyle(
                                        color: product.isAvailable ? Colors.green : Colors.orange,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.description,
                            style: TextStyle(
                              color: product.isAvailable ? Colors.grey : Colors.grey[600],
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                '\$${product.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: product.isAvailable ? Colors.green : Colors.grey[500],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  product.category,
                                  style: const TextStyle(
                                    color: Colors.blueAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (product.sellerName != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Seller: ${product.sellerName}',
                              style: TextStyle(
                                color: product.isAvailable ? Colors.grey : Colors.grey[600],
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      children: [
                        Text(
                          product.isAvailable ? 'Customers can see this' : 'Hidden from customers',
                          style: TextStyle(
                            color: product.isAvailable ? Colors.green : Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Switch(
                          value: product.isAvailable,
                          onChanged: (value) => _toggleProductAvailability(product.id, value),
                          activeColor: Colors.green,
                          inactiveThumbColor: Colors.orange,
                          inactiveTrackColor: Colors.orange.withOpacity(0.3),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.isAvailable ? 'VISIBLE' : 'HIDDEN',
                          style: TextStyle(
                            color: product.isAvailable ? Colors.green : Colors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[800],
                              ),
                              child: product.imageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        product.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            Icons.inventory,
                                            color: Colors.grey[400],
                                            size: 30,
                                          );
                                        },
                                      ),
                                    )
                                  : Icon(
                                      Icons.inventory,
                                      color: Colors.grey[400],
                                      size: 30,
                                    ),
                            ),
                            if (!product.isAvailable)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.black.withOpacity(0.7),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.visibility_off,
                                      color: Colors.orange,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: TextStyle(
                                  color: product.isAvailable ? Colors.white : Colors.grey[400],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  decoration: product.isAvailable ? null : TextDecoration.lineThrough,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '\$${product.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: product.isAvailable ? Colors.green : Colors.grey[500],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: product.isAvailable ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    product.isAvailable ? Icons.visibility : Icons.visibility_off,
                                    size: 10,
                                    color: product.isAvailable ? Colors.green : Colors.orange,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    product.isAvailable ? 'VISIBLE' : 'HIDDEN',
                                    style: TextStyle(
                                      color: product.isAvailable ? Colors.green : Colors.orange,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: product.isAvailable,
                              onChanged: (value) => _toggleProductAvailability(product.id, value),
                              activeColor: Colors.green,
                              inactiveThumbColor: Colors.orange,
                              inactiveTrackColor: Colors.orange.withOpacity(0.3),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description,
                      style: TextStyle(
                        color: product.isAvailable ? Colors.grey : Colors.grey[600],
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.category,
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (product.sellerName != null) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Seller: ${product.sellerName}',
                              style: TextStyle(
                                color: product.isAvailable ? Colors.grey : Colors.grey[600],
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: product.isAvailable ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: product.isAvailable ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            product.isAvailable ? Icons.visibility : Icons.visibility_off,
                            size: 16,
                            color: product.isAvailable ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              product.isAvailable 
                                  ? 'This product is visible to customers and can be purchased'
                                  : 'This product is hidden from customers and cannot be purchased',
                              style: TextStyle(
                                color: product.isAvailable ? Colors.green : Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
