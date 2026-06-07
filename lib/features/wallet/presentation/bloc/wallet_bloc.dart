import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:luxihub_handyman/features/wallet/domain/usecases/get_stripe_onboarding_url.dart';
import 'package:luxihub_handyman/features/wallet/domain/usecases/get_wallet_balance.dart';
import 'package:luxihub_handyman/features/wallet/domain/usecases/get_withdrawals.dart';
import 'package:luxihub_handyman/features/wallet/domain/usecases/request_withdrawal.dart';
import 'package:luxihub_handyman/features/wallet/presentation/bloc/wallet_event.dart';
import 'package:luxihub_handyman/features/wallet/presentation/bloc/wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final GetWalletBalance getWalletBalance;
  final GetWithdrawals getWithdrawals;
  final RequestWithdrawal requestWithdrawal;
  final GetStripeOnboardingUrl getStripeOnboardingUrl;

  WalletBloc({
    required this.getWalletBalance,
    required this.getWithdrawals,
    required this.requestWithdrawal,
    required this.getStripeOnboardingUrl,
  }) : super(const WalletInitial()) {
    on<WalletFetchRequested>(_onFetch);
    on<WithdrawalRequested>(_onRequestWithdrawal);
    on<ConnectStripeRequested>(_onConnectStripe);
  }

  Future<void> _onFetch(WalletFetchRequested event, Emitter<WalletState> emit) async {
    emit(const WalletLoading());
    final balanceResult = await getWalletBalance(ProfileIdParams(event.profileId));
    final withdrawalsResult = await getWithdrawals(ProfileIdParams(event.profileId));

    balanceResult.fold(
      (f) => emit(WalletError(f.message)),
      (wallet) => withdrawalsResult.fold(
        (f) => emit(WalletError(f.message)),
        (withdrawals) => emit(WalletLoaded(wallet: wallet, withdrawals: withdrawals)),
      ),
    );
  }

  Future<void> _onRequestWithdrawal(WithdrawalRequested event, Emitter<WalletState> emit) async {
    final result = await requestWithdrawal(RequestWithdrawalParams(
      profileId: event.profileId,
      amount: event.amount,
      bankName: event.bankName,
      accountLast4: event.accountLast4,
      platformFeePercent: event.platformFeePercent,
      feeAmount: event.feeAmount,
      netAmount: event.netAmount,
    ));
    await result.fold(
      (f) async => emit(WalletError(f.message)),
      (withdrawal) async {
        emit(WithdrawalSuccess(withdrawal));
        // Re-fetch so the balance reflects the DB-side deduction from the trigger.
        final balanceResult = await getWalletBalance(ProfileIdParams(event.profileId));
        final withdrawalsResult = await getWithdrawals(ProfileIdParams(event.profileId));
        balanceResult.fold(
          (f) => emit(WalletError(f.message)),
          (wallet) => withdrawalsResult.fold(
            (f) => emit(WalletError(f.message)),
            (withdrawals) => emit(WalletLoaded(wallet: wallet, withdrawals: withdrawals)),
          ),
        );
      },
    );
  }

  Future<void> _onConnectStripe(ConnectStripeRequested event, Emitter<WalletState> emit) async {
    emit(const WalletLoading());
    final result = await getStripeOnboardingUrl(ProfileIdParams(event.profileId));
    result.fold(
      (f) => emit(WalletError(f.message)),
      (url) => emit(StripeOnboardingUrlReady(url)),
    );
  }
}
