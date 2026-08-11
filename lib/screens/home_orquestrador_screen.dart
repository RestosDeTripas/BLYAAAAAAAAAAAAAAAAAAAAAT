import 'package:flutter/material.dart';

import '../models/musica_orquestrada_model.dart';
import '../services/orquestrador_facade.dart';
import '../services/spotify_service.dart';
import '../widgets/dados_card_widget.dart';

class HomeOrquestradorScreen extends StatefulWidget {
  const HomeOrquestradorScreen({super.key, required this.orquestradorFacade});

  final OrquestradorFacade orquestradorFacade;

  @override
  State<HomeOrquestradorScreen> createState() => _HomeOrquestradorScreenState();
}

class _HomeOrquestradorScreenState extends State<HomeOrquestradorScreen> {
  late final TextEditingController _queryController;
  late final HomeOrquestradorNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
    _notifier = HomeOrquestradorNotifier(widget.orquestradorFacade);
  }

  @override
  void dispose() {
    _queryController.dispose();
    _notifier.dispose();
    super.dispose();
  }

  Future<void> _orquestrar() async {
    FocusScope.of(context).unfocus();
    await _notifier.orquestrar(_queryController.text);

    if (!mounted || _notifier.erro == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_notifier.erro!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orquestrador Musical')),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _notifier,
          builder: (context, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(context),
                  const SizedBox(height: 16),
                  if (_notifier.carregando) _buildLoading(context),
                  if (_notifier.resultado != null) ...[
                    _buildResumoPrincipal(context, _notifier.resultado!),
                    const SizedBox(height: 16),
                    _buildSecaoSpotify(context, _notifier.resultado!),
                    const SizedBox(height: 16),
                    _buildSecaoMusicBrainz(context, _notifier.resultado!),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _queryController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _orquestrar(),
            decoration: InputDecoration(
              hintText: 'Digite música, artista ou ISRC',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _queryController.clear();
                  _notifier.limparResultado();
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: _notifier.carregando ? null : _orquestrar,
          icon: const Icon(Icons.hub),
          label: const Text('Orquestrar'),
        ),
      ],
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(_notifier.mensagemProgresso)),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoPrincipal(BuildContext context, MusicaOrquestradaModel model) {
    final temCapa = model.urlCapaAlbum != 'Não Catalogado';

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 96,
                height: 96,
                child: temCapa
                    ? Image.network(
                        model.urlCapaAlbum,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildAlbumPlaceholder(),
                      )
                    : _buildAlbumPlaceholder(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.titulo,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    model.artistaPrincipal,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    model.albumNome,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text('Lançamento: ${model.dataLancamento}')),
                      Chip(label: Text('Faixa #${model.numeroFaixa}')),
                      Chip(label: Text(model.conteudoExplicito ? 'Explícita' : 'Não Explícita')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumPlaceholder() {
    return Container(
      color: Colors.black12,
      child: const Icon(Icons.album, size: 44),
    );
  }

  Widget _buildSecaoSpotify(BuildContext context, MusicaOrquestradaModel model) {
    final popularidade = model.popularidade.clamp(0, 100).toDouble();
    return DadosCardWidget(
      titulo: 'Streaming & Métricas (Spotify)',
      icone: Icons.graphic_eq_rounded,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.timer_outlined),
          title: const Text('Duração'),
          trailing: Text(model.duracaoFormatada),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.vpn_key_outlined),
          title: const Text('ISRC'),
          trailing: Text(model.isrc),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.explore_outlined),
          title: const Text('Popularidade'),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(value: popularidade / 100),
          ),
          trailing: Text('${model.popularidade}%'),
        ),
      ],
    );
  }

  Widget _buildSecaoMusicBrainz(BuildContext context, MusicaOrquestradaModel model) {
    return DadosCardWidget(
      titulo: 'Metadados Catalográficos (MusicBrainz)',
      icone: Icons.library_music_outlined,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _badge('MBID Faixa', model.mbidFaixa),
            _badge('MBID Artista', model.mbidArtista),
            _badge('Tipo Artista', model.tipoArtista),
            _badge('Gravadora', model.gravadora),
            _badge('Tipo Lançamento', model.tipoLancamento),
            _badge('Status', model.statusLancamento),
            _badge('País', model.paisOrigem),
            _badge('Mídia', model.formatoMidia),
            _badge('Desambiguação', model.edicaoDesambiguacao),
          ],
        ),
        const SizedBox(height: 12),
        Text('Tags/Gêneros', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: model.generosTags
              .map((tag) => Chip(label: Text(tag)))
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _badge(String label, String value) {
    return Badge(
      label: const Icon(Icons.check, size: 10),
      child: Chip(
        avatar: const Icon(Icons.info_outline, size: 16),
        label: Text('$label: $value'),
      ),
    );
  }
}

class HomeOrquestradorNotifier extends ChangeNotifier {
  HomeOrquestradorNotifier(this._orquestradorFacade);

  final OrquestradorFacade _orquestradorFacade;

  bool carregando = false;
  String mensagemProgresso = 'Pronto para orquestrar.';
  MusicaOrquestradaModel? resultado;
  String? erro;

  Future<void> orquestrar(String query) async {
    final consulta = query.trim();
    if (consulta.isEmpty) {
      erro = 'Informe uma busca válida para continuar.';
      notifyListeners();
      return;
    }

    carregando = true;
    erro = null;
    mensagemProgresso = 'Consultando Spotify...';
    notifyListeners();

    try {
      final model = await _orquestradorFacade.orquestrarMusica(
        consulta,
        onProgress: (mensagem) {
          mensagemProgresso = mensagem;
          notifyListeners();
        },
      );
      resultado = model;
    } on MusicaNaoEncontradaException catch (e) {
      erro = e.toString();
      resultado = null;
    } on CredenciaisSpotifyInvalidasException catch (e) {
      erro = e.toString();
      resultado = null;
    } catch (e) {
      erro = 'Falha de integração: $e';
      resultado = null;
    } finally {
      carregando = false;
      mensagemProgresso = 'Processamento finalizado.';
      notifyListeners();
    }
  }

  void limparResultado() {
    resultado = null;
    erro = null;
    mensagemProgresso = 'Pronto para orquestrar.';
    notifyListeners();
  }
}
