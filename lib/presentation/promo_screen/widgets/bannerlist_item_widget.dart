import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../models/bannerlist_item_model.dart';

// ignore_for_file: must_be_immutable
class BannerlistItemWidget extends StatelessWidget {
  BannerlistItemWidget(this.bannerlistItemModelObj, {Key? key})
      : super(
          key: key,
        );

  BannerlistItemModel bannerlistItemModelObj;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.symmetric(vertical: 90.h),
      decoration: BoxDecoration(
        color: appTheme.blueGray100,
        borderRadius: BorderRadiusStyle.roundedBorder24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            bannerlistItemModelObj.banner!,
            style: theme.textTheme.bodyLarge,
          )
        ],
      ),
    );
  }
}
