import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(const ElementsApp());
}

class ElementsApp extends StatelessWidget {
  const ElementsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alkuaineharjoitukset',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class ElementItem {
  final String name;
  final String symbol;
  ElementItem(this.name, this.symbol);
  factory ElementItem.fromMap(Map<String, dynamic> m) =>
      ElementItem(m['name'] as String, m['symbol'] as String);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<ElementItem>> _futureData;

  @override
  void initState() {
    super.initState();
    _futureData = _loadData();
  }

  Future<List<ElementItem>> _loadData() async {
    final raw = await rootBundle.loadString('assets/elements_fi.json');
    final List<dynamic> data = jsonDecode(raw);
    return data
        .map((e) => ElementItem.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ElementItem>>(
      future: _futureData,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            body: Center(
                child: Text('Datan lataus epäonnistui: ${snapshot.error}')),
          );
        }
        final items = snapshot.data!;
        return Scaffold(
          appBar: AppBar(title: const Text('Alkuaineharjoitukset')),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Valitse harjoitus',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.abc),
                      label:
                          const Text('Näytetään lyhenne - valitse oikea nimi'),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuizScreen(
                                items: items,
                                mode: QuizMode.symbolToName,
                              ),
                            ));
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.label),
                      label:
                          const Text('Näytetään nimi - valitse oikea lyhenne'),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuizScreen(
                                items: items,
                                mode: QuizMode.nameToSymbol,
                              ),
                            ));
                      },
                    ),
                    const SizedBox(height: 36),
                    const Text(
                        'Kumpikin harjoitus käyttää samaa dataa. Kierros on 20 kysymystä.',
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

enum QuizMode { symbolToName, nameToSymbol }

class QuizScreen extends StatefulWidget {
  final List<ElementItem> items;
  final QuizMode mode;
  const QuizScreen({super.key, required this.items, required this.mode});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const int totalQuestions = 20;
  late List<ElementItem> _pool;
  int _index = 0;
  int _correct = 0;
  late Random _rng;
  late List<_Q> _questions;
  bool _locked = false;
  int? _selected;

  @override
  void initState() {
    super.initState();
    _rng = Random();
    _pool = List<ElementItem>.from(widget.items);
    _pool.shuffle(_rng);
    if (_pool.length < totalQuestions) {
      // If data is smaller than 20, we cycle to reach 20.
      while (_pool.length < totalQuestions) {
        _pool.addAll(widget.items);
      }
    }
    _pool = _pool.take(totalQuestions).toList();
    _questions = _pool.map((e) => _makeQuestion(e)).toList();
  }

  _Q _makeQuestion(ElementItem correct) {
    // pick two unique distractors
    final candidates = List<ElementItem>.from(widget.items);
    candidates.removeWhere((x) => x.symbol == correct.symbol);
    candidates.shuffle(_rng);
    final distractors = candidates.take(2).toList();

    List<String> options;
    String prompt;
    int correctIndex;

    if (widget.mode == QuizMode.symbolToName) {
      prompt = correct.symbol;
      options = [correct.name, distractors[0].name, distractors[1].name];
    } else {
      prompt = correct.name;
      options = [correct.symbol, distractors[0].symbol, distractors[1].symbol];
    }
    options.shuffle(_rng);
    correctIndex = options.indexOf(
        widget.mode == QuizMode.symbolToName ? correct.name : correct.symbol);
    return _Q(prompt: prompt, options: options, correctIndex: correctIndex);
  }

  void _choose(int i) {
    if (_locked) return;
    setState(() {
      _selected = i;
      _locked = true;
      if (i == _questions[_index].correctIndex) _correct++;
    });
  }

  void _next() {
    if (_index + 1 >= _questions.length) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ResultScreen(total: _questions.length, correct: _correct),
          ));
      return;
    }
    setState(() {
      _index++;
      _locked = false;
      _selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_index];
    final isSymbolToName = widget.mode == QuizMode.symbolToName;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSymbolToName ? 'Lyhenne -> nimi' : 'Nimi -> lyhenne'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Kysymys ${_index + 1} / ${_questions.length}',
                        style: const TextStyle(fontSize: 16)),
                    Text('Oikein: $_correct',
                        style: const TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          q.prompt,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 40, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        for (int i = 0; i < q.options.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: ElevatedButton(
                              onPressed: () => _choose(i),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 12),
                                backgroundColor: _locked
                                    ? (i == q.correctIndex
                                        ? Colors.green[300]
                                        : (i == _selected
                                            ? Colors.red[300]
                                            : null))
                                    : null,
                              ),
                              child: Text(q.options[i],
                                  style: const TextStyle(fontSize: 18)),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: _next,
                              icon: const Icon(Icons.navigate_next),
                              label: Text(_index + 1 >= _questions.length
                                  ? 'Tuloksiin'
                                  : 'Seuraava'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Q {
  final String prompt;
  final List<String> options;
  final int correctIndex;
  _Q({required this.prompt, required this.options, required this.correctIndex});
}

class ResultScreen extends StatelessWidget {
  final int total;
  final int correct;
  const ResultScreen({super.key, required this.total, required this.correct});

  @override
  Widget build(BuildContext context) {
    final percent = ((correct / total) * 100).toStringAsFixed(1);
    return Scaffold(
      appBar: AppBar(title: const Text('Tulos')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Oikeita vastauksia: $correct / $total',
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 8),
                Text('Onnistumisprosentti: $percent %',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (route) => false);
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Takaisin valikkoon'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
