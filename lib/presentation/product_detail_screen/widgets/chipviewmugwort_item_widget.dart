import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../models/chipviewmugwort_item_model.dart';

// ignore_for_file: must_be_immutable
class ChipviewmugwortItemWidget extends StatelessWidget {
  ChipviewmugwortItemWidget(this.chipviewmugwortItemModelObj,
      {super.key, this.onSelectedChipView});

  ChipviewmugwortItemModel chipviewmugwortItemModelObj;

  Function(bool)? onSelectedChipView;

  @override
  Widget build(BuildContext context) {
    return RawChip(
      padding: EdgeInsets.symmetric(
        horizontal: 10.h,
        vertical: 2.h,
      ),
      showCheckmark: false,
      labelPadding: EdgeInsets.zero,
      label: Text(
        chipviewmugwortItemModelObj.mugwortsOne!,
        style: TextStyle(
          color: appTheme.black900,
          fontSize: 16.fSize,
          fontFamily: 'Lato',
          fontWeight: FontWeight.w400,
        ),
      ),
      selected: (chipviewmugwortItemModelObj.isSelected ?? false),
      backgroundColor: appTheme.whiteA700,
      selectedColor: theme.colorScheme.primary,
      shape: (chipviewmugwortItemModelObj.isSelected ?? false)
          ? RoundedRectangleBorder(
              side: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.h,
              ),
              borderRadius: BorderRadius.circular(
                6.h,
              ))
          : RoundedRectangleBorder(
              side: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.h,
              ),
              borderRadius: BorderRadius.circular(
                6.h,
              ),
            ),
      onSelected: (value) {
        onSelectedChipView?.call(value);
      },
    );
  }
}
