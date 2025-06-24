import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import 'package:shared_preferences/shared_preferences.dart';

class Question {
  final int id;
  final int itemOrder;
  final String content;
  final String domain;
  final String color;
  final List<AnswerItem> itens;

  Question({
    required this.id,
    required this.itemOrder,
    required this.content,
    required this.domain,
    required this.color,
    required this.itens,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      itemOrder: json['item_order'],
      content: json['content'],
      domain: json['domain'],
      color: json['color'],
      itens: (json['itens'] as List)
          .map((item) => AnswerItem.fromJson(item))
          .toList(),
    );
  }
}

class AnswerItem {
  final int id;
  final int itemOrder;
  final String content;
  final String score;

  AnswerItem({
    required this.id,
    required this.itemOrder,
    required this.content,
    required this.score,
  });

  factory AnswerItem.fromJson(Map<String, dynamic> json) {
    return AnswerItem(
      id: json['id'],
      itemOrder: json['item_order'],
      content: json['content'],
      score: json['score'],
    );
  }
}

// Insira os models aqui (Question e AnswerItem)

class MakeAvaliation extends StatefulWidget {
  final int avaliation;
  final String client;

  const MakeAvaliation({
    super.key,
    required this.avaliation,
    required this.client,
  });

  @override
  State<MakeAvaliation> createState() => _MakeAvaliationState();
}

class _MakeAvaliationState extends State<MakeAvaliation>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController; // Adicione isto
  List<Question> _questions = [];
  final Map<int, AnswerItem> _selectedAnswers = {};
  bool _isLoading = true;

  String identifier = "";
  late final TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController();
    _loadIdentifier();
    _fetchQuestions();
  }

  Future<void> _loadIdentifier() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      identifier = prefs.getString('identifier') ?? "";
      _titleController = TextEditingController(
        text: "Avaliação de $identifier",
      );
    });
  }

  final _observationController = TextEditingController(text: "Observações...");

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose(); // Não esqueça de descartar
    super.dispose();
  }

  Future<void> _fetchQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final server = prefs.getString('server') ?? 'localhost';
    final url = '$server/scale/${widget.avaliation}';

    try {
      final dio = Dio();
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data as List;
        setState(() {
          _questions = data.map((q) => Question.fromJson(q)).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (context.mounted) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Erro ao carregar perguntas: ${response.statusCode}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar perguntas: $e')),
        );
      }
    }
  }

  void _selectAnswer(int questionIndex, int questionId, AnswerItem item) {
    setState(() {
      _selectedAnswers[questionId] = item;
    });
    // Após selecionar, rola para o próximo card se houver
    if (questionIndex < _questions.length - 1) {
      // Calcula a posição aproximada do próximo card
      // Aqui, cada card tem altura variável, então usamos ensureVisible
      // Para garantir que funcione, cada card precisa de uma GlobalKey
      _scrollToCard(questionIndex + 1);
    }
  }

  final List<GlobalKey> _cardKeys = [];

  @override
  Widget build(BuildContext context) {
    // Garante que há uma key para cada card
    while (_cardKeys.length < _questions.length) {
      _cardKeys.add(GlobalKey());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Avaliação"), // de ${widget.client}
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Questionário"),
            Tab(text: "Complemento"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // TAB 1 - FIELDS
                Column(
                  children: [
                    // Barra de progresso
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value: _questions.isEmpty
                                ? 0
                                : _selectedAnswers.length / _questions.length,
                            minHeight: 8,
                            backgroundColor: Theme.of(context).primaryColor,
                            color: Colors.blue[300],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${_selectedAnswers.length} de ${_questions.length} respondidas",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    // Lista de perguntas
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: _questions.length,
                        itemBuilder: (context, index) {
                          final question = _questions[index];
                          return Card(
                            key: _cardKeys[index], // Adicione a key aqui
                            // color: Color(
                            // int.parse(
                            //   question.color.replaceFirst('#', '0xff'),
                            // ),
                            // ),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                color: Color(
                                  int.parse(
                                    question.color.replaceFirst('#', '0xff'),
                                  ),
                                ),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${question.itemOrder}. ${question.content}",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Domínio: ${question.domain}",
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: question.itens.map((item) {
                                      final selected =
                                          _selectedAnswers[question.id] == item;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4.0,
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? Colors.blue.shade100
                                                : const Color.fromARGB(
                                                    255,
                                                    12,
                                                    12,
                                                    12,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: selected
                                                  ? const Color.fromARGB(
                                                      255,
                                                      73,
                                                      173,
                                                      255,
                                                    )
                                                  : const Color.fromARGB(
                                                      255,
                                                      12,
                                                      12,
                                                      12,
                                                    ),
                                            ),
                                          ),
                                          child: InkWell(
                                            onTap: () => _selectAnswer(
                                              index,
                                              question.id,
                                              item,
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Text(
                                                item.content,
                                                style: TextStyle(
                                                  color: selected
                                                      ? Colors.blue.shade900
                                                      : const Color.fromARGB(
                                                          221,
                                                          192,
                                                          192,
                                                          192,
                                                        ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                // TAB 2 - COMPLEMENTO
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: "Título da avaliação",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _observationController,
                          maxLines: 25,
                          decoration: const InputDecoration(
                            // labelText: "Observações",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _submitAvaliation();
        },
        child: const Icon(Icons.check),
      ),
    );
  }

  void _scrollToCard(int index) {
    if (index < _cardKeys.length) {
      final context = _cardKeys[index].currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  Future<void> _submitAvaliation() async {
    final prefs = await SharedPreferences.getInstance();
    final server = prefs.getString('server') ?? 'localhost';
    final token = prefs.getString('acetoken') ?? '';
    final url = '$server/avaliation/submit/';

    final answers = _selectedAnswers.entries
        .map((e) => {"question": e.key, "item": e.value.id})
        .toList();

    final data = {
      "scale": widget.avaliation,
      "title": _titleController.text,
      "notes": _observationController.text,
      "client": widget.client,
      "answers": answers,
    };

    try {
      final dio = Dio();
      final response = await dio.post(
        url,
        data: data,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (context.mounted) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avaliação enviada com sucesso!')),
          );
          // Volta uma página usando go_router
          // Certifique-se de importar: import 'package:go_router/go_router.dart';
          Future.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted) {
              // ignore: use_build_context_synchronously
              context.pop();
            }
          });
        }
      } else {
        if (context.mounted) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao enviar avaliação: ${response.statusCode}'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao enviar avaliação: $e')));
      }
    }
  }
}
