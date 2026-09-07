import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

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

  Future<void> _exportPdf() async {
    if (_history.isEmpty) return;
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blueGrey800,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Calculator History Report',
                        style: pw.TextStyle(color: PdfColors.white, fontSize: 16, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        DateTime.now().toString().split(' ')[0],
                        style: const pw.TextStyle(color: PdfColors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  headers: ['No', 'Calculation & Result'],
                  data: List.generate(
                    _history.length,
                    (index) => ['${index + 1}', _history[index]],
                  ),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellPadding: const pw.EdgeInsets.all(8),
                ),
              ],
            );
          },
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'calculator_history.pdf',
      );
    } catch (_) {}
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
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                        tooltip: 'خروجی PDF',
                        onPressed: _exportPdf,
                      ),
                      IconButton(
                        icon: const Icon(Icons.share, color: Color(0xFF00E676)),
                        tooltip: 'اشتراک‌گذاری متنی',
                        onPressed: () {
                          if (_history.isNotEmpty) {
                            Share.share('📊 تاریخچه محاسبات:\n\n${_history.join('\n')}');
                          }
                        },
                      ),
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
                  )
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
                            trailing: const Icon(Icons.arrow_back_ios_new, size: 14, color: Colors.white30),
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
  List<FlSpot> _spots = [];

  void _plotGraph() {
    final formula = _controller.text;
    List<FlSpot> newSpots = [];
    try {
      Parser p = Parser();
      Expression exp = p.parse(formula.replaceAll('×', '*').replaceAll('÷', '/'));
      ContextModel cm = ContextModel();
      Variable xVar = Variable('x');

      for (double x = -10; x <= 10; x += 0.5) {
        cm.bindVariable(xVar, Number(x));
        double y = (exp.evaluate(EvaluationType.REAL, cm) as num).toDouble();
        if (!y.isNaN && !y.isInfinite && y.abs() < 100) {
          newSpots.add(FlSpot(x, y));
        }
      }
    } catch (_) {}

    setState(() {
      _spots = newSpots;
    });
  }

  @override
  void initState() {
    super.initState();
    _plotGraph();
  }

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
                onPressed: _plotGraph,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _spots.isEmpty
                ? const Center(child: Text('فرمول وارد شده معتبر نیست.'))
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true),
                      titlesData: const FlTitlesData(
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true, border: Border.all(color: Colors.white24)),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _spots,
                          isCurved: true,
                          color: const Color(0xFF00E676),
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
