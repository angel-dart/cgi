import 'dart:async';
import 'dart:io';
import 'package:angel_container/angel_container.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http2.dart';
import 'package:mock_request/mock_request.dart';

class IOResponse extends ResponseContext<IOSink> {
  final IOSink rawResponse;
  LockableBytesBuilder _buffer;

  bool _isDetached = false, _isClosed = false, _streamInitialized = false;

  IOResponse(this.rawResponse);

  @override
  BytesBuilder get buffer => _buffer;

  @override
  // TODO: implement correspondingRequest
  RequestContext get correspondingRequest => null;

  @override
  FutureOr<IOSink> detach() {
    // TODO: implement detach
    return null;
  }

  @override
  // TODO: implement isBuffered
  bool get isBuffered => null;

  @override
  // TODO: implement isOpen
  bool get isOpen => null;

  @override
  void useBuffer() {
    _buffer = new LockableBytesBuilder();
  }

  /// Write headers, status, etc. to the underlying [stream].
  bool _openStream() {
    if (_streamInitialized) return false;

    var headers = <Header>[
      new Header.ascii(':status', statusCode.toString()),
    ];

    if (encoders.isNotEmpty && correspondingRequest != null) {
      if (_allowedEncodings != null) {
        for (var encodingName in _allowedEncodings) {
          Converter<List<int>, List<int>> encoder;
          String key = encodingName;

          if (encoders.containsKey(encodingName))
            encoder = encoders[encodingName];
          else if (encodingName == '*') {
            encoder = encoders[key = encoders.keys.first];
          }

          if (encoder != null) {
            this.headers['content-encoding'] = key;
            break;
          }
        }
      }
    }

    // Add all normal headers
    for (var key in this.headers.keys) {
      headers.add(new Header.ascii(key.toLowerCase(), this.headers[key]));
    }

    // Persist session ID
    cookies.add(new Cookie('DARTSESSID', _req.session.id));

    // Send all cookies
    for (var cookie in cookies) {
      headers.add(new Header.ascii('set-cookie', cookie.toString()));
    }

    stream.sendHeaders(headers);
    return _streamInitialized = true;
  }

  @override
  Future addStream(Stream<List<int>> stream) {
    if (!isOpen && isBuffered) throw ResponseContext.closed();
    _openStream();

    Stream<List<int>> output = stream;

    if (encoders.isNotEmpty && correspondingRequest != null) {
      if (_allowedEncodings != null) {
        for (var encodingName in _allowedEncodings) {
          Converter<List<int>, List<int>> encoder;
          String key = encodingName;

          if (encoders.containsKey(encodingName))
            encoder = encoders[encodingName];
          else if (encodingName == '*') {
            encoder = encoders[key = encoders.keys.first];
          }

          if (encoder != null) {
            output = encoders[key].bind(output);
            break;
          }
        }
      }
    }

    return output.forEach(this.stream.sendData);
  }

  @override
  void add(List<int> data) {
    if (!isOpen && isBuffered)
      throw ResponseContext.closed();
    else if (!isBuffered) {
      _openStream();

      if (!_isClosed) {
        if (encoders.isNotEmpty && correspondingRequest != null) {
          if (_allowedEncodings != null) {
            for (var encodingName in _allowedEncodings) {
              Converter<List<int>, List<int>> encoder;
              String key = encodingName;

              if (encoders.containsKey(encodingName))
                encoder = encoders[encodingName];
              else if (encodingName == '*') {
                encoder = encoders[key = encoders.keys.first];
              }

              if (encoder != null) {
                data = encoders[key].convert(data);
                break;
              }
            }
          }
        }

        stream.sendData(data);
      }
    } else
      buffer.add(data);
  }

  @override
  Future close() async {
    if (!_isDetached && !_isClosed && !isBuffered) {
      _openStream();
      await stream.outgoingMessages.close();
    }

    _isClosed = true;
    await super.close();
  }
}
