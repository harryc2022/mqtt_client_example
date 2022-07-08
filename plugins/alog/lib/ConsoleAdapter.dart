
import 'package:flutter_ulog/flutter_ulog.dart';

class ConsoleAdapter extends ULogConsoleAdapter{
  bool loggable;
  ConsoleAdapter(this.loggable);
  @override
  bool isLoggable(ULogType type, String? tag) => this.loggable;
}