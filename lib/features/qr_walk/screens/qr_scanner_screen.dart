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

    setState(() {
      _isProcessing = true;
    });

    await _scannerController.stop();

    try {
      final Map<String, dynamic> result =
          await _qrWalkService.processOwnerQr(
        rawData: cleanData,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(
        jsonEncode(result),
      );
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
                    fontWeight: FontWeight.w600,
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
                  _roundButton(
                    icon:
                        Icons.arrow_back_rounded,
                    onTap:
                        _closeScanner,
                  ),

                  const SizedBox(width: 14),

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
                // ----------------------------------------------
                // SCANNER FRAME
                // ----------------------------------------------

                SizedBox(
                  width: 300,
                  height: 300,
                  child: Stack(
                    alignment:
                        Alignment.center,
                    children: [
                      // ----------------------------------------
                      // SOFT CENTER BOX
                      // ----------------------------------------

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

                      // ----------------------------------------
                      // TOP LEFT
                      // ----------------------------------------

                      Positioned(
                        top: 21,
                        left: 21,
                        child:
                            _scannerCorner(
                          top: true,
                          left: true,
                        ),
                      ),

                      // ----------------------------------------
                      // TOP RIGHT
                      // ----------------------------------------

                      Positioned(
                        top: 21,
                        right: 21,
                        child:
                            _scannerCorner(
                          top: true,
                          left: false,
                        ),
                      ),

                      // ----------------------------------------
                      // BOTTOM LEFT
                      // ----------------------------------------

                      Positioned(
                        bottom: 21,
                        left: 21,
                        child:
                            _scannerCorner(
                          top: false,
                          left: true,
                        ),
                      ),

                      // ----------------------------------------
                      // BOTTOM RIGHT
                      // ----------------------------------------

                      Positioned(
                        bottom: 21,
                        right: 21,
                        child:
                            _scannerCorner(
                          top: false,
                          left: false,
                        ),
                      ),

                      // ----------------------------------------
                      // CENTER QR ICON
                      // ----------------------------------------

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

                // ----------------------------------------------
                // MAIN INSTRUCTION
                // ----------------------------------------------

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
          // BOTTOM HELP
          // ====================================================

          if (!_isProcessing)
            Positioned(
              left: 16,
              right: 16,
              bottom: 22,
              child: SafeArea(
                top: false,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(
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
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                        child: const Icon(
                          Icons
                              .center_focus_strong_rounded,
                          color:
                              AppColors.primary,
                          size: 21,
                        ),
                      ),

                      const SizedBox(width: 12),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
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
                            SizedBox(height: 3),
                            Text(
                              'Keep the QR clear and well lit.',
                              style: TextStyle(
                                color:
                                    Colors.white70,
                                fontSize: 11,
                                fontWeight:
                                    FontWeight.w500,
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
          // -----------------------------------------------
          // HORIZONTAL
          // -----------------------------------------------

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

          // -----------------------------------------------
          // VERTICAL
          // -----------------------------------------------

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
