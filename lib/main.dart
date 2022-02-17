// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:developer';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:graphql/client.dart' as graphql;

Future<List<Album>> fetchAlbum() async {
  const String getPokemones = r'''
  query getPokemones {
  results: pokemon_v2_pokemon {
    id
    name
    types: pokemon_v2_pokemontypes {
      type:pokemon_v2_type {
        name
      }
    }
  }
}

''';
  final _httpLink = graphql.HttpLink(
    'https://beta.pokeapi.co/graphql/v1beta',
  );

  final graphql.GraphQLClient client = graphql.GraphQLClient(
    /// **NOTE** The default store is the InMemoryStore, which does NOT persist to disk
    cache: graphql.GraphQLCache(),
    link: _httpLink,
  );

  final graphql.QueryOptions options = graphql.QueryOptions(
    document: graphql.gql(getPokemones),
  );

  final graphql.QueryResult response = await client.query(options);

  if (!response.hasException) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    List<dynamic> parsedListJson = response.data!['results'];
    return List<Album>.from(
        parsedListJson.map((album) => Album.fromJson(album)));
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load album');
  }
}

class Album {
  final int id;
  final String name;
  final List<String> type;

  const Album({required this.id, required this.name, required this.type});

  factory Album.fromJson(Map<String, dynamic> json) {
    final List<String> listTypes = [];
    json['types'].forEach((item) => {listTypes.add(item['type']['name'])});
    return Album(id: json['id'], name: json['name'], type: listTypes);
  }
}

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<List<Album>> futureAlbum;
  final List<Album> futureAlbumFavorites = [];
  late List<Album> displayList = [];
  late String searchText = '';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    futureAlbum = fetchAlbum();
    getPoke();
  }

  Future<void> getPoke() async {
    displayList = await fetchAlbum();
  }

  void search(String text) {
    setState(() {
      searchText = text;
      futureAlbum
          .then((value) => {value.forEach((item) => displayList.add(item))});
      displayList =
          displayList.where((poke) => poke.name.contains(text)).toList();
    });
  }

  Widget _buildCard(Album album) {
    final alreadySaved =
        futureAlbumFavorites.any((element) => element.id == album.id);
    return Card(
      elevation: 10,
      child: Column(
        children: <Widget>[
          ListTile(
            leading: CircleAvatar(
              radius: 30.0,
              backgroundImage: NetworkImage(
                  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${album.id.toString()}.png'),
              backgroundColor: Colors.transparent,
            ),
            title: Text(album.name),
            subtitle: Row(
              children: [
                Row(
                  children: <Widget>[
                    for (var type in album.type) _builChip(type)
                  ],
                )
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text('#' + album.id.toString()),
                IconButton(
                  iconSize: 18,
                  padding: EdgeInsets.all(0),
                  visualDensity: VisualDensity.compact,
                  icon: (Icon(
                    alreadySaved ? Icons.favorite : Icons.favorite_border,
                    color: alreadySaved
                        ? Color.fromARGB(255, 255, 0, 119)
                        : Colors.grey,
                  )),
                  onPressed: () {
                    setState(() {
                      if (alreadySaved) {
                        futureAlbumFavorites.remove(album);
                      } else {
                        futureAlbumFavorites.add(album);
                      }
                      log(futureAlbumFavorites.toString());
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _builChip(String type) {
    Map<String, dynamic> _colors = {
      'grass': '7BC45B',
      'electric': 'FACD55',
      'water': '46A0F8',
      'poison': 'A35994',
      'flying': '6E97EF',
      'fire': 'E94A41',
      'normal': 'B0AEA2',
      'ground': 'D7B85F',
      'bug': 'AFBF45',
      'fairy': 'E6A0E6',
      'psychic': 'ED5AA1',
      'fighting': 'B05943',
      'rock': 'CAE70',
      'steel': 'B3B2C4',
      'ghost': '6E6DBB',
      'ice': '80DEFA',
      'dark': '855F52',
      'dragon': '816FEB'
    };
    Color color = Color(int.parse('0xFF${_colors[type]}'));
    return SizedBox(
      height: 20,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 2, horizontal: 10),
        margin: EdgeInsets.only(right: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          color: color,
        ),
        child: Text(
          type,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Fetch Data Example',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Scaffold(
            appBar: AppBar(
              title: const Text('Fetch Data Example'),
            ),
            body: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(5),
                    child: SizedBox(
                        height: 40,
                        child: TextField(
                          decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Buscar',
                              suffixIcon: Icon(Icons.search)),
                          onChanged: (text) => search(text),
                        )),
                  ),
                  if (searchText == '' && _selectedIndex == 0)
                    FutureBuilder<List<Album>>(
                      future: futureAlbum,
                      builder: (context, payload) {
                        if (payload.hasData) {
                          return Expanded(
                              child: ListView(
                            scrollDirection: Axis.vertical,
                            shrinkWrap: true,
                            children: <Widget>[
                              for (var item in payload.data ?? [])
                                _buildCard(item)
                            ],
                          ));
                        } else if (payload.hasError) {
                          return Text('${payload.error}');
                        }
                        // By default, show a loading spinner.
                        return const CircularProgressIndicator();
                      },
                    ),
                  if (searchText != '' && _selectedIndex == 0)
                    Expanded(
                        child: ListView.builder(
                      itemCount: displayList.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return _buildCard(displayList[index]);
                      },
                    )),
                  if (_selectedIndex != 0)
                    Expanded(
                        child: ListView.builder(
                      itemCount: futureAlbumFavorites.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return _buildCard(futureAlbumFavorites[index]);
                      },
                    ))
                ]),
            bottomNavigationBar: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.favorite),
                  label: 'Favoritos',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: _selectedIndex == 0
                  ? Colors.amber[800]
                  : Color.fromARGB(255, 255, 0, 119),
              onTap: _onItemTapped,
            )));
  }
}
