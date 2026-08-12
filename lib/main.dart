import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const TopMusicasApp());
}

class TopMusicasApp extends StatelessWidget {
  const TopMusicasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Top Músicas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const TopMusicasScreen(),
    );
  }
}

class TopMusicasScreen extends StatefulWidget {
  const TopMusicasScreen({super.key});

  @override
  State<TopMusicasScreen> createState() => _TopMusicasScreenState();
}

class _TopMusicasScreenState extends State<TopMusicasScreen> {
  final http.Client _httpClient = http.Client();

  bool _isLoading = false;
  String? _errorMessage;
  List<MusicaModel> _musicas = const [];

  @override
  void initState() {
    super.initState();
    _carregarMusicasMusicBrainz();
  }

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }

  Future<void> _carregarMusicasMusicBrainz() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Endpoint público de busca de gravações (recordings) na MusicBrainz
      final uri = Uri.https(
        'musicbrainz.org',
        '/ws/2/recording',
        <String, String>{
          'query': 'tag:pop OR tag:rock', // Busca faixas de pop/rock
          'fmt': 'json',                   // Formato da resposta em JSON
          'limit': '25',                   // Limite de faixas por requisição
        },
      );

      final response = await _httpClient.get(
        uri,
        headers: {
          // A MusicBrainz EXIGE um User-Agent identificando sua aplicação
          'User-Agent': 'MeuAppFlutter/1.0.0 ( contato@meuemail.com )',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw HttpException(
          'Falha na API MusicBrainz (${response.statusCode}): ${response.body}',
        );
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final recordings = payload['recordings'] as List<dynamic>? ?? const [];

      final musicas = <MusicaModel>[];
      for (int index = 0; index < recordings.length; index++) {
        final item = recordings[index] as Map<String, dynamic>;
        musicas.add(MusicaModel.fromMusicBrainzMap(item, index + 1));
      }

      setState(() {
        _musicas = musicas;
      });
    } on HttpException catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
    } on SocketException {
      setState(() {
        _errorMessage = 'Erro de conexão. Verifique sua internet e tente novamente.';
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Erro inesperado ao carregar faixas: $error';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _abrirDetalhes(MusicaModel musica) async {
    final bool? resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DetalhesMusicaScreen(musica: musica),
      ),
    );

    if (!mounted) return;

    final mensagem = switch (resultado) {
      true => 'Você confirmou: ${musica.titulo}.',
      false => 'Você cancelou: ${musica.titulo}.',
      null => 'Você voltou sem confirmar.',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Músicas (MusicBrainz API)'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Consultando API pública do MusicBrainz...'),
          ],
        ),
      )
          : _errorMessage != null
          ? _buildErrorView()
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _musicas.length,
        itemBuilder: (context, index) {
          final musica = _musicas[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                backgroundColor: Colors.deepPurple,
                child: Text(
                  '#${musica.posicao}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                musica.titulo,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${musica.artista} • ${musica.album} • ${musica.duracao}',
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _abrirDetalhes(musica),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Erro desconhecido.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _carregarMusicasMusicBrainz,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class DetalhesMusicaScreen extends StatelessWidget {
  const DetalhesMusicaScreen({super.key, required this.musica});

  final MusicaModel musica;

  @override
  Widget build(BuildContext context) {
    final detalhes = [
      _Detalhe(label: 'Posição', valor: '#${musica.posicao}'),
      _Detalhe(label: 'Título', valor: musica.titulo),
      _Detalhe(label: 'Artista', valor: musica.artista),
      _Detalhe(label: 'Álbum/Release', valor: musica.album),
      _Detalhe(label: 'Duração', valor: musica.duracao),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da Música')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  musica.titulo,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Divider(height: 30),
                ...detalhes.map(
                      (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            '${item.label}:',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(child: Text(item.valor)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Confirmar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(Icons.close_rounded),
                label: const Text('Cancelar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Detalhe {
  const _Detalhe({required this.label, required this.valor});

  final String label;
  final String valor;
}

class MusicaModel {
  const MusicaModel({
    required this.posicao,
    required this.titulo,
    required this.artista,
    required this.album,
    required this.duracao,
  });

  final int posicao;
  final String titulo;
  final String artista;
  final String album;
  final String duracao;

  factory MusicaModel.fromMusicBrainzMap(Map<String, dynamic> item, int posicao) {
    // Extrai o nome do artista
    final artistCredit = item['artist-credit'] as List<dynamic>? ?? const [];
    final firstArtist = artistCredit.isNotEmpty ? artistCredit.first as Map<String, dynamic> : const {};

    // Extrai o nome do álbum (releases)
    final releases = item['releases'] as List<dynamic>? ?? const [];
    final firstRelease = releases.isNotEmpty ? releases.first as Map<String, dynamic> : const {};

    return MusicaModel(
      posicao: posicao,
      titulo: _asString(item['title']),
      artista: _asString(firstArtist['name']),
      album: _asString(firstRelease['title']),
      duracao: _formatarDuracao(_toInt(item['length'])),
    );
  }

  static String _asString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return 'Não catalogado';
    }
    return text;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _formatarDuracao(int durationMs) {
    if (durationMs <= 0) return 'Duração N/A';
    final totalSeconds = (durationMs / 1000).floor();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString()}:${seconds.toString().padLeft(2, '0')}';
  }
}