import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:luxihub_handyman/core/dummy/dummy.dart';
import 'package:luxihub_handyman/core/router/app_routes.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';
import 'package:luxihub_handyman/features/chat/presentation/widgets/inbox_chat_tile.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  String _selectedFilter = 'All';
  String _searchQuery = '';

  List<
      ({
        String clientName,
        String lastMessage,
        String time,
        int unreadCount,
        String jobCategory,
      })> get _filtered {
    return Dummy.inboxMessages.where((m) {
      final matchesFilter = switch (_selectedFilter) {
        'Unread' => m.unreadCount > 0,
        'Read' => m.unreadCount == 0,
        _ => true,
      };
      final matchesSearch = _searchQuery.isEmpty ||
          m.clientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.lastMessage.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.jobCategory.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final totalUnread =
        Dummy.inboxMessages.fold(0, (sum, m) => sum + m.unreadCount);

    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceBackground,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Text('Inbox', style: AppTextStyles.titleLarge),
            if (totalUnread > 0) ...[
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(50.r),
                ),
                child: Text(
                  '$totalUnread',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11.sp,
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Search + filter ───────────────────────────────────────────────
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
                    hintText: 'Search messages or clients...',
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

                // Filter chips
                Row(
                  children: Dummy.inboxFilters.map((filter) {
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
                            borderRadius: BorderRadius.circular(50.r),
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

                SizedBox(height: 12.h),

                Text(
                  '${items.length} ${items.length == 1 ? 'conversation' : 'conversations'}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textHint),
                ),

                SizedBox(height: 8.h),
              ],
            ),
          ),

          // ── List ─────────────────────────────────────────────────────────
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 48.r,
                          color: AppColors.textHint,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'No messages found',
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
                      final m = items[index];
                      return InboxChatTile(
                        clientName: m.clientName,
                        lastMessage: m.lastMessage,
                        time: m.time,
                        unreadCount: m.unreadCount,
                        jobCategory: m.jobCategory,
                        onTap: () => context.push(
                          AppRoutes.chat.path,
                          extra: (
                            clientName: m.clientName,
                            jobCategory: m.jobCategory,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
