import 'package:flutter/material.dart';
// import 'product_initial_page.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  ProductScreenState createState() => ProductScreenState();
}

// ignore_for_file: must_be_immutable
class ProductScreenState extends State<ProductScreen> {
  GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      // body: Navigator(
      //   key: navigatorKey,
      //   initialRoute: AppRoutes.productInitialPage,
      //   onGenerateRoute: (routeSetting) => PageRouteBuilder(
        //   pageBuilder: (ctx, ani, ani1) =>
        //       getCurrentPage(context, routeSetting.name!),
        //   transitionDuration: const Duration(seconds: 1),
        // ),
      // ),
    );
  }

  // ///Handling page based on route
  // Widget getCurrentPage(
  //   BuildContext context,
  //   String currentRoute,
  // ) {
  //   switch (currentRoute) {
  //     case AppRoutes.productInitialPage:
  //       return const ProductInitialPage();
  //     default:
  //       return const DefaultWidget();
  //   }
  // }
}
