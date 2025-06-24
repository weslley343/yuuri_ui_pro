import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:yuuri_ui_pro/pages/home/components/drawer.dart';

class Client {
  final String id;
  final String identifier;
  final String fullName;
  final String? imageUrl;

  Client({
    required this.id,
    required this.identifier,
    required this.fullName,
    this.imageUrl,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      identifier: json['identifier'],
      fullName: json['full_name'],
      imageUrl: json['image_url'],
      id: '${json['id']}',
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final List<Client> _clients = [];
  bool _isLoading = true;
  int _page = 0;
  final int _pageSize = 10;
  bool _hasMore = true;

  final Dio _dio = Dio();
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _loadPreferencesAndFetch();
  }

  Future<void> _loadPreferencesAndFetch() async {
    _prefs = await SharedPreferences.getInstance();
    await _fetchClients(page: 0);
  }

  Future<void> _fetchClients({required int page}) async {
    final String? server = _prefs.getString('server');
    final String? acetoken = _prefs.getString('acetoken');

    if (server == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuração de servidor ausente.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _dio.get(
        '$server/client/byprofessional',
        queryParameters: {'skip': page * _pageSize, 'take': _pageSize},
        options: Options(
          headers: {
            'Authorization': 'Bearer ${acetoken ?? ''}',
            'User-Agent': 'FlutterApp/1.0',
          },
        ),
      );

      final List<dynamic> data = response.data;

      setState(() {
        _clients.clear();
        _clients.addAll(data.map((json) => Client.fromJson(json)).toList());
        _page = page;
        _hasMore = data.length == _pageSize;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao buscar dados: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildClientCard(Client client) {
    final String? server = _prefs.getString('server');
    return ListTile(
      leading: client.imageUrl != null
          ? Image.network(
              '$server${client.imageUrl}',
              width: 50,
              height: 50,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.image_not_supported),
            )
          : const Icon(Icons.account_circle, size: 50),
      title: Text(client.fullName),
      subtitle: Text(client.identifier),
      onTap: () {
        GoRouter.of(context).push(
          '/client/${client.id}/${Uri.encodeComponent(client.fullName)}',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: const [
          Image(image: AssetImage('assets/images/logo.png')),
          SizedBox(width: 15, height: 0),
        ],
      ),
      drawer: DrawerMenu(),
      body: _isLoading
            ? const Center(
              child: SizedBox.expand(
              child: Center(
                child: CircularProgressIndicator(),
              ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await _fetchClients(page: 0);
                    },
                    child: ListView.builder(
                      itemCount: _clients.length,
                      itemBuilder: (context, index) {
                        return _buildClientCard(_clients[index]);
                      },
                    ),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: _page > 0 && !_isLoading
                            ? () async {
                                await _fetchClients(page: _page - 1);
                              }
                            : null,
                        child: const Icon(Icons.arrow_back),
                      ),
                      Text("${_page + 1}"),
                      ElevatedButton(
                        onPressed: _hasMore && !_isLoading
                            ? () async {
                                await _fetchClients(page: _page + 1);
                              }
                            : null,
                        child: const Icon(Icons.arrow_forward),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
