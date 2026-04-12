import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:luxihub_handyman/core/dummy/dummy.dart';
import 'package:luxihub_handyman/core/router/app_routes.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';
import 'package:luxihub_handyman/features/wallet/presentation/widgets/wallet_balance_card.dart';
import 'package:luxihub_handyman/features/wallet/presentation/widgets/withdrawal_tile.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceBackground,
        title: Text('Wallet', style: AppTextStyles.titleLarge),
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Balance card ────────────────────────────────────────────────
            WalletBalanceCard(
              balance: Dummy.walletBalance,
              onWithdraw: () {},
            ),

            SizedBox(height: 28.h),

            // ── Recent withdrawals ──────────────────────────────────────────
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
            ...Dummy.recentWithdrawals.map(
              (w) => WithdrawalTile(
                amount: w.amount,
                bankName: w.bankName,
                accountLast4: w.accountLast4,
                date: w.date,
                status: w.status,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
