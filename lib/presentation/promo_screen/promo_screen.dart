import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/appbar_subtitle.dart';
import '../../widgets/app_bar/appbar_trailing_image.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import 'models/bannerlist_item_model.dart';
import 'notifier/promo_notifier.dart';
import 'widgets/bannerlist_item_widget.dart';

class PromoScreen extends ConsumerStatefulWidget {
  const PromoScreen({super.key});

  @override
  WireframePromoScreenState createState() => WireframePromoScreenState();
}

class WireframePromoScreenState extends ConsumerState<PromoScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Container(
        width: double.maxFinite,
        padding: EdgeInsets.symmetric(horizontal: 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [SizedBox(height: 16.h), _buildBannerList(context)],
        ),
      ),
    );
  }

  /// Section Widget
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return CustomAppBar(
      leadingWidth: 30.h,
      leading: AppbarLeadingImage(
        imagePath: ImageConstant.imgArrowLeft,
        margin: EdgeInsets.only(
          left: 25.h,
          top: 69.h,
          bottom: 17.h,
        ),
        onTap: () {
          onTapArrowleftone(context);
        },
      ),
      centerTitle: true,
      title: AppbarSubtitle(
        text: "lbl_special_promo".tr,
        margin: EdgeInsets.only(
          top: 70.h,
          bottom: 18.h,
        ),
      ),
      actions: [
        AppbarTrailingImage(
          imagePath: ImageConstant.imgTelevision,
          height: 26.h,
          width: 32.h,
          margin: EdgeInsets.only(
            top: 71.h,
            right: 25.h,
            bottom: 19.h,
          ),
        )
      ],
      styleType: Style.bgShadow,
    );
  }

  /// Section Widget
  Widget _buildBannerList(BuildContext context) {
    return Expanded(
      child: Consumer(
        builder: (context, ref, _) {
          return ListView.separated(
            padding: EdgeInsets.zero,
            physics: BouncingScrollPhysics(),
            shrinkWrap: true,
            separatorBuilder: (context, index) {
              return SizedBox(
                height: 20.h,
              );
            },
            itemCount: ref
                    .watch(promoNotifier)
                    .PromoModelObj
                    ?.bannerlistItemList
                    .length ??
                0,
            itemBuilder: (context, index) {
              BannerlistItemModel model = ref
                      .watch(promoNotifier)
                      .PromoModelObj
                      ?.bannerlistItemList[index] ??
                  BannerlistItemModel();
              return BannerlistItemWidget(
                model,
              );
            },
          );
        },
      ),
    );
  }

  /// Navigates back to the previous screen.
  onTapArrowleftone(BuildContext context) {
    NavigatorService.goBack();
  }
}
