// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:bizaro/main.dart';
import 'package:bizaro/services/musicbrainz_service.dart';
import 'package:bizaro/services/orquestrador_facade.dart';
import 'package:bizaro/services/spotify_service.dart';

void main() {
  testWidgets('renderiza home do orquestrador', (WidgetTester tester) async {
    await tester.pumpWidget(
      MyApp(
        orquestradorFacade: OrquestradorFacade(
          spotifyService: SpotifyService(
            clientId: 'id',
            clientSecret: 'secret',
            httpClient: http.Client(),
          ),
          musicBrainzService: MusicBrainzService(httpClient: http.Client()),
        ),
      ),
    );

    expect(find.text('Orquestrador Musical'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Orquestrar'), findsOneWidget);
  });
}
