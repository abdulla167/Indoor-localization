import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

class EspController {
  http.Client _client;
  http.Request _request;
  Future<http.StreamedResponse> _response;
  StreamSubscription<String> _subscription;
  String _transmittedData = '';

  StreamController _espDataController = StreamController<List<double>>();

  Stream<List<double>> get espData => _espDataController.stream;


  httpConnect() {
    _client = http.Client();
    _request = http.Request("GET", Uri.parse('http://localhost:8080/'));
    _request.headers["Accept"] = "text/event-stream";
    _request.headers["Cache-Control"] = "no-cache";
    _response = _client.send(_request);
    _response.then((streamResponse) {
      _subscription = utf8.decoder
          .bind(streamResponse.stream)
          .listen(_onData);
    });
  }

    _onData(String event) {
      _transmittedData += event;
      if (_transmittedData.contains("\n\n")) {
        String dataStr = _transmittedData.substring(
            _transmittedData.indexOf(":") + 1, _transmittedData.length - 2);
        List<double> dataList = dataStr.split(",").map<double>((e) => double.parse(e)).toList();
        print(dataList);
        _espDataController.sink.add(dataList);
        _transmittedData = '';
      }
    }

    void dispose(){
    _subscription.cancel();
    _espDataController.close();
    }
}