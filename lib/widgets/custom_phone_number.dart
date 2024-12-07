import 'package:flutter/material.dart';
import 'package:country_pickers/country.dart';
import 'package:country_pickers/country_pickers.dart';
import '../core/app_export.dart';

class CustomPhoneNumber extends StatefulWidget {
  const CustomPhoneNumber({
    super.key,
    this.initialCountry,
    required this.onTap,
    required this.controller, required Country country,
  });

  final Country? initialCountry;
  final Function(Country) onTap;
  final TextEditingController? controller;

  @override
  State<CustomPhoneNumber> createState() => _CustomPhoneNumberState();
}

class _CustomPhoneNumberState extends State<CustomPhoneNumber> {
  late Country country;

  @override
  void initState() {
    super.initState();
    country = widget.initialCountry ??
        Country(
          isoCode: 'ID',
          iso3Code: 'IDN',
          phoneCode: '62',
          name: 'Indonesia',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: appTheme.whiteA700,
        borderRadius: BorderRadius.circular(
          8.h,
        ),
        border: Border.all(
          color: theme.colorScheme.primary,
          width: 1.h,
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              _openCountryPicker(context);
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 8.h,
                vertical: 10.h,
              ),
              decoration: BoxDecoration(
                color: appTheme.orange200,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(8.h),
                ),
                border: Border.all(
                  color: theme.colorScheme.primary,
                  width: 1.h,
                ),
              ),
              child: Row(
                children: [
                  CountryPickerUtils.getDefaultFlagImage(country),
                  const SizedBox(width: 8.0),
                  Text(
                    "+${country.phoneCode}",
                    style: CustomTextStyles.bodySmallOnPrimary,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: 300.h,
              margin: EdgeInsets.only(left: 10.h),
              child: TextFormField(
                focusNode: FocusNode(),
                autofocus: true,
                controller: widget.controller,
                style: theme.textTheme.bodySmall!,
                decoration: InputDecoration(
                  hintText: "lbl_8".tr,
                  hintStyle: theme.textTheme.bodySmall!,
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.h,
                    vertical: 10.h,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogItem(Country country) => Row(
        children: <Widget>[
          CountryPickerUtils.getDefaultFlagImage(country),
          Container(
            margin: EdgeInsets.only(
              left: 10.h,
            ),
            width: 60.h,
            child: Text(
              "+${country.phoneCode}",
              style: TextStyle(fontSize: 14.fSize),
            ),
          ),
          const SizedBox(width: 8.0),
          Flexible(
            child: Text(
              country.name,
              style: TextStyle(fontSize: 14.fSize),
            ),
          ),
        ],
      );

  void _openCountryPicker(BuildContext context) => showDialog(
        context: context,
        builder: (context) => CountryPickerDialog(
          searchInputDecoration: InputDecoration(
            hintText: 'Search...',
            hintStyle: TextStyle(fontSize: 14.fSize),
          ),
          isSearchable: true,
          title: Text(
            'Select your phone code',
            style: TextStyle(fontSize: 14.fSize),
          ),
          onValuePicked: (Country pickedCountry) {
            setState(() {
              country = pickedCountry;
            });
            widget.onTap(pickedCountry);
          },
          itemBuilder: _buildDialogItem,
        ),
      );
}
