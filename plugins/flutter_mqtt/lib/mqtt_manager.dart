import 'dart:async';

import 'package:mqtt_client/mqtt_client.dart';
import 'mqtt_tools.dart';


/**
 * MqttManager
 * example：
 * void systemMsg(dynamic payload) {
 *   do work
 *  }
 * MqttManager.install.systemStatus.addListener(systemMsg,SystemStatus.EventMsg); //订阅
 *
 * MqttManager.install.systemStatus.removeListener(systemMsg,SystemStatus.EventMsg); // 取消订阅
 */
class MqttManager {
  MqttManager._() {
    _init();
  }

  static MqttManager? _instance;

  /// 单例共享
  static MqttManager get instance =>
      _instance != null ? _instance! : MqttManager._();

  void _init() {
    _instance = this;
  }

  Timer? connectTimer = null; // 定义定时器

  // MqttSystem systemManager = MqttSystem();
  BaseStatus systemStatus = SystemStatus();

  BaseStatus roomStatus = RoomStatus();

  String? _server;
  String? _clientIdentifier;
  int? _port;

  bool isConnectIng = false;

  bool isConnected(String server, String clientIdentifier,port) {
    if (_server == server
        && _clientIdentifier == clientIdentifier
        && _port == port
    ) {
      var status = MqttTool.sheard.getConnectionState();
      if (status == MqttConnectionState.connected ||
          status == MqttConnectionState.connecting) {
        return true;
      }
    }
    _server = server;
    _clientIdentifier = clientIdentifier;
    _port = port;
    return false;
  }

  void disConnect() {
    MqttTool.sheard.disconnect();
    _server = null;
    _clientIdentifier = null;
  }

  void connect(
      String server,
      String clientIdentifier,
      int port) async {
    if (isConnectIng) {
      return;
    }
    isConnectIng = true;
    if (server.isNotEmpty == true && clientIdentifier.isNotEmpty == true) {
      if (!isConnected(server, clientIdentifier,port)) {
        _initConnect();
      }
    }
    isConnectIng = false;
  }
  void _initConnect(){
    connectTimer?.cancel();
    connectTimer = null;
    _connect();
    connectTimer ??= Timer.periodic(const Duration(seconds: 10), (timer) {
      _connect();
    });
  }

  void _connect() async {
    if (_server == null
        || _clientIdentifier == null
    ) {
      connectTimer?.cancel();
      connectTimer = null;
      return;
    }
    if (!isConnected(_server!, _clientIdentifier!,_port)) {
      MqttTool.sheard.connect(_server!, _clientIdentifier!,_port!);
    }
    print("MqttManager connect Ip:${_server} userId:$_clientIdentifier status:${MqttTool.sheard.getConnectionState()}");
    if(MqttTool.sheard.getConnectionState() == MqttConnectionState.connected){
      connectTimer?.cancel();
      connectTimer = null;
      return;
    }
  }

  void doMsg(String cmd, String event, dynamic payload) async {
    switch (cmd) {
      case "system":
        systemStatus.doMsg(event, payload);
        break;
      case "room":
        roomStatus.doMsg(event, payload);
        break;
      default:
        print("MqttManager miss ==> cmd:$cmd event:$event payload:$payload");
        break;
    }
  }
}

abstract class BaseStatus {
  abstract String tag;

  /// 监听者
  Map<String, List<void Function(dynamic)>> _listener = {};


  /// 添加观察者
  void addListener(void Function(dynamic) fn, String name) async {
    if (name.isNotEmpty) {
      var otherLst = _listener[name];
      if (otherLst == null || otherLst.isEmpty) {
        _listener[name] = [fn];
      } else {
        _listener[name] = otherLst..add(fn);
      }
    }
  }

  /// 通知观察者
  void notificationListener({String? event, dynamic payload}) {
    var dl = _listener[event];
    if (dl != null) {
      for (var fn in dl) {
        try {
          fn(payload);
        } catch (e) {
          print(e);
        }
      }
    }
  }

  /// 移除观察者
  void removeListener(void Function(dynamic) fn, String? name) {
    if (name != null && name.isNotEmpty) {
      _listener[name]?.remove(fn);
    }
  }

  /// 移除所有监听
  void removeAllListener() {
    _listener.clear();
  }

  // void Function(dynamic payload)  systemMsg =(dsfsdf){
  //
  // };

  void doMsg(String event, dynamic payload) {
    notificationListener(event: event, payload: payload);
  }
}


class SystemStatus extends BaseStatus {
  static String EventMsg = "msg";

  @override
  String tag = "SystemStatus";
}

class RoomStatus extends BaseStatus {
  static String EventJoinRoom = "joinRoom";

  @override
  String tag = "RoomStatus";
}
