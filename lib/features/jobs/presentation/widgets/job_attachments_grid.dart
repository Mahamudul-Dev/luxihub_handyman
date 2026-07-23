import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JobAttachmentsGrid extends StatefulWidget {
  const JobAttachmentsGrid({super.key, required this.paths});

  final List<String> paths;

  @override
  State<JobAttachmentsGrid> createState() => _JobAttachmentsGridState();
}

class _JobAttachmentsGridState extends State<JobAttachmentsGrid> {
  final List<String> _imageUrls = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    if (widget.paths.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    try {
      final client = Supabase.instance.client;
      final urls = <String>[];

      for (final path in widget.paths) {
        // Get signed URL that's valid for 1 hour
        final signedUrl = await client.storage
            .from('job-attachments')
            .createSignedUrl(path, 3600);
        urls.add(signedUrl);
      }

      if (mounted) {
        setState(() {
          _imageUrls.addAll(urls);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading attachment images: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showFullImage(BuildContext context, String url, int index) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(16.r),
        child: Stack(
          children: [
            // Image
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 200.r,
                      color: AppColors.inputBorder,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, _, _) => Container(
                    height: 200.r,
                    color: AppColors.inputBorder,
                    child: Center(
                      child: Icon(Icons.broken_image_outlined,
                          size: 48.r, color: AppColors.textHint),
                    ),
                  ),
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 16.r,
              right: 16.r,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24.r,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Attachments', style: AppTextStyles.titleLarge),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppColors.splashBackground,
                borderRadius: BorderRadius.circular(50.r),
              ),
              child: Text(
                '${widget.paths.length}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),

        // Loading state
        if (_loading)
          Container(
            height: 120.r,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          )

        // Empty state
        else if (widget.paths.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 20.h),
            decoration: BoxDecoration(
              color: AppColors.surfaceBackground,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                Icon(Icons.image_not_supported_outlined,
                    size: 32.r, color: AppColors.textHint),
                SizedBox(height: 8.h),
                Text('No attachments',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textHint)),
              ],
            ),
          )

        // Images grid
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8.r,
              mainAxisSpacing: 8.r,
            ),
            itemCount: _imageUrls.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showFullImage(context, _imageUrls[index], index),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Image.network(
                    _imageUrls[index],
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceBackground,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 20.r,
                            height: 20.r,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, _, _) => Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceBackground,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            size: 24.r,
                            color: AppColors.textHint,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Failed',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 9.sp,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
