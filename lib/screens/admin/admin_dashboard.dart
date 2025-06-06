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

  // Seller Requests
  List<SellerRequest> _pendingRequests = [];

  // Users
  List<User> _users = [];
  String _userSearchQuery = '';
  bool _showOnlyActiveUsers = false;

  // Sellers
  List<Seller> _sellers = [];
  String _sellerSearchQuery = '';
  bool _showOnlyActiveSellers = false;

  // UI State
  bool _isLoading = true;
  int _tabIndex = 0;
  bool _isSidebarExpanded = true;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _userSearchController = TextEditingController();
  final TextEditingController _sellerSearchController = TextEditingController();

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
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // --- API CALLS ---

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchStats(),
      _fetchSellerRequests(),
      _fetchUsers(),
      _fetchSellers(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _fetchStats() async {
    final token = await _getToken();
    if (token == null) return;
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/admin/stats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _totalUsers = data['stats']['totalUsers'] ?? 0;
          _totalSellers = data['stats']['totalSellers'] ?? 0;
        });
      }
    } catch (_) {}
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
    } catch (_) {}
  }

  Future<void> _fetchUsers() async {
    final token = await _getToken();
    if (token == null) return;
    try {
      String url = '$_baseUrl/admin/users?limit=100';
      if (_userSearchQuery.isNotEmpty) {
        url += '&search=${Uri.encodeComponent(_userSearchQuery)}';
      }
      if (_showOnlyActiveUsers) {
        url += '&status=active';
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
      }
    } catch (_) {}
  }

  Future<void> _fetchSellers() async {
    final token = await _getToken();
    if (token == null) return;
    try {
      String url = '$_baseUrl/admin/sellers?limit=100';
      if (_sellerSearchQuery.isNotEmpty) {
        url += '&search=${Uri.encodeComponent(_sellerSearchQuery)}';
      }
      if (_showOnlyActiveSellers) {
        url += '&status=active';
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
      }
    } catch (_) {}
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

  // --- UI BUILD ---

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
        body: LayoutBuilder(
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

  // --- TABS ---

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Overview",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 30),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return Row(
                  children: [
                    Expanded(child: _statCard("No. of Users", _totalUsers.toString(), Icons.people)),
                    const SizedBox(width: 20),
                    Expanded(child: _statCard("No. of Sellers", _totalSellers.toString(), Icons.store_rounded)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _statCard("No. of Users", _totalUsers.toString(), Icons.people),
                    const SizedBox(height: 20),
                    _statCard("No. of Sellers", _totalSellers.toString(), Icons.store_rounded),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
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
          Icon(icon, size: 36, color: Colors.blueAccent),
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
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 500) {
                return Row(
                  children: [
                    Flexible(child: _sellerSearchBar()),
                    const SizedBox(width: 16),
                    _buildSellerActiveFilter(),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sellerSearchBar(),
                    const SizedBox(height: 12),
                    _buildSellerActiveFilter(),
                  ],
                );
              }
            },
          ),
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

  Widget _buildSellerActiveFilter() {
    return FilterChip(
      label: const Text("Active Only"),
      selected: _showOnlyActiveSellers,
      selectedColor: Colors.blueAccent.withOpacity(0.2),
      checkmarkColor: Colors.blueAccent,
      onSelected: (val) {
        setState(() {
          _showOnlyActiveSellers = val;
          _fetchSellers();
        });
      },
      labelStyle: TextStyle(
        color: _showOnlyActiveSellers ? Colors.blueAccent : Colors.white,
      ),
      backgroundColor: const Color(0xFF151A24),
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
          const SizedBox(height: 8),
          Text(
            '${seller.name} (${seller.email})',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
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
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 500) {
                return Row(
                  children: [
                    Flexible(child: _userSearchBar()),
                    const SizedBox(width: 16),
                    _buildUserActiveFilter(),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _userSearchBar(),
                    const SizedBox(height: 12),
                    _buildUserActiveFilter(),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _users.isEmpty
                ? const Center(
                child: Text(
                  "No users found.",
                  style: TextStyle(color: Colors.grey),
                ))
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

  Widget _buildUserActiveFilter() {
    return FilterChip(
      label: const Text("Active Only"),
      selected: _showOnlyActiveUsers,
      selectedColor: Colors.blueAccent.withOpacity(0.2),
      checkmarkColor: Colors.blueAccent,
      onSelected: (val) {
        setState(() {
          _showOnlyActiveUsers = val;
          _fetchUsers();
        });
      },
      labelStyle: TextStyle(
        color: _showOnlyActiveUsers ? Colors.blueAccent : Colors.white,
      ),
      backgroundColor: const Color(0xFF151A24),
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
                          'Phone: ${user.phone}',
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
                  const SizedBox(height: 8),
                  Text(
                    user.email,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Phone: ${user.phone}',
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

  @override
  void dispose() {
    _userSearchController.dispose();
    _sellerSearchController.dispose();
    super.dispose();
  }
}