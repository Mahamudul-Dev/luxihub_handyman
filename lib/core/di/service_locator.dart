import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:luxihub_handyman/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:luxihub_handyman/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:luxihub_handyman/features/authentication/domain/repositories/auth_repository.dart';
import 'package:luxihub_handyman/features/authentication/domain/usecases/get_current_user.dart';
import 'package:luxihub_handyman/features/authentication/domain/usecases/send_email_otp.dart';
import 'package:luxihub_handyman/features/authentication/domain/usecases/send_phone_otp.dart';
import 'package:luxihub_handyman/features/authentication/domain/usecases/sign_in_with_password.dart';
import 'package:luxihub_handyman/features/authentication/domain/usecases/sign_out.dart';
import 'package:luxihub_handyman/features/authentication/domain/usecases/sign_up_with_password.dart';
import 'package:luxihub_handyman/features/authentication/domain/usecases/get_account_status.dart';
import 'package:luxihub_handyman/features/authentication/domain/usecases/upload_kyc_documents.dart';
import 'package:luxihub_handyman/features/authentication/domain/usecases/verify_email_otp.dart';
import 'package:luxihub_handyman/features/authentication/domain/usecases/verify_phone_otp.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_bloc.dart';

import 'package:luxihub_handyman/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:luxihub_handyman/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:luxihub_handyman/features/profile/domain/repositories/profile_repository.dart';
import 'package:luxihub_handyman/features/profile/domain/usecases/get_profile.dart';
import 'package:luxihub_handyman/features/profile/domain/usecases/update_profile.dart';
import 'package:luxihub_handyman/features/profile/domain/usecases/upload_avatar.dart';
import 'package:luxihub_handyman/features/profile/presentation/bloc/profile_bloc.dart';

import 'package:luxihub_handyman/features/jobs/data/datasources/job_remote_datasource.dart';
import 'package:luxihub_handyman/features/jobs/data/repositories/job_repository_impl.dart';
import 'package:luxihub_handyman/features/jobs/domain/repositories/job_repository.dart';
import 'package:luxihub_handyman/features/jobs/domain/usecases/accept_job_request.dart';
import 'package:luxihub_handyman/features/jobs/domain/usecases/get_job_request_details.dart';
import 'package:luxihub_handyman/features/jobs/domain/usecases/get_job_requests.dart';
import 'package:luxihub_handyman/features/jobs/domain/usecases/reject_job_request.dart';
import 'package:luxihub_handyman/features/jobs/presentation/bloc/job_bloc.dart';

import 'package:luxihub_handyman/features/wallet/data/datasources/wallet_remote_datasource.dart';
import 'package:luxihub_handyman/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:luxihub_handyman/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:luxihub_handyman/features/wallet/domain/usecases/get_stripe_onboarding_url.dart';
import 'package:luxihub_handyman/features/wallet/domain/usecases/get_wallet_balance.dart';
import 'package:luxihub_handyman/features/wallet/domain/usecases/get_withdrawals.dart';
import 'package:luxihub_handyman/features/wallet/domain/usecases/request_withdrawal.dart';
import 'package:luxihub_handyman/features/wallet/presentation/bloc/wallet_bloc.dart';

import 'package:luxihub_handyman/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:luxihub_handyman/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:luxihub_handyman/features/chat/domain/repositories/chat_repository.dart';
import 'package:luxihub_handyman/features/chat/domain/usecases/get_conversations.dart';
import 'package:luxihub_handyman/features/chat/domain/usecases/get_messages.dart';
import 'package:luxihub_handyman/features/chat/domain/usecases/send_message.dart';
import 'package:luxihub_handyman/features/chat/presentation/bloc/chat_bloc.dart';

