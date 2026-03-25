import 'package:flutter/material.dart';
import '../../core/theme.dart';

class SwipeToConfirm extends StatefulWidget {
  final Future<void> Function() onConfirm;
  final String text;

  const SwipeToConfirm({
    Key? key,
    required this.onConfirm,
    this.text = 'Swipe to Confirm',
  }) : super(key: key);

  @override
  _SwipeToConfirmState createState() => _SwipeToConfirmState();
}

class _SwipeToConfirmState extends State<SwipeToConfirm> {
  double _position = 0.0;
  bool _isConfirmed = false;
  bool _isLoading = false;

  void _onPanUpdate(DragUpdateDetails details, double maxWidth) {
    if (_isConfirmed || _isLoading) return;

    setState(() {
      _position += details.delta.dx;
      if (_position < 0) _position = 0;
      if (_position > maxWidth - 60) _position = maxWidth - 60; // 60 is knob width
    });
  }

  void _onPanEnd(DragEndDetails details, double maxWidth) async {
    if (_isConfirmed || _isLoading) return;

    if (_position >= maxWidth - 60 - 20) { // Near the end
      setState(() {
        _position = maxWidth - 60;
        _isLoading = true;
      });
      
      try {
        await widget.onConfirm();
        if (mounted) {
          setState(() {
            _isConfirmed = true;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _position = 0;
            _isLoading = false;
          });
        }
      }
    } else {
      setState(() {
        _position = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        return Container(
          height: 60,
          decoration: BoxDecoration(
            color: _isConfirmed ? AppTheme.statusSuccess : AppTheme.bgOffWhite,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppTheme.textCharcoal, width: 2),
          ),
          child: Stack(
            children: [
              // Background Text
              Center(
                child: Text(
                  _isConfirmed ? 'Confirmed!' : widget.text,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isConfirmed ? Colors.white : Colors.black54,
                  ),
                ),
              ),
              // Swipe Knob
              if (!_isConfirmed)
                Positioned(
                  left: _position,
                  child: GestureDetector(
                    onPanUpdate: (d) => _onPanUpdate(d, maxWidth),
                    onPanEnd: (d) => _onPanEnd(d, maxWidth),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.accentTerracotta,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.textCharcoal, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 0))
                        ],
                      ),
                      child: Center(
                        child: _isLoading 
                          ? const SizedBox(
                              width: 24, height: 24, 
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            )
                          : const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
