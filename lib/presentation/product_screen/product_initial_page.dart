import 'package:flutter/material.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import '../../core/app_export.dart';
import '../../widgets/app_bar/appbar_subtitle.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import '../../widgets/custom_outlined_button.dart';
import '../../widgets/custom_search_view.dart';

class ProductInitialPage extends StatefulWidget {
  const ProductInitialPage({super.key});

  @override
  ProductInitialPageState createState() => ProductInitialPageState();
}

class ProductInitialPageState extends State<ProductInitialPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      decoration: BoxDecoration(
        color: appTheme.whiteA700,
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.maxFinite,
            child: _buildAppBar(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.maxFinite,
                padding: EdgeInsets.symmetric(horizontal: 24.h),
                child: Column(
                  children: [
                    SizedBox(height: 4.h),
                    _buildSearchRow(context),
                    SizedBox(height: 16.h),
                    _buildProductGrid(context)
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  /// Section Widget
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return CustomAppBar(
      height: 56.h,
      centerTitle: true,
      title: AppbarSubtitle(
        text: "lbl_facial_product".tr,
      ),
    );
  }

  /// Section Widget
  Widget _buildSearchRow(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: CustomSearchView(
              hintText: "lbl_search".tr,
              contentPadding: EdgeInsets.fromLTRB(14.h, 8.h, 12.h, 8.h),
            ),
          ),
          SizedBox(width: 12.h),
          CustomOutlinedButton(
            width: 100.h,
            text: "lbl_urutkan".tr,
            rightIcon: Container(
              margin: EdgeInsets.only(left: 14.h),
              child: CustomImageView(
                imagePath: ImageConstant.imgTelevision,
                height: 14.h,
                width: 18.h,
                fit: BoxFit.contain,
              ),
            ),
          )
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildProductGrid(BuildContext context) {
    // Replace this with your actual product items
    List<Widget> gridItems = []; // Populate this list with your product widgets

    return ResponsiveGridListBuilder(
      minItemWidth: 1,
      minItemsPerRow: 2,
      maxItemsPerRow: 2,
      horizontalGridSpacing: 12.h,
      verticalGridSpacing: 12.h,
      builder: (context, items) => ListView(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        children: items,
      ),
      gridItems: gridItems,
    );
  }

  /// Navigates to the promoDetailScreen when the action is triggered.
  onTapColumnweight(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.productDetailScreen,
    );
  }
}