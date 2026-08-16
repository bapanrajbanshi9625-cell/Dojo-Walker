@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF5F6F8),
    body: Stack(
      children: [
        // ========================================================
        // MAIN CONTENT
        // ========================================================

        Column(
          children: [
            // ====================================================
            // COMMON ORANGE HEADER
            // ====================================================

            const WalkerHomeHeader(),

            // ====================================================
            // SCROLLABLE CONTENT
            // ====================================================

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  14,
                  16,
                  115,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // ============================================
                    // WELCOME
                    // ============================================

                    const WelcomeContainer(),

                    const SizedBox(height: 18),

                    // ============================================
                    // TODAY SUMMARY
                    // ============================================

                    TodaySummaryContainer(
                      onDetails: ({
                        required String title,
                        required String description,
                        required IconData icon,
                      }) {
                        _showDetails(
                          context,
                          title: title,
                          description: description,
                          icon: icon,
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    // ============================================
                    // LIVE LOCATION
                    // ============================================

                    LiveLocationContainer(
                      isWalkStarted: _isWalkStarted,
                    ),

                    const SizedBox(height: 18),

                    // ============================================
                    // PAST WALKS
                    // ============================================

                    PastWalksContainer(
                      onDetails: ({
                        required String title,
                        required String description,
                        required IconData icon,
                      }) {
                        _showDetails(
                          context,
                          title: title,
                          description: description,
                          icon: icon,
                        );
                      },
                    ),

                    // ============================================
                    // ACTIVE WALK
                    // ============================================

                    if (_isWalkStarted) ...[
                      const SizedBox(height: 14),

                      _ActiveWalkButton(
                        ownerName: _ownerName ?? 'Owner',
                        onTap: _openActiveWalk,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),

        // ========================================================
        // FLOATING QR BUTTON
        // ========================================================

        if (!_isWalkStarted)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _FloatingQrButton(
              onTap: _openCameraScanner,
            ),
          ),
      ],
    ),
  );
}
