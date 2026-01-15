import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(const AnimatedLampApp());
}

class AnimatedLampApp extends StatelessWidget {
  const AnimatedLampApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animated Lamp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),
      home: const LampScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LampScreen extends StatefulWidget {
  const LampScreen({super.key});

  @override
  State<LampScreen> createState() => _LampScreenState();
}

class _LampScreenState extends State<LampScreen> with TickerProviderStateMixin {
  bool _isLampOn = false;
  late AnimationController _glowController;
  late AnimationController _stringController;
  late Animation<double> _glowAnimation;
  double _stringPullOffset = 0;

  @override
  void initState() {
    super.initState();
    
    // Glow animation for the lamp
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    // String pull animation
    _stringController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _stringController.dispose();
    super.dispose();
  }

  void _toggleLamp() {
    setState(() {
      _isLampOn = !_isLampOn;
      if (_isLampOn) {
        _glowController.forward();
      } else {
        _glowController.reverse();
      }
    });
  }

  void _onStringDragUpdate(DragUpdateDetails details) {
    setState(() {
      _stringPullOffset = math.max(0, math.min(50, _stringPullOffset + details.delta.dy));
    });
  }

  void _onStringDragEnd(DragEndDetails details) {
    if (_stringPullOffset > 20) {
      _toggleLamp();
    }
    setState(() {
      _stringPullOffset = 0;
    });
    _stringController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isLampOn ? const Color(0xFF2C2C2C) : const Color(0xFF1A1A1A),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _isLampOn
                ? [
                    const Color(0xFF2C2C2C),
                    const Color(0xFF1A1A1A),
                  ]
                : [
                    const Color(0xFF0A0A0A),
                    const Color(0xFF1A1A1A),
                  ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lamp fixture
              Container(
                width: 100,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 10),
              
              // Pull String
              GestureDetector(
                onVerticalDragUpdate: _onStringDragUpdate,
                onVerticalDragEnd: _onStringDragEnd,
                child: Column(
                  children: [
                    // String line
                    Container(
                      width: 2,
                      height: 40 + _stringPullOffset,
                      color: Colors.grey[600],
                    ),
                    // String handle
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Lamp bulb with glow effect
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    width: 150,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: _isLampOn
                          ? [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.6 * _glowAnimation.value),
                                blurRadius: 60 * _glowAnimation.value,
                                spreadRadius: 30 * _glowAnimation.value,
                              ),
                              BoxShadow(
                                color: Colors.yellow.withOpacity(0.4 * _glowAnimation.value),
                                blurRadius: 100 * _glowAnimation.value,
                                spreadRadius: 50 * _glowAnimation.value,
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Container(
                        width: 120,
                        height: 160,
                        decoration: BoxDecoration(
                          color: _isLampOn
                              ? Color.lerp(
                                  Colors.grey[700],
                                  Colors.amber[300],
                                  _glowAnimation.value,
                                )
                              : Colors.grey[700],
                          borderRadius: BorderRadius.circular(60),
                          border: Border.all(
                            color: Colors.grey[600]!,
                            width: 2,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Bulb filament effect when on
                            if (_isLampOn)
                              Center(
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 300),
                                  opacity: _glowAnimation.value,
                                  child: Container(
                                    width: 80,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      gradient: RadialGradient(
                                        colors: [
                                          Colors.yellow[100]!,
                                          Colors.amber[300]!.withOpacity(0.5),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            // Bulb base
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(60),
                                    bottomRight: Radius.circular(60),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 60),
              
              // Status text
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: 0.7,
                child: Text(
                  _isLampOn ? 'Lamp is ON' : 'Lamp is OFF',
                  style: TextStyle(
                    color: _isLampOn ? Colors.amber[200] : Colors.grey[600],
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2,
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Instruction text
              Text(
                'Pull the string to toggle',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
