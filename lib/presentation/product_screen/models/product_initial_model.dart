import 'package:equatable/equatable.dart';
import 'productgrid_item_model.dart';

/// This class is used in the [product_initial_page] screen.

// ignore_for_file: must_be_immutable
class ProductInitialModel extends Equatable {
  ProductInitialModel({this.productgridItemList = const []});

  List<ProductgridItemModel> productgridItemList;

  ProductInitialModel copyWith(
      {List<ProductgridItemModel>? productgridItemList}) {
    return ProductInitialModel(
      productgridItemList: productgridItemList ?? this.productgridItemList,
    );
  }

  @override
  List<Object?> get props => [productgridItemList];
}
