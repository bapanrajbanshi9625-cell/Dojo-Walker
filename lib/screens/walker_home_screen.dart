@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF5F6F8),

    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          // ======================================================
          // HEADER
          // ======================================================

          const WalkerHomeHeader(),

          // ======================================================
          // SCROLLABLE HOME CONTENT
          // ======================================================

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                95,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // ==================================================
                  // WELCOME
                  // ==================================================

                  const WelcomeContainer(),

                  const SizedBox(height: 18),

                  // ==================================================
                  // TODAY SUMMARY
                  // ==================================================

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

                  // ==================================================
                  // LIVE LOCATION
                  // ==================================================

                  LiveLocationContainer(
                    isWalkStarted: _isWalkStarted,
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // PAST WALKS
                  // ==================================================

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

                  // Bottom safe space.
                  // QR button is NOT inside the scroll.
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ],
      ),
    ),

    // ============================================================
    // FLOATING QR + MAIN NAVIGATION
    // ============================================================

    bottomNavigationBar: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --------------------------------------------------------
          // FLOATING QR BUTTON
          // --------------------------------------------------------

          if (!_isWalkStarted)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                10,
              ),
              child: ScanQrContainer(
                onTap: _openCameraScanner,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                10,
              ),
              child: _ActiveWalkButton(
                ownerName: _ownerName ?? 'Owner',
                onTap: _openActiveWalk,
              ),
            ),

          // --------------------------------------------------------
          // MAIN NAVIGATION
          //
          // IMPORTANT:
          // YAHAN tumhara existing app-level navigation hona chahiye.
          // WalkerHomeScreen ke andar koi second navigation nahi.
          // --------------------------------------------------------

          const SizedBox(height: 0),
        ],
      ),
    ),
  );
}
