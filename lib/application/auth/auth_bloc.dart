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

    // ✅ Emit FIRST inside fold (no async inside fold)
    result.fold(
      (failure) => emit(AuthError(_mapFailureToMessage(failure))),
      (authResponse) => emit(AuthAuthenticated(authResponse.user)),
    );

    // ✅ Await FCM AFTER fold+emit, only if login succeeded
    if (result.isRight()) {
      await _registerFcmToken();
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await registerUseCase(event.request);

    // ✅ Emit FIRST inside fold (no async inside fold)
    result.fold((failure) {
      if (failure is ValidationFailure) {
        emit(AuthError(failure.message));
      } else {
        emit(AuthError(_mapFailureToMessage(failure)));
      }
    }, (authResponse) => emit(AuthAuthenticated(authResponse.user)));

    // ✅ Await FCM AFTER fold+emit, only if register succeeded
    if (result.isRight()) {
      await _registerFcmToken();
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    await _removeFcmToken();

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
