import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  void _showWithdrawalSheet(
      double balance, String? stripeAccountId, double feePercent) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WithdrawalSheet(
        balance: balance,
        stripeAccountId: stripeAccountId,
        platformFeePercent: feePercent,
        onSubmit: (amount, bankName, accountLast4, feeAmount, netAmount) {
          if (_profileId == null) return;
          _walletBloc.add(WithdrawalRequested(
            profileId: _profileId!,
            amount: amount,
            bankName: bankName,
            accountLast4: accountLast4,
            platformFeePercent: feePercent,
            feeAmount: feeAmount,
            netAmount: netAmount,
          ));
        },
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

            return RefreshIndicator(
              onRefresh: () async {
                if (_profileId != null) {
                  _walletBloc.add(WalletFetchRequested(_profileId!));
                }
              },
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  WalletBalanceCard(
                    balance: loaded?.wallet.balance ?? 0.0,
                    platformFeePercent: loaded?.wallet.platformFeePercent ?? 10.0,
                    onWithdraw: () {
                      if (!stripeReady) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please connect your Stripe payout account first'),
                          ),
                        );
                        return;
                      }
                      _showWithdrawalSheet(
                        loaded?.wallet.balance ?? 0.0,
                        loaded?.wallet.stripeAccountId,
                        loaded?.wallet.platformFeePercent ?? 10.0,
                      );
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

// ── Withdrawal bottom sheet ──────────────────────────────────────────────────

class _WithdrawalSheet extends StatefulWidget {
  const _WithdrawalSheet({
    required this.balance,
    required this.onSubmit,
    required this.platformFeePercent,
    this.stripeAccountId,
  });

  final double balance;
  final String? stripeAccountId;
  final double platformFeePercent;
  final void Function(
    double amount,
    String bankName,
    String accountLast4,
    double feeAmount,
    double netAmount,
  ) onSubmit;

  @override
  State<_WithdrawalSheet> createState() => _WithdrawalSheetState();
}

class _WithdrawalSheetState extends State<_WithdrawalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  String? _bankName;
  String? _accountLast4;
  bool _loadingBank = true;
  String? _bankError;

  @override
  void initState() {
    super.initState();
    _fetchBankDetails();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _fetchBankDetails() async {
    if (widget.stripeAccountId == null) {
      setState(() => _loadingBank = false);
      return;
    }
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'get-stripe-bank-details',
        body: {'stripe_account_id': widget.stripeAccountId},
      );
      final data = res.data as Map<String, dynamic>?;
      if (mounted) {
        setState(() {
          _bankName = data?['bank_name'] as String?;
          _accountLast4 = data?['account_last4'] as String?;
          _loadingBank = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _bankError = 'Could not load bank details: $e';
          _loadingBank = false;
        });
      }
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final gross = double.parse(_amountController.text.trim());
    final fee = double.parse(
        (gross * widget.platformFeePercent / 100).toStringAsFixed(2));
    final net = double.parse((gross - fee).toStringAsFixed(2));
    Navigator.of(context).pop();
    widget.onSubmit(gross, _bankName ?? '', _accountLast4 ?? '', fee, net);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding:
            EdgeInsets.fromLTRB(20.w, 20.h, 20.w, bottomPadding + 24.h),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),

              Text('Request Withdrawal',
                  style: AppTextStyles.titleLarge.copyWith(fontSize: 17.sp)),
              SizedBox(height: 4.h),
              Text(
                'Available: £${widget.balance.toStringAsFixed(2)}',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textHint),
              ),
              SizedBox(height: 20.h),

              // ── Amount ────────────────────────────────────────────────
              TextFormField(
                controller: _amountController,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: AppTextStyles.inputText,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  prefixText: '£ ',
                ),
                validator: (v) {
                  final amount = double.tryParse(v ?? '');
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount';
                  }
                  if (amount > widget.balance) {
                    return 'Exceeds available balance (£${widget.balance.toStringAsFixed(2)})';
                  }
                  return null;
                },
              ),

              // ── Live fee breakdown ────────────────────────────────────
              Builder(builder: (_) {
                final gross =
                    double.tryParse(_amountController.text.trim());
                if (gross == null || gross <= 0) return const SizedBox.shrink();
                final fee = gross * widget.platformFeePercent / 100;
                final net = gross - fee;
                return Container(
                  margin: EdgeInsets.only(top: 12.h),
                  padding: EdgeInsets.all(14.r),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBackground,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      _FeeRow(
                        label: 'Gross amount',
                        value: '£${gross.toStringAsFixed(2)}',
                      ),
                      Divider(height: 16.h, color: AppColors.divider),
                      _FeeRow(
                        label:
                            'Platform fee (${widget.platformFeePercent.toStringAsFixed(0)}%)',
                        value: '− £${fee.toStringAsFixed(2)}',
                        valueColor: AppColors.error,
                      ),
                      SizedBox(height: 10.h),
                      _FeeRow(
                        label: 'You receive',
                        value: '£${net.toStringAsFixed(2)}',
                        bold: true,
                        valueColor: AppColors.primary,
                      ),
                    ],
                  ),
                );
              }),

              SizedBox(height: 20.h),

              // ── Bank details (read-only from Stripe) ──────────────────
              if (_loadingBank)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16.r,
                        height: 16.r,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text('Loading bank details…',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textHint)),
                    ],
                  ),
                )
              else if (_bankError != null)
                Text(_bankError!,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.error))
              else ...[
                _ReadOnlyBankRow(
                  icon: Icons.account_balance_rounded,
                  label: 'Bank',
                  value: _bankName ?? '—',
                ),
                SizedBox(height: 12.h),
                _ReadOnlyBankRow(
                  icon: Icons.credit_card_rounded,
                  label: 'Account',
                  value: _accountLast4 != null ? '•••• $_accountLast4' : '—',
                ),
              ],

              SizedBox(height: 24.h),

              ElevatedButton(
                onPressed: _loadingBank ? null : _submit,
                child: const Text('Submit Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyBankRow extends StatelessWidget {
  const _ReadOnlyBankRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38.r,
          height: 38.r,
          decoration: BoxDecoration(
            color: AppColors.surfaceBackground,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, size: 18.r, color: AppColors.textHint),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11.sp,
                    color: AppColors.textHint,
                  )),
              SizedBox(height: 2.h),
              Text(value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  )),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: AppColors.surfaceBackground,
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(color: AppColors.divider),
          ),
          child: Text(
            'From Stripe',
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 10.sp,
              color: AppColors.textHint,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeeRow extends StatelessWidget {
  const _FeeRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: bold ? AppColors.textPrimary : AppColors.textHint,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
