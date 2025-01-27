import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/gestures.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: const MaterialScrollBehavior()
          .copyWith(dragDevices: PointerDeviceKind.values.toSet()),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  List<Token> tokenList = [];
  int _start = 0;
  final limit = 20;
  update() {
    setState(() {});
  }

  void getRating() async {
    WebClient().getRating(_start, limit).then((value) {
      tokenList = value;
      update();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (tokenList.isEmpty) {
      getRating();
    }

    return Scaffold(
        appBar: AppBar(
          title: Row(children: [
            Text("Token rating", style: TextStyle(fontSize: 22)),
            ElevatedButton(
                child: Text("Prev", style: TextStyle(fontSize: 22)),
                onPressed: () {
                  if (_start >= limit) {
                    _start -= limit;
                    getRating();
                  }
                }),
            ElevatedButton(
                child: Text("Next", style: TextStyle(fontSize: 22)),
                onPressed: () {
                  _start += limit;
                  getRating();
                }),
          ]),
        ),
        body: RefreshIndicator(
            onRefresh: () async {
              getRating();
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8),
              itemCount: tokenList.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(
                      "${tokenList[index].rank}. ${tokenList[index].symbol} | ${tokenList[index].name}"),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TokenScreen(tokenList[index], null),
                        ));
                  },
                );
              },
            )));
  }
}

class TokenScreen extends StatelessWidget {
  const TokenScreen(this.token, Key? key) : super(key: key);
  final Token token;

  @override
  Widget build(BuildContext context) {
    dynamic tokenMap = token.toMap();
    return Scaffold(
      appBar: AppBar(title: Text("Token info", style: TextStyle(fontSize: 22))),
      body: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: tokenMap.length,
          itemBuilder: (BuildContext context, int index) {
            return Text(
                "${tokenMap.keys.toList()[index]}: ${tokenMap.values.toList()[index]}");
          }),
    );
  }
}

class Token {
  final int id;
  final String symbol;
  final String name;
  final int rank;
  final double price_usd;
  final double percent_change_24h;
  final double percent_change_1h;
  final double percent_change_7d;
  final double price_btc;
  final double market_cap_usd;
  final double volume24;
  final double volume24a;
  final dynamic csupply;
  final dynamic tsupply;
  final dynamic msupply;
  Token(
      {required this.id,
      required this.symbol,
      required this.name,
      required this.rank,
      required this.price_usd,
      required this.percent_change_24h,
      required this.percent_change_1h,
      required this.percent_change_7d,
      required this.price_btc,
      required this.market_cap_usd,
      required this.volume24,
      required this.volume24a,
      required this.csupply,
      required this.tsupply,
      required this.msupply});
  factory Token.fromJson(Map<String, dynamic> json) {
    return Token(
      id: int.parse(json['id']),
      symbol: json['symbol'],
      name: json['name'],
      rank: json['rank'],
      price_usd: double.parse(json['price_usd']),
      percent_change_24h: double.parse(json['percent_change_24h']),
      percent_change_1h: double.parse(json['percent_change_1h']),
      percent_change_7d: double.parse(json['percent_change_7d']),
      price_btc: double.parse(json['price_btc']),
      market_cap_usd: double.tryParse(json['market_cap_usd']) ?? 0,
      volume24: (json['volume24'] ?? 0).toDouble(),
      volume24a: (json['volume24a'] ?? 0).toDouble(),
      csupply: json['csupply'],
      tsupply: json['tsupply'],
      msupply: json['msupply'],
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'ID': id,
      'Symbol': symbol,
      'Name': name,
      'Rank': rank,
      'Price (USD)': price_usd,
      'Percent change (24h)': percent_change_24h,
      'Percent change (1h)': percent_change_1h,
      'Percent change (7d)': percent_change_7d,
      'Price (BTC)': price_btc,
      'Marketcap (USD)': market_cap_usd,
      'Volume (24h in USD)': volume24,
      'Volume (24h in coins)': volume24a,
      'Circulating Supply': csupply,
      'Total Supply': tsupply,
      'Maximum Supply': msupply ?? "-",
    };
  }
}

class WebClient {
  final client = http.Client();
  WebClient();

  Future<List<Token>> getRating(int start, int limit) async {
    try {
      final response = await client.post(
        Uri.https('api.coinlore.net', '/api/tickers/', {
          'start': start.toString(),
          'limit': limit.toString(),
        }),
      );
      return (parseTokens(response.body));
    } finally {
      client.close();
    }
  }
}

List<Token> parseTokens(String responseBody) {
  final parsed = jsonDecode(responseBody) as Map<String, dynamic>;
  final data = parsed["data"] as List<dynamic>;
  return data.cast<Map<String, dynamic>>().map(Token.fromJson).toList();
}
