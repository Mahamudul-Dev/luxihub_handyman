import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:luxihub_handyman/features/authentication/presentation/bloc/auth_state.dart';
import 'package:luxihub_handyman/features/jobs/domain/entities/review.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

class AllReviewsPage extends StatefulWidget {
  const AllReviewsPage({super.key});

  @override
  State<AllReviewsPage> createState() => _AllReviewsPageState();
}

class _AllReviewsPageState extends State<AllReviewsPage> {
  List<Review> _reviews = [];
  bool _loading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        _fetchReviews(authState.user.id);
      }
    });
  }

  Future<void> _fetchReviews(String userId) async {
    setState(() => _loading = true);
    try {
      final client = Supabase.instance.client;

      final data = await client
          .from('reviews')
          .select('*')
          .eq('provider_id', userId)
          .order('created_at', ascending: false);

      final ids =
          (data as List).map((r) => r['client_id'] as String).toList();
      final reviewIds = data.map((r) => r['id'] as String).toList();

      final Map<String, String?> nameMap = {};
      if (ids.isNotEmpty) {
        final profiles = await client
            .from('profiles')
            .select('id, name')
            .inFilter('id', ids);
        for (final p in (profiles as List)) {
          nameMap[p['id'] as String] = p['name'] as String?;
        }
      }

      final Map<String, List<String>> photosMap = {};
      try {
        if (reviewIds.isNotEmpty) {
          final photosData = await client
              .from('review_photos')
              .select('review_id, storage_path')
              .inFilter('review_id', reviewIds);

          final allPhotos = (photosData as List)
              .map((p) => (
                    reviewId: p['review_id'] as String,
                    path: p['storage_path'] as String
                  ))
              .toList();

          if (allPhotos.isNotEmpty) {
            final paths = allPhotos.map((p) => p.path).toList();
            final signed = await client.storage
                .from('review-photos')
                .createSignedUrls(paths, 3600);
            final urlMap = {for (final s in signed) s.path: s.signedUrl};
            for (final photo in allPhotos) {
              final url = urlMap[photo.path];
              if (url != null) (photosMap[photo.reviewId] ??= []).add(url);
            }
          }
        }
      } catch (e) {
        debugPrint('Review photos error: $e');
      }

      final reviews = data
          .map((r) => Review.fromJson({
                ...r,
                'profiles': {'name': nameMap[r['client_id']]},
                'photo_urls': photosMap[r['id']] ?? [],
              }))
          .toList();

      if (mounted) setState(() => _reviews = reviews);
    } catch (e) {
      debugPrint('AllReviews fetch error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Review> get _filtered {
    if (_searchQuery.isEmpty) return _reviews;
    final q = _searchQuery.toLowerCase();
    return _reviews
        .where((r) =>
            (r.clientName ?? '').toLowerCase().contains(q) ||
            (r.comment ?? '').toLowerCase().contains(q))
        .toList();
  }

  double get _avg {
    if (_reviews.isEmpty) return 0;
    return _reviews.fold<double>(0, (s, r) => s + r.score) / _reviews.length;
  }

  Map<int, int> get _distribution {
    final map = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in _reviews) {
      final star = r.score.round().clamp(1, 5);
      map[star] = (map[star] ?? 0) + 1;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceBackground,
        leading: const BackButton(),
        title: Text('My Reviews', style: AppTextStyles.titleLarge),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Summary card ─────────────────────────────────────────
                if (_reviews.isNotEmpty)
                  _SummaryCard(
                    avg: _avg,
                    total: _reviews.length,
                    distribution: _distribution,
                  ),

                // ── Search ───────────────────────────────────────────────
                Padding(
                  padding:
                      EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        onChanged: (v) =>
                            setState(() => _searchQuery = v),
                        style: AppTextStyles.inputText,
                        decoration: InputDecoration(
                          hintText: 'Search by client or comment…',
                          hintStyle: AppTextStyles.inputHint,
                          prefixIcon: Icon(Icons.search_rounded,
                              size: 20.r, color: AppColors.textHint),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.close_rounded,
                                      size: 18.r,
                                      color: AppColors.textHint),
                                  onPressed: () => setState(
                                      () => _searchQuery = ''),
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
                      SizedBox(height: 8.h),
                      if (!_loading)
                        Text(
                          '${_filtered.length} ${_filtered.length == 1 ? 'review' : 'reviews'}',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textHint),
                        ),
                      SizedBox(height: 8.h),
                    ],
                  ),
                ),

                // ── List ─────────────────────────────────────────────────
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.rate_review_outlined,
                                  size: 48.r,
                                  color: AppColors.textHint),
                              SizedBox(height: 12.h),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No reviews yet'
                                    : 'No results for "$_searchQuery"',
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: AppColors.textHint),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(
                              16.w, 4.h, 16.w, 32.h),
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) =>
                              _ReviewCard(review: _filtered[i]),
                        ),
                ),
              ],
            ),
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.avg,
    required this.total,
    required this.distribution,
  });

  final double avg;
  final int total;
  final Map<int, int> distribution;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // ── Big score ───────────────────────────────────────────────
          Column(
            children: [
              Text(
                avg.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 48.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFF59E0B),
                  height: 1,
                ),
              ),
              SizedBox(height: 6.h),
              RatingBarIndicator(
                rating: avg,
                itemCount: 5,
                itemSize: 16.r,
                itemBuilder: (_, _) => const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFF59E0B),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '$total ${total == 1 ? 'review' : 'reviews'}',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textHint),
              ),
            ],
          ),

          SizedBox(width: 20.w),
          Container(width: 1, height: 80.h, color: AppColors.divider),
          SizedBox(width: 20.w),

          // ── Star breakdown bars ──────────────────────────────────────
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final count = distribution[star] ?? 0;
                final fraction = total == 0 ? 0.0 : count / total;
                return Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: Row(
                    children: [
                      Icon(Icons.star_rounded,
                          size: 12.r, color: const Color(0xFFF59E0B)),
                      SizedBox(width: 4.w),
                      Text('$star',
                          style: AppTextStyles.bodySmall
                              .copyWith(fontSize: 11.sp)),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4.r),
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: 6.h,
                            backgroundColor: AppColors.inputBorder,
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(
                                    Color(0xFFF59E0B)),
                          ),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      SizedBox(
                        width: 20.w,
                        child: Text('$count',
                            style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 11.sp,
                                color: AppColors.textHint)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Review card ───────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final Review review;

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadow,
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: AppColors.splashBackground,
                child: Text(
                  (review.clientName?.isNotEmpty == true)
                      ? review.clientName![0].toUpperCase()
                      : '?',
                  style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.clientName ?? 'Client',
                      style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                    ),
                    Text(
                      _formatDate(review.createdAt),
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    review.score.toStringAsFixed(1),
                    style: AppTextStyles.titleLarge.copyWith(
                        color: const Color(0xFFF59E0B),
                        fontWeight: FontWeight.w800),
                  ),
                  RatingBarIndicator(
                    rating: review.score,
                    itemCount: 5,
                    itemSize: 14.r,
                    itemBuilder: (_, _) => const Icon(
                        Icons.star_rounded, color: Color(0xFFF59E0B)),
                  ),
                ],
              ),
            ],
          ),
          if (review.comment?.isNotEmpty == true) ...[
            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: AppColors.surfaceBackground,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                '"${review.comment}"',
                style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                    height: 1.5),
              ),
            ),
          ],
          if (review.photoUrls.isNotEmpty) ...[
            SizedBox(height: 10.h),
            _ReviewPhotoStrip(photoUrls: review.photoUrls),
          ],
        ],
      ),
    );
  }
}

// ── Review photo strip ────────────────────────────────────────────────────────

class _ReviewPhotoStrip extends StatelessWidget {
  const _ReviewPhotoStrip({required this.photoUrls});

  final List<String> photoUrls;

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(16.r),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Image.network(
              url,
              fit: BoxFit.contain,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80.r,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photoUrls.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => _showFullImage(context, photoUrls[i]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: Image.network(
              photoUrls[i],
              width: 80.r,
              height: 80.r,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : Container(
                      width: 80.r,
                      height: 80.r,
                      decoration: BoxDecoration(
                        color: AppColors.inputBorder,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 20.r,
                          height: 20.r,
                          child: const CircularProgressIndicator(
                              strokeWidth: 2),
                        ),
                      ),
                    ),
              errorBuilder: (_, _, _) => Container(
                width: 80.r,
                height: 80.r,
                decoration: BoxDecoration(
                  color: AppColors.inputBorder,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.broken_image_outlined,
                    size: 24.r, color: AppColors.textHint),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
