import 'dart:convert';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app_klinik/core/app_export.dart';
import 'package:mobile_app_klinik/presentation/home_screen/detail_news_screen.dart';
import 'package:mobile_app_klinik/presentation/home_screen/news_list_screen.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/api_constant.dart';
import '../promo_screen/detail_promo_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  String? namaUser;
  late PersistentTabController _controller;
  bool _isLoading = true;
  int _notificationCount = 0;
  List<Map<String, dynamic>> _promos = [];
  List<Map<String, dynamic>> _news = [];
  bool _isLoadingNews = true;
  bool _isLoadingPromos = true;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: 0);
    WidgetsBinding.instance.addObserver(this);
    _loadUserName();
    _fetchNotificationCount();
    _fetchPromos();
    _fetchNews();
  }

  // Update this method to refresh all data including promos
  Future<void> _refreshAllData() async {
    print('🔄 Refreshing all data...');
    
    // Run all refresh operations in parallel
    await Future.wait([
      _loadUserName(),
      _fetchNotificationCount(),
      _fetchPromos(),
      _fetchNews(),
    ]);
    
    print('✅ All data refreshed successfully');
  }

  // Add method to fetch notification count
  Future<void> _fetchNotificationCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // ✅ Try multiple ways to get user ID
      int? userId = prefs.getInt('id_user');
      
      if (userId == null) {
        final userIdString = prefs.getString('id_user');
        if (userIdString != null) {
          userId = int.tryParse(userIdString);
        }
      }

      final token = prefs.getString('token');

      if (userId != null && token != null) {
        print('📡 Fetching notification count for user: $userId');
        
        // ✅ Use correct endpoint
        final response = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/notifications/$userId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        print('📡 Notification count response: ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            final unreadCount = data['data']['unread_count'] ?? 0;
            
            print('📱 Unread notifications: $unreadCount');
            
            if (mounted) {
              setState(() {
                _notificationCount = unreadCount;
              });
            }
          }
        }
      } else {
        print('⚠️ User ID or token not found for notification count');
        if (mounted) {
          setState(() {
            _notificationCount = 0;
          });
        }
      }
    } catch (e) {
      print('❌ Error fetching notification count: $e');
    }
  }


  Future<void> _fetchPromos() async {
    if (mounted) {
      setState(() {
        _isLoadingPromos = true;
      });
    }

    try {
      print('🔄 Fetching promos from: ${ApiConstants.promo}');
      final response = await http.get(Uri.parse(ApiConstants.promo));

      print('📡 Promo response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          final List<dynamic> data = jsonResponse['data'];
          print('📊 Total promos received: ${data.length}');
          
          // Filter only active promos
          final activePromos = data.where((promo) =>
              promo['status_promo'] == 'Aktif').toList();

          print('✅ Active promos found: ${activePromos.length}');

          if (mounted) {
            setState(() {
              _promos = List<Map<String, dynamic>>.from(activePromos);
              _isLoadingPromos = false;
            });
          }
        } else {
          print('❌ API returned success: false');
          if (mounted) {
            setState(() {
              _isLoadingPromos = false;
            });
          }
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        throw Exception('Failed to load promos');
      }
    } catch (e) {
      print('💥 Error fetching promos: $e');
      if (mounted) {
        setState(() {
          _isLoadingPromos = false;
        });
      }
    }
  }

  Future<void> _fetchNews() async {
    if (mounted) {
      setState(() {
        _isLoadingNews = true;
      });
    }

    try {
      print('🔄 Fetching news...');
      final response = await http.get(
        Uri.parse('https://gnews.io/api/v4/search?q=skincare%20OR%20face%20care%20OR%20facial%20OR%20acne%20OR%20moisturizer%20OR%20sunscreen%20OR%20skin%20health%20OR%20glowing%20skin&lang=en&max=10&apikey=12b7d8ecd9b4e2b3fda3033377788931'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final List<dynamic> articles = jsonResponse['articles'] ?? [];

        print('✅ News fetched: ${articles.length} articles');

        if (mounted) {
          setState(() {
            _news = List<Map<String, dynamic>>.from(articles.take(5));
            _isLoadingNews = false;
          });
        }
      } else {
        throw Exception('Failed to load news');
      }
    } catch (e) {
      print('💥 Error fetching news: $e');
      if (mounted) {
        setState(() {
          _isLoadingNews = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadUserName();
      _fetchNotificationCount(); // Also refresh notification count
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      // Debug logging
      final token = prefs.getString('token');
      final savedName = prefs.getString('nama_user');
      final userId = prefs.getInt('id_user');

      print('DEBUG HomeScreen: token = ${token != null ? "ada" : "tidak ada"}');
      print('DEBUG HomeScreen: nama_user = $savedName');
      print('DEBUG HomeScreen: id_user = $userId');

      // Simplify the logic - if we have a token and name, show the name
      if (token != null && savedName != null) {
        if (mounted) {
          setState(() {
            namaUser = savedName;
            _isLoading = false;
          });
        }
        return;
      }

      // Otherwise, set as guest
      if (mounted) {
        setState(() {
          namaUser = "Guest";
          _isLoading = false;
        });
      }
    } catch (e) {
      print('ERROR loading user name: $e');
      if (mounted) {
        setState(() {
          namaUser = "Guest";
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildNewsList() {
    if (_isLoadingNews) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: CircularProgressIndicator(color: appTheme.orange200),
      );
    }

    if (_news.isEmpty) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No news available',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _news.length,
      itemBuilder: (context, index) {
        final article = _news[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailNewsScreen(
                  url: article['url'],
                  title: article['title'],
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    article['image'] ?? '',
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 90,
                      height: 90,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        article['description'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        article['source']['name'] ?? '',
                        style: TextStyle(
                          fontSize: 10,
                          color: appTheme.orange200,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildPromoCard(Map<String, dynamic> promo) {
    final hasImage = promo['gambar_promo'] != null && 
                     promo['gambar_promo'].toString().isNotEmpty;
    
    if (hasImage) {
      // ✅ Promo with image - use ApiConstants.getImageUrl()
      return Stack(
        children: [
          // Background image
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18), // Slightly smaller than parent
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                ApiConstants.getImageUrl(promo['gambar_promo']), // ✅ Use getImageUrl
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: appTheme.lightBadge100,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: appTheme.orange200,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Loading image...',
                            style: TextStyle(
                              color: appTheme.lightGrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print('❌ Error loading promo image: ${promo['gambar_promo']} - $error');
                  print('❌ Full URL: ${ApiConstants.getImageUrl(promo['gambar_promo'])}');
                  
                  // ✅ Fallback to no-image design
                  return _buildNoImagePromoCard(promo);
                },
              ),
            ),
          ),
          
          // Dark overlay for better text readability
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          
          // Text content
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    promo['nama_promo'] ?? 'Promo Spesial',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    promo['deskripsi_promo'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Discount indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: appTheme.orange200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getDiscountText(promo),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      // ✅ Promo without image
      return _buildNoImagePromoCard(promo);
    }
  }

  Widget _buildNoImagePromoCard(Map<String, dynamic> promo) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            appTheme.lightBadge100,
            appTheme.lightGreen.withOpacity(0.3),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon at top
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: appTheme.orange200.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_offer,
                    color: appTheme.orange200,
                    size: 24,
                  ),
                ),
                const Spacer(),
                // Discount badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: appTheme.darkCherry,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getDiscountText(promo),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const Spacer(),
            
            // Content at bottom
            Text(
              promo['nama_promo'] ?? 'Promo Spesial',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: appTheme.black900,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              promo['deskripsi_promo'] ?? '',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: appTheme.black900.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            
            // Period info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: appTheme.lightGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Berlaku hingga ${_formatPromoDate(promo['tanggal_berakhir'])}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: appTheme.black900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Add helper methods
  String _getDiscountText(Map<String, dynamic> promo) {
    if (promo['tipe_potongan'] == 'Diskon') {
      return 'Diskon ${promo['potongan_harga']}%';
    } else {
      return 'Hemat ${_formatCurrency(promo['potongan_harga'])}';
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0';
    try {
      final num value = num.parse(amount.toString());
      if (value >= 1000000) {
        return '${(value / 1000000).toStringAsFixed(1)}Jt';
      } else if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(0)}K';
      } else {
        return value.toStringAsFixed(0);
      }
    } catch (e) {
      return '0';
    }
  }

  String _formatPromoDate(dynamic date) {
    if (date == null) return 'TBA';
    try {
      final DateTime dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return date.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      context,
      controller: _controller,
      screens: _buildScreens(context),
      items: _navBarsItems(),
      confineToSafeArea: true,
      handleAndroidBackButtonPress: true,
      resizeToAvoidBottomInset: true,
      stateManagement: true,
      navBarStyle: NavBarStyle.style7,
      backgroundColor: appTheme.whiteA700,
    );
  }

  List<Widget> _buildScreens(BuildContext context) {
    return [
      Navigator(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => _mainScreen(),
        ),
      ),
      Navigator(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) =>
              AppRoutes.routes[AppRoutes.productScreen]!(context),
        ),
      ),
      Navigator(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) =>
              AppRoutes.routes[AppRoutes.bookingScreen]!(context),
        ),
      ),
      Navigator(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) =>
              AppRoutes.routes[AppRoutes.userScreen]!(context),
        ),
      ),
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.home),
        title: "Home",
        activeColorPrimary: appTheme.lightGreen,
        activeColorSecondary: appTheme.whiteA700,
        inactiveColorPrimary: appTheme.lightGreen,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.shopping_bag),
        title: "Product",
        activeColorPrimary: appTheme.lightGreen,
        activeColorSecondary: appTheme.whiteA700,
        inactiveColorPrimary: appTheme.lightGreen,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.chat),
        title: "Booking",
        activeColorPrimary: appTheme.lightGreen,
        activeColorSecondary: appTheme.whiteA700,
        inactiveColorPrimary: appTheme.lightGreen,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.person),
        title: "User",
        activeColorPrimary: appTheme.lightGreen,
        activeColorSecondary: appTheme.whiteA700,
        inactiveColorPrimary: appTheme.lightGreen,
      ),
    ];
  }

  Widget _mainScreen() {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            if (namaUser == null || namaUser == "Guest") {
              Navigator.pushNamed(context, AppRoutes.loginUserScreen)
                  .then((_) => _loadUserName());
            } else {
              Navigator.pushNamed(context, AppRoutes.userScreen);
            }
          },
          child: _isLoading
              ? const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
          )
              : Text.rich(
              TextSpan(
                children: [
                  if (namaUser == null || namaUser == "Guest")
                    TextSpan(
                      text: "Masuk / Daftar",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: appTheme.orange200,
                      ),
                    )
                  else ...[
                    const TextSpan(
                      text: "Halo, ",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    TextSpan(
                      text: namaUser,
                      style: TextStyle(
                        color: appTheme.orange200,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(
                      text: "!",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ),
        actions: [
          // Notification bell with badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications,
                  color: appTheme.black900,
                  size: 32,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.notificationScreen)
                      .then((_) => _fetchNotificationCount());
                },
              ),
              if (_notificationCount > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: appTheme.darkCherry,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      _notificationCount > 99 ? '99+' : _notificationCount.toString(),
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
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAllData, // Updated to refresh all data including promos
        color: appTheme.orange200,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section dengan padding horizontal
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Latest Promo",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, AppRoutes.promoScreen);
                            },
                            child: Text(
                              "See List",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: appTheme.orange200,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Section Swiper (tanpa padding horizontal)
              _isLoadingPromos
                  ? Container(
                height: 250,
                alignment: Alignment.center,
                child: CircularProgressIndicator(color: appTheme.orange200),
              )
                  : _promos.isEmpty
                  ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: appTheme.whiteA700,
                    borderRadius: BorderRadius.circular(24.0),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: const Center(
                    child: Text(
                      "No promotions available",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              )
                  : SizedBox(
                height: 250,
                width: double.infinity,
                child: Swiper(
                  itemBuilder: (BuildContext context, int index) {
                    final promo = _promos[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailPromoScreen(promo: promo),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.black, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha((0.2 * 255).toInt()),
                              spreadRadius: 1,
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: _buildPromoCard(promo), // ✅ Extract to separate method
                      ),
                    );
                  },
                  itemCount: _promos.length,
                  viewportFraction: 0.8,
                  scale: 0.9,
                  autoplay: _promos.length > 1,
                  autoplayDelay: 2500,
                  fade: 1.0,
                  curve: Curves.easeInOut,
                  pagination: SwiperPagination(
                    alignment: Alignment.bottomCenter,
                    margin: const EdgeInsets.only(bottom: 16),
                    builder: DotSwiperPaginationBuilder(
                      activeColor: appTheme.orange200,
                      color: appTheme.lightGrey,
                      size: 8.0,
                      activeSize: 10.0,
                      space: 4.0,
                    ),
                  ),
                ),
              ),

              
              const SizedBox(height: 36),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: const Divider(
                  height: 1,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),

              // Baca Artikel section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Read Articles",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NewsListScreen(),
                              ),
                            );
                          },
                          child: Text(
                            "See List",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: appTheme.orange200,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildNewsList(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}