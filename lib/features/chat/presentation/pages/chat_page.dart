import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:luxihub_handyman/core/di/service_locator.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_state.dart';
import 'package:luxihub_handyman/features/chat/domain/entities/message.dart';
import 'package:luxihub_handyman/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:luxihub_handyman/features/chat/presentation/bloc/chat_event.dart';
import 'package:luxihub_handyman/features/chat/presentation/bloc/chat_state.dart';
import 'package:luxihub_handyman/features/chat/presentation/widgets/chat_bubble.dart';

String _formatTime(String isoString) {
  final dt = DateTime.tryParse(isoString)?.toLocal();
  if (dt == null) return '';
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.clientName,
    required this.jobCategory,
    required this.conversationId,
  });

  final String clientName;
  final String jobCategory;
  final String conversationId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final ChatBloc _chatBloc;

  @override
  void initState() {
    super.initState();
    _chatBloc = sl<ChatBloc>();
    _chatBloc.add(MessagesWatchStarted(widget.conversationId));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _chatBloc.close();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    _chatBloc.add(MessageSendRequested(
      conversationId: widget.conversationId,
      senderId: authState.user.id,
      text: text,
    ));
    _controller.clear();
    setState(() {});
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _chatBloc,
      child: Scaffold(
        backgroundColor: AppColors.surfaceBackground,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          titleSpacing: 0,
          leading: const BackButton(),
          title: Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: AppColors.splashShapeColor,
                child: Text(
                  widget.clientName.isNotEmpty
                      ? widget.clientName[0].toUpperCase()
                      : '?',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.clientName,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    widget.jobCategory,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11.sp,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.more_vert_rounded,
                  size: 22.r, color: AppColors.textSecondary),
            ),
            SizedBox(width: 4.w),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1.h),
            child: Divider(height: 1.h, color: AppColors.divider),
          ),
        ),
        body: Column(
          children: [
            // ── Messages ───────────────────────────────────────────────
            Expanded(
              child: BlocConsumer<ChatBloc, ChatState>(
                listener: (context, state) {
                  if (state is MessagesLoaded) _scrollToBottom();
                  if (state is ChatError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message)),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is ChatLoading || state is ChatInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = state is MessagesLoaded
                      ? state.messages
                      : <Message>[];

                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        'No messages yet. Say hello!',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textHint),
                      ),
                    );
                  }

                  final currentUserId =
                      (context.read<AuthBloc>().state as AuthAuthenticated?)
                          ?.user
                          .id;

                  return ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return ChatBubble(
                        text: msg.text,
                        time: _formatTime(msg.createdAt),
                        isSent: msg.senderId == currentUserId,
                      );
                    },
                  );
                },
              ),
            ),

            // ── Input bar ──────────────────────────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 12.w, 24.h),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(
                  top: BorderSide(color: AppColors.divider, width: 1.h),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  
                  Expanded(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 120.h),
                      child: TextField(
                        controller: _controller,
                        style: AppTextStyles.inputText,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: AppTextStyles.inputHint,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 10.h),
                          filled: true,
                          fillColor: AppColors.surfaceBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22.r),
                            borderSide:
                                const BorderSide(color: AppColors.inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22.r),
                            borderSide:
                                const BorderSide(color: AppColors.inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22.r),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 44.r,
                    height: 44.r,
                    decoration: BoxDecoration(
                      color: _controller.text.trim().isNotEmpty
                          ? AppColors.primary
                          : AppColors.divider,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _controller.text.trim().isNotEmpty
                          ? _sendMessage
                          : null,
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.send_rounded,
                        size: 20.r,
                        color: _controller.text.trim().isNotEmpty
                            ? AppColors.textOnPrimary
                            : AppColors.textHint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
