import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/gestures.dart';
import 'dart:math';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(brightness: Brightness.dark),
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior()
          .copyWith(dragDevices: PointerDeviceKind.values.toSet()),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final _limit = 20;
  const HomeScreen({super.key});
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  List<Token> _tokenList = [];
  bool _loadingstate = false;
  bool _errorstate = false;
  int _start = 0;

  update(int i, List<Token> value) {}

  @override
  initState() {
    super.initState();
    getRating(0);
  }

  Future<void> getRating(int i) async {
    if (_start + widget._limit * i >= 0) {
      setState(() {
        _errorstate = false;
        _loadingstate = true;
        _start += i * widget._limit;
      });

      try {
        final rating = await WebClient().getRating(_start, widget._limit);

        _tokenList = rating;
      } catch (e) {
        _errorstate = true;
      } finally {
        if (mounted) {
          setState(() {
            _loadingstate = false;
          });
        }
      }
    }
  }

  loading() {
    if (_errorstate) {
      return Center(
        child: Text("Couldn't upload data", style: TextStyle(fontSize: 22)),
      );
    }
    if (_loadingstate) {
      return Row(children: [
        Text(
          'Data is being uploaded',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        CircularProgressIndicator(),
      ]);
    } else {
      return Container();
    }
  }

  Widget prevButton() {
    return IconButton(
      icon: const Icon(Icons.arrow_back_sharp),
      onPressed: !(_loadingstate && _errorstate)
          ? () {
              getRating(-1);
            }
          : null,
    );
  }

  Widget nextButton() {
    return IconButton(
      icon: const Icon(Icons.arrow_forward_sharp),
      onPressed: !(_loadingstate && _errorstate)
          ? () {
              getRating(1);
            }
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.indigoAccent,
          title: SizedBox(
            width: 350,
            child: Row(children: [
              Expanded(
                flex: 2,
                child: Text("Token rating", style: TextStyle(fontSize: 22)),
              ),
              Expanded(
                flex: 1,
                child: prevButton(),
              ),
              Expanded(
                flex: 1,
                child: nextButton(),
              ),
            ]),
          ),
        ),
        body: Column(
          children: [
            SizedBox(
              height: 28,
              child: loading(),
            ),
            Expanded(
                child: RefreshIndicator(
              onRefresh: () async {
                return await getRating(0);
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(8),
                itemCount: _tokenList.length,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    title: Text(
                        "${_tokenList[index].rank}. ${_tokenList[index].symbol} | ${_tokenList[index].name}"),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TokenScreen(_tokenList[index], null),
                          ));
                    },
                  );
                },
              ),
            ))
          ],
        ));
  }
}

class TokenScreen extends StatefulWidget {
  const TokenScreen(this.token, Key? key) : super(key: key);
  final Token token;

  @override
  TokenScreenState createState() => TokenScreenState();
}

class TokenScreenState extends State<TokenScreen> {
  List<double>? _rList;
  final Random _rng = Random();
  List<Market> _markets = [];
  List<Market> _topMarkets = [];
  dynamic _tokenMap;
  dynamic _price, _p7d, _p24h;
  dynamic _spots;
  dynamic _maxY, _minY;

  @override
  initState() {
    super.initState();
    getMarkets(widget.token.id);
    _tokenMap = widget.token.toMap();
    _price = _tokenMap['Price (USD)'];
    _p7d = _tokenMap['Percent change (7d)'] / 100;
    _p24h = _tokenMap['Percent change (24h)'] / 100;

    _rList = [
      _rng.nextDouble() - 0.5,
      _rng.nextDouble() - 0.5,
      _rng.nextDouble() - 0.5,
      _rng.nextDouble() - 0.5,
      _rng.nextDouble() - 0.5,
      _rng.nextDouble() - 0.5,
    ];

    _spots = [
      FlSpot(1, _price * (1 + 0.1 * _rList![0])),
      FlSpot(2, _price / (1 + _p7d)),
      FlSpot(3, _price * (1 + 0.1 * _rList![0])),
      FlSpot(4, _price * (1 + 0.1 * _rList![1])),
      FlSpot(5, _price * (1 + 0.1 * _rList![2])),
      FlSpot(6, _price * (1 + 0.1 * _rList![3])),
      FlSpot(7, _price * (1 + 0.1 * _rList![4])),
      FlSpot(8, _price / (1 + _p24h)),
      FlSpot(9, _price),
    ];

    _maxY = _price * (1 + max(_p24h.abs(), _p7d.abs()) + 0.05);
    _minY = _price * (1 - max(_p24h.abs(), _p7d.abs()) - 0.05);
  }

