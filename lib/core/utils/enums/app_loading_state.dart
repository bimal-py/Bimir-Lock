enum AppLoadingState {
  initial,
  loading,
  success,
  failure;

  bool get isInitial => this == AppLoadingState.initial;
  bool get isLoading => this == AppLoadingState.loading;
  bool get isSuccess => this == AppLoadingState.success;
  bool get isFailure => this == AppLoadingState.failure;
}
