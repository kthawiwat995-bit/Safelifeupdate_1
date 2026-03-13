import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_theme.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  StreamSubscription<Position>? _positionStream;
  Position? _currentPosition;
  bool _isFollowingUser = true;
  bool _hasLocationPermission = false;

  // ศูนย์กลางประเทศไทยเริ่มต้น (กรณีดึงพิกัดแอสซิงโครนัสไม่ได้ทันที)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(13.7563, 100.5018), // กรุงเทพ
    zoom: 10,
  );

  @override
  void initState() {
    super.initState();
    _checkLocationPermissionAndStartTracking();
  }

  Future<void> _checkLocationPermissionAndStartTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเปิดบริการ Location (GPS)')),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('คุณปฏิเสธการเข้าถึงตำแหน่ง')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('การเข้าถึงตำแหน่งถูกปิดใช้งานถาวร กรุณาไปเปิดในตั้งค่าเครื่อง'),
          ),
        );
      }
      return;
    }

    // เมื่อได้รับอนุญาต อัปเดตสิทธิ์ให้แผนที่
    if (mounted) {
      setState(() {
        _hasLocationPermission = true;
      });
    }

    // ดึงตำแหน่งล่าสุดที่เครื่องจำไว้ก่อน (เร็วมาก)
    Position? position = await Geolocator.getLastKnownPosition();

    // ถ้าไม่มีให้ดึงใหม่โดยรอไม่เกิน 3 วินาที
    if (position == null) {
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        ).timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('ดึงพิกัดช้าเกินไป อาศัยพิกัดเริ่มต้นแทน');
      }
    }

    if (position != null && mounted) {
      setState(() {
        _currentPosition = position;
      });

      // รอ map controller พร้อม แล้วเลื่อนกล้องไปพิกัดผู้ใช้
      if (_controller.isCompleted) {
        final GoogleMapController mapController = await _controller.future;
        if (mounted) {
          mapController.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 16.0,
            ),
          ));
        }
      }
    }

    // เริ่มการสตรีมพิกัดตามตัว (Tracking real-time)
    _startTracking();
  }

  void _startTracking() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // อัปเดตเมื่อเคลื่อนที่เกิน 10 เมตร
      ),
    ).listen((Position position) async {
      if (!mounted) return;
      setState(() {
        _currentPosition = position;
      });

      if (_isFollowingUser && _controller.isCompleted) {
        final GoogleMapController mapController = await _controller.future;
        if (mounted) {
          mapController.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 16.0,
            ),
          ));
        }
      }
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    // dispose GoogleMapController เพื่อป้องกัน memory leak และ crash
    if (_controller.isCompleted) {
      _controller.future.then((c) => c.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แผนที่ (Google Maps)'),
        backgroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialPosition,
            myLocationEnabled: _hasLocationPermission,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              if (!_controller.isCompleted) {
                _controller.complete(controller);
              }
            },
            onCameraMoveStarted: () {
              setState(() {
                _isFollowingUser = false;
              });
            },
          ),

          // ปุ่ม Location ขวาล่าง
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton(
              onPressed: () async {
                setState(() {
                  _isFollowingUser = true;
                });

                if (_currentPosition != null && _controller.isCompleted) {
                  final GoogleMapController mapController = await _controller.future;
                  if (mounted) {
                    mapController.animateCamera(CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                        zoom: 16.0,
                      ),
                    ));
                  }
                }
              },
              backgroundColor: _isFollowingUser ? AppTheme.primary : Colors.white,
              child: Icon(
                Icons.my_location,
                color: _isFollowingUser ? Colors.white : AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
