import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../models/productgrid_item_model.dart';

// ignore_for_file: must_be_immutable
class ProductgridItemWidget extends StatelessWidget {
  ProductgridItemWidget(this.productgridItemModelObj,
      {super.key, this.onTapColumnweight});

  ProductgridItemModel productgridItemModelObj;

  VoidCallback? onTapColumnweight;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTapColumnweight?.call();
      },
      child: Container(
        width: double.maxFinite,
        padding: EdgeInsets.symmetric(
          horizontal: 6.h,
          vertical: 8.h,
        ),
        decoration: BoxDecoration(
          color: appTheme.orange200,
          borderRadius: BorderRadiusStyle.roundedBorder16,
          border: Border.all(
            color: theme.colorScheme.primary,
            width: 1.h,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomImageView(
              imagePath: productgridItemModelObj.image!,
              height: 164.h,
              width: 164.h,
              radius: BorderRadius.circular(
                16.h,
              ),
            ),
            SizedBox(height: 4.h),
            Container(
              width: double.maxFinite,
              margin: EdgeInsets.only(left: 2.h),
              child: Text(
                productgridItemModelObj.weight!,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge,
              ),
            ),
            SizedBox(height: 4.h),
            Container(
              width: 80.h,
              margin: EdgeInsets.only(left: 2.h),
              child: Text(
                productgridItemModelObj.rpCounter!,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
            SizedBox(height: 8.h)
          ],
        ),
      ),
    );
  }
}
