import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:latlong2/latlong.dart';
import 'package:luxihub_handyman/features/dashboard/presentation/widgets/job_request_tile.dart';
import 'package:luxihub_handyman/features/jobs/presentation/widgets/job_attachments_grid.dart';
import 'package:luxihub_handyman/features/jobs/presentation/widgets/job_issue_card.dart';
import 'package:luxihub_handyman/features/jobs/presentation/widgets/job_location_map.dart';

class JobRequestDetailsPage extends StatelessWidget {
  const JobRequestDetailsPage({super.key});

  static const _providerLocation = LatLng(3.1390, 101.6869);
  static const _clientLocation = LatLng(3.1580, 101.7120);

  static const _issueText =
      'The bathroom pipe under the sink has been leaking for about 3 days. '
      'Water is dripping onto the cabinet floor and I\'m worried about water '
      'damage to the wood. The leak seems to be coming from the joint near the '
      'drainage pipe. I\'ve placed a bucket underneath for now but it needs '
      'urgent attention. Please bring the necessary tools and replacement parts.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Job Request Details'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Client summary tile ──────────────────────────────────────
            JobRequestTile(
              clientName: 'John Smith',
              jobCategory: 'Plumbing',
              distanceKm: 2.3,
              postedAgo: '5 min ago',
              showDetailsButton: false,
              onAccept: () {},
              onReject: () {},
            ),

            SizedBox(height: 24.h),

            // ── 2. Issue details ────────────────────────────────────────────
            const JobIssueCard(message: _issueText),

            SizedBox(height: 24.h),

            // ── 3. Attachments ──────────────────────────────────────────────
            const JobAttachmentsGrid(count: 5),

            SizedBox(height: 24.h),

            // ── 4. Location map ─────────────────────────────────────────────
            const JobLocationMap(
              providerLocation: _providerLocation,
              clientLocation: _clientLocation,
            ),

            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }
}
