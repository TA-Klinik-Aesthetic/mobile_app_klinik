import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/bannerlist_item_model.dart';
import '../models/wireframe_promo_model.dart';
part 'promo_state.dart';

final promoNotifier = StateNotifierProvider.autoDispose<
    PromoNotifier, PromoState>(
  (ref) => PromoNotifier(PromoState(
    PromoModelObj: PromoModel(bannerlistItemList: [
      BannerlistItemModel(banner: "Banner"),
      BannerlistItemModel(banner: "Banner"),
      BannerlistItemModel(banner: "Banner"),
      BannerlistItemModel(banner: "Banner")
    ]),
  )),
);

/// A notifier that manages the state of a Promo according to the event that is dispatched to it.
class PromoNotifier extends StateNotifier<PromoState> {
  PromoNotifier(super.state);
}
