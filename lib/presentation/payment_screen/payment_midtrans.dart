import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import '../../theme/theme_helper.dart';
import '../../api/api_constant.dart';
import '../../core/app_export.dart';

class PaymentMidtrans extends StatefulWidget {
  final String snapUrl;
  final String title;
  final String? paymentId;

  const PaymentMidtrans({
    super.key,
    required this.snapUrl,
    this.title = 'Pembayaran',
    this.paymentId,
  });

  @override
  State<PaymentMidtrans> createState() => _PaymentMidtransState();
}

class _PaymentMidtransState extends State<PaymentMidtrans> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _loadingTimer;
  bool _hasError = false;
  int _retryCount = 0;
  static const int maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  void _initializeWebView() {
    print('Initializing WebView with URL: ${widget.snapUrl}');
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      // ✅ Simplified User-Agent
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36'
      )
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView is loading (progress : $progress%)');
            
            // ✅ Reset error state when loading starts making progress
            if (progress > 0 && _hasError) {
              setState(() {
                _hasError = false;
                _errorMessage = null;
              });
            }
          },
          onPageStarted: (String url) {
            print('Page started loading: $url');
            setState(() {
              _isLoading = true;
              _errorMessage = null;
              _hasError = false;
            });
            
            // ✅ Set timeout untuk loading
            _startLoadingTimer();
          },
          onPageFinished: (String url) {
            print('Page finished loading: $url');
            _loadingTimer?.cancel();
            
            // ✅ Add delay before stopping loading indicator
            Future.delayed(const Duration(milliseconds: 1000), () {
              if (mounted && !_hasError) {
                setState(() {
                  _isLoading = false;
                });
                
                // ✅ Inject JavaScript after page is fully loaded
                _injectJavaScriptHandlers();
              }
            });
            
            _checkPaymentStatus(url);
          },
          onWebResourceError: (WebResourceError error) {
            print('=== WebView Resource Error ===');
            print('Description: ${error.description}');
            print('Error code: ${error.errorCode}');
            print('Error type: ${error.errorType}');
            print('URL: ${error.url}');
            
            // ✅ Only handle main frame errors, ignore resource errors
            if (error.errorType == WebResourceErrorType.hostLookup ||
                error.errorType == WebResourceErrorType.timeout ||
                error.errorType == WebResourceErrorType.connect ||
                error.description.contains('ERR_BLOCKED_BY_ORB') ||
                error.description.contains('ERR_NETWORK_CHANGED')) {
              
              _handleLoadingError(error.description);
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            print('Navigation request to: ${request.url}');
            
            // ✅ Allow all Midtrans and payment related URLs
            if (_isPaymentRelatedUrl(request.url)) {
              return NavigationDecision.navigate;
            }
            
            // ✅ Handle completion URLs
            if (_isPaymentCompletionUrl(request.url)) {
              _handlePaymentCompletion(request.url);
              return NavigationDecision.prevent;
            }
            
            return NavigationDecision.navigate;
          },
          onUrlChange: (UrlChange change) {
            if (change.url != null) {
              print('URL changed to: ${change.url}');
              _checkPaymentStatus(change.url!);
            }
          },
        ),
      );

    // ✅ Load URL with simplified approach
    _loadUrl();
  }

  // ✅ Simplified loading timer
  void _startLoadingTimer() {
    _loadingTimer?.cancel();
    _loadingTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && _isLoading) {
        print('Loading timeout after 15 seconds');
        _handleLoadingError('Timeout loading halaman pembayaran');
      }
    });
  }

  // ✅ Handle loading errors
  void _handleLoadingError(String errorDescription) {
    _loadingTimer?.cancel();
    
    setState(() {
      _isLoading = false;
      _hasError = true;
      _errorMessage = 'Terjadi masalah keamanan browser. Mencoba membuka ulang...';
    });

    // ✅ Auto retry with delay
    if (_retryCount < maxRetries) {
      _retryCount++;
      print('Auto retry attempt $_retryCount/$maxRetries');
      
      Future.delayed(Duration(seconds: 2 * _retryCount), () {
        if (mounted) {
          _retryLoading();
        }
      });
    } else {
      setState(() {
        _errorMessage = 'Gagal memuat halaman setelah $maxRetries percobaan. Silakan coba lagi atau gunakan browser external.';
      });
    }
  }

  // ✅ Simplified URL loading
  Future<void> _loadUrl() async {
    try {
      await _controller.loadRequest(
        Uri.parse(widget.snapUrl),
        headers: {
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'id-ID,id;q=0.9,en;q=0.8',
          'Cache-Control': 'no-cache',
          'Sec-Fetch-Dest': 'document',
          'Sec-Fetch-Mode': 'navigate',
          'Sec-Fetch-Site': 'cross-site',
          'Upgrade-Insecure-Requests': '1',
        },
      );
    } catch (e) {
      print('Error loading URL: $e');
      _handleLoadingError('Error loading URL: $e');
    }
  }

  // ✅ Simplified JavaScript injection
  Future<void> _injectJavaScriptHandlers() async {
    try {
      await _controller.runJavaScript('''
        console.log('=== Payment WebView JavaScript Loaded ===');
        
        // ✅ Simple error handling
        window.addEventListener('error', function(e) {
          console.log('JavaScript Error:', e.message);
        });
        
        // ✅ Monitor for payment completion
        function checkPaymentStatus() {
          const url = window.location.href;
          console.log('Current URL:', url);
          
          // Check for success indicators
          if (url.includes('success') || url.includes('finish') || 
              url.includes('status_code=200') || url.includes('status_code=201')) {
            console.log('Payment success detected');
          }
          
          // Check for failure indicators  
          if (url.includes('failed') || url.includes('error') || 
              url.includes('status_code=400') || url.includes('status_code=500')) {
            console.log('Payment failure detected');
          }
          
          // Check for pending
          if (url.includes('pending')) {
            console.log('Payment pending detected');
          }
        }
        
        // Check status every 2 seconds
        setInterval(checkPaymentStatus, 2000);
        
        // Initial check
        checkPaymentStatus();
        
        console.log('Payment monitoring initialized');
      ''');
    } catch (e) {
      print('Error injecting JavaScript: $e');
      // Don't fail the whole process if JavaScript injection fails
    }
  }

  // ✅ Retry loading with cleanup
  Future<void> _retryLoading() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });
      
      // ✅ Clear cache and cookies
      await _controller.clearCache();
      await _controller.clearLocalStorage();
      
      // ✅ Wait before retry
      await Future.delayed(const Duration(milliseconds: 500));
      
      // ✅ Reload URL
      await _loadUrl();
      
    } catch (e) {
      print('Retry failed: $e');
      _handleLoadingError('Retry failed: $e');
    }
  }

  // ✅ More comprehensive URL checking
  bool _isPaymentRelatedUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    
    final paymentDomains = [
      'midtrans.com',
      'veritrans.co.id',
      'snap.midtrans.com',
      'api.midtrans.com',
      'app.midtrans.com',
      'simulator.sandbox.midtrans.com',
      'app.sandbox.midtrans.com',
      'payment.midtrans.com',
      // ✅ Add more payment gateways if needed
      'gopay.co.id',
      'dana.id',
      'ovo.id',
    ];
    
    return paymentDomains.any((domain) => 
      uri.host.contains(domain) || uri.host.endsWith(domain));
  }

  bool _isPaymentCompletionUrl(String url) {
    final completionIndicators = [
      'finish',
      'success',
      'pending', 
      'failure',
      'error',
      'close',
      'status_code=200',
      'status_code=201',
      'status_code=400',
      'status_code=500',
      'transaction_status=settlement',
      'transaction_status=pending',
      'transaction_status=cancel',
      'transaction_status=expire',
      'transaction_status=failure',
    ];
    
    return completionIndicators.any((indicator) => url.contains(indicator));
  }

  void _checkPaymentStatus(String url) {
    if (_isPaymentCompletionUrl(url)) {
      // ✅ Add delay to ensure page is fully loaded
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _handlePaymentCompletion(url);
        }
      });
    }
  }

  void _handlePaymentCompletion(String url) {
    String status = 'unknown';
    String message = 'Pembayaran selesai';

    // ✅ More comprehensive status detection
    if (url.contains('success') || 
        url.contains('finish') || 
        url.contains('status_code=200') ||
        url.contains('status_code=201') ||
        url.contains('transaction_status=settlement')) {
      status = 'success';
      message = 'Pembayaran berhasil!';
    } else if (url.contains('pending') || 
               url.contains('transaction_status=pending')) {
      status = 'pending';
      message = 'Pembayaran sedang diproses';
    } else if (url.contains('failure') || 
               url.contains('error') ||
               url.contains('status_code=400') ||
               url.contains('status_code=500') ||
               url.contains('transaction_status=failure')) {
      status = 'failed';
      message = 'Pembayaran gagal';
    } else if (url.contains('close') || 
               url.contains('cancel') ||
               url.contains('transaction_status=cancel') ||
               url.contains('transaction_status=expire')) {
      status = 'cancelled';
      message = 'Pembayaran dibatalkan';
    }

    print('Payment completion detected: $status - $message');
    _showPaymentResult(status, message);
  }

  // ✅ Enhanced refresh method
  Future<void> _refreshWebView() async {
    _retryCount = 0; // Reset retry count on manual refresh
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasError = false;
    });
    
    try {
      await _controller.clearCache();
      await _controller.clearLocalStorage();
      await Future.delayed(const Duration(milliseconds: 300));
      await _controller.reload();
    } catch (e) {
      print('Error refreshing WebView: $e');
      _handleLoadingError('Error refreshing: $e');
    }
  }

  // ✅ Manual retry method
  void _manualRetry() {
    _retryCount = 0; // Reset retry count
    setState(() {
      _errorMessage = null;
      _hasError = false;
    });
    _retryLoading();
  }

  // ... (rest of the methods remain the same: _refreshPaymentStatus, _showPaymentResult, etc.)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(
            color: appTheme.orange200,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: appTheme.whiteA700,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: appTheme.black900),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshWebView,
            tooltip: 'Refresh',
          ),
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: _showDebugInfo,
              tooltip: 'Debug Info',
            ),
        ],
      ),
      body: Stack(
        children: [
          if (_errorMessage != null && _hasError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 64,
                    color: Colors.orange.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error memuat halaman pembayaran',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _manualRetry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appTheme.orange200,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Coba Lagi'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          // ✅ Option to open in external browser
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('URL: ${widget.snapUrl}'),
                              action: SnackBarAction(
                                label: 'Salin',
                                onPressed: () {
                                  // Copy URL to clipboard
                                },
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Buka di Browser External'),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            WebViewWidget(controller: _controller),
          
          // ✅ Enhanced loading indicator
          if (_isLoading && !_hasError)
            Container(
              color: Colors.white.withOpacity(0.9),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(appTheme.orange200),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Memuat halaman pembayaran...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: appTheme.black900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_retryCount > 0)
                      Text(
                        'Percobaan ke-${_retryCount + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _refreshPaymentStatus() async {
    if (widget.paymentId == null) {
      print('Payment ID not available for refresh');
      return;
    }

    try {
      final String refreshUrl = ApiConstants.refreshPembayaranMidtrans
          .replaceAll('{id_pembayaran}', widget.paymentId!);

      print('=== REFRESHING PAYMENT STATUS ===');
      print('URL: $refreshUrl');
      print('Payment ID: ${widget.paymentId}');

      // Call API without authentication header (as it works in Postman)
      final response = await http.get(
        Uri.parse(refreshUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Refresh response status: ${response.statusCode}');
      print('Refresh response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Payment status refreshed successfully');
        
        // Extract payment information from response
        final paymentData = data['data'];
        final syncInfo = data['sync_info'];
        final paymentInfo = data['payment_info'];
        
        if (paymentData != null) {
          final String currentStatus = paymentData['status_pembayaran'] ?? 'Unknown';
          final String transactionStatus = paymentData['transaction_status'] ?? 'Unknown';
          
          print('=== PAYMENT SYNC RESULT ===');
          print('Current Status: $currentStatus');
          print('Transaction Status: $transactionStatus');
          
          if (syncInfo != null) {
            final bool synced = syncInfo['synced'] ?? false;
            final String? oldStatus = syncInfo['old_status'];
            final String? newStatus = syncInfo['new_status'];
            
            print('Synced: $synced');
            print('Status Changed: $oldStatus → $newStatus');
            
            if (synced && oldStatus != newStatus) {
              print('✅ Payment status successfully updated in database');
            }
          }
          
          if (paymentInfo != null) {
            final bool isSuccess = paymentInfo['is_success'] ?? false;
            final bool isPending = paymentInfo['is_pending'] ?? false;
            final bool isFailed = paymentInfo['is_failed'] ?? false;
            
            print('Payment Result - Success: $isSuccess, Pending: $isPending, Failed: $isFailed');
            
            if (isSuccess) {
              print('🎉 Payment confirmed as successful!');
            } else if (isPending) {
              print('⏳ Payment is still pending');
            } else if (isFailed) {
              print('❌ Payment failed');
            }
          }
        }
        
      } else {
        print('Failed to refresh payment status: ${response.statusCode}');
        print('Error response: ${response.body}');
        
        // Handle specific error cases
        if (response.statusCode == 404) {
          print('Payment record not found');
        } else if (response.statusCode >= 500) {
          print('Server error occurred');
        }
      }
    } catch (e) {
      print('Error refreshing payment status: $e');
      rethrow;
    }
  }

  void _showPaymentResult(String status, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        IconData icon;
        Color color;

        switch (status) {
          case 'success':
            icon = Icons.check_circle;
            color = Colors.green;
            break;
          case 'pending':
            icon = Icons.schedule;
            color = Colors.orange;
            break;
          case 'failed':
            icon = Icons.error;
            color = Colors.red;
            break;
          case 'cancelled':
            icon = Icons.cancel;
            color = Colors.grey;
            break;
          default:
            icon = Icons.info;
            color = Colors.blue;
        }

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              const Text('Status Pembayaran'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 8),
              Text(
                'Anda akan kembali ke layar sebelumnya.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Tutup dialog dulu
                Navigator.of(dialogCtx).pop();
                // Lalu kembalikan status ke PaymentScreen
                // Gunakan context milik State (aman, bukan dialogCtx)
                if (!mounted) return;
                Navigator.of(context).pop(status);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ✅ Add debug info method
  void _showDebugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Snap URL: ${widget.snapUrl}'),
              const SizedBox(height: 8),
              Text('Payment ID: ${widget.paymentId ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text('Error: ${_errorMessage ?? 'None'}'),
              const SizedBox(height: 8),
              Text('Loading: $_isLoading'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}