  Future<void> getMarkets(int id) {
    return WebClient().getMarkets(id).then((value) {
      setState(() {
        _markets = value;
        _topMarkets = value.sublist(0, 5);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.indigoAccent,
          title: Text("Token info", style: TextStyle(fontSize: 22)),
        ),
        body: RefreshIndicator(
            onRefresh: () async {
              getMarkets(widget.token.id);
            },
            child: Container(
                padding: EdgeInsets.all(24),
                width: 400,
                child: ListView(
                  physics: AlwaysScrollableScrollPhysics(),
                  children: [
                    Container(
                      padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
                      height: 330,
                      child: ListView.builder(
                          physics: const ScrollPhysics(),
                          itemCount: _tokenMap.length,
                          itemBuilder: (BuildContext context, int index) {
                            return Text(
                                "${_tokenMap.keys.toList()[index]}: ${_tokenMap.values.toList()[index]}");
                          }),
                    ),
                    Container(
                      height: 150,
                      padding: EdgeInsets.fromLTRB(0, 0, 32, 16),
                      child: LineChart(
                        LineChartData(
                          titlesData: tData,
                          maxY: _maxY,
                          minY: _minY,
                          lineBarsData: [
                            LineChartBarData(
                              color: Colors.indigoAccent,
                              spots: _spots,
                            )
                          ],
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Markets:',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MarketsScreen(
                                            widget.token, _markets, null),
                                      ));
                                },
                                child: Text('Detailed'),
                              ),
                            )
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.fromLTRB(8, 16, 8, 0),
                          height: 170,
                          child: ListView.builder(
                            physics: const ScrollPhysics(),
                            itemCount: _topMarkets.length,
                            itemBuilder: (BuildContext context, int index) {
                              return Text(
                                "${_topMarkets[index].name}: \$${_topMarkets[index].priceUsd}",
                                style: TextStyle(fontSize: 16),
                                maxLines: 1,
                                softWrap: false,
                              );
                            },
                          ),
                        ),
                      ],
                    )
                  ],
                ))));
  }
}

class MarketsScreen extends StatefulWidget {
  const MarketsScreen(this._token, this._initMarkets, Key? key)
      : super(key: key);
  final Token _token;
  final List<Market> _initMarkets;
  @override
  MarketsScreenState createState() => MarketsScreenState();
}

class MarketsScreenState extends State<MarketsScreen> {
  List<Market> _allMarkets = [];
  List<Market> _visibleMarkets = [];
  Set<String> quoteTypeList = {'All'};
  String _quoteType = "";
  String _name = "";
  static const List<String> _sortTypeList = [
    'No sort',
    'Name ↓',
    'Name ↑',
    'Price ↓',
    'Price ↑',
  ];
  String _sortType = "";

  void sort(String sortType) {
    switch (_sortType = sortType) {
      case 'Name ↓':
        _visibleMarkets.sort(
            (m1, m2) => m1.name.toLowerCase().compareTo(m2.name.toLowerCase()));
      case 'Name ↑':
        _visibleMarkets.sort(
            (m1, m2) => m2.name.toLowerCase().compareTo(m1.name.toLowerCase()));
      case 'Price ↓':
        _visibleMarkets.sort((m1, m2) => (m1.priceUsd - m2.priceUsd).toInt());
      case 'Price ↑':
        _visibleMarkets.sort((m1, m2) => (m2.priceUsd - m1.priceUsd).toInt());
    }
  }

  void filter({String? name, String? quote}) {
    name ??= _name;
    quote ??= _quoteType;

    setState(() {
      _name = name!;
      _quoteType = quote!;
      _visibleMarkets = _allMarkets
          .where((m) =>
              (m.quote == _quoteType || _quoteType == "All") &&
              m.name.toLowerCase().contains(_name.toLowerCase()))
          .toList();
      sort(_sortType);
    });
  }

