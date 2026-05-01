import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:luxihub_handyman/core/di/service_locator.dart';
import 'package:luxihub_handyman/core/router/app_routes.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_state.dart';
import 'package:luxihub_handyman/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:luxihub_handyman/features/wallet/presentation/bloc/wallet_event.dart';
import 'package:luxihub_handyman/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:luxihub_handyman/features/wallet/presentation/widgets/wallet_balance_card.dart';
import 'package:luxihub_handyman/features/wallet/presentation/widgets/withdrawal_tile.dart';

String _formatDate(String isoString) {
  final dt = DateTime.tryParse(isoString)?.toLocal();
  if (dt == null) return isoString;
  return '${dt.day}/${dt.month}/${dt.year}';
}

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  late final WalletBloc _walletBloc;

  @override
  void initState() {
    super.initState();
    _walletBloc = sl<WalletBloc>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        _walletBloc.add(WalletFetchRequested(authState.user.id));
      }
    });
  }

  @override
  void dispose() {
    _walletBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _walletBloc,
      child: Scaffold(
        backgroundColor: AppColors.surfaceBackground,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceBackground,
          title: Text('Wallet', style: AppTextStyles.titleLarge),
          centerTitle: false,
          automaticallyImplyLeading: false,
        ),
        body: BlocConsumer<WalletBloc, WalletState>(
          listener: (context, state) {
            if (state is WalletError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            if (state is WalletLoading || state is WalletInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is WalletError) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(24.r),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48.r, color: AppColors.error),
                      SizedBox(height: 12.h),
                      Text(state.message,
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textHint),
                          textAlign: TextAlign.center),
                      SizedBox(height: 16.h),
                      ElevatedButton(
                        onPressed: () {
                          final authState = context.read<AuthBloc>().state;
                          if (authState is AuthAuthenticated) {
                            _walletBloc
                                .add(WalletFetchRequested(authState.user.id));
                          }
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final loaded = state is WalletLoaded ? state : null;
            final recentWithdrawals =
                loaded?.withdrawals.take(4).toList() ?? [];

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WalletBalanceCard(
                    balance: loaded?.wallet.balance ?? 0.0,
                    onWithdraw: () {},
                  ),
                  SizedBox(height: 28.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Withdrawals',
                          style: AppTextStyles.titleLarge),
                      TextButton(
                        onPressed: () =>
                            context.push(AppRoutes.withdrawals.path),
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  if (recentWithdrawals.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.h),
                      child: Center(
                        child: Text(
                          'No withdrawals yet',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textHint),
                        ),
                      ),
                    )
                  else
                    ...recentWithdrawals.map(
                      (w) => WithdrawalTile(
                        amount: w.amount,
                        bankName: w.bankName,
                        accountLast4: w.accountLast4,
                        date: _formatDate(w.createdAt),
                        status: w.status,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
