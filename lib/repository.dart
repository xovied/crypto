import 'dart:convert';
import 'service.dart';

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

Future<List<Token>?> getRating(int start, int limit) async {
  List<Token>? rating;
  try {
    await WebClient().getRating(start, limit).then((responseBody) {
      final parsed = jsonDecode(responseBody) as Map<String, dynamic>;
      final data = parsed["data"] as List<dynamic>;
      rating = data.cast<Map<String, dynamic>>().map(Token.fromJson).toList();
    });
  } catch (e) {
    // do smth
  }
  return rating;
}

Future<List<Market>?> getMarkets(int id) async {
  List<Market>? markets;
  try {
    await WebClient().getMarkets(id).then((responseBody) {
      final parsed = jsonDecode(responseBody) as List<dynamic>;
      markets =
          parsed.cast<Map<String, dynamic>>().map(Market.fromJson).toList();
    });
  } catch (e) {
    // do smth
  }
  return markets;
}
