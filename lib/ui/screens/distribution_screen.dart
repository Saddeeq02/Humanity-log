import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/beneficiary.dart';
import '../../models/distribution_log.dart';
import '../../providers/beneficiary_provider.dart';
import '../../providers/distribution_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/auth_provider.dart';
import '../widgets/swipe_to_confirm.dart';
import '../../core/theme.dart';

class DistributionScreen extends ConsumerStatefulWidget {
  const DistributionScreen({super.key});

  @override
  ConsumerState<DistributionScreen> createState() => _DistributionScreenState();
}

class _DistributionScreenState extends ConsumerState<DistributionScreen> {
  final String _aidType = 'Standard Relief Kit (Rice, Water, Meds)';

  // Form Controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();

  // Validation State
  bool _isFormValid = false;

  // Camera & Location State
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  XFile? _capturedImage;
  Position? _currentPosition;

  bool _isInitCamera = true;
  bool _isLocating = false;
  bool _cameraError = false;

  @override
  void initState() {
    super.initState();
    _initializeCameraAndLocation();
    
    // Add listeners to validate form on the fly
    _nameController.addListener(_validateForm);
    _ageController.addListener(_validateForm);
    _locationController.addListener(_validateForm);
  }

  void _validateForm() {
    final isValid = _nameController.text.trim().isNotEmpty &&
                    _ageController.text.trim().isNotEmpty &&
                    _locationController.text.trim().isNotEmpty;
    
    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  Future<void> _initializeCameraAndLocation() async {
    final cameraStatus = await Permission.camera.request();
    final locationStatus = await Permission.location.request();

    if (cameraStatus.isGranted || await Permission.camera.isGranted) {
      try {
        _cameras = await availableCameras();
        if (_cameras != null && _cameras!.isNotEmpty) {
          _cameraController = CameraController(
            _cameras![0],
            ResolutionPreset.medium,
            enableAudio: false,
          );
          await _cameraController!.initialize();
          if (mounted) setState(() {});
        }
      } catch (e) {
        if (mounted) setState(() => _cameraError = true);
      }
    } else {
       if (mounted) setState(() => _cameraError = true);
    }
    
    if (mounted) setState(() => _isInitCamera = false);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();
      
      Position? position;
      if (serviceEnabled && (permission == LocationPermission.always || permission == LocationPermission.whileInUse)) {
         position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      }

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLocating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLocating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location.', style: GoogleFonts.outfit()), backgroundColor: AppTheme.statusError),
        );
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      final image = await _cameraController!.takePicture();
      if (mounted) {
        setState(() => _capturedImage = image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture photo.', style: GoogleFonts.outfit()), backgroundColor: AppTheme.statusError),
        );
      }
    }
  }

  Future<void> _handleConfirm() async {
    final currentInventory = ref.read(inventoryProvider);
    String locationString = '${_currentPosition!.latitude}, ${_currentPosition!.longitude}';

    final finalizedBeneficiary = Beneficiary.create(
      name: _nameController.text.trim(),
      age: int.parse(_ageController.text.trim()),
      location: _locationController.text.trim(),
      photoUrl: _capturedImage!.path,
    );

    final newLog = DistributionLog.create(
      assignmentId: currentInventory.assignmentId ?? 'unknown', 
      beneficiaryId: finalizedBeneficiary.id, 
      agentId: ref.read(authProvider).user?.id ?? 'unknown',
      aidType: _aidType,
      photoPath: _capturedImage!.path,
      locationCoordinate: locationString,
    );

    await ref.read(beneficiaryProvider.notifier).addBeneficiary(finalizedBeneficiary);
    await ref.read(distributionProvider.notifier).addDistribution(newLog);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aid Successfully Distributed to ${finalizedBeneficiary.name}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          backgroundColor: AppTheme.statusSuccess,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _openCameraDialog() {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        body: _buildCameraFullscreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isPhotoDone = _capturedImage != null;
    final bool isLocationDone = _currentPosition != null;
    final bool requirementsMet = _isFormValid && isPhotoDone && isLocationDone;

    return Scaffold(
      appBar: AppBar(title: Text('Proof of Delivery', style: GoogleFonts.outfit())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // STEP 1: Details
            Text('1. Beneficiary Details', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textCharcoal)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController, style: GoogleFonts.inter(fontSize: 16),
              decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ageController, keyboardType: TextInputType.number, style: GoogleFonts.inter(fontSize: 16),
              decoration: const InputDecoration(labelText: 'Age', prefixIcon: Icon(Icons.cake)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationController, style: GoogleFonts.inter(fontSize: 16),
              decoration: const InputDecoration(labelText: 'Village / Location', prefixIcon: Icon(Icons.location_city)),
            ),
            
            const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Divider()),

            // STEP 2: Verification
            Text('2. Verification Requirements', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textCharcoal)),
            if (!_isFormValid)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: Text('Please fill out all beneficiary details above first.', style: GoogleFonts.inter(color: AppTheme.statusError, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: 16),

            _buildActionCard(
              title: 'Capture Beneficiary Photo',
              subtitle: isPhotoDone ? 'Photo captured successfully.' : 'Tap to open the camera.',
              icon: Icons.camera_alt,
              isDone: isPhotoDone,
              isLoading: false,
              isEnabled: _isFormValid,
              onTap: _isFormValid ? _openCameraDialog : null,
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              title: 'Record GPS Location',
              subtitle: isLocationDone ? 'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(4)}' : 'Tap to fetch device coordinates.',
              icon: Icons.location_on,
              isDone: isLocationDone,
              isLoading: _isLocating,
              isEnabled: _isFormValid,
              onTap: (_isFormValid && !isLocationDone) ? _fetchLocation : null,
            ),

            const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Divider()),

            // STEP 3: Submit
            Text('3. Provide Aid', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textCharcoal)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: requirementsMet ? AppTheme.primaryTeal.withOpacity(0.1) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: requirementsMet ? AppTheme.primaryTeal : Colors.grey.shade300, width: 2),
              ),
              child: Row(
                children: [
                  Icon(Icons.inventory_2, color: requirementsMet ? AppTheme.primaryTeal : Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_aidType, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: requirementsMet ? AppTheme.primaryTeal : Colors.grey))),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Opacity(
              opacity: requirementsMet ? 1.0 : 0.4,
              child: AbsorbPointer(
                absorbing: !requirementsMet,
                child: SwipeToConfirm(
                  text: 'SWIPE TO SUBMIT \u2192',
                  onConfirm: _handleConfirm,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({required String title, required String subtitle, required IconData icon, required bool isDone, required bool isLoading, required bool isEnabled, required VoidCallback? onTap}) {
    Color borderColor = Colors.grey.shade300;
    Color bgColor = isEnabled ? Colors.white : Colors.grey.shade100;
    Color iconColor = isEnabled ? AppTheme.primaryTeal : Colors.grey;
    Color iconBgColor = isEnabled ? AppTheme.primaryTeal.withOpacity(0.1) : Colors.grey.shade200;

    if (isDone) {
      borderColor = AppTheme.statusSuccess;
      bgColor = AppTheme.statusSuccess.withOpacity(0.05);
      iconColor = Colors.white;
      iconBgColor = AppTheme.statusSuccess;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor, width: 2)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
              child: Icon(isDone ? Icons.check : icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: isEnabled ? AppTheme.textCharcoal : Colors.grey)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 14, color: isEnabled ? Colors.black54 : Colors.grey)),
                ],
              ),
            ),
            if (isLoading) const CircularProgressIndicator(color: AppTheme.primaryTeal, strokeWidth: 2)
            else if (!isDone && isEnabled) const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraFullscreen() {
    if (_isInitCamera) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal));
    if (_cameraError || _cameraController == null || !_cameraController!.value.isInitialized) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography, size: 64, color: AppTheme.statusError),
              const SizedBox(height: 16),
              Text('Camera Access Denied or Unavailable', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_cameraController!),
        Container(
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.3)),
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.5,
              decoration: BoxDecoration(border: Border.all(color: AppTheme.primaryTeal, width: 3), borderRadius: BorderRadius.circular(24)),
            ),
          ),
        ),
        Positioned(
          top: 60, left: 16,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 32),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        Positioned(
          top: 60, left: 0, right: 0,
          child: Text(
            'Align Component Image',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, shadows: const [Shadow(color: Colors.black54, blurRadius: 10)]),
          ),
        ),
        Positioned(
          bottom: 60, left: 0, right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () async {
                  await _capturePhoto();
                  if (mounted) Navigator.pop(context); // Close dialog on success
                },
                child: Container(
                  height: 80, width: 80, padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
                  child: Container(decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                ),
              ).animate().scale(duration: 200.ms),
            ],
          ),
        )
      ],
    );
  }
}
