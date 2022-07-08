import 'dart:async';

import 'package:alog/ConsoleAdapter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ulog/flutter_ulog.dart';
export 'package:flutter_ulog/flutter_ulog.dart';

class Alog {
  static const MethodChannel _channel = MethodChannel('alog');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  // static toJson? tojson;
  //
  // static void init(toJson? tojsonfun){
  //   tojson = tojsonfun;
  // }

  static void init(bool isLoggable) {
    ULog.addLogAdapter(ConsoleAdapter(isLoggable));
  }

  static void Function() clearLogAdapters = ULog.clearLogAdapters;

  static void Function(ULogAdapter adapter) removeLogAdapters =
      ULog.removeLogAdapters;

  /// Log a message at level [ULogType.verbose].
  static void Function(dynamic message,
      {dynamic error, StackTrace? stackTrace, String? tag}) v = ULog.v;

  /// Log a message at level [ULogType.debug].
  static void Function(dynamic message,
      {dynamic error, StackTrace? stackTrace, String? tag}) d = ULog.d;

  /// Log a message at level [ULogType.info].
  static void Function(dynamic message,
      {dynamic error, StackTrace? stackTrace, String? tag}) i = ULog.i;

  /// Log a message at level [ULogType.warning].
  static void Function(dynamic message,
      {dynamic error, StackTrace? stackTrace, String? tag}) w = ULog.w;

  /// Log a message at level [ULogType.error].
  static void Function(dynamic message,
      {dynamic error, StackTrace? stackTrace, String? tag}) e = ULog.e;

  static void Function(String json, {String? tag}) json = ULog.json;

  // static void xml(String xml,{String? tag}) {
  //   printer.xml(xml,tag:tag);
  // }

  // static void o(dynamic obj,{String? tag}) {
  //   printer.o(obj,tag: tag);
  // }
  static void netPrint(Object message){
    print(message);
  }
}
