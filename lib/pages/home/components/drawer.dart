import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Text('v 0.1.0 (^~^)'),
          ),
          ListTile(
            title: const Text('Adicionar cliente'),
            onTap: () {
              context.push('/addrelation');
            },
            leading: const Icon(Icons.add),
          ),
          ListTile(
            title: const Text('Remover cliente'),
            onTap: () {
              context.push('/removerelation');
            },
            leading: const Icon(Icons.remove),
          ),
          ListTile(
            title: const Text('Configurações'),
            onTap: () {
              context.push('/configuration');
            },
            leading: const Icon(CupertinoIcons.gear),
          ),
          ListTile(
            title: const Text(
              'Sair',
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: () {
              SystemNavigator.pop();
            },
            leading: const Icon(
              Icons.exit_to_app_outlined,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}
