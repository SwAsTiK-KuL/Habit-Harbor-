import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/failures/failures.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/verify_token_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final GetProfileUseCase getProfileUseCase;
  final VerifyTokenUseCase verifyTokenUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.getProfileUseCase,
    required this.verifyTokenUseCase,
  }) : super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<GetProfileRequested>(_onGetProfileRequested);
    on<AuthErrorCleared>(_onAuthErrorCleared);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await verifyTokenUseCase();
    result.fold(
      (failure) => emit(AuthUnauthenticated()),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await loginUseCase(event.request);
    result.fold(
      (failure) => emit(AuthError(_mapFailureToMessage(failure))),
      (authResponse) => emit(AuthAuthenticated(authResponse.user)),
    );
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await registerUseCase(event.request);
    result.fold((failure) {
      if (failure is ValidationFailure) {
        // Try to parse validation errors if they exist
        emit(AuthError(failure.message));
      } else {
        emit(AuthError(_mapFailureToMessage(failure)));
      }
    }, (authResponse) => emit(AuthAuthenticated(authResponse.user)));
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await logoutUseCase();
    result.fold(
      (failure) => emit(AuthError(_mapFailureToMessage(failure))),
      (_) => emit(AuthUnauthenticated()),
    );
  }

  Future<void> _onGetProfileRequested(
    GetProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await getProfileUseCase();
    result.fold(
      (failure) => emit(AuthError(_mapFailureToMessage(failure))),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  void _onAuthErrorCleared(AuthErrorCleared event, Emitter<AuthState> emit) {
    emit(AuthUnauthenticated());
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return failure.message;
      case CacheFailure:
        return failure.message;
      case NetworkFailure:
        return failure.message;
      case ValidationFailure:
        return failure.message;
      default:
        return 'An unexpected error occurred';
    }
  }
}
