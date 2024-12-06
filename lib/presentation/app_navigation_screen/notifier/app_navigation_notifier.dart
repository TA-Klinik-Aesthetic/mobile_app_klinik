import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/app_navigation_model.dart';
part 'app_navigation_state.dart';

final appNavigationNotifier = StateNotifierProvider.autoDispose<
    AppNavigationNotifier, AppNavigationState>(
  (ref) => AppNavigationNotifier(AppNavigationState()),
);

/// A notifier that manages the state of a AppNavigation according to the event that is dispatched to it.
class AppNavigationNotifier extends StateNotifier<AppNavigationState> {
  AppNavigationNotifier(AppNavigationState state) : super(state);
}
