import 'dart:convert';

import 'package:http/http.dart' as http;

class MusicBrainzService {
  MusicBrainzService({required this.httpClient});

  static const _basePath = '/ws/2';
  static const _userAgent =
      'MeuMicroAppOrquestrador/1.0.0 ( contato@meudominio.com )';

  final http.Client httpClient;

  Future<Map<String, dynamic>?> buscarRecordingPorIsrc(String isrc) async {
    if (isrc.trim().isEmpty || isrc == 'Não Catalogado') {
      return null;
    }
    return _buscarPrimeiroRecording('isrc:$isrc');
  }

  Future<Map<String, dynamic>?> buscarRecordingPorTituloEArtista({
    required String titulo,
    required String artista,
  }) {
    final query = 'recording:"$titulo" AND artist:"$artista"';
    return _buscarPrimeiroRecording(query);
  }

  Future<String> buscarTipoArtista(String mbidArtista) async {
    if (mbidArtista.trim().isEmpty || mbidArtista == 'Não Catalogado') {
      return 'Não Catalogado';
    }

    final uri = Uri.https(
      'musicbrainz.org',
      '$_basePath/artist/$mbidArtista',
      <String, String>{'fmt': 'json'},
    );
    final response = await httpClient.get(
      uri,
      headers: const {'User-Agent': _userAgent, 'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw MusicBrainzHttpException(
        'Falha no lookup de artista no MusicBrainz (${response.statusCode}): ${response.body}',
      );
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final tipo = payload['type']?.toString().trim();
    return (tipo == null || tipo.isEmpty) ? 'Não Catalogado' : tipo;
  }

  Future<Map<String, dynamic>?> _buscarPrimeiroRecording(String query) async {
    final uri = Uri.https(
      'musicbrainz.org',
      '$_basePath/recording',
      <String, String>{
        'query': query,
        'fmt': 'json',
        'inc': 'releases+artist-credits+labels+tags+media',
      },
    );

    final response = await httpClient.get(
      uri,
      headers: const {'User-Agent': _userAgent, 'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw MusicBrainzHttpException(
        'Falha na busca do MusicBrainz (${response.statusCode}): ${response.body}',
      );
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final recordings = payload['recordings'] as List<dynamic>? ?? const [];
    if (recordings.isEmpty) {
      return null;
    }

    return recordings.first as Map<String, dynamic>? ?? const {};
  }
}

class MusicBrainzHttpException implements Exception {
  const MusicBrainzHttpException(this.message);
  final String message;

  @override
  String toString() => message;
}
