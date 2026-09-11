import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walker_colors.dart';

class IncomingWalkTopBar extends StatelessWidget {
  const IncomingWalkTopBar({
    super.key,
    this.onMore,
  });

  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                blurRadius: 12,
                offset: const Offset(0, 3),
                color: Colors.black.withValues(alpha: 0.10),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              // ==================================================
              // DOJO WALKER LOGO
              // ==================================================
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: DojoWalkerColors.primary.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'assets/DOJO_WALKER.png',
                  fit: BoxFit.contain,
                  errorBuilder: (
                    BuildContext context,
                    Object error,
                    StackTrace? stackTrace,
                  ) {
                    return const Icon(
                      Icons.pets_rounded,
                      color: DojoWalkerColors.primary,
                      size: 23,
                    );
                  },
                ),
              ),

              // ==================================================
              // CENTER TITLE
              // ==================================================
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const <Widget>[
                    Text(
                      'INSTA WALK NEW WALK REQUEST',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                        height: 1.1,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'New walk request',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // THREE DOT MENU
              // ==================================================
              SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  tooltip: 'More',
                  onPressed: onMore,
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: DojoWalkerColors.primary,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
