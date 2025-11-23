// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preferences_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserPreferencesNotifier)
const userPreferencesProvider = UserPreferencesNotifierProvider._();

final class UserPreferencesNotifierProvider
    extends $AsyncNotifierProvider<UserPreferencesNotifier, UserPreferences> {
  const UserPreferencesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userPreferencesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userPreferencesNotifierHash();

  @$internal
  @override
  UserPreferencesNotifier create() => UserPreferencesNotifier();
}

String _$userPreferencesNotifierHash() =>
    r'580f7babefb5db7c9fff1ed78c5b67121ff7e94c';

abstract class _$UserPreferencesNotifier
    extends $AsyncNotifier<UserPreferences> {
  FutureOr<UserPreferences> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<UserPreferences>, UserPreferences>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<UserPreferences>, UserPreferences>,
              AsyncValue<UserPreferences>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
