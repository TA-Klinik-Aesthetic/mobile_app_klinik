import 'package:equatable/equatable.dart';

/// This class defines the variables used in the [product_screen],
/// and is typically used to hold data that is passed between different parts of the application.
class ProductModel extends Equatable {
  const ProductModel();

  ProductModel copyWith() {
    return const ProductModel();
  }

  @override
  List<Object?> get props => [];
}
