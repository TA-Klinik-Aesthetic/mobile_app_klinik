part of 'product_notifier.dart';

/// Represents the state of Product in the application.

// ignore_for_file: must_be_immutable
class ProductState extends Equatable {
  ProductState(
      {this.searchController,
      this.productInitialModelObj,
      this.productModelObj});

  TextEditingController? searchController;

  ProductModel? productModelObj;

  ProductInitialModel? productInitialModelObj;

  @override
  List<Object?> get props =>
      [searchController, productInitialModelObj, productModelObj];
  ProductState copyWith({
    TextEditingController? searchController,
    ProductInitialModel? productInitialModelObj,
    ProductModel? productModelObj,
  }) {
    return ProductState(
      searchController: searchController ?? this.searchController,
      productInitialModelObj:
          productInitialModelObj ?? this.productInitialModelObj,
      productModelObj: productModelObj ?? this.productModelObj,
    );
  }
}
