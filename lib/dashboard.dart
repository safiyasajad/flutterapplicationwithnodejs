import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutterapplicationwithnodejs/login.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

//use of set state to change the body of the dashboard page to order
//history page and vice versa when the bottom navigation bar icons
//are clicked

class _DashboardState extends State<Dashboard> {
  //defining the text editing controllers for the CreateOrders
  final _itemNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  String _selectedStatus = "Preparing";
  String _searchText = '';
  bool _sortNewestFirst = true;
  List<dynamic> _filteredOrders = [];

  void _runFilter(String value) {
    _searchText = value;
    _applyFiltersAndSort();
  }

  double _orderPrice(dynamic order) {
    return double.tryParse(order['price'].toString()) ?? 0;
  }

  DateTime _orderDate(dynamic order) {
    return DateTime.tryParse(order['ordered_at'].toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  void _applyFiltersAndSort() {
    final minPrice = double.tryParse(_minPriceController.text.trim());
    final maxPrice = double.tryParse(_maxPriceController.text.trim());

    final results = _orders.where((order) {
      final itemName = order['item_name'].toString().toLowerCase();
      final price = _orderPrice(order);
      final matchesSearch = itemName.contains(_searchText.toLowerCase());
      final aboveMin = minPrice == null || price >= minPrice;
      final belowMax = maxPrice == null || price <= maxPrice;

      return matchesSearch && aboveMin && belowMax;
    }).toList();

    results.sort((a, b) {
      final firstDate = _orderDate(a);
      final secondDate = _orderDate(b);

      return _sortNewestFirst
          ? secondDate.compareTo(firstDate)
          : firstDate.compareTo(secondDate);
    });

    setState(() {
      _filteredOrders = results;
    });
  }

  //returns the color of the status of the order
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'preparing':
        return Colors.yellow.shade700;
      case 'out for delivery':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  int _selectedIndex = 0;
  // This is the same backend base URL used by the login page.
  // 10.0.2.2 is used because the Android emulator needs this special address
  // to reach localhost on your computer.
  final String baseUrl = 'http://10.0.2.2:5000/api/auth';

  // Stores the logged-in usLer's details returned by GET /api/auth/me.
  // The backend returns keys like name, email, and phonenumber.
  Map<String, dynamic>? _user;
  List<dynamic> _orders = [];
  // Stores an error message if loading the profile fails.
  String? _error;

  // Controls whether the loading spinner or the profile details are shown.
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Load the current user's profile as soon as the dashboard opens.
    _loadUser();
    _loadOrders();
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      // The token was saved in SharedPreferences after login/register.
      // It is needed so the backend knows which user is requesting /me.
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No saved login token');
      }

      // Ask the backend for the current user's details.
      // Authorization: Bearer <token> sends the JWT to the protected route.
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // The backend sends JSON, so decode it into a Dart map.
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Save the user details in state so the UI rebuilds and displays them.
        setState(() {
          _user = data;
          _isLoading = false;
        });
      } else {
        // If the server returns an error, show its message if available.
        throw Exception(data['message'] ?? 'Failed to load user');
      }
    } catch (e) {
      // Any network, JSON, or auth error ends up here and is shown on screen.
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  //delete order function
  Future<void> _deleteOrder(dynamic order) async {
    try {
      final orderId = order['id'];

      if (orderId == null) {
        throw Exception('Order id is missing');
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No saved login token');
      }

      //sends the delete requet. if
      final response = await http.delete(
        Uri.parse('$baseUrl/orders/$orderId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _orders.removeWhere((item) => item['id'] == orderId);
        });
        _applyFiltersAndSort();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order deleted successfully')),
        );
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to delete order');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _loadOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('$baseUrl/orders'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print(response.statusCode);
      print(response.body);

      if (response.statusCode == 200) {
        _orders = jsonDecode(response.body);
        _applyFiltersAndSort();
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> logout(BuildContext context) async {
    // Remove the saved JWT so the app no longer treats the user as logged in.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    // Send the user back to the login page and remove dashboard from history.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> CreateOrders() async {
    try {
      final quantity = int.tryParse(_quantityController.text.trim());
      final price = double.tryParse(_priceController.text.trim());

      if (_itemNameController.text.trim().isEmpty ||
          quantity == null ||
          price == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill all fields correctly")),
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "item_name": _itemNameController.text.trim(),
          "quantity": quantity,
          "price": price,
          "status": _selectedStatus,
        }),
      );

      if (response.statusCode == 201) {
        if (!mounted) return;
        Navigator.pop(context);

        _itemNameController.clear();
        _quantityController.clear();
        _priceController.clear();

        await _loadOrders();
      } else {
        print(response.body);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //app bar
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? "Order History" : "Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),

      //floating action button
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Create Order'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _itemNameController,
                      decoration: const InputDecoration(
                        labelText: 'Item Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: "Status",
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "Preparing",
                          child: Text("Preparing"),
                        ),
                        DropdownMenuItem(
                          value: "Out for Delivery",
                          child: Text("Out for Delivery"),
                        ),
                        DropdownMenuItem(
                          value: "Delivered",
                          child: Text("Delivered"),
                        ),
                        DropdownMenuItem(
                          value: "Cancelled",
                          child: Text("Cancelled"),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          _selectedStatus = value;
                        });
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: CreateOrders,
                    child: const Text('Create'),
                  ),
                ],
              );
            },
          );
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
      ),

      bottomNavigationBar: BottomAppBar(
        notchMargin: 6.0,
        shape: const CircularNotchedRectangle(),
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              Expanded(
                child: IconButton(
                  iconSize: 32,
                  icon: const Icon(Icons.restaurant_menu),
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                  },
                ),
              ),

              const VerticalDivider(
                width: 1,
                thickness: 1,
                indent: 10,
                endIndent: 10,
              ),

              Expanded(
                child: IconButton(
                  iconSize: 32,
                  icon: const Icon(Icons.home),
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 0;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      //when the user is logged in the page that gets displayed is the
      //order history page
      body: _selectedIndex == 0 ? dashboardPage() : orderHistoryPage(),
    );
  }

  //creates a dashboard page with user details
  Widget dashboardPage() {
    return Center(child: _buildBody());
  }

  //creates a order history page
  Widget orderHistoryPage() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: _runFilter,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<bool>(
                  value: _sortNewestFirst,
                  decoration: const InputDecoration(
                    labelText: 'Sort by date',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: true, child: Text('Newest first')),
                    DropdownMenuItem(value: false, child: Text('Oldest first')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;

                    _sortNewestFirst = value;
                    _applyFiltersAndSort();
                  },
                ),
              ),
              SizedBox(
                width: 140,
                child: TextField(
                  controller: _minPriceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Min price',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _applyFiltersAndSort(),
                ),
              ),
              SizedBox(
                width: 140,
                child: TextField(
                  controller: _maxPriceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Max price',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _applyFiltersAndSort(),
                ),
              ),
              TextButton(
                onPressed: () {
                  _minPriceController.clear();
                  _maxPriceController.clear();
                  _applyFiltersAndSort();
                },
                child: const Text('Clear price'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Expanded(
          child: ListView.builder(
            itemCount: _filteredOrders.length,
            itemBuilder: (context, index) {
              final order = _filteredOrders[index];

              return Card(
                child: ListTile(
                  title: Text(order['item_name']),
                  subtitle: RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        TextSpan(
                          text:
                              "Qty: ${order['quantity']} • RM ${order['price']} • ",
                        ),
                        TextSpan(
                          text: order['status'].toString(),
                          style: TextStyle(
                            color: _getStatusColor(order['status'].toString()),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'details') {
                        print('Details ${order['item_name']}');
                      } else if (value == 'edit') {
                        print('Edit ${order['item_name']}');
                      } else if (value == 'delete') {
                        _deleteOrder(order); //calls the deleteOrder function
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    // While /me is loading, show a spinner instead of empty content.
    if (_isLoading) {
      return const CircularProgressIndicator();
    }

    // If loading failed, show the error message in the dashboard body.
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(_error!, textAlign: TextAlign.center),
      );
    }

    // Use fallback text so the UI does not crash if a field is missing.
    // final id = _user?['id'] ?? 'Unknown';
    final name = _user?['name'] ?? 'Unknown';
    final email = _user?['email'] ?? 'Unknown';
    final phone = _user?['phonenumber'] ?? 'Unknown';

    // Display the profile values loaded from the backend.
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Details',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 24),
          Text('Name: $name', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 12),
          Text('Phone: $phone', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 12),
          Text('Email: $email', style: const TextStyle(fontSize: 18)),
          // const SizedBox(height: 12),
          // Text('user: $id', style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}
