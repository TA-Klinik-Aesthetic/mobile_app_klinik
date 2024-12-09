import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/appbar_title.dart';
import '../../widgets/app_bar/appbar_trailing_image.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import '../../widgets/custom_outlined_button.dart';
import 'models/chipviewmugwort_item_model.dart';
import 'models/relatedproducts_item_model.dart';
import 'notifier/product_detail_notifier.dart';
import 'widgets/chipviewmugwort_item_widget.dart';
import 'widgets/relatedproducts_item_widget.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({Key? key})
      : super(
          key: key,
        );

  @override
  PromoDetailScreenState createState() => PromoDetailScreenState();
}

class PromoDetailScreenState extends ConsumerState<ProductDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Container(
        width: double.maxFinite,
        margin: EdgeInsets.only(bottom: 20.h),
        child: SingleChildScrollView(
          child: Container(
            width: double.maxFinite,
            decoration: BoxDecoration(
              color: appTheme.whiteA700,
            ),
            child: Column(
              children: [
                _buildProductImageGallery(context),
                SizedBox(height: 10.h),
                _buildProductDetails(context),
                SizedBox(height: 10.h),
                _buildRelatedProducts(context)
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Section Widget
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return CustomAppBar(
      height: 74.h,
      leadingWidth: 30.h,
      leading: AppbarLeadingImage(
        imagePath: ImageConstant.imgArrowLeft,
        margin: EdgeInsets.only(left: 25.h),
        onTap: () {
          onTapArrowleftone(context);
        },
      ),
      centerTitle: true,
      title: AppbarTitle(
        text: "lbl_detail_produk".tr,
      ),
      actions: [
        AppbarTrailingImage(
          imagePath: ImageConstant.imgSignal,
          height: 36.h,
          width: 38.h,
          margin: EdgeInsets.only(right: 25.h),
        )
      ],
      styleType: Style.bgShadow,
    );
  }

  /// Section Widget
  Widget _buildProductImageGallery(BuildContext context) {
    return SizedBox(
      width: 1712.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              height: 300.h,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomImageView(
                    imagePath: ImageConstant.imgRectangle7300x428,
                    height: 300.h,
                    width: double.maxFinite,
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      margin: EdgeInsets.only(
                        left: 26.h,
                        bottom: 16.h,
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 10.h),
                      decoration: BoxDecoration(
                        color: appTheme.blueGray100,
                        borderRadius: BorderRadiusStyle.circleBorder10,
                      ),
                      child: Text(
                        "lbl_1_4".tr,
                        textAlign: TextAlign.left,
                        style: CustomTextStyles.bodySmallOnPrimary,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.maxFinite,
              padding: EdgeInsets.only(
                left: 24.h,
                top: 16.h,
                bottom: 16.h,
              ),
              decoration: BoxDecoration(
                color: appTheme.blueGray100,
                border: Border.all(
                  color: appTheme.whiteA700,
                  width: 1.h,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 100.h),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      "lbl_photo_product".tr,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  SizedBox(height: 80.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.h,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: appTheme.blueGray100,
                      borderRadius: BorderRadiusStyle.circleBorder10,
                    ),
                    child: Text(
                      "lbl_2_4".tr,
                      textAlign: TextAlign.center,
                      style: CustomTextStyles.bodySmallOnPrimary,
                    ),
                  )
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.maxFinite,
              padding: EdgeInsets.only(
                left: 24.h,
                top: 16.h,
                bottom: 16.h,
              ),
              decoration: BoxDecoration(
                color: appTheme.blueGray100,
                border: Border.all(
                  color: appTheme.whiteA700,
                  width: 1.h,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 100.h),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      "lbl_photo_product".tr,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  SizedBox(height: 80.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.h,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: appTheme.blueGray100,
                      borderRadius: BorderRadiusStyle.circleBorder10,
                    ),
                    child: Text(
                      "lbl_3_4".tr,
                      textAlign: TextAlign.center,
                      style: CustomTextStyles.bodySmallOnPrimary,
                    ),
                  )
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.maxFinite,
              padding: EdgeInsets.only(
                left: 24.h,
                top: 14.h,
                bottom: 14.h,
              ),
              decoration: BoxDecoration(
                color: appTheme.blueGray100,
                border: Border.all(
                  color: appTheme.whiteA700,
                  width: 2.h,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 100.h),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      "lbl_photo_product".tr,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  SizedBox(height: 80.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.h,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: appTheme.blueGray100,
                      borderRadius: BorderRadiusStyle.circleBorder10,
                    ),
                    child: Text(
                      "lbl_4_4".tr,
                      textAlign: TextAlign.center,
                      style: CustomTextStyles.bodySmallOnPrimary,
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildProductDetails(BuildContext context) {
    return Container(
      width: double.maxFinite,
      margin: EdgeInsets.symmetric(horizontal: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "msg_skintific_acne".tr.toUpperCase(),
            style: CustomTextStyles.titleLargeSemiBold,
          ),
          SizedBox(height: 14.h),
          CustomOutlinedButton(
            height: 30.h,
            width: 110.h,
            text: "lbl_sabun_cuci_muka".tr,
            buttonStyle: CustomButtonStyles.outlinePrimaryTL6,
            buttonTextStyle: theme.textTheme.labelLarge!,
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: 198.h,
            child: Text(
              "lbl_rp_100_000_00".tr,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineLarge,
            ),
          ),
          SizedBox(height: 14.h),
          SizedBox(
            width: double.maxFinite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130.h,
                  child: Text(
                    "msg_dekskripsi_produk".tr,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  "msg_lorem_ipsum_dolor".tr,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.justify,
                  style: theme.textTheme.bodyLarge,
                ),
                SizedBox(
                  width: 52.h,
                  child: Text(
                    "lbl_see_more".tr,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                )
              ],
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: 102.h,
            child: Text(
              "lbl_varian_produk".tr,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
          ),
          SizedBox(height: 8.h),
          SizedBox(
            width: double.maxFinite,
            child: Consumer(
              builder: (context, ref, _) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Wrap(
                    direction: Axis.horizontal,
                    runSpacing: 7.h,
                    spacing: 7.h,
                    children: List<Widget>.generate(
                      ref
                              .watch(productDetailNotifier)
                              .productDetailModelObj
                              ?.chipviewmugwortItemList
                              .length ??
                          0,
                      (index) {
                        ChipviewmugwortItemModel model = ref
                                .watch(productDetailNotifier)
                                .productDetailModelObj
                                ?.chipviewmugwortItemList[index] ??
                            ChipviewmugwortItemModel();
                        return ChipviewmugwortItemWidget(
                          model,
                          onSelectedChipView: (value) {
                            ref
                                .read(productDetailNotifier.notifier)
                                .onSelectedChipView(index, value);
                          },
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: 234.h,
            child: Text(
              "msg_produk_sabun_cuci".tr,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
          )
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildRelatedProducts(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(left: 24.h),
        child: Consumer(
          builder: (context, ref, _) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                direction: Axis.horizontal,
                spacing: 6.h,
                children: List.generate(
                  ref
                          .watch(productDetailNotifier)
                          .productDetailModelObj
                          ?.relatedproductsItemList
                          .length ??
                      0,
                  (index) {
                    RelatedproductsItemModel model = ref
                            .watch(productDetailNotifier)
                            .productDetailModelObj
                            ?.relatedproductsItemList[index] ??
                        RelatedproductsItemModel();
                    return RelatedproductsItemWidget(
                      model,
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Navigates back to the previous screen.
  onTapArrowleftone(BuildContext context) {
    NavigatorService.goBack();
  }
}
