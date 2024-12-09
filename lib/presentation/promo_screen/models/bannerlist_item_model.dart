import '../../../core/app_export.dart';

/// This class is used in the [bannerlist_item_widget] screen.

// ignore_for_file: must_be_immutable
class BannerlistItemModel {
  BannerlistItemModel({this.banner, this.id}) {
    banner = banner ?? "Banner";
    id = id ?? "";
  }

  String? banner;

  String? id;
}
