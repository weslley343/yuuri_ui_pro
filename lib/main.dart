import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yuuri_ui_pro/pages/add_relation/add_relation.dart';
import 'package:yuuri_ui_pro/pages/client/client.dart';
import 'package:yuuri_ui_pro/pages/congiruration/configuration.dart';
import 'package:yuuri_ui_pro/pages/detail_avaliation/detail_avaliation.dart';
import 'package:yuuri_ui_pro/pages/detail_sugestions/detail_sugestions.dart';
import 'package:yuuri_ui_pro/pages/home/home.dart';
import 'package:yuuri_ui_pro/pages/list_scales/list_scales.dart';
import 'package:yuuri_ui_pro/pages/login/login.dart';
import 'package:yuuri_ui_pro/pages/remove_relation/remove_relation.dart';

final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const Home(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const Login(),
    ),
    GoRoute(
      path: '/recsys/:avaliationid/:clientid/:scaleid',
      name: 'recsys',
      builder: (context, state) {
        final avaliationId = state.pathParameters['avaliationid'] ?? '0';
        // You need to extract clientId and scaleId from state.pathParameters or queryParameters as appropriate
        final clientId = state.pathParameters['clientid'] ?? '';
        final scaleId = state.pathParameters['scaleid'] ?? '';
        return DetailSugestion(
          avaliationId: avaliationId,
          clientId: clientId,
          scaleId: scaleId,
        );
      },
    ),
    GoRoute(
      path: '/client/:id/:name',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final name = state.pathParameters['name']!;
        return ClientPage(id: id, name: name);
      },
    ),
    GoRoute(
      path: '/listscales/:client',
      builder: (context, state) {
        final client = state.pathParameters['client']!;
        return ListScales(client: client);
      },
    ),
    GoRoute(
      path: '/avaliationdetail/:id',
      name: 'avaliationdetail',
      builder: (context, state) {
        final avaliationId = state.pathParameters['id'] ?? '0';

        return DetailAvaliation(avaliationId: avaliationId);
      },
    ),

    GoRoute(
      path: '/addrelation',
      name: 'addrelation',
      builder: (context, state) => const AddRelation(),
    ),

    // GoRoute(
    //     path: '/configuration',
    //     name: 'configuration',
    //     builder: (context, state) => const Configuration()),
    GoRoute(
      path: '/removerelation',
      name: 'removerelation',
      builder: (context, state) => const RemoveRelation(),
    ),
     GoRoute(
      path: '/configuration',
      name: 'configuration',
      builder: (context, state) => const Configuration(),
    ),
  ],
);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      showSemanticsDebugger: false,
      // debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlue, // Cor base azul claro
          brightness: Brightness.dark, // Garante modo escuro
        ),
      ),
      routerConfig: _router,
    );
  }
}
