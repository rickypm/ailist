import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final _supabase = Supabase.instance.client;
  late Razorpay _razorpay;

  // Callbacks
  Function(PaymentSuccessResponse)? onSuccess;
  Function(PaymentFailureResponse)? onFailure;
  Function(ExternalWalletResponse)? onWallet;

  // Current payment info
  String? _currentPlan;
  double? _currentAmount;
  String? _userId;
  String? _userType;
  String? _orderId;
  
  // Cached Razorpay key from server
  String? _razorpayKey;

  // ============================================================
  // GET RAZORPAY KEY FROM SERVER (SUPABASE)
  // ============================================================
  
  Future<String?> _getRazorpayKey() async {
    // Return cached key if available
    if (_razorpayKey != null && _razorpayKey!.isNotEmpty) {
      return _razorpayKey;
    }

    try {
      final response = await _supabase
          .from('settings')
          .select('value')
          .eq('key', 'razorpay_key_id')
          .maybeSingle();
      
      if (response != null) {
        _razorpayKey = response['value'] as String?;
        debugPrint('Razorpay key loaded from server');
        return _razorpayKey;
      }
      
      // Fallback to config if not in database
      debugPrint('Razorpay key not found in settings, using config');
      return AppConfig.razorpayKeyId;
    } catch (e) {
      debugPrint('Error getting Razorpay key from server: $e');
      // Fallback to config
      return AppConfig.razorpayKeyId;
    }
  }

  // ============================================================
  // INITIALIZATION
  // ============================================================

  void init({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    Function(ExternalWalletResponse)? onWallet,
  }) {
    this.onSuccess = onSuccess;
    this.onFailure = onFailure;
    this.onWallet = onWallet;

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    debugPrint('PaymentService initialized');
  }

  // ============================================================
  // START PAYMENT
  // ============================================================

  Future<void> startPayment({
    required String userId,
    required String userType,
    required String plan,
    required double amount,
    required String userName,
    required String userEmail,
    String? userPhone,
  }) async {
    _currentPlan = plan;
    _currentAmount = amount;
    _userId = userId;
    _userType = userType;

    try {
      // Get Razorpay key from server
      final razorpayKey = await _getRazorpayKey();
      
      if (razorpayKey == null || razorpayKey.isEmpty) {
        debugPrint('Razorpay key not found');
        onFailure?.call(PaymentFailureResponse(
          Razorpay.UNKNOWN_ERROR,
          'Payment configuration error. Please contact support.',
          null,
        ));
        return;
      }

      // Create order via Edge Function
      final orderResponse = await _supabase.functions.invoke(
        'create-order',
        body: {
          'amount': (amount * 100).toInt(), // Convert to paise
          'currency': 'INR',
          'receipt': 'order_${DateTime.now().millisecondsSinceEpoch}',
          'notes': {
            'user_id': userId,
            'plan': plan,
            'user_type': userType,
          },
        },
      );

      if (orderResponse.status != 200) {
        throw Exception('Failed to create order');
      }

      final orderData = orderResponse.data;
      if (orderData['success'] != true) {
        throw Exception(orderData['error'] ?? 'Failed to create order');
      }

      _orderId = orderData['order']['id'];

      // Open Razorpay checkout
      final options = {
        'key': razorpayKey,
        'amount': (amount * 100).toInt(),
        'currency': 'INR',
        'name': 'WeList',
        'description': 'Subscription - $plan',
        'order_id': _orderId,
        'prefill': {
          'name': userName,
          'email': userEmail,
          if (userPhone != null) 'contact': userPhone,
        },
        'theme': {
          'color': '#6366F1',
        },
      };

      _razorpay.open(options);
    } catch (e) {
      debugPrint('Payment error: $e');
      onFailure?.call(PaymentFailureResponse(
        Razorpay.UNKNOWN_ERROR,
        e.toString(),
        null,
      ));
    }
  }

  // ============================================================
  // PAYMENT HANDLERS
  // ============================================================

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('Payment success: ${response.paymentId}');

    try {
      // Verify payment via Edge Function
      final verifyResponse = await _supabase.functions.invoke(
        'verify-payment',
        body: {
          'razorpay_order_id': response.orderId,
          'razorpay_payment_id': response.paymentId,
          'razorpay_signature': response.signature,
          'user_id': _userId,
          'plan': _currentPlan,
        },
      );

      if (verifyResponse.status == 200 && verifyResponse.data['success'] == true) {
        onSuccess?.call(response);
      } else {
        onFailure?.call(PaymentFailureResponse(
          Razorpay.UNKNOWN_ERROR,
          'Payment verification failed',
          null,
        ));
      }
    } catch (e) {
      debugPrint('Verification error: $e');
      onFailure?.call(PaymentFailureResponse(
        Razorpay.UNKNOWN_ERROR,
        'Payment verification error: $e',
        null,
      ));
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Payment error: ${response.code} - ${response.message}');
    onFailure?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External wallet: ${response.walletName}');
    onWallet?.call(response);
  }

  // ============================================================
  // CLEANUP
  // ============================================================

  void dispose() {
    _razorpay.clear();
  }

  // ============================================================
  // GETTERS
  // ============================================================
  
  String? get currentPlan => _currentPlan;
  double? get currentAmount => _currentAmount;
  String? get userId => _userId;
  String? get userType => _userType;
  String? get orderId => _orderId;
}