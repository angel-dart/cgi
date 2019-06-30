import 'dart:async';
import 'dart:io';
import 'package:angel_container/src/container.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:mock_request/mock_request.dart';

class IORequest extends RequestContext<Stream<List<int>>> {
  @override
  final Container container;

  @override
  final Stream<List<int>> rawRequest;

  final StreamController<List<int>> _body = StreamController();
  Uri _uri;

  @override
  Angel app;

  @override
  final LockableMockHttpHeaders headers = LockableMockHttpHeaders();

  IORequest(this.app, this.rawRequest)
      : container = app.container.createChild();

  @override
  Stream<List<int>> get body => _body.stream;

  @override
  // TODO: implement cookies
  List<Cookie> get cookies => null;

  @override
  // TODO: implement hostname
  String get hostname => null;

  @override
  // TODO: implement method
  String get method => null;

  @override
  // TODO: implement originalMethod
  String get originalMethod => null;

  @override
  // TODO: implement path
  String get path => null;

  @override
  // TODO: implement remoteAddress
  InternetAddress get remoteAddress => null;

  @override
  // TODO: implement session
  HttpSession get session => null;

  @override
  // TODO: implement uri
  Uri get uri => null;
}
