class MusicaOrquestradaModel {
  const MusicaOrquestradaModel({
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
    required this.mbidFaixa,
    required this.tipoLancamento,
    required this.statusLancamento,
    required this.paisOrigem,
    required this.gravadora,
    required this.tipoArtista,
    required this.generosTags,
    required this.formatoMidia,
    required this.mbidArtista,
    required this.edicaoDesambiguacao,
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
  final String mbidFaixa;
  final String tipoLancamento;
  final String statusLancamento;
  final String paisOrigem;
  final String gravadora;
  final String tipoArtista;
  final List<String> generosTags;
  final String formatoMidia;
  final String mbidArtista;
  final String edicaoDesambiguacao;
}
