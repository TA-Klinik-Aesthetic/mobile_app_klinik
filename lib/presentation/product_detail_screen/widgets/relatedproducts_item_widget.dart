import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../models/relatedproducts_item_model.dart';

// ignore_for_file: must_be_immutable
class RelatedproductsItemWidget extends StatelessWidget {
  RelatedproductsItemWidget(this.relatedproductsItemModelObj, {Key? key})
      : super(
          key: key,
        );

  RelatedproductsItemModel relatedproductsItemModelObj;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90.h,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 90.h,
          padding: EdgeInsets.all(4.h),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomImageView(
                imagePath: ImageConstant.imgRectangle776x76,
                height: 76.h,
                width: 76.h,
                radius: BorderRadius.circular(
                  12.h,
                ),
              ),
              SizedBox(height: 4.h),
              SizedBox(
                width: double.maxFinite,
                child: Text(
                  relatedproductsItemModelObj.weight!,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall,
                ),
              ),
              SizedBox(height: 2.h)
            ],
          ),
        ),
      ),
    );
  }
}