import 'package:luxihub_handyman/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:luxihub_handyman/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:luxihub_handyman/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:luxihub_handyman/features/dashboard/domain/usecases/get_all_earnings.dart';
import 'package:luxihub_handyman/features/dashboard/domain/usecases/get_dashboard_stats.dart';
import 'package:luxihub_handyman/features/dashboard/domain/usecases/get_recent_earnings.dart';
import 'package:luxihub_handyman/features/dashboard/domain/usecases/get_recent_job_requests.dart';
import 'package:luxihub_handyman/features/dashboard/presentation/bloc/dashboard_bloc.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // ── External ─────────────────────────────────────────────────────────────
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // ── Auth ──────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton(() => SendPhoneOtp(sl()));
  sl.registerLazySingleton(() => VerifyPhoneOtp(sl()));
  sl.registerLazySingleton(() => SendEmailOtp(sl()));
  sl.registerLazySingleton(() => VerifyEmailOtp(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => SignUpWithPassword(sl()));
  sl.registerLazySingleton(() => SignInWithPassword(sl()));
  sl.registerLazySingleton(() => UploadKycDocuments(sl()));
  sl.registerLazySingleton(() => GetAccountStatus(sl()));
  sl.registerLazySingleton(() => AuthBloc(
        sendPhoneOtp: sl(),
        verifyPhoneOtp: sl(),
        sendEmailOtp: sl(),
        verifyEmailOtp: sl(),
        signOut: sl(),
        getCurrentUser: sl(),
        uploadKycDocuments: sl(),
        getAccountStatus: sl(),
        signUpWithPassword: sl(),
        signInWithPassword: sl(),
      ));

  // ── Profile ───────────────────────────────────────────────────────────────
  sl.registerLazySingleton<ProfileRemoteDatasource>(
      () => ProfileRemoteDatasourceImpl(sl()));
  sl.registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetProfile(sl()));
  sl.registerLazySingleton(() => UpdateProfile(sl()));
  sl.registerLazySingleton(() => UploadAvatar(sl()));
  sl.registerFactory(() => ProfileBloc(
        getProfile: sl(),
        updateProfile: sl(),
        uploadAvatar: sl(),
      ));

  // ── Jobs ──────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<JobRemoteDatasource>(
      () => JobRemoteDatasourceImpl(sl()));
  sl.registerLazySingleton<JobRepository>(() => JobRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetJobRequests(sl()));
  sl.registerLazySingleton(() => GetJobRequestDetails(sl()));
  sl.registerLazySingleton(() => AcceptJobRequest(sl()));
  sl.registerLazySingleton(() => RejectJobRequest(sl()));
  sl.registerFactory(() => JobBloc(
        getJobRequests: sl(),
        getJobRequestDetails: sl(),
        acceptJobRequest: sl(),
        rejectJobRequest: sl(),
      ));

  // ── Wallet ────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<WalletRemoteDatasource>(
      () => WalletRemoteDatasourceImpl(sl()));
  sl.registerLazySingleton<WalletRepository>(
      () => WalletRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetWalletBalance(sl()));
  sl.registerLazySingleton(() => GetWithdrawals(sl()));
  sl.registerLazySingleton(() => RequestWithdrawal(sl()));
  sl.registerLazySingleton(() => GetStripeOnboardingUrl(sl()));
  sl.registerFactory(() => WalletBloc(
        getWalletBalance: sl(),
        getWithdrawals: sl(),
        requestWithdrawal: sl(),
        getStripeOnboardingUrl: sl(),
      ));

  // ── Chat ──────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<ChatRemoteDatasource>(
      () => ChatRemoteDatasourceImpl(sl()));
  sl.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetConversations(sl()));
  sl.registerLazySingleton(() => GetMessages(sl()));
  sl.registerLazySingleton(() => SendMessage(sl()));
  sl.registerFactory(() => ChatBloc(
        getConversations: sl(),
        getMessages: sl(),
        sendMessage: sl(),
        repository: sl(),
      ));

  // ── Dashboard ─────────────────────────────────────────────────────────────
  sl.registerLazySingleton<DashboardRemoteDataSource>(
      () => DashboardRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<DashboardRepository>(
      () => DashboardRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetDashboardStats(sl()));
  sl.registerLazySingleton(() => GetRecentEarnings(sl()));
  sl.registerLazySingleton(() => GetAllEarnings(sl()));
  sl.registerLazySingleton(() => GetRecentJobRequests(sl()));
  sl.registerFactory(() => DashboardBloc(
        getDashboardStats: sl(),
        getRecentEarnings: sl(),
        getAllEarnings: sl(),
        getRecentJobRequests: sl(),
        repository: sl(),
      ));
}
