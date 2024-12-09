import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/product_initial_model.dart';
import '../models/product_model.dart';
import '../models/productgrid_item_model.dart';
part 'product_state.dart';

final productNotifier =
    StateNotifierProvider.autoDispose<ProductNotifier, ProductState>(
  (ref) => ProductNotifier(ProductState(
    searchController: TextEditingController(),
    productInitialModelObj: ProductInitialModel(productgridItemList: [
      ProductgridItemModel(
          image: ImageConstant.imgRectangle7,
          weight: "Skintific - Acne Clay Stick 40G",
          rpCounter: "Rp 100.000,00"),
      ProductgridItemModel(
          image: ImageConstant.imgRectangle7164x164,
          weight: "Kahf Oil & Acne Care Face Wash 50 ml",
          rpCounter: "Rp 100.000,00"),
      ProductgridItemModel(
          image: ImageConstant.imgRectangle71,
          weight: "Skintific - Acne Clay Stick 40G",
          rpCounter: "Rp 100.000,00"),
      ProductgridItemModel(
          image: ImageConstant.imgRectangle71,
          weight: "Skintific - Acne Clay Stick 40G",
          rpCounter: "Rp 100.000,00"),
      ProductgridItemModel(),
      ProductgridItemModel()
    ]),
  )),
);

/// A notifier that manages the state of a Product according to the event that is dispatched to it.
class ProductNotifier extends StateNotifier<ProductState> {
  ProductNotifier(ProductState state) : super(state);
}
