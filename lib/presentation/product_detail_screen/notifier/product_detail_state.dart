part of 'product_detail_notifier.dart';

/// Represents the state of PromoDetail in the application.

// ignore_for_file: must_be_immutable
class ProductDetailState extends Equatable {
  ProductDetailState({this.productDetailModelObj});

  ProductDetailModel? productDetailModelObj;

  @override
  List<Object?> get props => [productDetailModelObj];
  ProductDetailState copyWith({ProductDetailModel? productDetailModelObj}) {
    return ProductDetailState(
      productDetailModelObj: productDetailModelObj ?? this.productDetailModelObj,
    );
  }
}
