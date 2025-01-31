import 'package:http/http.dart' as http;

class WebClient {
  final client = http.Client();
  WebClient();
  Future<String> getRating(int start, int limit) async {
    try {
      final response = await client.post(
        Uri.https('api.coinlore.net', '/api/tickers/', {
          'start': start.toString(),
          'limit': limit.toString(),
        }),
      );
      return response.body;
    } finally {
      client.close();
    }
  }

  Future<String> getMarkets(int id) async {
    try {
      final response = await client.post(
        Uri.https('api.coinlore.net', '/api/coin/markets/', {
          'id': id.toString(),
        }),
      );
      return response.body;
    } catch (e) {
      return "";
    } finally {
      client.close();
    }
  }
}
