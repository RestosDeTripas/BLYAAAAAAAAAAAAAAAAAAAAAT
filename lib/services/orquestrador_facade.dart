import '../models/musica_orquestrada_model.dart';
import 'musicbrainz_service.dart';
import 'spotify_service.dart';

class OrquestradorFacade {
  OrquestradorFacade({
    required this.spotifyService,
    required this.musicBrainzService,
  });

  final SpotifyService spotifyService;
  final MusicBrainzService musicBrainzService;

  Future<MusicaOrquestradaModel> orquestrarMusica(
    String query, {
    void Function(String mensagem)? onProgress,
  }) async {
    onProgress?.call('Autenticando no Spotify...');
    final spotifyTrack = await spotifyService.buscarFaixa(query);
    if (spotifyTrack == null) {
      throw const MusicaNaoEncontradaException(
        'Nenhuma música encontrada no Spotify para essa consulta.',
      );
    }

    onProgress?.call('Consultando Spotify...');
    Map<String, dynamic>? recording;
    onProgress?.call('Conectando ao MusicBrainz via ISRC...');
    recording = await musicBrainzService.buscarRecordingPorIsrc(spotifyTrack.isrc);

    if (recording == null) {
      onProgress?.call('Fallback: buscando no MusicBrainz por Título + Artista...');
      recording = await musicBrainzService.buscarRecordingPorTituloEArtista(
        titulo: spotifyTrack.titulo,
        artista: spotifyTrack.artistaPrincipal,
      );
    }

    final release = _firstMap(recording?['releases']);
    final releaseGroup = _asMap(release['release-group']);
    final labelInfo = _firstMap(release['label-info']);
    final label = _asMap(labelInfo['label']);
    final media = _firstMap(release['media']);
    final artistCredit = _firstMap(recording?['artist-credit']);
    final artist = _asMap(artistCredit['artist']);
    final tags = recording?['tags'] as List<dynamic>? ?? const [];

    final mbidArtista = _asString(artist['id']);
    final tipoArtistaNoRecording = _asString(artist['type']);
    final tipoArtista = tipoArtistaNoRecording == 'Não Catalogado'
        ? await musicBrainzService.buscarTipoArtista(mbidArtista)
        : tipoArtistaNoRecording;

    final generosTags = tags
        .map((tag) => _asString((tag as Map<String, dynamic>?)?['name']))
        .where((tag) => tag != 'Não Catalogado')
        .toList();

    return MusicaOrquestradaModel(
      titulo: spotifyTrack.titulo,
      artistaPrincipal: spotifyTrack.artistaPrincipal,
      albumNome: spotifyTrack.albumNome,
      dataLancamento: spotifyTrack.dataLancamento,
      urlCapaAlbum: spotifyTrack.urlCapaAlbum,
      duracaoFormatada: spotifyTrack.duracaoFormatada,
      popularidade: spotifyTrack.popularidade,
      isrc: spotifyTrack.isrc,
      numeroFaixa: spotifyTrack.numeroFaixa,
      conteudoExplicito: spotifyTrack.conteudoExplicito,
      mbidFaixa: _asString(recording?['id']),
      tipoLancamento: _asString(releaseGroup['primary-type']),
      statusLancamento: _asString(release['status']),
      paisOrigem: _asString(release['country']),
      gravadora: _asString(label['name']),
      tipoArtista: tipoArtista,
      generosTags: generosTags.isEmpty ? const ['Não Catalogado'] : generosTags,
      formatoMidia: _asString(media['format']),
      mbidArtista: mbidArtista,
      edicaoDesambiguacao: _asString(recording?['disambiguation']),
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  return (value as Map<String, dynamic>?) ?? const {};
}

Map<String, dynamic> _firstMap(dynamic value) {
  final list = value as List<dynamic>? ?? const [];
  return (list.isNotEmpty ? list.first as Map<String, dynamic>? : null) ?? const {};
}

String _asString(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) {
    return 'Não Catalogado';
  }
  return text;
}

class MusicaNaoEncontradaException implements Exception {
  const MusicaNaoEncontradaException(this.message);
  final String message;

  @override
  String toString() => message;
}
