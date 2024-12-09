part of 'promo_notifier.dart';

/// Represents the state of Promo in the application.

// ignore_for_file: must_be_immutable
class PromoState extends Equatable {
  PromoState({this.PromoModelObj});

  PromoModel? PromoModelObj;

  @override
  List<Object?> get props => [PromoModelObj];
  PromoState copyWith({PromoModel? PromoModelObj}) {
    return PromoState(
      PromoModelObj:
          PromoModelObj ?? this.PromoModelObj,
    );
  }
}
