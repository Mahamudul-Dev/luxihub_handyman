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
import 'package:luxihub_handyman/features/chat/domain/entities/conversation.dart';
import 'package:luxihub_handyman/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:luxihub_handyman/features/chat/presentation/bloc/chat_event.dart';
import 'package:luxihub_handyman/features/chat/presentation/bloc/chat_state.dart';
import 'package:luxihub_handyman/features/chat/presentation/widgets/inbox_chat_tile.dart';

String _relativeTime(String? isoString) {
  if (isoString == null) return '';
  final dt = DateTime.tryParse(isoString);
  if (dt == null) return '';
  final diff = DateTime.now().toUtc().difference(dt.toUtc());
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  static const _filters = ['All', 'Unread', 'Read'];

  late final ChatBloc _chatBloc;
  String _selectedFilter = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _chatBloc = sl<ChatBloc>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        _chatBloc.add(ConversationsFetchRequested(authState.user.id));
      }
    });
  }

  @override
  void dispose() {
    _chatBloc.close();
    super.dispose();
  }

  List<Conversation> _filter(List<Conversation> convs) {
    return convs.where((c) {
      final matchesFilter = switch (_selectedFilter) {
        'Unread' => c.unreadCount > 0,
        'Read' => c.unreadCount == 0,
        _ => true,
      };
      final matchesSearch = _searchQuery.isEmpty ||
          (c.clientName ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (c.lastMessage ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (c.jobCategory ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _chatBloc,
      child: Scaffold(
        backgroundColor: AppColors.surfaceBackground,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceBackground,
          automaticallyImplyLeading: false,
          title: BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              final totalUnread = state is ConversationsLoaded
                  ? state.conversations.fold(0, (s, c) => s + c.unreadCount)
                  : 0;
              return Row(
                children: [
                  Text('Inbox', style: AppTextStyles.titleLarge),
                  if (totalUnread > 0) ...[
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 2.h),
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
              );
            },
          ),
        ),
        body: Column(
          children: [
            // ── Search + filter ─────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: AppTextStyles.inputText,
                    decoration: InputDecoration(
                      hintText: 'Search messages or clients...',
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
                  SizedBox(height: 8.h),
                ],
              ),
            ),

            // ── List ────────────────────────────────────────────────────
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state is ChatLoading || state is ChatInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is ChatError) {
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
                                final authState =
                                    context.read<AuthBloc>().state;
                                if (authState is AuthAuthenticated) {
                                  _chatBloc.add(ConversationsFetchRequested(
                                      authState.user.id));
                                }
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final allConvs = state is ConversationsLoaded
                      ? state.conversations
                      : <Conversation>[];
                  final items = _filter(allConvs);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
                        child: Text(
                          '${items.length} ${items.length == 1 ? 'conversation' : 'conversations'}',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textHint),
                        ),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () async {
                            final authState =
                                context.read<AuthBloc>().state;
                            if (authState is AuthAuthenticated) {
                              _chatBloc.add(ConversationsFetchRequested(
                                  authState.user.id));
                            }
                          },
                          color: AppColors.primary,
                          child: items.isEmpty
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    SizedBox(
                                      height: 300.h,
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons
                                                  .chat_bubble_outline_rounded,
                                              size: 48.r,
                                              color: AppColors.textHint,
                                            ),
                                            SizedBox(height: 12.h),
                                            Text(
                                              'No messages found',
                                              style: AppTextStyles.bodyMedium
                                                  .copyWith(
                                                      color:
                                                          AppColors.textHint),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: EdgeInsets.fromLTRB(
                                      16.w, 4.h, 16.w, 32.h),
                                  itemCount: items.length,
                                  itemBuilder: (context, index) {
                                    final c = items[index];
                                    return InboxChatTile(
                                      clientName:
                                          c.clientName ?? 'Unknown',
                                      lastMessage:
                                          c.lastMessage ?? 'No messages yet',
                                      time: _relativeTime(c.lastMessageAt),
                                      unreadCount: c.unreadCount,
                                      jobCategory: c.jobCategory ?? '',
                                      onTap: () => context.push(
                                        AppRoutes.chat.path,
                                        extra: (
                                          clientName:
                                              c.clientName ?? 'Unknown',
                                          jobCategory: c.jobCategory ?? '',
                                          conversationId: c.id,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
