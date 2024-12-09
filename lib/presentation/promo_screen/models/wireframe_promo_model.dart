import 'package:equatable/equatable.dart';
import 'bannerlist_item_model.dart';

/// This class defines the variables used in the [wireframe_promo_screen],
/// and is typically used to hold data that is passed between different parts of the application.

// ignore_for_file: must_be_immutable
class PromoModel extends Equatable {
  PromoModel({this.bannerlistItemList = const []});

  List<BannerlistItemModel> bannerlistItemList;

  PromoModel copyWith(
      {List<BannerlistItemModel>? bannerlistItemList}) {
    return PromoModel(
      bannerlistItemList: bannerlistItemList ?? this.bannerlistItemList,
    );
  }

  @override
  List<Object?> get props => [bannerlistItemList];
}
