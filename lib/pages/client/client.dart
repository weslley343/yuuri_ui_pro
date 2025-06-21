import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:yuuri_ui_pro/pages/client/components/evolution.dart';
import 'package:yuuri_ui_pro/pages/client/components/historic.dart';

class Client {
  final String? id;
  // ignore: non_constant_identifier_names
  final String? image_url;
  final String? identifier;
  final String? code;
  final String? name;
  final String? gender;
  final String? description;

  Client({
    this.id,
    // ignore: non_constant_identifier_names
    this.image_url,
    this.identifier,
    this.code,
    this.name,
    this.gender,
    this.description,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      image_url: json['image_url'],
      identifier: json['identifier'],
      code: json['code'],
      name: json['full_name'],
      gender: json['gender'],
      description: json['description'],
    );
  }
}

class DomainResult {
  final String domain;
  final String color;
  final String totalScore;

  DomainResult({
    required this.domain,
    required this.color,
    required this.totalScore,
  });

  factory DomainResult.fromJson(Map<String, dynamic> json) {
    return DomainResult(
      domain: json['domain'],
      color: json['color'],
      totalScore: json['total_score'],
    );
  }
}

class ClientPage extends StatefulWidget {
  final String id;
  final String name;

  const ClientPage({super.key, required this.id, required this.name});

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('acetoken');
  }

  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final server = prefs.getString('server') ?? 'http://localhost:4000';
    return server;
  }

  Future<Client> fetchUsuario() async {
    String? token = await getAccessToken();
    if (token == null) {
      throw Exception('Token não encontrado. Usuário não autenticado.');
    }

    final baseUrl = await getBaseUrl();

    try {
      final dio = Dio(BaseOptions(headers: {'Authorization': 'Bearer $token'}));
      final response = await dio.get('$baseUrl/client/${widget.id}');
      if (response.statusCode == 200) {
        return Client.fromJson(response.data);
      } else {
        throw Exception(
          'Erro ao buscar cliente: código ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erro ao buscar cliente: $e');
    }
  }

  Future<List<DomainResult>> fetchLastTestResults() async {
    String? token = await getAccessToken();
    if (token == null) {
      throw Exception('Token não encontrado. Usuário não autenticado.');
    }
    final baseUrl = await getBaseUrl();
    try {
      final dio = Dio(BaseOptions(headers: {'Authorization': 'Bearer $token'}));
      final response = await dio.get('$baseUrl/avaliation/resultoflasttest/${widget.id}');
      if (response.statusCode == 200) {
        final List data = response.data;
        return data.map((e) => DomainResult.fromJson(e)).toList();
      } else {
        throw Exception('Erro ao buscar resultados: código ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar resultados: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const <Widget>[
            Tab(icon: Icon(Icons.person_2_outlined), text: "cliente"),
            Tab(
              icon: Icon(Icons.auto_graph_outlined),
              text: "progresso por área",
            ),
            Tab(icon: Icon(Icons.list), text: "avaliações"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          FutureBuilder<Client>(
            future: fetchUsuario(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Erro ao carregar os dados do usuário: ${snapshot.error}',
                  ),
                );
              } else if (!snapshot.hasData) {
                return const Center(child: Text('Usuário não encontrado'));
              } else {
                final usuario = snapshot.data!;
                return FutureBuilder<String>(
                  future: getBaseUrl(),
                  builder: (context, baseUrlSnapshot) {
                    if (!baseUrlSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final String? fullImageUrl = usuario.image_url != null
                        ? '${baseUrlSnapshot.data}${usuario.image_url}'
                        : null;
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.3,
                            width: double.infinity,
                            child: fullImageUrl != null
                                ? FadeInImage.assetNetwork(
                                    placeholder: 'assets/images/background.png',
                                    image: fullImageUrl,
                                    fit: BoxFit.cover,
                                    imageErrorBuilder:
                                        (context, error, stackTrace) {
                                          return Image.asset(
                                            'assets/images/logo.png',
                                            fit: BoxFit.cover,
                                          );
                                        },
                                  )
                                : Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 9,
                              horizontal: 9,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      "IDENTIFICADOR: ",
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      (usuario.identifier ??
                                          "identificador não encontrado : ("),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Text(
                                      "NOME: ",
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      (usuario.name ?? "nome não encontrado : ("),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Text(
                                      "DESCRIÇÃO: ",
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      (usuario.description ??
                                          "descrição não encontrada : ("),
                                    ),
                                  ],
                                ),
                                const Divider(thickness: 1, color: Colors.grey),
                                // NOVO BLOCO: Resultados do último teste
                                FutureBuilder<List<DomainResult>>(
                                  future: fetchLastTestResults(),
                                  builder: (context, resultSnapshot) {
                                    if (resultSnapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(child: CircularProgressIndicator());
                                    } else if (resultSnapshot.hasError) {
                                      return Text(
                                        'Erro ao carregar resultados do último teste: ${resultSnapshot.error}',
                                        style: const TextStyle(color: Colors.red),
                                      );
                                    } else if (!resultSnapshot.hasData || resultSnapshot.data!.isEmpty) {
                                      return const Text('Nenhum resultado de teste encontrado.');
                                    } else {
                                      final results = resultSnapshot.data!;
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Resultados do último teste:",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          ...results.map((r) => Card(
                                            child: ListTile(
                                              leading: CircleAvatar(
                                                backgroundColor: Color(
                                                  int.parse(r.color.replaceFirst('#', '0xff')),
                                                ),
                                              ),
                                              title: Text(r.domain),
                                              trailing: Text(
                                                r.totalScore,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                          )),
                                        ],
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }
            },
          ),
          Evolution(clientId: widget.id),
          Historic(clientId: widget.id),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => {
          GoRouter.of(context).push('/listscales/${widget.id}'),
        },
        child: const Icon(Icons.content_paste_go_rounded, color: Colors.white),
      ),
    );
  }
}
