import 'package:equatable/equatable.dart';
import 'chipviewmugwort_item_model.dart';
import 'relatedproducts_item_model.dart';


// ignore_for_file: must_be_immutable
class ProductDetailModel extends Equatable {
  ProductDetailModel(
      {this.chipviewmugwortItemList = const [],
      this.relatedproductsItemList = const []});

  List<ChipviewmugwortItemModel> chipviewmugwortItemList;

  List<RelatedproductsItemModel> relatedproductsItemList;

  ProductDetailModel copyWith({
    List<ChipviewmugwortItemModel>? chipviewmugwortItemList,
    List<RelatedproductsItemModel>? relatedproductsItemList,
  }) {
    return ProductDetailModel(
      chipviewmugwortItemList:
          chipviewmugwortItemList ?? this.chipviewmugwortItemList,
      relatedproductsItemList:
          relatedproductsItemList ?? this.relatedproductsItemList,
    );
  }

  @override
  List<Object?> get props => [chipviewmugwortItemList, relatedproductsItemList];
}
