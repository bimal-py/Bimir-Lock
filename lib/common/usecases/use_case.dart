import 'dart:async';

abstract class UseCase<ReturnType, Params> {
  FutureOr<ReturnType> execute(Params params);
}

abstract class StreamUseCase<ReturnType, Params> {
  Stream<ReturnType> execute(Params params);
}
