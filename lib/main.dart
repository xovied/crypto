import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/gestures.dart';

WebClient client = WebClient();
List<Token> tokenList = [];
void main() {
  client.getRating(0, 100)
    .then((value) {tokenList = value;});
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      scrollBehavior: const MaterialScrollBehavior()
          .copyWith(dragDevices: PointerDeviceKind.values.toSet()),
      home:  HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  update(List<Token> tl){
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: ElevatedButton(
        child: Text("Click", style: TextStyle(fontSize: 22)),
        onPressed:(){update(tokenList);}
      )),
      body: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(8),
        itemCount: tokenList.length,
        itemBuilder: (BuildContext context, int index) {
          return Text(tokenList[index].symbol + " | " + tokenList[index].name);
        },
      )
    );
  }
}

class Token {
  int id;
  String symbol;
  String name;
  int rank;
  double price_usd;
  double percent_change_24h;
  double percent_change_1h;
  double percent_change_7d;
  double price_btc;
  double market_cap_usd;
  double volume24;
  double volume24a;
  double csupply;
  double tsupply;
  double? msupply;
  Token({required this.id, required this.symbol, required this.name, required this.rank, required this.price_usd, 
    required this.percent_change_24h, required this.percent_change_1h, required this.percent_change_7d,
    required this.price_btc, required this.market_cap_usd, required this.volume24, required this.volume24a,
    required this.csupply, required this.tsupply, this.msupply});
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
    market_cap_usd: double.parse(json['market_cap_usd']),
    volume24: json['volume24'],
    volume24a: json['volume24a'],
    csupply: double.parse(json['csupply']),
    tsupply: double.parse(json['tsupply']),
    msupply: json['msupply'] != "" && json['msupply'] != null ? double.parse(json['msupply']) : null
    );
  }
}
class WebClient {
  var client = http.Client();
  WebClient();

  Future<List<Token>> getRating(int start, int limit) async
  {
    try {
      var response = await client.post(
        Uri.https('api.coinlore.net', '/api/tickers/'),
        body: {'start': start.toString(), 'limit': limit.toString()});
        
      return (parseTokens(response.body));
    } finally {
      client.close();
    }
  }
}
List<Token> parseTokens(String responseBody) {
  List<Token> tokenList = [];
  var parsed = jsonDecode(responseBody) as Map<String, dynamic>;
  //(jsonDecode(responseBody)).cast<Map<String, dynamic>>();
  List<dynamic> ls = parsed["data"];
  for (dynamic d in ls)
  {
    tokenList.add(Token.fromJson(d));
  }
  return tokenList;
}