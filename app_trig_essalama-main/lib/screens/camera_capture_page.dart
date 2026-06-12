import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../providers/locale_provider.dart';
import '../services/api_client.dart';
import '../services/camera_capture_service.dart';
import 'camera_captures_history_page.dart';

class CameraCapturePage extends StatefulWidget {
  const CameraCapturePage({super.key});

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage> {
  CameraController? _controller;
  bool _initializing = true;
  String? _error;
  bool _capturing = false;
  bool _gettingPosition = false;
  Position? _lastPosition;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initCamera();
    } else {
      _initializing = false;
      _error = 'Web camera not supported in this flow';
    }
  }

  Future<void> _initCamera() async {
    setState(() {
      _initializing = true;
      _error = null;
    });
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _initializing = false;
          _error = 'none';
        });
        return;
      }
      final selected = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      // Medium réduit fortement la taille du fichier et évite les échecs d'upload.
      final ctrl = CameraController(selected, ResolutionPreset.medium, enableAudio: false);
      await ctrl.initialize();
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      await _controller?.dispose();
      setState(() {
        _controller = ctrl;
        _initializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<Position?> _resolveCurrentPosition() async {
    final s = context.read<LocaleProvider>().strings;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.cameraLocationDenied),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    }
    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _onPositionTap() async {
    if (_gettingPosition) return;
    final s = context.read<LocaleProvider>().strings;
    setState(() => _gettingPosition = true);
    try {
      final pos = await _resolveCurrentPosition();
      if (!mounted || pos == null) return;
      setState(() => _lastPosition = pos);
      final latLng = LatLng(pos.latitude, pos.longitude);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${s.cameraPositionReady} • ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
          ),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: s.cameraOpenMap,
            onPressed: () => Navigator.of(context).pop<LatLng>(latLng),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.errorPrefix}$e'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _gettingPosition = false);
    }
  }

  Future<void> _takePictureAndSave() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || _capturing) return;
    final messenger = ScaffoldMessenger.of(context);
    final s = context.read<LocaleProvider>().strings;
    final service = CameraCaptureService(context.read<ApiClient>());
    setState(() => _capturing = true);
    HapticFeedback.mediumImpact();
    try {
      final shot = await c.takePicture();
      // On récupère la position en temps réel au moment de la capture.
      final position = await _resolveCurrentPosition();
      if (!mounted || position == null) return;
      _lastPosition = position;

      final bytes = await shot.readAsBytes();
      messenger.showSnackBar(
        SnackBar(content: Text(s.cameraSavingCapture), behavior: SnackBarBehavior.floating),
      );

      await service.uploadCapture(
        imageBytes: bytes,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(s.cameraCaptureSaved),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('${s.cameraCaptureSaveError}: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;

    if (kIsWeb) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          title: Text(s.cameraPageTitle),
        ),
        body: Center(
          child: Text(s.cameraNoCamera, style: const TextStyle(color: Colors.black54)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_initializing)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error == 'none' ? s.cameraNoCamera : _error!,
                      style: const TextStyle(color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(s.close, style: const TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              ),
            )
          else if (_controller != null && _controller!.value.isInitialized)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.previewSize!.height,
                  height: _controller!.value.previewSize!.width,
                  child: CameraPreview(_controller!),
                ),
              ),
            ),

          // top gradient + header card
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 180,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xAA000000), Color(0x00000000)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _iconGlassButton(Icons.close, () => Navigator.of(context).pop()),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        s.cameraPageTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _iconGlassButton(
                    Icons.photo_library_outlined,
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CameraCapturesHistoryPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // bottom controls
          if (!_initializing && _error == null && _controller != null && _controller!.value.isInitialized)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(16, 22, 16, MediaQuery.of(context).padding.bottom + 22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.78)],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        icon: _gettingPosition ? Icons.hourglass_top_rounded : Icons.my_location_rounded,
                        label: s.cameraPositionSnack,
                        onTap: _gettingPosition ? null : _onPositionTap,
                      ),
                    ),
                    const SizedBox(width: 14),
                    _shutterButton(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.32),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          _lastPosition == null
                              ? '--'
                              : '${_lastPosition!.latitude.toStringAsFixed(3)}, ${_lastPosition!.longitude.toStringAsFixed(3)}',
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _iconGlassButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0084FF), Color(0xFF44B0FF)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0084FF).withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shutterButton() {
    return GestureDetector(
      onTap: _capturing ? null : _takePictureAndSave,
      child: Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          color: Colors.white24,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 10)],
        ),
        alignment: Alignment.center,
        child: _capturing
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
              )
            : Container(
                width: 66,
                height: 66,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              ),
      ),
    );
  }
}
