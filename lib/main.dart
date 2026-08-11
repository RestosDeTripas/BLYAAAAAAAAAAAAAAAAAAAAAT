import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'screens/home_orquestrador_screen.dart';
import 'services/musicbrainz_service.dart';
import 'services/orquestrador_facade.dart';
import 'services/spotify_service.dart';

void main() {
  final httpClient = http.Client();
  final spotifyService = SpotifyService(
    clientId: const String.fromEnvironment('SPOTIFY_CLIENT_ID'),
    clientSecret: const String.fromEnvironment('SPOTIFY_CLIENT_SECRET'),
    httpClient: httpClient,
  );

  final musicBrainzService = MusicBrainzService(httpClient: httpClient);
  final orquestradorFacade = OrquestradorFacade(
    spotifyService: spotifyService,
    musicBrainzService: musicBrainzService,
  );

  runApp(MyApp(orquestradorFacade: orquestradorFacade));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.orquestradorFacade});

  final OrquestradorFacade orquestradorFacade;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Micro App Orquestrador Musical',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: HomeOrquestradorScreen(orquestradorFacade: orquestradorFacade),
    );
  }
}
