import 'package:_abm/presentation/bottomscreen.dart/calculatescreen.dart';
import 'package:_abm/presentation/bottomscreen.dart/lsitscreen.dart';
import 'package:_abm/presentation/bottomscreen.dart/profilescreen.dart';
import 'package:_abm/services/undo_redo_service.dart';
import 'package:_abm/theme/theme_manager.dart';
import 'package:flutter/material.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 200,
            color: Colors.blue,
          ),
          SizedBox(height: 10),
          Row(
            children: [
              SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: IconButton(
                    onPressed: () {
                      themeManager.setTheme(ThemeMode.light);
                    },
                    icon: Icon(Icons.light_mode),
                    color: Colors.black,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: IconButton(
                    onPressed: () {
                      themeManager.setTheme(ThemeMode.dark);
                    },
                    icon: Icon(Icons.dark_mode),
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          GestureDetector(
            child: ListTile(
              title: Text('Home Page'),
              leading: IconButton(onPressed: () {}, icon: Icon(Icons.home)),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => ListScreen()));
            },
            child: ListTile(
              title: Text('List Page'),
              leading: IconButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => ListScreen()));
                  },
                  icon: Icon(Icons.list)),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => CalculateScreen()));
            },
            child: ListTile(
              title: Text('Calculator Page'),
              leading: IconButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => CalculateScreen()));
                  },
                  icon: Icon(Icons.calculate)),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ProfileScreen()));
            },
            child: ListTile(
              title: Text('Profile Page'),
              leading: IconButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ProfileScreen()));
                  },
                  icon: Icon(Icons.account_circle_rounded)),
            ),
          ),
          ListenableBuilder(
            listenable: UndoRedoManager(),
            builder: (context, _) {
              final manager = UndoRedoManager();
              return Column(
                children: [
                  ListTile(
                    title: const Text('Undo'),
                    leading: const Icon(Icons.undo),
                    enabled: manager.canUndo,
                    onTap: manager.canUndo
                        ? () async {
                            await manager.undo();
                            if (context.mounted)
                              Navigator.pop(context); // Close drawer
                          }
                        : null,
                  ),
                  ListTile(
                    title: const Text('Redo'),
                    leading: const Icon(Icons.redo),
                    enabled: manager.canRedo,
                    onTap: manager.canRedo
                        ? () async {
                            await manager.redo();
                            if (context.mounted)
                              Navigator.pop(context); // Close drawer
                          }
                        : null,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
