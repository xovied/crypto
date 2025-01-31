import 'package:flutter/material.dart';

import 'viewmodel.dart';

Widget errorNotif() {
  return Center(
    child: Text("Couldn't upload data", style: TextStyle(fontSize: 22)),
  );
}

Widget loadingNotif() {
  return Row(children: [
    Text(
      'Data is being uploaded',
    ),
    CircularProgressIndicator(),
  ]);
}

Widget noNotif() {
  return Container();
}

Widget getHomeScreen(Map<String, Function> funcMap, List<dynamic> data) {
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
              child: IconButton(
                icon: const Icon(Icons.arrow_back_sharp),
                onPressed: () => funcMap["pageDown"]!.call(),
              ),
            ),
            Expanded(
              flex: 1,
              child: IconButton(
                icon: const Icon(Icons.arrow_forward_sharp),
                onPressed: () => funcMap["pageUp"]!.call(),
              ),
            ),
          ]),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 30,
            child: funcMap["loading"]!.call(),
          ),
          Expanded(
              child: RefreshIndicator(
            onRefresh: () async {
              return await funcMap["refresh"]!.call();
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8),
              itemCount: data.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(
                      "${data[index].rank}. ${data[index].symbol} | ${data[index].name}"),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TokenScreen(data[index], null),
                        ));
                  },
                );
              },
            ),
          ))
        ],
      ));
}
