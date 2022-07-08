// ignore_for_file: avoid_print, prefer_conditional_assignment, unnecessary_brace_in_string_interps, prefer_final_fields

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter_mqtt/mqtt_manager.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:typed_data/typed_buffers.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert' as convert;


typedef ConnectedCallback = void Function();

class MqttTool {
  MqttQos _qos = MqttQos.atLeastOnce;
  MqttServerClient? _client;
  static MqttTool? _instance;
  Map<String,ConnectedCallback> subscribeMessageTask = HashMap();


  static MqttTool _getInstance() {
    if (_instance == null) {
      _instance = MqttTool();
    }
    return _instance!;
  }

  bool _isConnected = false;

  static MqttTool sheard = _getInstance();

  MqttConnectionState getConnectionState(){
    if(_isConnected){
      return _client?.connectionStatus?.state?? MqttConnectionState.disconnecting;
    }
    return  MqttConnectionState.disconnected;
  }

  /// server:服务 id:用户ID isSsl:是否加密
  Future<MqttServerClient?> connect(String server,
      String clientIdentifier,
      int port,
      {bool isSsl = false}) async {
    if(_isConnected){
      disconnect();
    }
    _client = MqttServerClient.withPort(server, clientIdentifier, port);

    _client?.onConnected = onConnected;

    _client?.onSubscribed = _onSubscribed;

    _client?.onSubscribeFail = _onSubscribeFail;

    _client?.onUnsubscribed = _onUnSubscribed;
    _client?.onDisconnected = () async {
      _isConnected = false;
      await _tryToConnect(clientIdentifier);
    };
    _client?.pongCallback = () {
      print("mqtt MqttManager pongCallback:${_client?.server}");
    };
    _client?.setProtocolV311();
    _client?.keepAlivePeriod = 30;
    _client?.logging(on: false); //是否打印MQTT Log
    _client?.published?.listen((event) {
      print("mqtt published ${event}");
    });
    _client?.keepAlivePeriod = 30;
    _client?.logging(on: false); //是否打印MQTT Log
    if (isSsl) {
      _client?.secure = true;
      _client?.onBadCertificate = (dynamic a) => true;
    }
    _tryToConnect(clientIdentifier);
    return _client;
  }

  void doMsg( Map<String, dynamic> msg) async{
    print("mqtt MqttTool Msg :"+msg.toString());
    if(msg.containsKey('cmd') &&
        msg.containsKey('event') &&
        msg.containsKey('payload')
    ){
      String  cmd = msg['cmd'];
      String  event = msg['event'];
      dynamic  payload = msg['payload'];
      MqttManager.instance.doMsg(cmd, event, payload);
    }else{
      print("MqttTool error Msg :"+msg.toString());
    }
  }

  ///断开MQTT连接
  disconnect() {
    _isConnected = false;
    _client?.onDisconnected = null;
    _client?.disconnect();
    print("mqtt MqttManager disconnect:${_client?.server}");
    _client =null;
  }

  ///订阅
  int? publishMessage(String id, String msg) {
    var pTopic = "live/app/pub/$id/domain/report";
    print("mqtt_发送数据-topic:$pTopic,playLoad:$msg");
    Uint8Buffer uint8buffer = Uint8Buffer();
    var codeUnits = msg.codeUnits;
    uint8buffer.addAll(codeUnits);

    return _client?.publishMessage(pTopic, _qos, uint8buffer, retain: false);
  }

  ///发布消息
  int? publishRawMessage(String pTopic, List<int> list) {
      print("mqtt_发送数据-topic:${130102699},playLoad:$list");
      Uint8Buffer uint8buffer = Uint8Buffer();
      uint8buffer.addAll(list);
      return _client?.publishMessage(pTopic, _qos, uint8buffer, retain: false);
    }

    ///订阅消息
  Subscription? subscribeMessage(String subtopic) {
    print("mqtt 订阅消息成功");
    if(getConnectionState() == MqttConnectionState.connected){
      return _client?.subscribe(subtopic, _qos);
    }else{
      subscribeMessageTask[subtopic] =() {
        _client?.subscribe(subtopic, _qos);
      };
    }
    return null;
  }

  ///取消订阅
  void unsubscribeMessage(String? unSubtopic) {
    print("mqtt 取消订阅");
    if(unSubtopic?.isNotEmpty == true){
      subscribeMessageTask.remove(unSubtopic);
      if(_isConnected){
        _client?.unsubscribe(unSubtopic!);
      }
    }
  }

  ///MQTT状态
  MqttClientConnectionStatus? getMqttStatus() {
    return _client?.connectionStatus;
  }

  ///连接的回调
  Function()? onConnected() {
    print("MqttManager onConnected:${_client?.server}");
    var keys = subscribeMessageTask.keys.toList();
    while(keys.isNotEmpty){
      var key=keys.removeLast();
      subscribeMessageTask[key]?.call();
      subscribeMessageTask.remove(key);
    }
    return _client?.onConnected;
  }

  //订阅直播间主题
  subLiveStream(String roomId) {
    subscribeMessage("live/app/sub/room/$roomId/#");
  }

  //取消直播间订阅
  unSubLiveStream(String roomId) {
    unsubscribeMessage("live/app/sub/room/$roomId/#");
  }

  //订阅用户信息主题
  subUserStream(String id) {
    subscribeMessage("live/app/user/$id/#");
  }

  //订阅游戏主题
  subscribeGameStream() {
    subscribeMessage("live/app/sub/game/#");
  }

  ///订阅成功
  _onSubscribed(String topic) {
    print("mqtt _订阅主题成功---topic:$topic");
  }

  ///取消订阅
  _onUnSubscribed(String? topic) {
    print("mqtt _取消订阅主题成功---topic:$topic");
  }

  ///订阅失败
  _onSubscribeFail(String topic) {
    print("mqtt 订阅失败");
  }

  Future _tryToConnect(id) async {
    if(_client!=null){
      await _client?.connect("live" + id, md5.convert(utf8.encode("u" + id)).toString().substring(8, 24));
      _client?.updates?.listen((event) {
        //接收消息
        print("Listen ${event}");
        var message = event[0].payload as MqttPublishMessage;
        var strMsg = MqttPublishPayload.bytesToStringAsString(message.payload.message);
        // var strMsg = const Utf8Decoder().convert(message.payload.message);
        Map<String, dynamic> map = convert.jsonDecode(strMsg);
        doMsg(map);
      });
      _isConnected = true;
    }
  }
}
