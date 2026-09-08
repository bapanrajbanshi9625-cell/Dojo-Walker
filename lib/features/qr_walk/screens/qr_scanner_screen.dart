// File:
// lib/features/qr_walk/screens/qr_scanner_screen.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/constants/app_colors.dart';
import '../../live_walk/screens/live_walk_screen.dart';
import '../services/qr_walk_service.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({
    super.key,
  });

  @override
  State<QrScannerScreen> createState() =>
      _QrScannerScreenState();
}

class _QrScannerScreenState
    extends State<QrScannerScreen> {
  // ==========================================================
  // SERVICE
  // ==========================================================

  final QrWalkService _qrWalkService =
      QrWalkService();

  // ==========================================================
  // SCANNER
  // ==========================================================

  final MobileScannerController
      _scannerController =
      MobileScannerController();

  // ==========================================================
  // GALLERY
  // ==========================================================

  final ImagePicker _imagePicker =
      ImagePicker();

  // ==========================================================
  // STATE
  // ==========================================================

  bool _isProcessing = false;
  bool _isFlashOn = false;

  // ==========================================================
  // QR PROCESS
  // ==========================================================

  Future<void> _processQr(
    String rawData,
  ) async {
    if (_isProcessing) {
      return;
    }

    final String cleanData =
        rawData.trim();

    if (cleanData.isEmpty) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    await _scannerController.stop();

    try {
      // ======================================================
      // PROCESS OWNER QR
      // ======================================================

      final Map<String, dynamic> result =
          await _qrWalkService.processOwnerQr(
        rawData: cleanData,
      );

      if (!mounted) {
        return;
      }

      // ======================================================
      // OPEN LIVE WALK
      // ======================================================

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
        error
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            )
            .trim(),
      );
    }
  }

  // ==========================================================
  // OPEN LIVE WALK
  // ==========================================================

  Future<void> _openLiveWalk(
    Map<String, dynamic> result,
  ) async {
    if (!mounted) {
      return;
    }

    // ========================================================
    // CANONICAL REQUEST / WALK ID
    //
    // New architecture:
    // requestId = DW000001
    //
    // Backward compatibility:
    // walkId
    // ========================================================

    final String requestId =
        _firstNonEmpty(
      <String?>[
        result['requestId']?.toString(),
        result['walkId']?.toString(),
      ],
    );

    // ========================================================
    // LIVE SESSION ID
    // ========================================================

    final String liveSessionId =
        _firstNonEmpty(
      <String?>[
        result['liveSessionId']?.toString(),
        result['sessionId']?.toString(),
      ],
    );

    if (requestId.isEmpty &&
        liveSessionId.isEmpty) {
      setState(() {
        _isProcessing = false;
      });

      await _scannerController.start();

      _showError(
        'Walk ID is missing from QR code.',
      );

      return;
    }

    // ========================================================
    // SCREEN ID
    // ========================================================

    final String screenId =
        requestId.isNotEmpty
            ? requestId
            : liveSessionId;

    // ========================================================
    // OWNER DATA
    // ========================================================

    final String ownerUid =
        result['ownerUid']
                ?.toString()
                .trim() ??
            '';

    final String ownerName =
        result['ownerName']
                ?.toString()
                .trim()
                .isNotEmpty ==
            true
        ? result['ownerName']
            .toString()
            .trim()
        : 'Owner';

    // ========================================================
    // DOG DATA
    // ========================================================

    final String dogName =
        result['dogName']
                ?.toString()
                .trim()
                .isNotEmpty ==
            true
        ? result['dogName']
            .toString()
            .trim()
        : 'Dog';

    final String dogBreed =
        result['dogBreed']
                ?.toString()
                .trim() ??
            '';

    // ========================================================
    // OWNER PHONE
    // ========================================================

    final String ownerPhoneValue =
        result['ownerPhone']
                ?.toString()
                .trim() ??
            '';

    final String? ownerPhone =
        ownerPhoneValue.isEmpty
            ? null
            : ownerPhoneValue;

    // ========================================================
    // REQUIRED OWNER UID CHECK
    // ========================================================

    if (ownerUid.isEmpty) {
      setState(() {
        _isProcessing = false;
      });

      await _scannerController.start();

      _showError(
        'Owner information is incomplete.',
      );

      return;
    }

    // ========================================================
    // OPEN LIVE WALK
    // ========================================================

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LiveWalkScreen(
          ownerUid: ownerUid,
          ownerName: ownerName,
          requestId: screenId,
          dogName: dogName,
          dogBreed: dogBreed.isEmpty
              ? null
              : dogBreed,
          ownerPhone: ownerPhone,
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
      final XFile? image =
          await _imagePicker.pickImage(
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
      // NO QR FOUND
      // ======================================================

      if (capture == null ||
          capture.barcodes.isEmpty) {
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

      for (final Barcode barcode
          in capture.barcodes) {
        final String? value =
            barcode.rawValue;

        if (value != null &&
            value.trim().isNotEmpty) {
          qrValue = value.trim();
          break;
        }
      }

      // ======================================================
      // INVALID QR
      // ======================================================

      if (qrValue == null ||
          qrValue.isEmpty) {
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
      // PROCESS GALLERY QR
      // ======================================================

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
        error
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            )
            .trim(),
      );
    }
  }

  // ==========================================================
  // ERROR
  // ==========================================================

  void _showError(
    String message,
  ) {
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
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message.isEmpty
                      ? 'Unable to scan QR code.'
                      : message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor:
              AppColors.errorDark,
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            20,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
        ),
      );
  }

  // ==========================================================
  // FLASH
  // ==========================================================

  Future<void> _toggleFlash() async {
    await _scannerController.toggleTorch();

    if (!mounted) {
      return;
    }

    setState(() {
      _isFlashOn = !_isFlashOn;
    });
  }

  // ==========================================================
  // FIRST NON EMPTY
  // ==========================================================

  String _firstNonEmpty(
    List<String?> values,
  ) {
    for (final String? value in values) {
      final String cleaned =
          value?.trim() ?? '';

      if (cleaned.isNotEmpty) {
        return cleaned;
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
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ====================================================
          // CAMERA
          // ====================================================

          MobileScanner(
            controller:
                _scannerController,
            onDetect:
                (BarcodeCapture capture) {
              if (_isProcessing) {
                return;
              }

              for (
                final Barcode barcode
                    in capture.barcodes
              ) {
                final String? value =
                    barcode.rawValue;

                if (value != null &&
                    value.trim().isNotEmpty) {
                  _processQr(value);
                  break;
                }
              }
            },
          ),

          // ====================================================
          // CAMERA OVERLAY
          // ====================================================

          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin:
                      Alignment.topCenter,
                  end:
                      Alignment.bottomCenter,
                  stops: const [
                    0.0,
                    0.28,
                    0.62,
                    1.0,
                  ],
                  colors: [
                    Colors.black.withValues(
                      alpha: .68,
                    ),
                    Colors.black.withValues(
                      alpha: .18,
                    ),
                    Colors.black.withValues(
                      alpha: .10,
                    ),
                    Colors.black.withValues(
                      alpha: .72,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ====================================================
          // TOP BAR
          // ====================================================

          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                12,
                16,
                0,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan Owner QR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight:
                                FontWeight.w900,
                            letterSpacing: -.2,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Connect to a Live Walk',
                          style: TextStyle(
                            color:
                                Colors.white70,
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  _roundButton(
                    icon: _isFlashOn
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    onTap:
                        _toggleFlash,
                  ),
                ],
              ),
            ),
          ),

          // ====================================================
          // CENTER SCANNER
          // ====================================================

          Center(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                SizedBox(
                  width: 300,
                  height: 300,
                  child: Stack(
                    alignment:
                        Alignment.center,
                    children: [
                      Container(
                        width: 258,
                        height: 258,
                        decoration:
                            BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(
                            26,
                          ),
                          border:
                              Border.all(
                            color: Colors.white
                                .withValues(
                              alpha: .16,
                            ),
                            width: 1,
                          ),
                        ),
                      ),

                      Positioned(
                        top: 21,
                        left: 21,
                        child:
                            _scannerCorner(
                          top: true,
                          left: true,
                        ),
                      ),

                      Positioned(
                        top: 21,
                        right: 21,
                        child:
                            _scannerCorner(
                          top: true,
                          left: false,
                        ),
                      ),

                      Positioned(
                        bottom: 21,
                        left: 21,
                        child:
                            _scannerCorner(
                          top: false,
                          left: true,
                        ),
                      ),

                      Positioned(
                        bottom: 21,
                        right: 21,
                        child:
                            _scannerCorner(
                          top: false,
                          left: false,
                        ),
                      ),

                      Container(
                        width: 42,
                        height: 42,
                        decoration:
                            BoxDecoration(
                          color: Colors.black
                              .withValues(
                            alpha: .32,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons
                              .qr_code_scanner_rounded,
                          color: Colors.white
                              .withValues(
                            alpha: .65,
                          ),
                          size: 23,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Container(
                  margin:
                      const EdgeInsets.symmetric(
                    horizontal: 30,
                  ),
                  padding:
                      const EdgeInsets.fromLTRB(
                    18,
                    14,
                    20,
                    14,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors.black
                        .withValues(
                      alpha: .68,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                    border:
                        Border.all(
                      color: Colors.white
                          .withValues(
                        alpha: .12,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration:
                            BoxDecoration(
                          color: AppColors
                              .primary
                              .withValues(
                            alpha: .18,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            11,
                          ),
                        ),
                        child: const Icon(
                          Icons.qr_code_2_rounded,
                          color:
                              AppColors.primary,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 11),
                      const Flexible(
                        child: Text(
                          'Place the Owner QR\ninside the frame',
                          textAlign:
                              TextAlign.left,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.3,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ====================================================
          // PROCESSING
          // ====================================================

          if (_isProcessing)
            Container(
              color: Colors.black.withValues(
                alpha: .78,
              ),
              child: Center(
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(
                    horizontal: 30,
                  ),
                  padding:
                      const EdgeInsets.fromLTRB(
                    26,
                    28,
                    26,
                    25,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(
                      26,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 25,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Container(
                        width: 66,
                        height: 66,
                        decoration:
                            BoxDecoration(
                          color: AppColors
                              .primary
                              .withValues(
                            alpha: .10,
                          ),
                          shape:
                              BoxShape.circle,
                        ),
                        child: const Padding(
                          padding:
                              EdgeInsets.all(
                            16,
                          ),
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor:
                                AlwaysStoppedAnimation<
                                    Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'Connecting to Owner',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.w900,
                          color:
                              AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 7),

                      const Text(
                        'Verifying QR and creating\nyour Live Walk session.',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color:
                              AppColors.textSecondary,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ====================================================
          // BOTTOM HELP + GALLERY
          // ====================================================

          if (!_isProcessing)
            Positioned(
              left: 16,
              right: 16,
              bottom: 22,
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Material(
                      color: Colors.black
                          .withValues(
                        alpha: .72,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                      child: InkWell(
                        onTap:
                            _pickQrFromGallery,
                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),
                        child: SizedBox(
                          width: 58,
                          height: 66,
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            children: [
                              const Icon(
                                Icons
                                    .photo_library_rounded,
                                color:
                                    AppColors.primary,
                                size: 22,
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              const Text(
                                'Gallery',
                                style:
                                    TextStyle(
                                  color:
                                      Colors.white,
                                  fontSize: 9,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors.black
                              .withValues(
                            alpha: .72,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            18,
                          ),
                          border:
                              Border.all(
                            color: Colors.white
                                .withValues(
                              alpha: .10,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration:
                                  BoxDecoration(
                                color: AppColors
                                    .primary
                                    .withValues(
                                  alpha: .16,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  12,
                                ),
                              ),
                              child:
                                  const Icon(
                                Icons
                                    .center_focus_strong_rounded,
                                color:
                                    AppColors
                                        .primary,
                                size: 21,
                              ),
                            ),

                            const SizedBox(
                              width: 12,
                            ),

                            const Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    'Ready to scan',
                                    style:
                                        TextStyle(
                                      color: Colors
                                          .white,
                                      fontSize: 13,
                                      fontWeight:
                                          FontWeight
                                              .w800,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 3,
                                  ),
                                  Text(
                                    'Keep the QR clear and well lit.',
                                    style:
                                        TextStyle(
                                      color: Colors
                                          .white70,
                                      fontSize: 11,
                                      fontWeight:
                                          FontWeight
                                              .w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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

  // ==========================================================
  // ROUND BUTTON
  // ==========================================================

  Widget _roundButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withValues(
        alpha: .52,
      ),
      borderRadius:
          BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(16),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // SCANNER CORNER
  // ==========================================================

  Widget _scannerCorner({
    required bool top,
    required bool left,
  }) {
    const double size = 48;
    const double thickness = 4;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned(
            top: top ? 0 : null,
            bottom: top ? null : 0,
            left: left ? 0 : null,
            right: left ? null : 0,
            child: Container(
              width: size,
              height: thickness,
              decoration:
                  BoxDecoration(
                color:
                    AppColors.primary,
                borderRadius:
                    BorderRadius.circular(
                  5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors
                        .primary
                        .withValues(
                      alpha: .35,
                    ),
                    blurRadius: 7,
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: top ? 0 : null,
            bottom: top ? null : 0,
            left: left ? 0 : null,
            right: left ? null : 0,
            child: Container(
              width: thickness,
              height: size,
              decoration:
                  BoxDecoration(
                color:
                    AppColors.primary,
                borderRadius:
                    BorderRadius.circular(
                  5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors
                        .primary
                        .withValues(
                      alpha: .35,
                    ),
                    blurRadius: 7,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
