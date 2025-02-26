import 'package:flutter/material.dart';

class RainbowFloatingActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isChatOpen;
  final IconData icon;

  const RainbowFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.isChatOpen,
    required this.icon,
  });

  @override
  State<RainbowFloatingActionButton> createState() =>
      _RainbowFloatingActionButtonState();
}

class _RainbowFloatingActionButtonState
    extends State<RainbowFloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _colorAnimation = TweenSequence<Color?>([
      TweenSequenceItem(
        weight: 1.0,
        tween: ColorTween(begin: Colors.red, end: Colors.orange),
      ),
      TweenSequenceItem(
        weight: 1.0,
        tween: ColorTween(begin: Colors.orange, end: Colors.yellow),
      ),
      TweenSequenceItem(
        weight: 1.0,
        tween: ColorTween(begin: Colors.yellow, end: Colors.green),
      ),
      TweenSequenceItem(
        weight: 1.0,
        tween: ColorTween(begin: Colors.green, end: Colors.blue),
      ),
      TweenSequenceItem(
        weight: 1.0,
        tween: ColorTween(begin: Colors.blue, end: Colors.purple),
      ),
      TweenSequenceItem(
        weight: 1.0,
        tween: ColorTween(begin: Colors.purple, end: Colors.red),
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return FloatingActionButton(
          backgroundColor: _colorAnimation.value,
          onPressed: widget.onPressed,
          child: Icon(widget.isChatOpen ? Icons.close : widget.icon),
        );
      },
    );
  }
}
