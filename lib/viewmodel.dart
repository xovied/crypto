import 'dart:math';
import 'package:crypto/view.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'repository.dart' as rep;
import 'view.dart' as vw;

class HomeScreen extends StatefulWidget {
  final _limit = 20;
  const HomeScreen({super.key});
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  List<rep.Token>? _tokenList = [];
  bool _loadingstate = false;
  bool _errorstate = false;
  int _start = 0;
  Map<String, Function>? funcMap;

  update(int i, List<rep.Token> value) {}

  @override
  initState() {
    super.initState();
    getRating(0);
    funcMap = {
      "pageUp": pageUp,
      "pageDown": pageDown,
      "loading": loading,
      "refresh": refresh,
    };
  }

  void refresh() {
    getRating(0);
  }

  Future<void> getRating(int i) async {
    if (_start + widget._limit * i >= 0) {
      setState(() {
        _errorstate = false;
        _loadingstate = true;
        _start = _start + i * widget._limit;
      });
      final tokenList = await rep.getRating(_start, widget._limit);
      setState(() {
        if (tokenList == null) {
          _errorstate = true;
          _tokenList = [];
        } else {
          _tokenList = tokenList;
        }

        if (mounted) {
          _loadingstate = false;
        }
      });
    }
  }

  loading() {
    if (_errorstate) {
      return vw.errorNotif();
    }
    if (_loadingstate) {
      return vw.loadingNotif();
    } else {
      return vw.noNotif();
    }
  }

  pageDown() {
    if (!(_loadingstate && _errorstate)) {
      getRating(-1);
    }
  }

  pageUp() {
    if (!(_loadingstate && _errorstate)) {
      getRating(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return getHomeScreen(funcMap!, _tokenList!);
  }
}

class TokenScreen extends StatefulWidget {
  const TokenScreen(this.token, Key? key) : super(key: key);
  final rep.Token token;

  @override
  TokenScreenState createState() => TokenScreenState();
}

class TokenScreenState extends State<TokenScreen> {
  List<double>? _rList;
  final Random _rng = Random();
  List<rep.Market> _markets = [];
  List<rep.Market> _topMarkets = [];
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

  Future<void> getMarkets(int id) async {
    final markets = await rep.getMarkets(id);
    setState(() {
      _markets = markets ?? [];
      _topMarkets = _markets.length > 5 ? _markets.sublist(0, 5) : _markets;
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
  final rep.Token _token;
  final List<rep.Market> _initMarkets;
  @override
  MarketsScreenState createState() => MarketsScreenState();
}

class MarketsScreenState extends State<MarketsScreen> {
  List<rep.Market> _allMarkets = [];
  List<rep.Market> _visibleMarkets = [];
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
