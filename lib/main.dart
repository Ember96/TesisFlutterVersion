import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
//import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'TRHEAD',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 23, 245, 89)),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();

    void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  var favorites = <WordPair>[];

  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }
}

// ...

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    Widget page;
      switch (selectedIndex) {
        case 0:
          page = GeneratorPage();
          break;
        case 1:
          page = TakePic();
          break;
        default:
          throw UnimplementedError('no widget for $selectedIndex');
        }
    return LayoutBuilder(
      builder: (context, constraints) {
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
      }
    );
  }
}


class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

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
          BigCard(pair: pair),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite();
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
        ],
      ),
    );
  }
}

class TakePic extends StatefulWidget {
  @override
  State<TakePic> createState() => _TakePicState();
}

class _TakePicState extends State<TakePic> {
  var image = Image.asset('assets/base_avatar.jpg');
  /*Future<File> saveImage(File image) async {
    final directory = await getApplicationDocumentsDirectory();
    final File rawImage = await image.copy('${directory.path}/image1.png');
    print(rawImage.path);
    return rawImage;
  }*/
  Future<void> imageUpload(source) async {
    ImagePicker picker = ImagePicker();
    XFile? file;
    if (source == "camera") {
      file = await picker.pickImage(source: ImageSource.camera);
    } else {
      file = await picker.pickImage(source: ImageSource.gallery);
    }
    if (file == null) return;
    File rawImage = File(file.path);
    await ipfsUpload(rawImage.path);
    setState(() {
      image = Image.file(rawImage);
    });
  }
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
//hero goes the placeholder for the picture
          SizedBox(height: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 8,
                    color: Colors.green,
                  ),
                  borderRadius: BorderRadius.circular(20), 
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image(image: image.image, width: 350, height: 400, fit: BoxFit.fill)),
              ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => imageUpload("camera"),
                label: Text('Tomar Foto'),
                icon: Icon(Icons.camera_alt),
              ),
              SizedBox(height: 10),
              SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => imageUpload("gallery"),
                label: Text(' Subir Foto '),
                icon: Icon(Icons.upload),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
// ...

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
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(
          pair.asLowerCase,
          style: style,
          semanticsLabel: "${pair.first} ${pair.second}",
        ),
      ),
    );
  }
}

Future<void> ipfsUpload(String filePath) async {
  var infuraProjectId = '2KiK6S75slDQfxRFU5dfP7z7TQG';
  var infuraProjectSecret = '622237ae0de6536fe6464071ffa0a100';

  var apiUrl = Uri.parse('https://ipfs.infura.io:5001/api/v0/add?pin=true');

  var request = http.MultipartRequest('POST', apiUrl);
  request.headers['Authorization'] =
      'Basic ${base64Encode(utf8.encode('$infuraProjectId:$infuraProjectSecret'))}';
  request.files.add(await http.MultipartFile.fromPath('file', filePath));

  var response = await request.send();

  if (response.statusCode == 200) {
    // File uploaded successfully
    var responseBody = await response.stream.bytesToString();
    print('IPFS Response: $responseBody');
  } else {
    // Handle error
    print('Failed to upload file to IPFS. Error: ${response.statusCode}');
  }
}

/*Future<void> ipfsUpload(File file) async {
  try {
    var auth = base64Encode(utf8.encode('2KiK6S75slDQfxRFU5dfP7z7TQG:622237ae0de6536fe6464071ffa0a100'));
    IpfsClient ipfsClient = IpfsClient(url: "https://ipfs.infura.io:5001", authorizationToken: auth);
  var res = await ipfsClient.write(
      dir: '',
      filePath: file.path,
      fileName: "Simulator.png");
  print("++++++++++++++++++++++++++++");
  print(res);
  } catch (e) {
    print(e);
  }
  var res1 = await ipfsClient.write(
      dir: 'testpath3/Simulator.png',
      filePath: "[FILE_PATH]/Simulator.png",
      fileName: "Simulator.png");
  print(res1);
  var res2 = await ipfsClient.ls(dir: "testDir");
  print(res2);
}*/