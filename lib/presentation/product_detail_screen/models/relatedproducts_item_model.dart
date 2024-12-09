import '../../../core/app_export.dart';

/// This class is used in the [relatedproducts_item_widget] screen.

// ignore_for_file: must_be_immutable
class RelatedproductsItemModel {
  RelatedproductsItemModel({this.weight, this.id}) {
    weight = weight ?? "Skintific - Acne Clay Stick 40G";
    id = id ?? "";
  }

  String? weight;

  String? id;
}
