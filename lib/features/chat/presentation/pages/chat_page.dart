import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:luxihub_handyman/core/dummy/dummy.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';
import 'package:luxihub_handyman/features/chat/presentation/widgets/chat_bubble.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.clientName,
    required this.jobCategory,
  });

  final String clientName;
  final String jobCategory;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            icon: Icon(
              Icons.more_vert_rounded,
              size: 22.r,
              color: AppColors.textSecondary,
            ),
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
          // ── Messages list ───────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
              itemCount: Dummy.chatMessages.length,
              itemBuilder: (context, index) {
                final msg = Dummy.chatMessages[index];
                return ChatBubble(
                  text: msg.text,
                  time: msg.time,
                  isSent: msg.isSent,
                );
              },
            ),
          ),

          // ── Input bar ───────────────────────────────────────────────────
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
                // Attachment icon
                SizedBox(
                  width: 40.r,
                  height: 40.r,
                  child: IconButton(
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.attach_file_rounded,
                      size: 22.r,
                      color: AppColors.textHint,
                    ),
                  ),
                ),

                SizedBox(width: 8.w),

                // Text field
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

                // Send button
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
                        ? () {
                            _controller.clear();
                            setState(() {});
                            _scrollToBottom();
                          }
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
    );
  }
}
