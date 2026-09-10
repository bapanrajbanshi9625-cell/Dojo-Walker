import 'package:flutter/foundation.dart';

/// The state represented by the Walker Accept/Live Strip.
///
/// The strip has only three meaningful states:
///
/// accepted -> Incoming Walk screen
/// live     -> Live Walk screen
/// hidden   -> no strip
enum AcceptLiveStripStatus {
  hidden,
  accepted,
  live,
}

@immutable
class AcceptLiveStripData {
  const AcceptLiveStripData({
    required this.status,
    required this.requestId,
  });

  const AcceptLiveStripData.hidden()
      : status = AcceptLiveStripStatus.hidden,
        requestId = '';

  final AcceptLiveStripStatus status;

  /// Canonical Dojo walk request ID.
  ///
  /// Example:
  /// DW000001
  final String requestId;

  bool get show {
    return status != AcceptLiveStripStatus.hidden;
  }

  bool get isAccepted {
    return status == AcceptLiveStripStatus.accepted;
  }

  bool get isLive {
    return status == AcceptLiveStripStatus.live;
  }

  bool get isHidden {
    return status == AcceptLiveStripStatus.hidden;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AcceptLiveStripData &&
            other.status == status &&
            other.requestId == requestId;
  }

  @override
  int get hashCode {
    return Object.hash(
      status,
      requestId,
    );
  }
}
