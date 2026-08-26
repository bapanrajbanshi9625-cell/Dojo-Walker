// File:
// lib/features/qr_walk/screens/qr_scanner_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/constants/app_colors.dart';
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
  // STATE
  // ==========================================================

  bool _isProcessing = false;
  bool _isFlashOn = false;

  // ==========================================================
  // SCAN QR
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
      // RETURN RESULT
      // ======================================================

      Navigator.of(context).pop(
        jsonEncode(result),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isProcessing = false;
      });

      await _scannerController.start();

      _showError(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
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
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
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
  // CLOSE
  // ==========================================================

  Future<void> _closeScanner() async {
    await _scannerController.stop();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
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
      backgroundColor:
          Colors.black,

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
          // DARK OVERLAY
          // ====================================================

          IgnorePointer(
            child: Container(
              color:
                  Colors.black.withOpacity(
                0.38,
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
                  _roundButton(
                    icon:
                        Icons.arrow_back_rounded,
                    onTap:
                        _closeScanner,
                  ),

                  const SizedBox(
                    width: 14,
                  ),

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
                                FontWeight.w800,
                          ),
                        ),
                        SizedBox(
                          height: 2,
                        ),
                        Text(
                          'Connect to a live walk',
                          style: TextStyle(
                            color: Colors.white70,
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
                // ----------------------------------------------
                // QR FRAME
                // ----------------------------------------------

                SizedBox(
                  width: 286,
                  height: 286,
                  child: Stack(
                    children: [
                      // ----------------------------------------
                      // CENTER GUIDE
                      // ----------------------------------------

                      Center(
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration:
                              BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(
                              24,
                            ),
                            border:
                                Border.all(
                              color:
                                  Colors.white.withOpacity(
                                0.12,
                              ),
                              width: 1,
                            ),
                          ),
                        ),
                      ),

                      // ----------------------------------------
                      // CORNERS
                      // ----------------------------------------

                      Positioned(
                        top: 16,
                        left: 16,
                        child: _scannerCorner(
                          top: true,
                          left: true,
                        ),
                      ),

                      Positioned(
                        top: 16,
                        right: 16,
                        child: _scannerCorner(
                          top: true,
                          left: false,
                        ),
                      ),

                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: _scannerCorner(
                          top: false,
                          left: true,
                        ),
                      ),

                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: _scannerCorner(
                          top: false,
                          left: false,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 26,
                ),

                // ----------------------------------------------
                // INSTRUCTION
                // ----------------------------------------------

                Container(
                  margin:
                      const EdgeInsets.symmetric(
                    horizontal: 30,
                  ),
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors.black
                        .withOpacity(0.62),
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                    border:
                        Border.all(
                      color: Colors.white
                          .withOpacity(
                        0.12,
                      ),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.qr_code_2_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Flexible(
                        child: Text(
                          'Place the Owner QR inside the frame',
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
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
          // PROCESSING OVERLAY
          // ====================================================

          if (_isProcessing)
            Container(
              color:
                  Colors.black.withOpacity(
                0.72,
              ),
              child: Center(
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(
                    horizontal: 34,
                  ),
                  padding:
                      const EdgeInsets.all(
                    26,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(
                      24,
                    ),
                  ),
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 42,
                        height: 42,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 3.5,
                          valueColor:
                              const AlwaysStoppedAnimation<
                                  Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      const Text(
                        'Connecting to Owner',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w800,
                          color:
                              AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(
                        height: 7,
                      ),

                      const Text(
                        'Verifying QR and creating your Live Walk session.',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color:
                              AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ====================================================
          // BOTTOM HELP
          // ====================================================

          if (!_isProcessing)
            Positioned(
              left: 20,
              right: 20,
              bottom: 28,
              child: SafeArea(
                top: false,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 15,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors.black
                        .withOpacity(0.70),
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                    border:
                        Border.all(
                      color: Colors.white
                          .withOpacity(
                        0.10,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration:
                            BoxDecoration(
                          color:
                              AppColors.primary
                                  .withOpacity(
                            0.18,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                        child: const Icon(
                          Icons
                              .center_focus_strong_rounded,
                          color:
                              AppColors.primary,
                          size: 20,
                        ),
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ready to scan',
                              style: TextStyle(
                                color:
                                    Colors.white,
                                fontSize: 13,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                            SizedBox(
                              height: 3,
                            ),
                            Text(
                              'Keep the QR code clear and well lit.',
                              style: TextStyle(
                                color:
                                    Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
      color:
          Colors.black.withOpacity(0.48),
      borderRadius:
          BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(15),
        child: SizedBox(
          width: 46,
          height: 46,
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
    const double size = 46;
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
                  4,
                ),
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
                  4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