  @override
  initState() {
    super.initState();
    _sortType = _sortTypeList.first;
    _allMarkets = widget._initMarkets;
    _quoteType = quoteTypeList.first;
    quoteTypeList.addAll(_allMarkets.map((market) => market.quote).toSet());
    _visibleMarkets = widget._initMarkets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.indigoAccent,
          title: Text("Markets for ${widget._token.name}")),
      body: Container(
          padding: EdgeInsets.all(8),
          width: 350,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                      child: Padding(
                    padding: EdgeInsets.all(16),
                    child: TextField(
                      onChanged: (text) {
                        filter(name: text);
                      },
                      decoration: InputDecoration(
                        hintText: "Name",
                      ),
                    ),
                  )),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: DropdownButton<String>(
                          iconSize: 0,
                          value: _quoteType,
                          icon: const Icon(Icons.arrow_downward),
                          elevation: 16,
                          style: const TextStyle(color: Colors.deepPurple),
                          underline: Container(
                            height: 2,
                            color: Colors.deepPurpleAccent,
                          ),
                          onChanged: (String? quote) {
                            filter(quote: quote);
                          },
                          items: quoteTypeList
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList()),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: DropdownButton<String>(
                        iconSize: 0,
                        value: _sortType,
                        icon: const Icon(Icons.arrow_downward),
                        elevation: 16,
                        style: const TextStyle(color: Colors.deepPurple),
                        underline: Container(
                          height: 2,
                          color: Colors.deepPurpleAccent,
                        ),
                        onChanged: (String? sortType) {
                          setState(() {
                            sort(sortType!);
                          });
                        },
                        items: _sortTypeList
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _visibleMarkets.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                        title: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "${_visibleMarkets[index].name}:",
                            maxLines: 1,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "${_visibleMarkets[index].quote} ${_visibleMarkets[index].price}",
                            maxLines: 1,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "\$${_visibleMarkets[index].priceUsd}",
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ));
                  },
                ),
              )
            ],
          )),
    );
  }
}

class Token {
  final int id;
  final String symbol;
  final String name;
  final int rank;
  final double priceUsd;
  final double percentChange24h;
  final double percentChange1h;
  final double percentChange7d;
  final double priceBtc;
  final double marketCapUsd;
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
      required this.priceUsd,
      required this.percentChange24h,
      required this.percentChange1h,
      required this.percentChange7d,
      required this.priceBtc,
      required this.marketCapUsd,
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
      priceUsd: double.parse(json['price_usd']),
      percentChange24h: double.parse(json['percent_change_24h']),
      percentChange1h: double.parse(json['percent_change_1h']),
      percentChange7d: double.parse(json['percent_change_7d']),
      priceBtc: double.parse(json['price_btc']),
      marketCapUsd: double.tryParse(json['market_cap_usd']) ?? 0,
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
      'Price (USD)': priceUsd,
      'Percent change (24h)': percentChange24h,
      'Percent change (1h)': percentChange1h,
      'Percent change (7d)': percentChange7d,
      'Price (BTC)': priceBtc,
      'Marketcap (USD)': marketCapUsd,
      'Volume (24h in USD)': volume24,
      'Volume (24h in coins)': volume24a,
      'Circulating Supply': csupply,
      'Total Supply': tsupply,
      'Maximum Supply': msupply ?? "-",
    };
  }
}

class Market {
  final String name;
  final String base;
  final String quote;
  final double price;
  final double priceUsd;
  final double volume;
  final double volumeUsd;
  final double time;
  Market(
      {required this.name,
      required this.base,
      required this.quote,
      required this.price,
      required this.priceUsd,
      required this.volume,
      required this.volumeUsd,
      required this.time});
  factory Market.fromJson(Map<String, dynamic> json) {
    return Market(
      name: json['name'] ?? "",
      base: json['base'] ?? "",
      quote: json['quote'] ?? "",
      price: json['price']?.toDouble() ?? 0,
      priceUsd: json['price_usd']?.toDouble() ?? 0,
      volume: json['volume']?.toDouble() ?? 0,
      volumeUsd: json['volume_usd']?.toDouble() ?? 0,
      time: json['time']?.toDouble() ?? 0,
    );
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

  Future<List<Market>> getMarkets(int id) async {
    try {
      final response = await client.post(
        Uri.https('api.coinlore.net', '/api/coin/markets/', {
          'id': id.toString(),
        }),
      );
      return (parseMarkets(response.body));
    } catch (e) {
      return [];
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

List<Market> parseMarkets(String responseBody) {
  final parsed = jsonDecode(responseBody) as List<dynamic>;
  return parsed.cast<Map<String, dynamic>>().map(Market.fromJson).toList();
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
  String day = DateFormat("dd.MM")
      .format(DateTime.now().subtract(Duration(days: (9 - value).toInt())));
  const style = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );
  Widget text;
  text = (value % 2 != 0) ? Text(day, style: style) : Text('');
  return SideTitleWidget(
    meta: meta,
    space: 10,
    child: text,
  );
}
