import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const ScientificCalculatorApp());
}

class ScientificCalculatorApp extends StatelessWidget {
  const ScientificCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ماشین حساب مهندسی پیشرفته',
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
          elevation: 2,
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
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList('calc_history') ?? [];
    });
  }

  Future<void> _saveToHistory(String record) async {
    final prefs = await SharedPreferences.getInstance();
    _history.insert(0, record);
    await prefs.setStringList('calc_history', _history);
    setState(() {});
  }

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
      String parsed = _expression
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('π', '3.141592653589793')
          .replaceAll('e', '2.718281828459045')
          .replaceAll('√', 'sqrt');

      Parser p = Parser();
      Expression exp = p.parse(parsed);
      ContextModel cm = ContextModel();
      double eval = (exp.evaluate(EvaluationType.REAL, cm) as num).toDouble();

      String formattedResult = eval.toStringAsFixed(eval.truncateToDouble() == eval ? 0 : 4);
      setState(() {
        _result = formattedResult;
      });

      _saveToHistory('$_expression = $formattedResult');
    } catch (e) {
      setState(() {
        _result = 'خطا در محاسبه';
      });
    }
  }

  void _showHistoryModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1F26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('تاریخچه محاسبات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                    tooltip: 'پاک کردن',
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('calc_history');
                      setState(() => _history.clear());
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const Divider(color: Colors.white24),
              Expanded(
                child: _history.isEmpty
                    ? const Center(child: Text('تاریخچه‌ای وجود ندارد.'))
                    : ListView.builder(
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(_history[index], style: const TextStyle(fontSize: 16)),
                            onTap: () {
                              final parts = _history[index].split(' = ');
                              if (parts.isNotEmpty) {
                                setState(() {
                                  _expression = parts[0];
                                });
                              }
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttons = [
      ['AC', 'DEL', '(', ')', '÷'],
      ['sin', 'cos', 'tan', '^', '×'],
      ['7', '8', '9', '√', '-'],
      ['4', '5', '6', 'log', '+'],
      ['1', '2', '3', 'ln', '='],
      ['0', '.', 'π', 'e', '%'],
    ];

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: IconButton(
              icon: const Icon(Icons.history, color: Color(0xFF00E676)),
              onPressed: _showHistoryModal,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.bottomRight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
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
                                    : ['÷', '×', '-', '+'].contains(btn)
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
  final TextEditingController _controller = TextEditingController(text: 'x^2');
  String _currentFormula = 'x^2';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'فرمول تابع f(x)',
              hintText: 'مثال: x^2 یا sin(x)',
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
                painter: GraphPainter(_currentFormula),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GraphPainter extends CustomPainter {
  final String formula;
  GraphPainter(this.formula);

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1;

    final paintAxes = Paint()
      ..color = Colors.white54
      ..strokeWidth = 2;

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

    try {
      Parser p = Parser();
      Expression exp = p.parse(formula.replaceAll('×', '*').replaceAll('÷', '/'));
      ContextModel cm = ContextModel();
      Variable xVar = Variable('x');

      Path path = Path();
      bool first = true;

      for (double pixelX = 0; pixelX <= size.width; pixelX += 2) {
        double xVal = (pixelX - center.dx) / scale;
        cm.bindVariable(xVar, Number(xVal));
        try {
          double yVal = (exp.evaluate(EvaluationType.REAL, cm) as num).toDouble();
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
    } catch (_) {}
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) => oldDelegate.formula != formula;
}
