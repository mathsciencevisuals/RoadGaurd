import 'alert_event.dart';

abstract class AlertDispatcher {
  Future<void> dispatch(AlertEvent event);
}
