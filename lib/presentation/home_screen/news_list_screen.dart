import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/app_export.dart';
import 'detail_news_screen.dart';

class NewsListScreen extends StatefulWidget {
  const NewsListScreen({Key? key}) : super(key: key);

  @override
  State<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  List<Map<String, dynamic>> _news = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchNews();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && _hasMore && !_isLoading) {
      _fetchNews();
    }
  }

  Future<void> _fetchNews() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://gnews.io/api/v4/search?q=skincare%20OR%20face%20care%20OR%20facial%20OR%20acne%20OR%20moisturizer%20OR%20sunscreen%20OR%20skin%20health%20OR%20glowing%20skin&lang=en&max=10&apikey=12b7d8ecd9b4e2b3fda3033377788931'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final List<dynamic> articles = jsonResponse['articles'] ?? [];

        setState(() {
          if (_currentPage == 1) {
            _news = List<Map<String, dynamic>>.from(articles);
          } else {
            _news.addAll(List<Map<String, dynamic>>.from(articles));
          }
          _currentPage++;
          _hasMore = articles.length == 10;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load news');
      }
    } catch (e) {
      print('Error fetching news: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshNews() async {
    setState(() {
      _news.clear();
      _currentPage = 1;
      _hasMore = true;
    });
    await _fetchNews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Read Articles',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: appTheme.orange200,
          ),
        ),
        backgroundColor: appTheme.whiteA700,
        elevation: 0.0,
        centerTitle: true,
        foregroundColor: appTheme.black900,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshNews,
        color: appTheme.orange200,
        child: _news.isEmpty && _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: _news.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _news.length) {
              return Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                child: CircularProgressIndicator(color: appTheme.orange200),
              );
            }

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
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        article['image'] ?? '',
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: double.infinity,
                          height: 200,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, size: 50, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      article['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      article['description'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          article['source']['name'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: appTheme.orange200,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _formatDate(article['publishedAt']),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }
}