import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _serverController = TextEditingController();
  final _sugestionServerController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    _serverController.text = prefs.getString('server') ?? '';
    _sugestionServerController.text = prefs.getString('sugestion_server') ?? '';
    _emailController.text = prefs.getString('email') ?? '';
    _passwordController.text = prefs.getString('password') ?? '';
  }

  Future<void> _signin() async {
    final server = _serverController.text.trim();
    final sugestionServer = _sugestionServerController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (server.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage("Preencha todos os campos");
      return;
    }

    setState(() {
      _loading = true;
    });

    final url = '$server/professional/signin';

    try {
      final response = await _dio.post(
        url,
        data: {'email': email, 'password': password},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final data = response.data;

      if (data['signin'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('reftoken', data['reftoken']);
        await prefs.setString('acetoken', data['acetoken']);
        await prefs.setString('identifier', data['identifier']);
        await prefs.setString('id', data['id']);
        await prefs.setString('server', server);

        // Salva sugestion_server
        await prefs.setString('sugestion_server', sugestionServer);

        // Salva email e password
        await prefs.setString('email', email);
        await prefs.setString('password', password);

        _showMessage("Login bem-sucedido!");
        if (mounted) {
          context.goNamed('home');
        }
      } else {
        _showMessage("Credenciais inválidas.");
      }
    } on DioException catch (e) {
      String msg = 'Erro de conexão';
      if (e.response != null) {
        msg = 'Erro ${e.response?.statusCode}: ${e.response?.data}';
      } else if (e.message != null) {
        msg = e.message!;
      }
      _showMessage(msg);
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SingleChildScrollView(
        child: _loading
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 100.0),
                child: Center(child: CircularProgressIndicator()),
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: MediaQuery.of(context).size.height * 0.3,
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),

                      TextField(
                        controller: _serverController,
                        decoration: const InputDecoration(
                          labelText: "Servidor (ex: http://localhost:4000)",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _sugestionServerController,
                        decoration: const InputDecoration(
                          labelText:
                              "Sugestion Server (ex: http://localhost:4000)",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Senha",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            await _signin();
                          },
                          child: const Text('ENTRAR'),
                        ),
                      ),
                      const SizedBox(height: 42),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _serverController.dispose();
    _sugestionServerController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
