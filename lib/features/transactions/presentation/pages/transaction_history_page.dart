import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:luxihub_handyman/core/di/service_locator.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_state.dart';
import 'package:luxihub_handyman/features/transactions/domain/entities/transaction.dart';
import 'package:luxihub_handyman/features/transactions/domain/usecases/get_invoice_pdf.dart';
import 'package:luxihub_handyman/features/transactions/presentation/bloc/transactions_bloc.dart';
import 'package:luxihub_handyman/features/transactions/presentation/bloc/transactions_event.dart';
import 'package:luxihub_handyman/features/transactions/presentation/bloc/transactions_state.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

String _formatDate(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  late final TransactionsBloc _bloc;
  String? _downloadingId;

  @override
  void initState() {
    super.initState();
    _bloc = sl<TransactionsBloc>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        _bloc.add(TransactionsFetchRequested(authState.user.id));
      }
    });
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  Future<void> _downloadInvoice(Transaction transaction) async {
    setState(() => _downloadingId = transaction.id);
    try {
      final result = await sl<GetInvoicePdf>()(TransactionIdParams(transaction.id));
      await result.fold(
        (failure) async {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not download invoice: ${failure.message}')),
            );
          }
        },
        (bytes) async {
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/invoice-${transaction.id.substring(0, 8)}.pdf');
          await file.writeAsBytes(bytes, flush: true);
          if (!mounted) return;
          await SharePlus.instance.share(
            ShareParams(files: [XFile(file.path)], fileNameOverrides: [file.uri.pathSegments.last]),
          );
        },
      );
    } finally {
      if (mounted) setState(() => _downloadingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: AppColors.surfaceBackground,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceBackground,
          title: Text('Transaction History', style: AppTextStyles.titleLarge),
        ),
        body: BlocBuilder<TransactionsBloc, TransactionsState>(
          builder: (context, state) {
            if (state is TransactionsLoading || state is TransactionsInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is TransactionsError) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(24.r),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48.r, color: AppColors.error),
                      SizedBox(height: 12.h),
                      Text(state.message,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
                      SizedBox(height: 16.h),
                      ElevatedButton(
                        onPressed: () {
                          final authState = context.read<AuthBloc>().state;
                          if (authState is AuthAuthenticated) {
                            _bloc.add(TransactionsFetchRequested(authState.user.id));
                          }
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final transactions = state is TransactionsLoaded ? state.transactions : <Transaction>[];

            if (transactions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 64.r, color: AppColors.textHint),
                    SizedBox(height: 16.h),
                    Text('No transactions yet',
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    SizedBox(height: 8.h),
                    Text('Completed and pending job payments will show up here',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: EdgeInsets.all(16.r),
              itemCount: transactions.length,
              separatorBuilder: (_, _) => SizedBox(height: 10.h),
              itemBuilder: (context, index) {
                final t = transactions[index];
                return _TransactionTile(
                  transaction: t,
                  isDownloading: _downloadingId == t.id,
                  onDownload: () => _downloadInvoice(t),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.isDownloading,
    required this.onDownload,
  });

  final Transaction transaction;
  final bool isDownloading;
  final VoidCallback onDownload;

  Color _statusColor() {
    switch (transaction.status) {
      case 'completed':
        return AppColors.success;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  String _formatAmount() {
    final symbol = transaction.currency.toLowerCase() == 'gbp' ? '£' : transaction.currency.toUpperCase();
    return '$symbol${transaction.amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final category = transaction.category.isNotEmpty
        ? transaction.category[0].toUpperCase() + transaction.category.substring(1)
        : 'Service';

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: AppColors.splashBackground,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 20.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                SizedBox(height: 3.h),
                Text(
                  '${transaction.clientName ?? 'Client'} · ${transaction.paymentMethod == 'stripe' ? 'Card' : 'Cash'} · ${_formatDate(transaction.createdAt)}',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint, fontSize: 11.sp),
                ),
                SizedBox(height: 4.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: _statusColor().withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    transaction.status[0].toUpperCase() + transaction.status.substring(1),
                    style: AppTextStyles.bodySmall
                        .copyWith(fontSize: 11.sp, fontWeight: FontWeight.w600, color: _statusColor()),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatAmount(), style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
              SizedBox(height: 6.h),
              if (transaction.status == 'completed')
                isDownloading
                    ? SizedBox(
                        width: 20.r,
                        height: 20.r,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: Icon(Icons.download_outlined, size: 20.r, color: AppColors.primary),
                        tooltip: 'Download invoice',
                        onPressed: onDownload,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
            ],
          ),
        ],
      ),
    );
  }
}
