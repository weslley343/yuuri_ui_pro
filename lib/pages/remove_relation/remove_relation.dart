import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class RemoveRelation extends StatefulWidget {
  const RemoveRelation({super.key});

  @override
  State<RemoveRelation> createState() => _RemoveRelationState();
}

class _RemoveRelationState extends State<RemoveRelation> {
  final _formKey = GlobalKey<FormState>();
  String identifier = '';
  String feedbackMessage = '';
  bool isLoading = false;

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('acetoken');
  }

  Future<void> submitData() async {
    setState(() {
      isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final server = prefs.getString('server') ?? 'localhost';
    final uriString = '$server/relation/professional';

    final url = Uri.parse(uriString);

    String? token = await getAccessToken();

    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'identifier': identifier}),
    );

    if (response.statusCode == 200) {
      setState(() {
        feedbackMessage = '';
        identifier = '';
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dados enviados com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      _formKey.currentState?.reset();
    } else {
      setState(() {
        feedbackMessage = '';
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha ao enviar dados: ${response.statusCode}'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remover Cliente'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Identifier'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o identificador';
                  }
                  return null;
                },
                onSaved: (value) {
                  identifier = value!;
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  isLoading
                      ? const CircularProgressIndicator()
                      : Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                _formKey.currentState!.save();
                                submitData();
                              }
                            },
                            child: const Text('Enviar'),
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 20),
              // Text(feedbackMessage),
            ],
          ),
        ),
      ),
    );
  }
}
