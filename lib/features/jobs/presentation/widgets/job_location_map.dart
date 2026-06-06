import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:luxihub_handyman/core/theme/app_colors.dart';
import 'package:luxihub_handyman/core/theme/app_text_styles.dart';

class JobLocationMap extends StatefulWidget {
  const JobLocationMap({
    super.key,
    required this.clientLocation,
  });

  final LatLng clientLocation;

  @override
  State<JobLocationMap> createState() => _JobLocationMapState();
}

class _JobLocationMapState extends State<JobLocationMap> {
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionSub;

  LatLng? _myLocation;
  Set<Polyline> _polylines = {};
  bool _permissionDenied = false;
  bool _fetchingRoute = false;
  LatLng? _lastRouteFetch;
  bool _initialFitDone = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (mounted) setState(() => _permissionDenied = true);
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _permissionDenied = true);
      return;
    }

    // Snap to first position immediately.
    final initial = await Geolocator.getCurrentPosition(
      locationSettings:
          const LocationSettings(accuracy: LocationAccuracy.high),
    );
    if (!mounted) return;
    final pos = LatLng(initial.latitude, initial.longitude);
    setState(() => _myLocation = pos);
    _fetchRoute(pos);
    _fitBounds(pos);

    // Stream real-time updates; re-route every 50 m of movement.
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
      ),
    ).listen((p) {
      if (!mounted) return;
      final updated = LatLng(p.latitude, p.longitude);
      setState(() => _myLocation = updated);
      _maybeRefetchRoute(updated);
    });
  }

  void _maybeRefetchRoute(LatLng current) {
    if (_lastRouteFetch == null) {
      _fetchRoute(current);
      return;
    }
    final dist = Geolocator.distanceBetween(
      current.latitude,
      current.longitude,
      _lastRouteFetch!.latitude,
      _lastRouteFetch!.longitude,
    );
    if (dist > 50) _fetchRoute(current);
  }

  Future<void> _fetchRoute(LatLng from) async {
    if (_fetchingRoute) return;
    _fetchingRoute = true;
    _lastRouteFetch = from;
    try {
      final url = 'https://router.project-osrm.org/route/v1/driving/'
          '${from.longitude},${from.latitude};'
          '${widget.clientLocation.longitude},${widget.clientLocation.latitude}';
      final res = await Dio().get(url, queryParameters: {
        'overview': 'full',
        'geometries': 'geojson',
      });
      final routes = res.data['routes'] as List?;
      if (routes == null || routes.isEmpty) return;
      final coords = routes[0]['geometry']['coordinates'] as List;
      final points = coords
          .map((c) => LatLng(
                (c[1] as num).toDouble(),
                (c[0] as num).toDouble(),
              ))
          .toList();
      if (mounted) {
        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: points,
              color: AppColors.primary,
              width: 4,
            ),
          };
        });
      }
    } catch (_) {
      // Fallback: straight line between the two points.
      if (mounted) {
        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: [from, widget.clientLocation],
              color: AppColors.primary,
              width: 4,
            ),
          };
        });
      }
    } finally {
      _fetchingRoute = false;
    }
  }

  void _fitBounds(LatLng myLocation) {
    if (_initialFitDone) return;
    _initialFitDone = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _mapController == null) return;
      final bounds = LatLngBounds(
        southwest: LatLng(
          math.min(myLocation.latitude, widget.clientLocation.latitude),
          math.min(myLocation.longitude, widget.clientLocation.longitude),
        ),
        northeast: LatLng(
          math.max(myLocation.latitude, widget.clientLocation.latitude),
          math.max(myLocation.longitude, widget.clientLocation.longitude),
        ),
      );
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 80),
      );
    });
  }

  Future<void> _openDirections() async {
    if (_myLocation == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${_myLocation!.latitude},${_myLocation!.longitude}'
      '&destination=${widget.clientLocation.latitude},${widget.clientLocation.longitude}'
      '&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Location', style: AppTextStyles.titleLarge),
            OutlinedButton.icon(
              onPressed: _myLocation != null ? _openDirections : null,
              icon: Icon(Icons.directions_rounded, size: 16.r),
              label: const Text('Directions'),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(0, 34.h),
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                side: BorderSide(
                  color: _myLocation != null
                      ? AppColors.primary
                      : AppColors.inputBorder,
                ),
                foregroundColor: _myLocation != null
                    ? AppColors.primary
                    : AppColors.textHint,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),

        // ── Legend ──────────────────────────────────────────────────────────
        Row(
          children: [
            _LegendDot(color: Colors.blue),
            SizedBox(width: 6.w),
            Text('Your location',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
            SizedBox(width: 16.w),
            _LegendDot(color: AppColors.error),
            SizedBox(width: 6.w),
            Text("Client's location",
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
        SizedBox(height: 10.h),

        // ── Map / Permission denied ──────────────────────────────────────────
        if (_permissionDenied)
          _PermissionDeniedCard()
        else
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: SizedBox(
                  height: 280.h,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: widget.clientLocation,
                      zoom: 13.5,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                      if (_myLocation != null) {
                        _fitBounds(_myLocation!);
                      }
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                    polylines: _polylines,
                    markers: {
                      Marker(
                        markerId: const MarkerId('client'),
                        position: widget.clientLocation,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed,
                        ),
                        infoWindow: const InfoWindow(title: "Client's location"),
                      ),
                    },
                  ),
                ),
              ),

              // Loading overlay while acquiring GPS fix.
              if (_myLocation == null)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.12),
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 10.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16.r,
                                height: 16.r,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                'Getting your location…',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 10.r,
        height: 10.r,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _PermissionDeniedCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(Icons.location_off_outlined,
              size: 40.r, color: AppColors.textHint),
          SizedBox(height: 12.h),
          Text(
            'Location access denied',
            style: AppTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4.h),
          Text(
            'Enable location permission to see live directions.',
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          OutlinedButton(
            onPressed: Geolocator.openAppSettings,
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
