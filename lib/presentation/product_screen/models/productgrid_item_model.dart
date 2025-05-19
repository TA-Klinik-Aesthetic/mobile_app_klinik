import '../../../core/app_export.dart';

// ignore_for_file: must_be_immutable
class ProductgridItemModel {
  ProductgridItemModel({this.image, this.weight, this.rpCounter, this.id}) {
    image = image ?? ImageConstant.imgRectangle7;
    weight = weight ?? "Skintific - Acne Clay Stick 40G";
    rpCounter = rpCounter ?? "Rp 100.000,00";
    id = id ?? "";
  }

  String? image;

  String? weight;

  String? rpCounter;

  String? id;
}
