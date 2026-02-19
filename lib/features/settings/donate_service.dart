import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Product ID - must match Google Play Console
const String kCoffeeProductId = 'buy_coffee_tip';

/// Simple donation service
class DonateService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  Function(bool success)? onPurchaseComplete;

  Future<void> init() async {
    final available = await _iap.isAvailable();
    if (!available) {
      debugPrint('In-app purchases not available');
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (error) => debugPrint('Purchase error: $error'),
    );
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased) {
        onPurchaseComplete?.call(true);
      } else if (purchase.status == PurchaseStatus.error) {
        onPurchaseComplete?.call(false);
      }

      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  /// Get coffee price
  Future<String> getPrice() async {
    try {
      final response = await _iap.queryProductDetails({kCoffeeProductId});
      if (response.productDetails.isNotEmpty) {
        return response.productDetails.first.price;
      }
    } catch (e) {
      debugPrint('Error getting price: $e');
    }
    return '\$0.99';
  }

  /// Buy coffee
  Future<bool> buyCoffee() async {
    try {
      final response = await _iap.queryProductDetails({kCoffeeProductId});
      
      if (response.productDetails.isEmpty) {
        debugPrint('Product not found');
        return false;
      }

      final product = response.productDetails.first;
      final purchaseParam = PurchaseParam(productDetails: product);
      
      return await _iap.buyConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('Purchase failed: $e');
      return false;
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}