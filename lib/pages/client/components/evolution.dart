import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

class Evolution extends StatefulWidget {
  final String clientId;
  const Evolution({super.key, required this.clientId});

  @override
  State<Evolution> createState() => _EvolutionState();
}

class _EvolutionState extends State<Evolution> {
  List<dynamic> scales = [];
  dynamic selectedScale;
  List<dynamic> historic = [];
  List<dynamic> evolutionData = [];
  bool loadingScales = true;
  bool loadingHistoric = false;
  bool loadingEvolution = false;
  String? server;

  @override
  void initState() {
    super.initState();
    _loadServer();
  }

  Future<void> _loadServer() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      server = prefs.getString('server') ?? 'http://localhost:4000';
    });
    _fetchScales();
  }

  Future<void> _fetchScales() async {
    setState(() {
      loadingScales = true;
    });
    final url = Uri.parse('$server/scale/');
    final response = await http.get(
      url,
      headers: {'User-Agent': 'insomnia/10.2.0'},
    );
    if (response.statusCode == 200) {
      setState(() {
        scales = jsonDecode(response.body);
        loadingScales = false;
      });
    } else {
      setState(() {
        loadingScales = false;
      });
      // Handle error as needed
    }
  }

  Future<void> _fetchEvolution() async {
    if (selectedScale == null) return;
    setState(() {
      loadingEvolution = true;
      evolutionData = [];
    });
    final url = Uri.parse(
      '$server/avaliation/listevolutionbyarea/${widget.clientId}/${selectedScale['id']}',
    );
    final response = await http.get(
      url,
      headers: {'User-Agent': 'insomnia/10.2.0'},
    );
    if (response.statusCode == 200) {
      setState(() {
        evolutionData = jsonDecode(response.body);
        loadingEvolution = false;
      });
    } else {
      setState(() {
        loadingEvolution = false;
      });
      // Handle error as needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                loadingScales
                    ? const CircularProgressIndicator()
                    : Expanded(
                        child: DropdownButtonFormField<dynamic>(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color.fromARGB(255, 14, 11, 11),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                50,
                              ),
                              borderSide: BorderSide(
                                color: Colors.grey.shade400,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                20,
                              ),
                              borderSide: BorderSide(
                                color: Colors.grey.shade400,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                20,
                              ),
                              borderSide: BorderSide(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          dropdownColor: const Color.fromARGB(255, 14, 11, 11),
                          hint: const Text('Selecione a avaliação'),
                          value: selectedScale,
                          items: scales
                              .map<DropdownMenuItem<dynamic>>(
                                (scale) => DropdownMenuItem(
                                  value: scale,
                                  child: Text(scale['name']),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedScale = value;
                            });
                          },
                          menuMaxHeight: 350,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: selectedScale == null || loadingEvolution
                      ? null
                      : _fetchEvolution,
                  child: loadingEvolution
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                ),
              ],
            ),
          ),
          if (evolutionData.isNotEmpty)
            SizedBox(
              height: 400,
              child: loadingEvolution
                  ? const Center(child: CircularProgressIndicator())
                  : evolutionData.isEmpty
                  ? const Center(child: Text('Nenhuma evolução encontrada.'))
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: LineChart(
                        LineChartData(
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) =>
                                    Text('T${value.toInt() + 1}'),
                              ),
                            ),
                          ),
                          lineBarsData: evolutionData.map<LineChartBarData>((
                            domain,
                          ) {
                            final color = Color(
                              int.parse(
                                domain['color'].replaceFirst('#', '0xff'),
                              ),
                            );
                            final scores = domain['score'] as List;
                            final spots = scores
                                .asMap()
                                .entries
                                .map(
                                  (e) => FlSpot(
                                    e.key.toDouble(),
                                    (e.value as num).toDouble(),
                                  ),
                                )
                                .toList();
                            return LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: color,
                              barWidth: 3,
                              dotData: FlDotData(show: true),
                              belowBarData: BarAreaData(show: false),
                            );
                          }).toList(),
                          lineTouchData: LineTouchData(
                            enabled: true,
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((touchedSpot) {
                                  final domain =
                                      evolutionData[touchedSpot.barIndex];
                                  final label =
                                      domain['label'] != null &&
                                              domain['label'].length >
                                                  touchedSpot.spotIndex
                                          ? domain['label'][touchedSpot.spotIndex]
                                          : 'Valor: ${touchedSpot.y}';
                                  return LineTooltipItem(
                                    label,
                                    const TextStyle(color: Colors.white),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                          gridData: FlGridData(show: true),
                          borderData: FlBorderData(show: true),
                        ),
                      ),
                    ),
            ),
          if (evolutionData.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Domínio')),
                  DataColumn(label: Text('Cor')),
                ],
                rows: evolutionData.map<DataRow>((domain) {
                  final color = Color(
                    int.parse(domain['color'].replaceFirst('#', '0xff')),
                  );
                  return DataRow(
                    cells: [
                      DataCell(Text(domain['domain'] ?? '')),
                      DataCell(
                        Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
