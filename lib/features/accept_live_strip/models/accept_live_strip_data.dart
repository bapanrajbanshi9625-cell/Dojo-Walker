import 'package:flutter/foundation.dart';

/// The state represented by the Walker Accept/Live Strip.
///
/// accepted -> Incoming Walk screen
/// ready    -> Live Walk Start screen
/// live     -> Live Walk screen
/// hidden   -> no strip
enum AcceptLiveStripStatus {
  hidden,
  accepted,
  ready,
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

  bool get isReady {
    return status == AcceptLiveStripStatus.ready;
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
