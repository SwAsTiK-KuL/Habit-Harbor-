import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:habit_harbor/core/service/notification/notification_service.dart';
import '../../core/failures/failures.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/verify_token_usecase.dart';
import '../../domain/usecases/register_fcm_token_usecase.dart';
import '../../domain/usecases/remove_fcm_token_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final GetProfileUseCase getProfileUseCase;
  final VerifyTokenUseCase verifyTokenUseCase;
  final RegisterFcmTokenUseCase registerFcmTokenUseCase;
  final RemoveFcmTokenUseCase removeFcmTokenUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.getProfileUseCase,
    required this.verifyTokenUseCase,
    required this.registerFcmTokenUseCase,
    required this.removeFcmTokenUseCase,
  }) : super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<GetProfileRequested>(_onGetProfileRequested);
    on<AuthErrorCleared>(_onAuthErrorCleared);
  }

  Future<void> _registerFcmToken() async {
    try {
      final notificationService = GetIt.instance<NotificationService>();
      final fcmToken = await notificationService.getToken();
      if (fcmToken != null) {
        await registerFcmTokenUseCase(fcmToken);
        print('✅ FCM token registered');
      }
    } catch (e) {
      print('⚠️ FCM token registration skipped: $e');
    }
  }

  Future<void> _removeFcmToken() async {
    try {
      final notificationService = GetIt.instance<NotificationService>();
      final fcmToken = await notificationService.getToken();
      if (fcmToken != null) {
        await removeFcmTokenUseCase(fcmToken);
        print('✅ FCM token removed');
      }
    } catch (e) {
      print('⚠️ FCM token removal skipped: $e');
    }
  }

  /// ✅ FIX: Wrapped in try-catch.
  /// Without this, any exception thrown inside verifyTokenUseCase()
  /// (network error, Dio timeout, SSL issue, etc.) causes the BLoC
  /// handler to crash after emitting AuthLoading — no further state
  /// is ever emitted — leaving the splash screen frozen forever in
  /// release mode.
  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());
      print('🔵 AuthBloc: Checking auth status...');

      final result = await verifyTokenUseCase();

      result.fold(
        (failure) {
          print('🔵 AuthBloc: Token invalid → Unauthenticated');
          emit(AuthUnauthenticated());
        },
        (user) {
          print('✅ AuthBloc: Token valid → Authenticated');
          emit(AuthAuthenticated(user));
        },
      );
    } catch (e, st) {
      // ✅ This is the critical catch — in release mode any uncaught
      // exception here previously left state stuck on AuthLoading.
      print('❌ AuthBloc: _onCheckAuthStatus exception: $e');
      print('❌ AuthBloc: StackTrace: $st');
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());

      final result = await loginUseCase(event.request);

      result.fold(
        (failure) => emit(AuthError(_mapFailureToMessage(failure))),
        (authResponse) => emit(AuthAuthenticated(authResponse.user)),
      );

      if (result.isRight()) {
        await _registerFcmToken();
      }
    } catch (e) {
      print('❌ AuthBloc: _onLoginRequested exception: $e');
      emit(AuthError('Login failed. Please try again.'));
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());

      final result = await registerUseCase(event.request);

      result.fold((failure) {
        if (failure is ValidationFailure) {
          emit(AuthError(failure.message));
        } else {
          emit(AuthError(_mapFailureToMessage(failure)));
        }
      }, (authResponse) => emit(AuthAuthenticated(authResponse.user)));

      if (result.isRight()) {
        await _registerFcmToken();
      }
    } catch (e) {
      print('❌ AuthBloc: _onRegisterRequested exception: $e');
      emit(AuthError('Registration failed. Please try again.'));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());
      await _removeFcmToken();

      final result = await logoutUseCase();
      result.fold(
        (failure) => emit(AuthError(_mapFailureToMessage(failure))),
        (_) => emit(AuthUnauthenticated()),
      );
    } catch (e) {
      print('❌ AuthBloc: _onLogoutRequested exception: $e');
      // Force unauthenticated even if logout API fails
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onGetProfileRequested(
    GetProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());

      final result = await getProfileUseCase();
      result.fold(
        (failure) => emit(AuthError(_mapFailureToMessage(failure))),
        (user) => emit(AuthAuthenticated(user)),
      );
    } catch (e) {
      print('❌ AuthBloc: _onGetProfileRequested exception: $e');
      emit(AuthError('Failed to load profile.'));
    }
  }

  void _onAuthErrorCleared(AuthErrorCleared event, Emitter<AuthState> emit) {
    emit(AuthUnauthenticated());
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) return failure.message;
    if (failure is CacheFailure) return failure.message;
    if (failure is NetworkFailure) return failure.message;
    if (failure is ValidationFailure) return failure.message;
    return 'An unexpected error occurred';
  }
}
