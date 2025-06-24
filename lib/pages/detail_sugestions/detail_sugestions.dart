import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modelo simples para uma pergunta retornada pela API
class Question {
  final int id;
  final int order;
  final String content;
  final String domain;
  final String? color; // Novo atributo opcional

  Question({
    required this.id,
    required this.order,
    required this.content,
    required this.domain,
    this.color,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['questionid'] as int,
      order: json['item_order'] as int,
      content: json['content'] as String,
      domain: json['domain'] as String,
      color: json['color'] as String?, // Pode ser null ou um valor hexadecimal
    );
  }
}

/// Tela que exibe as sugestões de perguntas para um determinado cliente/avaliação/escala.
class DetailSugestion extends StatefulWidget {
  final String clientId;
  final String avaliationId;
  final String scaleId;

  // Adiciona um print para verificar o conteúdo dos parâmetros
  @override
  const DetailSugestion({
    super.key,
    required this.clientId,
    required this.avaliationId,
    required this.scaleId,
  });
  State<DetailSugestion> createState() => _DetailSugestionState();
}

class _DetailSugestionState extends State<DetailSugestion> {
  late Future<List<Question>> _futureQuestions;

  /// Safely parses a hex color string, returns null if invalid.
  Color? _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) return null;
    try {
      String hex = colorString.replaceFirst('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex'; // add alpha if missing
      }
      return Color(int.parse('0x$hex'));
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _futureQuestions = _getQuestions();
  }

  /// Faz a requisição GET /recommend e devolve até 5 perguntas.
  Future<List<Question>> _getQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final server =
        prefs.getString('sugestion_server') ?? 'http://127.0.0.1:8000';
    final dio = Dio(BaseOptions(baseUrl: server));

    final response = await dio.get(
      '/recommend',
      queryParameters: {
        'client': widget.clientId,
        'avaliation': widget.avaliationId,
        'scale': widget.scaleId,
        'limit': 5, // if the backend accepts this parameter
      },
    );

    if (response.statusCode == 200) {
      final filteredQuestions = response.data['filtered_questions'];
      if (filteredQuestions == null || filteredQuestions is! List) {
        return [];
      }
      final data = filteredQuestions;
      // Ensure at most 5, even if the backend sends more
      return data.map((e) => Question.fromJson(e)).take(5).toList();
    }

    throw Exception(
      'Failed to get recommendations: status ${response.statusMessage}, code ${response.statusCode}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sugestões')),
      body: FutureBuilder<List<Question>>(
        future: _futureQuestions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final questions = snapshot.data ?? [];

          if (questions.isEmpty) {
            return const Center(child: Text('Nenhuma sugestão encontrada.'));
          }

          return Column(
            children: [
              const Divider(),
              Text(
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                'Itens de possível melhoria : ',
              ),
              
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: questions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final q = questions[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color:
                              _parseColor(q.color) ?? const Color(0xFFBDBDBD),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              _parseColor(q.color) ??
                              Theme.of(context).primaryColor,
                          child: Text(q.order.toString()),
                        ),
                        title: Text(q.content),
                        subtitle: Text(q.domain),
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
            ],
          );
        },
      ),
    );
  }
}
