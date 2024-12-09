import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/chipviewmugwort_item_model.dart';
import '../models/product_detail_model.dart';
import '../models/relatedproducts_item_model.dart';
part 'product_detail_state.dart';

final productDetailNotifier =
    StateNotifierProvider.autoDispose<ProductDetailNotifier, ProductDetailState>(
  (ref) => ProductDetailNotifier(ProductDetailState(
    productDetailModelObj: ProductDetailModel(chipviewmugwortItemList: [
      ChipviewmugwortItemModel(mugwortsOne: "Mugworts"),
      ChipviewmugwortItemModel(mugwortsOne: "Alaskan Volcano")
    ], relatedproductsItemList: [
      RelatedproductsItemModel(weight: "Skintific - Acne Clay Stick 40G"),
      RelatedproductsItemModel(weight: "Skintific - Acne Clay Stick 40G"),
      RelatedproductsItemModel(weight: "Skintific - Acne Clay Stick 40G"),
      RelatedproductsItemModel(weight: "Skintific - Acne Clay Stick 40G"),
      RelatedproductsItemModel(weight: "Skintific - Acne Clay Stick 40G")
    ]),
  )),
);

/// A notifier that manages the state of a PromoDetail according to the event that is dispatched to it.
class ProductDetailNotifier extends StateNotifier<ProductDetailState> {
  ProductDetailNotifier(super.state);

  void onSelectedChipView(
    int index,
    bool value,
  ) {
    List<ChipviewmugwortItemModel> newList =
        List<ChipviewmugwortItemModel>.from(
            state.productDetailModelObj!.chipviewmugwortItemList);
    newList[index] = newList[index].copyWith(isSelected: value);
    state = state.copyWith(
        productDetailModelObj: state.productDetailModelObj
            ?.copyWith(chipviewmugwortItemList: newList));
  }
}
