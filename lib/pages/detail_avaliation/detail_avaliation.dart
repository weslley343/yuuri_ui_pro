import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple DTO for each evaluation item
class EvaluationItem {
  final int itemOrder;
  final String content;
  final String answer;
  final String domain;
  final Color color;
  final int score;

  EvaluationItem({
    required this.itemOrder,
    required this.content,
    required this.answer,
    required this.domain,
    required this.color,
    required this.score,
  });

  factory EvaluationItem.fromJson(Map<String, dynamic> json) {
    Color parseColor(String hex) {
      // Ensure we handle strings like "#FFFFFF" and fallback to white
      try {
        return Color(int.parse(hex.replaceFirst('#', '0xff')));
      } catch (_) {
        return Colors.white;
      }
    }

    return EvaluationItem(
      itemOrder: json['item_order'] as int,
      content: json['content'] as String,
      answer: json['answer'] as String,
      domain: json['domain'] as String,
      color: parseColor(json['color'] as String),
      score: int.tryParse(json['score'].toString()) ?? 0,
    );
  }
}

class DetailAvaliation extends StatefulWidget {
  /// The ID of the evaluation to load
  final String avaliationId;
  const DetailAvaliation({super.key, required this.avaliationId});

  @override
  State<DetailAvaliation> createState() => _DetailAvaliationState();
}

class _DetailAvaliationState extends State<DetailAvaliation> {
  late Future<List<EvaluationItem>> _futureItems;
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _futureItems = _fetchAvaliationItems();
  }

  Future<List<EvaluationItem>> _fetchAvaliationItems() async {
    final prefs = await SharedPreferences.getInstance();
    final server = prefs.getString('server') ?? 'localhost';

    final response = await _dio.get(
      '$server/avaliation/${widget.avaliationId}',
      options: Options(responseType: ResponseType.json),
    );

    if (response.statusCode == 200 && response.data is List) {
      final List data = response.data as List;
      return data
          .map((e) => EvaluationItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load evaluation items');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Avaliação #${widget.avaliationId}')),
      body: FutureBuilder<List<EvaluationItem>>(
        future: _futureItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 8),
                    Text('Erro ao carregar avaliação: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _futureItems = _fetchAvaliationItems();
                        });
                      },
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum item encontrado.'));
          }

          final items = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: item.color,
                    child: Text(item.itemOrder.toString()),
                  ),
                  title: Text(item.content),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Resposta: ${item.answer}'),
                      Text('Domínio: ${item.domain}'),
                    ],
                  ),
                  trailing: Chip(
                    label: Text(item.score.toString()),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.secondaryContainer,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
