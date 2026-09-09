import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/dojo_walker.dart';
import '../../live_walk/screens/live_walk_start_screen.dart';
import '../services/qr_walk_service.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({
    super.key,
  });

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final QrWalkService _qrWalkService = QrWalkService();

  final MobileScannerController _scannerController =
      MobileScannerController();

  final ImagePicker _imagePicker = ImagePicker();

  bool _isProcessing = false;
  bool _isFlashOn = false;

  // ==========================================================
  // PROCESS QR
  // ==========================================================

  Future<void> _processQr(String rawData) async {
    if (_isProcessing) {
      return;
    }

    final String cleanData = rawData.trim();

    if (cleanData.isEmpty) {
      _showError('Invalid QR code.');
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await _scannerController.stop();

      final Map<String, dynamic> result =
          await _qrWalkService.processOwnerQr(
        rawData: cleanData,
      );

      if (!mounted) {
        return;
      }

      await _openLiveWalk(result);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isProcessing = false;
      });

      await _scannerController.start();

      _showError(
        error.toString().replaceFirst('Exception: ', '').trim(),
      );
    }
  }

  // ==========================================================
  // OPEN LIVE WALK
  // ==========================================================

  Future<void> _openLiveWalk(
    Map<String, dynamic> result,
  ) async {
    final String ownerUid =
        _firstNonEmpty([
      result['ownerUid']?.toString(),
      result['ownerAuthUid']?.toString(),
      result['authUid']?.toString(),
    ]);

    final String ownerName =
        _firstNonEmpty([
      result['ownerName']?.toString(),
      'Owner',
    ]);

    final String screenId =
        _firstNonEmpty([
      result['requestId']?.toString(),
      result['walkId']?.toString(),
    ]);

    final String dogName =
        _firstNonEmpty([
      result['dogName']?.toString(),
      'Dog',
    ]);

    final String dogBreed =
        _firstNonEmpty([
      result['dogBreed']?.toString(),
    ]);

    final String ownerPhone =
        _firstNonEmpty([
      result['ownerPhone']?.toString(),
      result['phone']?.toString(),
    ]);

    if (ownerUid.isEmpty) {
      throw Exception('Owner information not found.');
    }

    if (screenId.isEmpty) {
      throw Exception('Walk ID not found.');
    }

    if (!mounted) {
      return;
    }

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LiveWalkStartScreen(
          ownerUid: ownerUid,
          ownerName: ownerName,
          requestId: screenId,
          dogName: dogName,
          dogBreed: dogBreed,
          ownerPhone: ownerPhone.isEmpty ? null : ownerPhone,
        ),
      ),
    );
  }

  // ==========================================================
  // GALLERY
  // ==========================================================

  Future<void> _pickQrFromGallery() async {
    if (_isProcessing) {
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null) {
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isProcessing = true;
      });

      await _scannerController.stop();

      // ======================================================
      // ANALYZE GALLERY IMAGE
      // ======================================================

      final BarcodeCapture? capture =
          await _scannerController.analyzeImage(
        image.path,
      );

      // ======================================================
      // NO QR
      // ======================================================

      if (capture == null || capture.barcodes.isEmpty) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isProcessing = false;
        });

        await _scannerController.start();

        _showError(
          'No valid QR code found in this image.',
        );

        return;
      }

      // ======================================================
      // FIND QR VALUE
      // ======================================================

      String? qrValue;

      for (final Barcode barcode in capture.barcodes) {
        final String? value = barcode.rawValue;

        if (value != null && value.trim().isNotEmpty) {
          qrValue = value.trim();
          break;
        }
      }

      // ======================================================
      // INVALID QR
      // ======================================================

      if (qrValue == null || qrValue.isEmpty) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isProcessing = false;
        });

        await _scannerController.start();

        _showError(
          'No valid QR code found in this image.',
        );

        return;
      }

      // ======================================================
      // PROCESS QR
      //
      // IMPORTANT:
      // _pickQrFromGallery() already set _isProcessing = true.
      // _processQr() also checks _isProcessing at the beginning.
      //
      // Reset it here so _processQr() can take over normally.
      // No QR/Firebase/Live Walk logic is changed.
      // ======================================================

      if (!mounted) {
        return;
      }

      setState(() {
        _isProcessing = false;
      });

      await _processQr(qrValue);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isProcessing = false;
      });

      await _scannerController.start();

      _showError(
        error.toString().replaceFirst('Exception: ', '').trim(),
      );
    }
  }

  // ==========================================================
  // ERROR
  // ==========================================================

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: DojoWalkerColors.white,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message.isEmpty
                      ? 'Unable to scan QR code.'
                      : message,
                  style: const TextStyle(
                    color: DojoWalkerColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: DojoWalkerColors.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
  }

  // ==========================================================
  // FLASH
  // ==========================================================

  Future<void> _toggleFlash() async {
    try {
      await _scannerController.toggleTorch();

      if (!mounted) {
        return;
      }

      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (_) {
      // Ignore torch errors.
    }
  }

  // ==========================================================
  // FIRST NON EMPTY
  // ==========================================================

  String _firstNonEmpty(List<String?> values) {
    for (final String? value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return '';
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ====================================================
          // CAMERA
          // ====================================================

          MobileScanner(
            controller: _scannerController,
            onDetect: (BarcodeCapture capture) {
              if (_isProcessing) {
                return;
              }

              for (final Barcode barcode in capture.barcodes) {
                final String? value = barcode.rawValue;

                if (value != null && value.trim().isNotEmpty) {
                  _processQr(value.trim());
                  break;
                }
              }
            },
          ),

          // ====================================================
          // DARK OVERLAY
          // ====================================================

          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.42),
              ),
            ),
          ),

          // ====================================================
          // TOP CONTENT
          // ====================================================

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),

                const Text(
                  'Scan Owner QR',
                  style: TextStyle(
                    color: DojoWalkerColors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 8),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Scan the owner QR code to connect and start the Live Walk.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: DojoWalkerColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const Spacer(),

                // ==================================================
                // SCANNER FRAME
                // ==================================================

                SizedBox(
                  width: 270,
                  height: 270,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        child: _scannerCorner(
                          topLeft: true,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _scannerCorner(
                          topRight: true,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: _scannerCorner(
                          bottomLeft: true,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: _scannerCorner(
                          bottomRight: true,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ==================================================
                // PROCESSING
                // ==================================================

                if (_isProcessing)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        DojoWalkerColors.primary,
                      ),
                    ),
                  ),

                // ==================================================
                // CONTROLS
                // ==================================================

                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    0,
                    24,
                    34,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _roundButton(
                        icon: _isFlashOn
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        onTap: _toggleFlash,
                      ),
                      const SizedBox(width: 24),
                      _roundButton(
                        icon: Icons.photo_library_rounded,
                        onTap: _pickQrFromGallery,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ROUND BUTTON
  // ==========================================================

  Widget _roundButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: _isProcessing ? null : onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(
            icon,
            color: DojoWalkerColors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // SCANNER CORNER
  // ==========================================================

  Widget _scannerCorner({
    bool topLeft = false,
    bool topRight = false,
    bool bottomLeft = false,
    bool bottomRight = false,
  }) {
    const double size = 34;
    const double thickness = 4;

    BorderRadius radius;

    if (topLeft) {
      radius = const BorderRadius.only(
        topLeft: Radius.circular(8),
      );
    } else if (topRight) {
      radius = const BorderRadius.only(
        topRight: Radius.circular(8),
      );
    } else if (bottomLeft) {
      radius = const BorderRadius.only(
        bottomLeft: Radius.circular(8),
      );
    } else {
      radius = const BorderRadius.only(
        bottomRight: Radius.circular(8),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border(
          top: topLeft || topRight
              ? const BorderSide(
                  color: DojoWalkerColors.primary,
                  width: thickness,
                )
              : BorderSide.none,
          bottom: bottomLeft || bottomRight
              ? const BorderSide(
                  color: DojoWalkerColors.primary,
                  width: thickness,
                )
              : BorderSide.none,
          left: topLeft || bottomLeft
              ? const BorderSide(
                  color: DojoWalkerColors.primary,
                  width: thickness,
                )
              : BorderSide.none,
          right: topRight || bottomRight
              ? const BorderSide(
                  color: DojoWalkerColors.primary,
                  width: thickness,
                )
              : BorderSide.none,
        ),
        borderRadius: radius,
      ),
    );
  }
}
