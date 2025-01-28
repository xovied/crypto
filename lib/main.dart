import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/gestures.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior()
          .copyWith(dragDevices: PointerDeviceKind.values.toSet()),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final limit = 20;
  const HomeScreen({super.key});
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  List<Token> tokenList = [];
  int _start = 0;

  update(int i, List<Token> value) {
    if (mounted) {
      setState(() {
        _start += i * widget.limit;
        tokenList = value;
      });
    }
  }

  @override
  initState() {
    super.initState();
    getRating(0);
  }

  void getRating(int i) async {
    WebClient()
        .getRating(_start + i * widget.limit, widget.limit)
        .then((value) {
      update(i, value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Row(children: [
            Text("Token rating", style: TextStyle(fontSize: 22)),
            ElevatedButton(
                child: Text("Prev", style: TextStyle(fontSize: 22)),
                onPressed: () {
                  if (_start >= widget.limit) {
                    getRating(-1);
                  }
                }),
            ElevatedButton(
                child: Text("Next", style: TextStyle(fontSize: 22)),
                onPressed: () {
                  getRating(1);
                }),
          ]),
        ),
        body: RefreshIndicator(
            onRefresh: () async {
              getRating(0);
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
    final Random rng = Random();
    final List<double> rList = [
      rng.nextDouble() - 0.5,
      rng.nextDouble() - 0.5,
      rng.nextDouble() - 0.5,
      rng.nextDouble() - 0.5,
      rng.nextDouble() - 0.5,
    ];
    final dynamic tokenMap = token.toMap();

    final double price = tokenMap['Price (USD)'];
    final double p7d = tokenMap['Percent change (7d)'] / 100;
    final double p24h = tokenMap['Percent change (24h)'] / 100;

    return Scaffold(
        appBar:
            AppBar(title: Text("Token info", style: TextStyle(fontSize: 22))),
        body: RefreshIndicator(
            onRefresh: () async {},
            child: Column(
              children: <Widget>[
                SizedBox(
                  width: 400,
                  height: 320,
                  child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: tokenMap.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Text(
                            "${tokenMap.keys.toList()[index]}: ${tokenMap.values.toList()[index]}");
                      }),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(0, 8, 24, 0),
                  height: 250,
                  width: 400,
                  child: LineChart(
                    LineChartData(
                      titlesData: tData,
                      maxY: (price * (1 + max(p24h.abs(), p7d.abs()) + 0.05)),
                      minY: price * (1 - max(p24h.abs(), p7d.abs()) - 0.05),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            FlSpot(1, price / (1 + p7d)),
                            FlSpot(2, price * (1 + 0.1 * rList[0])),
                            FlSpot(3, price * (1 + 0.1 * rList[1])),
                            FlSpot(4, price * (1 + 0.1 * rList[2])),
                            FlSpot(5, price * (1 + 0.1 * rList[3])),
                            FlSpot(6, price * (1 + 0.1 * rList[4])),
                            FlSpot(7, price / (1 + p24h)),
                            FlSpot(8, price),
                          ],
                        )
                      ],
                    ),
                  ),
                )
              ],
            )));
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

  Future<Token> getToken(int id) async {
    try {
      final response = await client.post(
        Uri.https('api.coinlore.net', '/api/tickers/', {
          'id': id.toString(),
        }),
      );
      return (parseToken(response.body));
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

Token parseToken(String responseBody) {
  final parsed = jsonDecode(responseBody) as Map<String, dynamic>;
  return Token.fromJson(parsed);
}

FlTitlesData get tData => FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: bottomTitles,
      ),
      rightTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
    );

SideTitles get bottomTitles => SideTitles(
      showTitles: true,
      reservedSize: 32,
      interval: 1,
      getTitlesWidget: bottomTitleWidgets,
    );

Widget bottomTitleWidgets(double value, TitleMeta meta) {
  DateTime day = DateTime.now().add(Duration(hours: -24 * (8 - value.toInt())));
  const style = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );
  Widget text = Text('${day.day}.${day.month}', style: style);
  return SideTitleWidget(
    meta: meta,
    space: 10,
    child: text,
  );
}
