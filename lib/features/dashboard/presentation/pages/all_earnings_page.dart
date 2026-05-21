import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:luxihub_handyman/core/di/service_locator.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_state.dart';
import 'package:luxihub_handyman/features/dashboard/domain/entities/earning.dart';
import 'package:luxihub_handyman/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:luxihub_handyman/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:luxihub_handyman/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:luxihub_handyman/features/dashboard/presentation/widgets/earnings_tile.dart';

String _formatDate(String? isoString) {
  if (isoString == null) return '';
  final dt = DateTime.tryParse(isoString)?.toLocal();
  if (dt == null) return isoString;
  return '${dt.day}/${dt.month}/${dt.year}';
}

class AllEarningsPage extends StatefulWidget {
  const AllEarningsPage({super.key});

  @override
  State<AllEarningsPage> createState() => _AllEarningsPageState();
}

class _AllEarningsPageState extends State<AllEarningsPage> {
  late final DashboardBloc _dashboardBloc;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _dashboardBloc = sl<DashboardBloc>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        _dashboardBloc.add(AllEarningsFetchRequested(authState.user.id));
      }
    });
  }

  @override
  void dispose() {
    _dashboardBloc.close();
    super.dispose();
  }

  List<Earning> _filter(List<Earning> earnings) {
    if (_searchQuery.isEmpty) return earnings;
    final q = _searchQuery.toLowerCase();
    return earnings.where((e) =>
        e.clientName.toLowerCase().contains(q) ||
        e.jobCategory.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _dashboardBloc,
      child: Scaffold(
        backgroundColor: AppColors.surfaceBackground,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceBackground,
          title: Text('All Earnings', style: AppTextStyles.titleLarge),
        ),
        body: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            final isLoading =
                state is DashboardLoading || state is DashboardInitial;
            final earnings =
                state is AllEarningsLoaded ? state.earnings : <Earning>[];
            final errorMessage =
                state is DashboardError ? state.message : null;
            final items = _filter(earnings);

            return Column(
              children: [
                // ── Search ────────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: AppTextStyles.inputText,
                        decoration: InputDecoration(
                          hintText: 'Search by client or category...',
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
                            borderSide:
                                const BorderSide(color: AppColors.inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.r),
                            borderSide:
                                const BorderSide(color: AppColors.inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.r),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 1.5),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      if (!isLoading && errorMessage == null)
                        Text(
                          '${items.length} ${items.length == 1 ? 'earning' : 'earnings'}',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textHint),
                        ),
                      SizedBox(height: 8.h),
                    ],
                  ),
                ),

                // ── List ─────────────────────────────────────────────
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : errorMessage != null
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.r),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.error_outline,
                                        size: 48.r, color: AppColors.error),
                                    SizedBox(height: 12.h),
                                    Text(
                                      errorMessage,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.textHint),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
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
                                        _searchQuery.isEmpty
                                            ? 'No earnings yet'
                                            : 'No results for "$_searchQuery"',
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
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
                                    final e = items[index];
                                    return EarningsTile(
                                      clientName: e.clientName,
                                      jobCategory: e.jobCategory,
                                      date: _formatDate(e.date),
                                      amount: e.amount,
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
