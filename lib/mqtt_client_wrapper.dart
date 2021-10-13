import 'package:flutter/material.dart';
import 'dart:async';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTClientWrapper {
  late MqttServerClient client;
  late final VoidCallback onConnectedCallback;
  late final Function(String) onResponseReceivedCallback;

  MQTTClientWrapper(this.onConnectedCallback, this.onResponseReceivedCallback);


  void _setupMqttClient() {
    client = MqttServerClient('test.mosquitto.org', 'my_client_id');
    client.keepAlivePeriod = 20;
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;
  }

  Future<void> _connectClient() async {
    try {
      print('MQTTClientWrapper::Mosquitto client connecting....');
      await client.connect();
    } on Exception catch (e) {
      print('MQTTClientWrapper::client exception - $e');
      client.disconnect();
    }
    if (client.connectionStatus!.state != MqttConnectionState.connected) {
      print('MQTTClientWrapper::ERROR Mosquitto client connection failed - disconnecting, status is ${client.connectionStatus}');
      client.disconnect();
    }
  }

  void _subscribeToTopic(String topicName) {
    print('MQTTClientWrapper::Subscribing to the $topicName topic');
    client.subscribe(topicName, MqttQos.atMostOnce);
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final MqttPublishMessage recMess = c![0].payload as MqttPublishMessage;
      final String pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message!);
      print("MQTTClientWrapper::GOT A NEW MESSAGE $pt");
      onResponseReceivedCallback(pt);
    });
  }

  void _onConnected() {
    print('MQTTClientWrapper::OnConnected client callback - Client connection was successful');
    onConnectedCallback();
  }

  void _onDisconnected() {
    print('MQTTClientWrapper::OnDisconnected client callback - Client disconnection');
    if (client.connectionStatus!.disconnectionOrigin  == MqttDisconnectionOrigin.solicited) {
      print('MQTTClientWrapper::OnDisconnected callback is solicited, this is correct');
    }
  }

  void _onSubscribed(String topic) {
    print('MQTTClientWrapper::Subscription confirmed for topic $topic');
  }

  void prepareMqttClient() async {
    _setupMqttClient();
    await _connectClient();
    _subscribeToTopic('Dart/Mqtt_client/testtopic');
  }

  void publishMessage(String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);

    print('MQTTClientWrapper::Publishing message $message to topic ${'Dart/Mqtt_client/testtopic'}');
    client.publishMessage('Dart/Mqtt_client/testtopic', MqttQos.exactlyOnce, builder.payload!);
  }
}