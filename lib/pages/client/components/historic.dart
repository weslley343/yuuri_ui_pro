import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class Historic extends StatefulWidget {
  final String clientId;
  const Historic({super.key, required this.clientId});

  @override
  State<Historic> createState() => _HistoricState();
}

class _HistoricState extends State<Historic> {
  List<dynamic> scales = [];
  dynamic selectedScale;
  List<dynamic> historic = [];
  bool loadingScales = true;
  bool loadingHistoric = false;
  String? server;

  @override
  void initState() {
    super.initState();
    _loadServer();
  }

  Future<void> _loadServer() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      server = prefs.getString('server') ?? 'localhost';
    });
    _fetchScales();
  }

  Future<void> _fetchScales() async {
    setState(() {
      loadingScales = true;
    });
    final url = Uri.parse('$server/scale/');
    final response = await http.get(
      url,
      headers: {'User-Agent': 'insomnia/10.2.0'},
    );
    if (response.statusCode == 200) {
      setState(() {
        scales = jsonDecode(response.body);
        loadingScales = false;
      });
    } else {
      setState(() {
        loadingScales = false;
      });
      // Handle error as needed
    }
  }

  Future<void> _fetchHistoric() async {
    if (selectedScale == null) return;
    setState(() {
      loadingHistoric = true;
      historic = [];
    });
    final url = Uri.parse(
      '$server/avaliation/historic/${widget.clientId}/${selectedScale['id']}',
    );
    final response = await http.get(
      url,
      headers: {'User-Agent': 'insomnia/10.2.0'},
    );
    if (response.statusCode == 200) {
      setState(() {
        historic = jsonDecode(response.body);
        loadingHistoric = false;
      });
    } else {
      setState(() {
        loadingHistoric = false;
      });
      // Handle error as needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              loadingScales
                  ? const CircularProgressIndicator()
                  : Expanded(
                      child: DropdownButtonFormField<dynamic>(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color.fromARGB(255, 14, 11, 11),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: Colors.grey.shade600),
                          ),
                        ),
                        dropdownColor: const Color.fromARGB(255, 14, 11, 11),
                        hint: const Text('Selecione a avaliação'),
                        value: selectedScale,
                        items: scales
                            .map<DropdownMenuItem<dynamic>>(
                              (scale) => DropdownMenuItem(
                                value: scale,
                                child: Text(scale['name']),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedScale = value;
                          });
                        },
                        menuMaxHeight: 350,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: selectedScale == null || loadingHistoric
                    ? null
                    : _fetchHistoric,
                child: loadingHistoric
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
              ),
            ],
          ),
        ),
        Expanded(
          child: loadingHistoric
              ? const Center(child: CircularProgressIndicator())
              : historic.isEmpty
              ? Center(child: const Text('Nenhum histórico encontrado.'))
              : ListView.builder(
                  itemCount: historic.length,
                  itemBuilder: (context, index) {
                    final item = historic[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(item['created_at']),
                            const SizedBox(height: 8),
                            ...((item['domains'] as List<dynamic>).map(
                              (domain) => Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: Color(
                                        int.parse(
                                          domain['color'].replaceFirst(
                                            '#',
                                            '0xff',
                                          ),
                                        ),
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${domain['domain']}: ${domain['pontuation']}',
                                    ),
                                  ),
                                ],
                              ),
                            )),
                            SizedBox(height: 11),
                            Row(
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(
                                      255,
                                      22,
                                      20,
                                      20,
                                    ),
                                  ),
                                  onPressed: () {
                                    context.push(
                                      '/avaliationdetail/${item['id']}',
                                    );
                                  },
                                  child: const Text('Detalhar'),
                                ),
                                Padding(padding: EdgeInsets.only(left: 12)),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(
                                      255,
                                      22,
                                      20,
                                      20,
                                    ),
                                  ),
                                  onPressed: () {
                                    GoRouter.of(context).push(
                                      '/recsys/${item['id']}/${widget.clientId}/${selectedScale?['id']}',
                                    );
                                  },
                                  child: const Text('Obter Sugestões'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
