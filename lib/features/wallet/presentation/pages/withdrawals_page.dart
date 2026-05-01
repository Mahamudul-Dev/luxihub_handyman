import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:luxihub_handyman/core/di/service_locator.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_state.dart';
import 'package:luxihub_handyman/features/wallet/domain/entities/withdrawal.dart';
import 'package:luxihub_handyman/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:luxihub_handyman/features/wallet/presentation/bloc/wallet_event.dart';
import 'package:luxihub_handyman/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:luxihub_handyman/features/wallet/presentation/widgets/withdrawal_tile.dart';

String _formatDate(String isoString) {
  final dt = DateTime.tryParse(isoString)?.toLocal();
  if (dt == null) return isoString;
  return '${dt.day}/${dt.month}/${dt.year}';
}

class WithdrawalsPage extends StatefulWidget {
  const WithdrawalsPage({super.key});

  @override
  State<WithdrawalsPage> createState() => _WithdrawalsPageState();
}

class _WithdrawalsPageState extends State<WithdrawalsPage> {
  static const _filters = ['All', 'Completed', 'Pending'];

  late final WalletBloc _walletBloc;
  String _selectedFilter = 'All';
  String _searchQuery = '';

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

  List<Withdrawal> _filter(List<Withdrawal> withdrawals) {
    return withdrawals.where((w) {
      final matchesFilter = _selectedFilter == 'All' ||
          w.status.toLowerCase() == _selectedFilter.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          w.bankName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          w.accountLast4.contains(_searchQuery);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _walletBloc,
      child: Scaffold(
        backgroundColor: AppColors.surfaceBackground,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceBackground,
          title: Text('Withdrawals', style: AppTextStyles.titleLarge),
        ),
        body: BlocBuilder<WalletBloc, WalletState>(
          builder: (context, state) {
            final allWithdrawals =
                state is WalletLoaded ? state.withdrawals : <Withdrawal>[];
            final items = _filter(allWithdrawals);
            final isLoading =
                state is WalletLoading || state is WalletInitial;

            return Column(
              children: [
                // ── Search + filter ───────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                  child: Column(
                    children: [
                      TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: AppTextStyles.inputText,
                        decoration: InputDecoration(
                          hintText: 'Search by bank or account...',
                          hintStyle: AppTextStyles.inputHint,
                          prefixIcon: Icon(Icons.search_rounded,
                              size: 20.r, color: AppColors.textHint),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.close_rounded,
                                      size: 18.r, color: AppColors.textHint),
                                  onPressed: () =>
                                      setState(() => _searchQuery = ''),
                                )
                              : null,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 12.h),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.r),
                            borderSide: const BorderSide(
                                color: AppColors.inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.r),
                            borderSide: const BorderSide(
                                color: AppColors.inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.r),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 1.5),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: _filters.map((filter) {
                          final isActive = filter == _selectedFilter;
                          return Padding(
                            padding: EdgeInsets.only(right: 8.w),
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedFilter = filter),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.primary
                                      : AppColors.background,
                                  borderRadius:
                                      BorderRadius.circular(50.r),
                                  border: Border.all(
                                    color: isActive
                                        ? AppColors.primary
                                        : AppColors.inputBorder,
                                  ),
                                ),
                                child: Text(
                                  filter,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isActive
                                        ? AppColors.textOnPrimary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Text(
                            '${items.length} ${items.length == 1 ? 'withdrawal' : 'withdrawals'}',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textHint),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                    ],
                  ),
                ),

                // ── List ─────────────────────────────────────────────
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : items.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.inbox_rounded,
                                      size: 48.r,
                                      color: AppColors.textHint),
                                  SizedBox(height: 12.h),
                                  Text(
                                    'No withdrawals found',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textHint),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.fromLTRB(
                                  16.w, 4.h, 16.w, 32.h),
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final w = items[index];
                                return WithdrawalTile(
                                  amount: w.amount,
                                  bankName: w.bankName,
                                  accountLast4: w.accountLast4,
                                  date: _formatDate(w.createdAt),
                                  status: w.status,
                                );
                              },
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
