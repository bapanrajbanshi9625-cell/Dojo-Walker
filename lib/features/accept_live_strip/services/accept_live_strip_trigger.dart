import '../models/accept_live_strip_data.dart';
import 'accept_live_strip_service.dart';

class AcceptLiveStripTrigger {
  AcceptLiveStripTrigger._();

  static final AcceptLiveStripTrigger instance =
      AcceptLiveStripTrigger._();

  Stream<AcceptLiveStripData> watch() {
    return AcceptLiveStripService.instance.watch();
  }
}
