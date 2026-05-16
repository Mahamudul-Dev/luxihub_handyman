import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
  String? _profileId;

  @override
  void initState() {
    super.initState();
    _walletBloc = sl<WalletBloc>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        _profileId = authState.user.id;
        _walletBloc.add(WalletFetchRequested(_profileId!));
      }
    });
  }

  @override
  void dispose() {
    _walletBloc.close();
    super.dispose();
  }

  void _showWithdrawalDialog(double balance) {
    final amountController = TextEditingController();
    final bankController = TextEditingController();
    final last4Controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Request Withdrawal', style: AppTextStyles.titleMedium),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (€)',
                  prefixIcon: Icon(Icons.euro_rounded),
                ),
                validator: (v) {
                  final amount = double.tryParse(v ?? '');
                  if (amount == null || amount <= 0) return 'Enter a valid amount';
                  if (amount > balance) return 'Exceeds available balance';
                  return null;
                },
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: bankController,
                decoration: const InputDecoration(
                  labelText: 'Bank Name',
                  prefixIcon: Icon(Icons.account_balance_rounded),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter bank name' : null,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: last4Controller,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'Last 4 digits of account',
                  prefixIcon: Icon(Icons.credit_card_rounded),
                ),
                validator: (v) {
                  if (v == null || v.length != 4) return 'Enter last 4 digits';
                  if (int.tryParse(v) == null) return 'Digits only';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(dialogCtx).pop();
              if (_profileId == null) return;
              _walletBloc.add(WithdrawalRequested(
                profileId: _profileId!,
                amount: double.parse(amountController.text.trim()),
                bankName: bankController.text.trim(),
                accountLast4: last4Controller.text.trim(),
              ));
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
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
            if (state is WithdrawalSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Withdrawal request submitted — pending admin approval'),
                  backgroundColor: Colors.green,
                ),
              );
            }
            if (state is StripeOnboardingUrlReady) {
              launchUrl(Uri.parse(state.url), mode: LaunchMode.externalApplication);
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
                      Icon(Icons.error_outline, size: 48.r, color: AppColors.error),
                      SizedBox(height: 12.h),
                      Text(state.message,
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textHint),
                          textAlign: TextAlign.center),
                      SizedBox(height: 16.h),
                      ElevatedButton(
                        onPressed: () {
                          if (_profileId != null) {
                            _walletBloc.add(WalletFetchRequested(_profileId!));
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
            final recentWithdrawals = loaded?.withdrawals.take(4).toList() ?? [];
            final stripeReady = loaded?.wallet.stripePayoutsEnabled ?? false;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  WalletBalanceCard(
                    balance: loaded?.wallet.balance ?? 0.0,
                    onWithdraw: () {
                      if (!stripeReady) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please connect your Stripe payout account first'),
                          ),
                        );
                        return;
                      }
                      _showWithdrawalDialog(loaded?.wallet.balance ?? 0.0);
                    },
                  ),

                  // ── Stripe connect banner ─────────────────────────────
                  if (!stripeReady && loaded != null) ...[
                    SizedBox(height: 16.h),
                    _StripeConnectBanner(
                      onConnect: () {
                        if (_profileId != null) {
                          _walletBloc.add(ConnectStripeRequested(_profileId!));
                        }
                      },
                    ),
                  ],

                  SizedBox(height: 28.h),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Withdrawals', style: AppTextStyles.titleLarge),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.withdrawals.path),
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

class _StripeConnectBanner extends StatelessWidget {
  const _StripeConnectBanner({
    required this.onConnect,
  });
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFFFCC02), width: 1),
      ),
      child: 
      Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: const Color(0xFFE65100), size: 28.r),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payout account not connected',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5D4037),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Connect Stripe to receive withdrawal payouts',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: const Color(0xFF795548)),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: ElevatedButton(
              onPressed: onConnect,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF635BFF),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                textStyle:
                    AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
              ),
              child: const Text('Connect'),
            ),
          ),
        ],
      ),
    );
  }
}
