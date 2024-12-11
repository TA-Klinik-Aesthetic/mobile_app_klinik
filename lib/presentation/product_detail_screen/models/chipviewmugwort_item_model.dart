import 'package:equatable/equatable.dart';

/// This class is used in the [chipviewmugwort_item_widget] screen.

// ignore_for_file: must_be_immutable
class ChipviewmugwortItemModel extends Equatable {
  ChipviewmugwortItemModel({this.mugwortsOne, this.isSelected}) {
    mugwortsOne = mugwortsOne ?? "Mugworts";
    isSelected = isSelected ?? false;
  }

  String? mugwortsOne;

  bool? isSelected;

  ChipviewmugwortItemModel copyWith({
    String? mugwortsOne,
    bool? isSelected,
  }) {
    return ChipviewmugwortItemModel(
      mugwortsOne: mugwortsOne ?? this.mugwortsOne,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  List<Object?> get props => [mugwortsOne, isSelected];
}
