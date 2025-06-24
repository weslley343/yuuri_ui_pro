import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:yuuri_ui_pro/pages/make_avaliation/make_avaliation.dart';

class ListScales extends StatefulWidget {
  final String client; // UUID do client

  const ListScales({super.key, required this.client});

  @override
  State<ListScales> createState() => _ListScalesState();
}

class _ListScalesState extends State<ListScales> {
  List<dynamic> scales = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchScales();
  }

  Future<void> fetchScales() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final server = prefs.getString('server') ?? 'localhost';

      final dio = Dio();
      // Adiciona o parâmetro client na requisição
      final response = await dio.get(
        '$server/scale/',
        // queryParameters: {'client': widget.client},
      );

      setState(() {
        scales = response.data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Erro ao carregar escalas: $e';
        isLoading = false;
      });
    }
  }

  Future<Widget> buildScaleCard(dynamic scale) async {
    final imageUrl = scale['image_url'];
    final prefs = await SharedPreferences.getInstance();
    final server = prefs.getString('server') ?? 'localhost';
    final fullImageUrl = imageUrl != null && imageUrl.toString().isNotEmpty
        ? '$server$imageUrl'
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: fullImageUrl != null
                  ? Image.network(
                      fullImageUrl,
                      width: 80,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/background.png',
                        width: 80,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      'assets/background.png',
                      width: 80,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scale['name'] ?? 'Sem nome',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    scale['description'] ?? 'Sem descrição',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MakeAvaliation(
                            avaliation: scale['id'],
                            client: widget.client,
                          ),
                        ),
                      );
                    },
                    child: const Text('Avaliar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escalas')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!))
          : FutureBuilder<List<Widget>>(
              future: Future.wait(scales.map((scale) => buildScaleCard(scale))),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Erro ao carregar escalas'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('Nenhuma escala encontrada'));
                }
                return ListView(children: snapshot.data!);
              },
            ),
    );
  }
}
