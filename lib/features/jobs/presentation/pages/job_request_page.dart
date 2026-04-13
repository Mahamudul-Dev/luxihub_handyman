import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:luxihub_handyman/core/dummy/dummy.dart';
import 'package:luxihub_handyman/core/router/app_routes.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';
import 'package:luxihub_handyman/features/dashboard/presentation/widgets/job_request_tile.dart';

class JobRequestPage extends StatefulWidget {
  const JobRequestPage({super.key});

  @override
  State<JobRequestPage> createState() => _JobRequestPageState();
}

class _JobRequestPageState extends State<JobRequestPage> {
  static const _categories = Dummy.jobCategories;

  String _selectedCategory = 'All';
  String _searchQuery = '';

  List<
      ({
        String clientName,
        String jobCategory,
        double distanceKm,
        String postedAgo,
      })> get _filtered {
    return Dummy.allJobRequests.where((j) {
      final matchesCategory = _selectedCategory == 'All' ||
          j.jobCategory.toLowerCase() ==
              _selectedCategory.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          j.clientName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          j.jobCategory
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceBackground,
        title: Text('Job Requests', style: AppTextStyles.titleLarge),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // ── Search + filter ─────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: AppTextStyles.inputText,
                  decoration: InputDecoration(
                    hintText: 'Search by client or category...',
                    hintStyle: AppTextStyles.inputHint,
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 20.r,
                      color: AppColors.textHint,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded,
                                size: 18.r, color: AppColors.textHint),
                            onPressed: () =>
                                setState(() => _searchQuery = ''),
                          )
                        : null,
                    contentPadding: EdgeInsets.symmetric(vertical: 12.h),
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

                // Category filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Row(
                    children: _categories.map((cat) {
                      final isActive = cat == _selectedCategory;
                      return Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.primary
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(50.r),
                              border: Border.all(
                                color: isActive
                                    ? AppColors.primary
                                    : AppColors.inputBorder,
                              ),
                            ),
                            child: Text(
                              cat,
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
                ),

                SizedBox(height: 12.h),

                // Result count
                Text(
                  '${items.length} ${items.length == 1 ? 'request' : 'requests'}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textHint),
                ),

                SizedBox(height: 8.h),
              ],
            ),
          ),

          // ── List ───────────────────────────────────────────────────────
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.work_off_outlined,
                          size: 48.r,
                          color: AppColors.textHint,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'No job requests found',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textHint),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding:
                        EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 32.h),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final job = items[index];
                      return JobRequestTile(
                        clientName: job.clientName,
                        jobCategory: job.jobCategory,
                        distanceKm: job.distanceKm,
                        postedAgo: job.postedAgo,
                        onAccept: () {},
                        onReject: () {},
                        onDetails: () => context
                            .push(AppRoutes.jobRequestDetails.path),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
