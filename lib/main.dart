import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:namer_app/data.dart';
import 'package:provider/provider.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(WordPairDataAdapter());

  await Hive.openBox('db');

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  var previous = WordPair.random();

  void getNext() {
    previous = current;
    current = WordPair.random();

    if (history.length > 6) {
      history.removeAt(0);
      history.add(previous);
    } else {
      history.add(previous);
    }

    notifyListeners();
  }

  List<WordPair> favorites = <WordPair>[];
  var history = <WordPair>[];

  Future<void> loadData() async {
    final box = await Hive.openBox('db');

    List<WordPairData> ls = ((box.get('favorites') ?? []) as List<dynamic>)
        .map((e) => e as WordPairData)
        .toList();
    favorites = ls.map((e) => WordPair(e.first, e.second)).toList();

    notifyListeners();
  }

  Future<void> saveData() async {
    var box = await Hive.openBox('db');
    var data = favorites
        .map((element) => WordPairData()
          ..first = element.first
          ..second = element.second)
        .toList();

    box.put('favorites', data);
  }

  MyAppState() {
    previous = current;
  }

  Future<void> toggleFavorite() async {
    await loadData();
    if (favorites.contains(current)) {
      removeFavorite(current);
    } else {
      favorites.add(current);
      await saveData();
      await loadData();
    }

    notifyListeners();
  }

  Future<void> removeFavorite(WordPair pair) async {
    await loadData();
    final removeElement = favorites
        .where((element) =>
            element.first == pair.first && element.second == pair.second)
        .toList();

    if (removeElement.isNotEmpty) {
      favorites.remove(removeElement.first);
    }

    await saveData();
    await loadData();

    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
      case 1:
        page = FavoritesPage();
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: constraints.maxWidth >= 600,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.home),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.favorite),
                    label: Text('Favorites'),
                  ),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;
    var history = appState.history;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: ListView(
                physics: NeverScrollableScrollPhysics(),
                padding: EdgeInsets.all(20),
                shrinkWrap: true,
                children: [
                  for (var pair in history)
                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Text(
                        pair.asLowerCase,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16.0, color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          ),
          BigCard(pair: pair),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  await appState.toggleFavorite();
                },
                icon: Icon(icon),
                label: Text('Like'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: Text('Next'),
              ),
            ],
          ),
          Spacer(),
        ],
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
      fontWeight: FontWeight.bold,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: AnimatedSize(
          duration: Duration(milliseconds: 200),
          child: MergeSemantics(
            child: Wrap(
              children: [
                Text(
                  pair.first,
                  style: style.copyWith(fontWeight: FontWeight.w200),
                ),
                Text(
                  pair.second,
                  style: style.copyWith(fontWeight: FontWeight.bold),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    return ValueListenableBuilder<Box>(
      valueListenable: Hive.box('db').listenable(),
      builder: (context, box, widget) {
        return ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Text(
                'You have '
                '${((box.get('favorites') ?? []) as List<dynamic>).length} favorites:',
                style: TextStyle(fontSize: 18),
              ),
            ),
            for (WordPairData pair in box.get('favorites'))
              ListTile(
                leading: IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  onPressed: () async {
                    await appState
                        .removeFavorite(WordPair(pair.first, pair.second));
                  },
                ),
                title: Text(WordPair(pair.first, pair.second).asLowerCase),
              )
          ],
        );
      },
    );
  }
}
