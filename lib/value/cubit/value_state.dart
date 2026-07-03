import 'package:equatable/equatable.dart';

import '../models/value_item.dart';
import '../services/value_service.dart';

/// Immutable state for the ranked values list. Holds the ordered values plus
/// the user's bookmarked quick-add presets and load/error flags.
class ValueState extends Equatable {
  /// All values, highest rank (lowest order) first.
  final List<ValueItem> values;

  /// The user's own bookmarked quick-add presets (defaults are added on top).
  final List<String> customPresets;
  final bool loading;
  final String? error;

  const ValueState({
    this.values = const [],
    this.customPresets = const [],
    this.loading = true,
    this.error,
  });

  ValueState copyWith({
    List<ValueItem>? values,
    List<String>? customPresets,
    bool? loading,
    Object? error = _sentinel,
  }) {
    return ValueState(
      values: values ?? this.values,
      customPresets: customPresets ?? this.customPresets,
      loading: loading ?? this.loading,
      error: error == _sentinel ? this.error : error as String?,
    );
  }

  static const Object _sentinel = Object();

  /// Quick-add suggestions shown in the add-value sheet: built-in defaults
  /// first, then the user's bookmarked ones, de-duplicated.
  List<String> get presets {
    final seen = <String>{};
    return [
      for (final t in [...kDefaultValuePresets, ...customPresets])
        if (seen.add(t)) t,
    ];
  }

  @override
  List<Object?> get props => [values, customPresets, loading, error];
}
