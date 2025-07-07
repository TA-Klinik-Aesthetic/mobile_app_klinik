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
  int _notificationCount = 0; // Add notification counter
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
    _fetchNotificationCount(); // Load notification count
    _fetchPromos();  // Fetch promos data
    _fetchNews(); // Fetch news data
  }

  // Add method to fetch notification count
  Future<void> _fetchNotificationCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('id_user');
      final token = prefs.getString('token');

      if (userId != null && token != null) {
        final response = await http.get(
          Uri.parse('${ApiConstants.notifications}/$userId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final notifications = data['notifications'] as List;
          final unreadCount = notifications.where((notif) => notif['is_read'] == false).length;

          setState(() {
            _notificationCount = unreadCount;
          });
        }
      }
    } catch (e) {
      print('Error fetching notification count: $e');
    }
  }

  Future<void> _fetchPromos() async {
    setState(() {
      _isLoadingPromos = true;
    });

    try {
      final response = await http.get(Uri.parse(ApiConstants.promo));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          final List<dynamic> data = jsonResponse['data'];
          final activePromos = data.where((promo) =>
          promo['status_promo'] == 'Aktif').toList();

          setState(() {
            _promos = List<Map<String, dynamic>>.from(activePromos);
            _isLoadingPromos = false;
          });
        }
      } else {
        throw Exception('Failed to load promos');
      }
    } catch (e) {
      print('Error fetching promos: $e');
      setState(() {
        _isLoadingPromos = false;
      });
    }
  }

  Future<void> _fetchNews() async {
    setState(() {
      _isLoadingNews = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://gnews.io/api/v4/search?q=skincare%20OR%20face%20care%20OR%20facial%20OR%20acne%20OR%20moisturizer%20OR%20sunscreen%20OR%20skin%20health%20OR%20glowing%20skin&lang=en&max=10&apikey=12b7d8ecd9b4e2b3fda3033377788931'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final List<dynamic> articles = jsonResponse['articles'] ?? [];

        setState(() {
          _news = List<Map<String, dynamic>>.from(articles.take(5));
          _isLoadingNews = false;
        });
      } else {
        throw Exception('Failed to load news');
      }
    } catch (e) {
      print('Error fetching news: $e');
      setState(() {
        _isLoadingNews = false;
      });
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
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    setState(() {
      _isLoading = true;
    });

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
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
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
                size: 36,
              ),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.notificationScreen)
                    .then((_) => _fetchNotificationCount());
              },
            ),
            if (_notificationCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: appTheme.darkCherry,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
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
        onRefresh: _loadUserName,
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
                child: CircularProgressIndicator(),
              )
                  : _promos.isEmpty
                  ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: appTheme.lightBadge100,
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
                          image: DecorationImage(
                            image: NetworkImage(promo['gambar_promo']),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withAlpha((0.3 * 255).toInt()),
                              BlendMode.darken,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                promo['nama_promo'] ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                promo['deskripsi_promo'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
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

              // Jadwal Treatment dengan padding
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  height: 70,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: appTheme.lightGreen,
                    borderRadius: BorderRadius.circular(24.0),
                    border: Border.all(color: appTheme.black900, width: 2),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.doctorScheduleScreen);
                    },
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Waktu Treatment Tersedia",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: appTheme.black900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.calendar_today,
                            color: appTheme.black900,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Add this after the doctor schedule section in the body
              const SizedBox(height: 24),
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