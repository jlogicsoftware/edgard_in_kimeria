import 'package:edgard_in_kimeria/edgard_in_kimeria.dart';
import 'package:flutter/material.dart';

class MainMenu extends StatelessWidget {
  final EdgardInKimeria game;

  const MainMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(10.0),
          height: double.infinity,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.all(
              Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Edgard in Kimeria',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 200,
                height: 75,
                child: ElevatedButton(
                  onPressed: () {
                    game.isGameStarted = true;
                    game.overlays.remove('MainMenu');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Play',
                    style: TextStyle(
                      fontSize: 40.0,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '''Use WASD or Arrow Keys for movement.
J to jump. K to attack. L to interact.
Collect as many stars as you can and avoid enemies!''',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
