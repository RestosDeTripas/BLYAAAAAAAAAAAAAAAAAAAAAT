import    'dart:convert';

import 'package:http/http.dart' as http;

class SpotifyService {
  SpotifyService({
    required this.clientId,
    required this.clientSecret,
    required this.httpClient,
  });

  final String clientId;
  final String clientSecret;
  final http.Client httpClient;

  String? _accessToken;
  DateTime? _tokenExpiraEm;

  Future<String> _obterTokenAcesso() async {
    final agora = DateTime.now();
    if (_accessToken != null &&
        _tokenExpiraEm != null &&
        agora.isBefore(_tokenExpiraEm!)) {
      return _accessToken!;
    }

    if (clientId.isEmpty || clientSecret.isEmpty) {
      throw const CredenciaisSpotifyInvalidasException(
        'Credenciais Spotify ausentes. Informe SPOTIFY_CLIENT_ID e SPOTIFY_CLIENT_SECRET em --dart-define.',
      );
    }

    final basicAuth = base64Encode(utf8.encode('$clientId:$clientSecret'));
    final response = await httpClient
        .post(
          Uri.parse('https://accounts.spotify.com/api/token'),
          headers: {
            'Authorization': 'Basic $basicAuth',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {'grant_type': 'client_credentials'},
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw SpotifyHttpException(
        'Falha ao autenticar no Spotify (${response.statusCode}): ${response.body}',
      );
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final token = (payload['access_token'] as String?) ?? '';
    final expiresIn = (payload['expires_in'] as num?)?.toInt() ?? 0;

    if (token.isEmpty) {
      throw const SpotifyHttpException(
        'Spotify retornou token vazio para Client Credentials.',
      );
    }

    _accessToken = token;
    _tokenExpiraEm = agora.add(Duration(seconds: expiresIn - 30));
    return token;
  }

  Future<SpotifyTrackData?> buscarFaixa(String query) async {
    final token = await _obterTokenAcesso();
    final uri = Uri.https(
      'api.spotify.com',
      '/v1/search',
      <String, String>{
        'q': query,
        'type': 'track',
        'limit': '20',
      },
    );

    final response = await httpClient.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw SpotifyHttpException(
        'Falha na busca do Spotify (${response.statusCode}): ${response.body}',
      );
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final tracks = payload['tracks'] as Map<String, dynamic>? ?? const {};
    final items = tracks['items'] as List<dynamic>? ?? const [];
    if (items.isEmpty) {
      return null;
    }

    final first = items.first as Map<String, dynamic>? ?? const {};
    return SpotifyTrackData.fromJson(first);
  }
}

class SpotifyTrackData {
  const SpotifyTrackData({
    required this.titulo,
    required this.artistaPrincipal,
    required this.albumNome,
    required this.dataLancamento,
    required this.urlCapaAlbum,
    required this.duracaoFormatada,
    required this.popularidade,
    required this.isrc,
    required this.numeroFaixa,
    required this.conteudoExplicito,
  });

  final String titulo;
  final String artistaPrincipal;
  final String albumNome;
  final String dataLancamento;
  final String urlCapaAlbum;
  final String duracaoFormatada;
  final int popularidade;
  final String isrc;
  final int numeroFaixa;
  final bool conteudoExplicito;

  factory SpotifyTrackData.fromJson(Map<String, dynamic> item) {
    final artists = item['artists'] as List<dynamic>? ?? const [];
    final album = item['album'] as Map<String, dynamic>? ?? const {};
    final images = album['images'] as List<dynamic>? ?? const [];
    final externalIds = item['external_ids'] as Map<String, dynamic>? ?? const {};

    final durationMs = _asInt(item['duration_ms']);
    final firstArtist = artists.isNotEmpty ? artists.first as Map<String, dynamic>? : null;
    final firstImage = images.isNotEmpty ? images.first as Map<String, dynamic>? : null;

    return SpotifyTrackData(
      titulo: _asString(item['name']),
      artistaPrincipal: _asString(firstArtist?['name']),
      albumNome: _asString(album['name']),
      dataLancamento: _asString(album['release_date']),
      urlCapaAlbum: _asString(firstImage?['url']),
      duracaoFormatada: _formatarDuracao(durationMs),
      popularidade: _asInt(item['popularity']),
      isrc: _asString(externalIds['isrc']),
      numeroFaixa: _asInt(item['track_number']),
      conteudoExplicito: (item['explicit'] as bool?) ?? false,
    );
  }
}

String _asString(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) {
    return 'Não Catalogado';
  }
  return text;
}

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

String _formatarDuracao(int durationMs) {
  final totalSegundos = (durationMs / 1000).floor();
  final minutos = totalSegundos ~/ 60;
  final segundos = totalSegundos % 60;
  return '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
}

class SpotifyHttpException implements Exception {
  const SpotifyHttpException(this.message);
  final String message;

  @override
  String toString() => message;
}

class CredenciaisSpotifyInvalidasException implements Exception {
  const CredenciaisSpotifyInvalidasException(this.message);
  final String message;

  @override
  String toString() => message;
}
