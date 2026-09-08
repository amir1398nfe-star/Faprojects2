import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  runApp(const ScientificCalculatorApp());
}

class ScientificCalculatorApp extends StatelessWidget {
  const ScientificCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ماشین حساب مهندسی',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF101216),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E676),
          surface: Color(0xFF1C1F26),
        ),
      ),
      home: const MainTabScreen(),
    );
  }
}

class MainTabScreen extends StatelessWidget {
  const MainTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ماشین حساب مهندسی'),
          centerTitle: true,
          backgroundColor: const Color(0xFF1C1F26),
          bottom: const TabBar(
            indicatorColor: Color(0xFF00E676),
            labelColor: Color(0xFF00E676),
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(icon: Icon(Icons.calculate), text: 'محاسبات'),
              Tab(icon: Icon(Icons.show_chart), text: 'رسم نمودار'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CalculatorTab(),
            GraphTab(),
          ],
        ),
      ),
    );
  }
}

class CalculatorTab extends StatefulWidget {
  const CalculatorTab({super.key});

  @override
  State<CalculatorTab> createState() => _CalculatorTabState();
}

class _CalculatorTabState extends State<CalculatorTab> {
  String _expression = '';
  String _result = '0';

  void _onButtonPressed(String btnText) {
    setState(() {
      if (btnText == 'AC') {
        _expression = '';
        _result = '0';
      } else if (btnText == 'DEL') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
      } else if (btnText == '=') {
        _calculateResult();
      } else {
        _expression += btnText;
      }
    });
  }

  void _calculateResult() {
    if (_expression.isEmpty) return;
    try {
      double eval = MathEvaluator.eval(_expression);
      setState(() {
        _result = eval.toStringAsFixed(eval.truncateToDouble() == eval ? 0 : 4);
      });
    } catch (_) {
      setState(() {
        _result = 'خطا در محاسبه';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttons = [
      ['AC', 'DEL', '(', ')', '/'],
      ['sin', 'cos', 'tan', '^', '*'],
      ['7', '8', '9', 'sqrt', '-'],
      ['4', '5', '6', 'log', '+'],
      ['1', '2', '3', 'ln', '='],
      ['0', '.', 'pi', 'e', '%'],
    ];

    return Column(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.bottomRight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAlignment.end,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Text(_expression.isEmpty ? '0' : _expression, style: const TextStyle(fontSize: 24, color: Colors.white70)),
                ),
                const SizedBox(height: 8),
                Text(_result, style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        ),
        const Divider(color: Colors.white10),
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Column(
              children: buttons.map((row) {
                return Expanded(
                  child: Row(
                    children: row.map((btn) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: Material(
                            color: btn == '='
                                ? const Color(0xFF00E676)
                                : ['AC', 'DEL'].contains(btn)
                                    ? const Color(0xFFFF5252)
                                    : ['/', '*', '-', '+'].contains(btn)
                                        ? const Color(0xFF29B6F6)
                                        : const Color(0xFF1C1F26),
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _onButtonPressed(btn),
                              child: Center(
                                child: Text(
                                  btn,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: btn == '=' ? Colors.black : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class GraphTab extends StatefulWidget {
  const GraphTab({super.key});

  @override
  State<GraphTab> createState() => _GraphTabState();
}

class _GraphTabState extends State<GraphTab> {
  final TextEditingController _controller = TextEditingController(text: 'x * x');
  String _currentFormula = 'x * x';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'فرمول f(x)',
              hintText: 'مثال: x * x یا sin(x)',
              filled: true,
              fillColor: const Color(0xFF1C1F26),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.play_arrow, color: Color(0xFF00E676)),
                onPressed: () {
                  setState(() {
                    _currentFormula = _controller.text;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1F26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: CustomPaint(
                painter: SimpleGraphPainter(_currentFormula),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SimpleGraphPainter extends CustomPainter {
  final String formula;
  SimpleGraphPainter(this.formula);

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()..color = Colors.white10..strokeWidth = 1;
    final paintAxes = Paint()..color = Colors.white54..strokeWidth = 2;
    final paintLine = Paint()
      ..color = const Color(0xFF00E676)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 20;

    for (double x = -10; x <= 10; x += 2) {
      double dx = center.dx + x * scale;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paintGrid);
    }
    for (double y = -10; y <= 10; y += 2) {
      double dy = center.dy - y * scale;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paintGrid);
    }

    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), paintAxes);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), paintAxes);

    if (formula.isEmpty) return;

    Path path = Path();
    bool first = true;

    for (double pixelX = 0; pixelX <= size.width; pixelX += 2) {
      double xVal = (pixelX - center.dx) / scale;
      try {
        double yVal = MathEvaluator.evalWithX(formula, xVal);
        if (yVal.isNaN || yVal.isInfinite) {
          first = true;
          continue;
        }
        double pixelY = center.dy - (yVal * scale);
        if (pixelY < -size.height || pixelY > size.height * 2) {
          first = true;
          continue;
        }

        if (first) {
          path.moveTo(pixelX, pixelY);
          first = false;
        } else {
          path.lineTo(pixelX, pixelY);
        }
      } catch (_) {
        first = true;
      }
    }

    canvas.drawPath(path, paintLine);
  }

  @override
  bool shouldRepaint(covariant SimpleGraphPainter oldDelegate) => oldDelegate.formula != formula;
}

class MathEvaluator {
  static double evalWithX(String expr, double xVal) {
    String substituted = expr.replaceAll('x', '($xVal)');
    return eval(substituted);
  }

  static double eval(String expression) {
    String clean = expression
        .replaceAll('pi', '${math.pi}')
        .replaceAll('e', '${math.e}')
        .replaceAll(' ', '');
    return _parseAddSub(clean);
  }

  static double _parseAddSub(String str) {
    if (str.isEmpty) return 0.0;
    int depth = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (str[i] == ')') depth++;
      if (str[i] == '(') depth--;
      if (depth == 0) {
        if (str[i] == '+' && i > 0 && !_isOp(str[i - 1])) {
          return _parseAddSub(str.substring(0, i)) + _parseMulDiv(str.substring(i + 1));
        }
        if (str[i] == '-' && i > 0 && !_isOp(str[i - 1])) {
          return _parseAddSub(str.substring(0, i)) - _parseMulDiv(str.substring(i + 1));
        }
      }
    }
    return _parseMulDiv(str);
  }

  static double _parseMulDiv(String str) {
    int depth = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (str[i] == ')') depth++;
      if (str[i] == '(') depth--;
      if (depth == 0) {
        if (str[i] == '*') {
          return _parseMulDiv(str.substring(0, i)) * _parsePow(str.substring(i + 1));
        }
        if (str[i] == '/') {
          return _parseMulDiv(str.substring(0, i)) / _parsePow(str.substring(i + 1));
        }
      }
    }
    return _parsePow(str);
  }

  static double _parsePow(String str) {
    int depth = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (str[i] == ')') depth++;
      if (str[i] == '(') depth--;
      if (depth == 0 && str[i] == '^') {
        return math.pow(_parsePow(str.substring(0, i)), _parseUnary(str.substring(i + 1))).toDouble();
      }
    }
    return _parseUnary(str);
  }

  static double _parseUnary(String str) {
    if (str.startsWith('-')) return -_parseUnary(str.substring(1));
    if (str.startsWith('+')) return _parseUnary(str.substring(1));
    if (str.startsWith('sin(') && str.endsWith(')')) {
      return math.sin(_parseAddSub(str.substring(4, str.length - 1)));
    }
    if (str.startsWith('cos(') && str.endsWith(')')) {
      return math.cos(_parseAddSub(str.substring(4, str.length - 1)));
    }
    if (str.startsWith('tan(') && str.endsWith(')')) {
      return math.tan(_parseAddSub(str.substring(4, str.length - 1)));
    }
    if (str.startsWith('sqrt(') && str.endsWith(')')) {
      return math.sqrt(_parseAddSub(str.substring(5, str.length - 1)));
    }
    if (str.startsWith('ln(') && str.endsWith(')')) {
      return math.log(_parseAddSub(str.substring(3, str.length - 1)));
    }
    if (str.startsWith('log(') && str.endsWith(')')) {
      return math.log(_parseAddSub(str.substring(4, str.length - 1))) / math.ln10;
    }
    if (str.startsWith('(') && str.endsWith(')')) {
      return _parseAddSub(str.substring(1, str.length - 1));
    }
    return double.parse(str);
  }

  static bool _isOp(String ch) => ch == '+' || ch == '-' || ch == '*' || ch == '/' || ch == '^';
}
