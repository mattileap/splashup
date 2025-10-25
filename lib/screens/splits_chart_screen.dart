import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../l10n/app_localizations.dart';
import '../models/athlete_model.dart';
import '../models/chrono_model.dart';
import '../models/team_model.dart';

/// Screen that displays split analysis with interactive line chart
class SplitsChartScreen extends StatefulWidget {
  final Team team;
  final Athlete athlete;
  final List<Chrono> allChronos;

  const SplitsChartScreen({
    super.key,
    required this.team,
    required this.athlete,
    required this.allChronos,
  });

  @override
  State<SplitsChartScreen> createState() => _SplitsChartScreenState();
}

class _SplitsChartScreenState extends State<SplitsChartScreen> {
  // Filter state
  int? _selectedDistance;
  String? _selectedStyle;
  String _selectedType = 'All'; // 'Race', 'Training', 'All'
  int _numberOfChronos = 5;

  // Chart data
  List<ChartLineData> _chartLines = [];
  Set<String> _visibleLines = {};

  @override
  void initState() {
    super.initState();
    _initializeFilters();
    _updateChartData();
  }

  void _initializeFilters() {
    // Set default distance and style from available chronos
    final chronosWithSplits = widget.allChronos.where((c) => c.splits.isNotEmpty).toList();
    if (chronosWithSplits.isNotEmpty) {
      _selectedDistance = chronosWithSplits.first.distance;
      _selectedStyle = chronosWithSplits.first.style;
    }
  }

  void _updateChartData() {
    final filteredChronos = _getFilteredChronos();
    
    if (filteredChronos.isEmpty) {
      setState(() {
        _chartLines = [];
        _visibleLines = {};
      });
      return;
    }

    // Sort by date (most recent first) and take only requested number
    filteredChronos.sort((a, b) => b.date.compareTo(a.date));
    final chronosToShow = filteredChronos.take(_numberOfChronos).toList();

    // Calculate performance colors
    final times = chronosToShow.map((c) => c.finalTimeMs ?? 0).where((t) => t > 0).toList();
    if (times.isEmpty) {
      setState(() {
        _chartLines = [];
        _visibleLines = {};
      });
      return;
    }

    final bestTime = times.reduce(math.min);
    final worstTime = times.reduce(math.max);

    // Create chart lines
    final lines = <ChartLineData>[];
    for (final chrono in chronosToShow) {
      final spots = _createSpotsForChrono(chrono);
      if (spots.isNotEmpty) {
        final color = _getColorForPerformance(
          chrono.finalTimeMs ?? 0,
          bestTime,
          worstTime,
        );
        lines.add(ChartLineData(
          chrono: chrono,
          spots: spots,
          color: color,
        ));
      }
    }

    setState(() {
      _chartLines = lines;
      _visibleLines = lines.map((l) => l.chrono.id).toSet();
    });
  }

  List<Chrono> _getFilteredChronos() {
    return widget.allChronos.where((chrono) {
      // Must have splits
      if (chrono.splits.isEmpty) return false;

      // Filter by distance
      if (_selectedDistance != null && chrono.distance != _selectedDistance) {
        return false;
      }

      // Filter by style
      if (_selectedStyle != null && chrono.style != _selectedStyle) {
        return false;
      }

      // Filter by type
      if (_selectedType == 'Race' && chrono.type != 'Race') return false;
      if (_selectedType == 'Training' && chrono.type != 'Training') return false;

      return true;
    }).toList();
  }

  List<FlSpot> _createSpotsForChrono(Chrono chrono) {
    final spots = <FlSpot>[];
    
    // FIXED: Always start from origin (0, 0)
    spots.add(const FlSpot(0, 0));
    
    for (final split in chrono.splits) {
      if (split.time != null && split.time! > 0) {
        // X: distance, Y: time in seconds
        final x = split.distance.toDouble();
        final y = split.time! / 1000.0; // Convert ms to seconds
        spots.add(FlSpot(x, y));
      }
    }
    return spots;
  }

  Color _getColorForPerformance(int timeMs, int bestTime, int worstTime) {
    if (bestTime == worstTime) return Colors.blue;

    final range = worstTime - bestTime;
    final position = (timeMs - bestTime) / range; // 0.0 (best) -> 1.0 (worst)

    // Gradient: Green (best) -> Yellow -> Red (worst)
    if (position < 0.33) {
      return Colors.green.shade600;
    } else if (position < 0.66) {
      return Colors.amber.shade700;
    } else {
      return Colors.red.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.splitAnalysis} - ${widget.athlete.name}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildFiltersCard(l10n, theme),
          const SizedBox(height: 16),
          // Show empty state only in chart area, not full screen
          _chartLines.isEmpty
              ? _buildEmptyState(l10n)
              : _buildChartCard(l10n, theme),
          if (_chartLines.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildLegendCard(l10n, theme),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.show_chart, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              l10n.noSplitData,
              style: TextStyle(fontSize: 20, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tryDifferentFilter,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersCard(AppLocalizations l10n, ThemeData theme) {
    final styleDisplayNames = {
      'Freestyle': l10n.freestyle,
      'Butterfly': l10n.butterfly,
      'Backstroke': l10n.backstroke,
      'Breaststroke': l10n.breaststroke,
      'IM': l10n.im,
    };

    // Get available options
    final chronosWithSplits = widget.allChronos.where((c) => c.splits.isNotEmpty).toList();
    final availableDistances = chronosWithSplits.map((c) => c.distance).toSet().toList()..sort();
    final availableStyles = chronosWithSplits.map((c) => c.style).toSet().toList()..sort();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.filters, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            
            // Distance and Style
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedDistance,
                    decoration: InputDecoration(
                      labelText: l10n.distance,
                      isDense: true,
                    ),
                    items: availableDistances.map((d) {
                      return DropdownMenuItem(value: d, child: Text('$d m'));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDistance = value;
                        _updateChartData();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedStyle,
                    decoration: InputDecoration(
                      labelText: l10n.style,
                      isDense: true,
                    ),
                    items: availableStyles.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Text(styleDisplayNames[s] ?? s),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStyle = value;
                        _updateChartData();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Type chips
            Text(l10n.type, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(l10n.allTypes),
                  selected: _selectedType == 'All',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedType = 'All';
                        _updateChartData();
                      });
                    }
                  },
                ),
                ChoiceChip(
                  label: Text(l10n.race),
                  selected: _selectedType == 'Race',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedType = 'Race';
                        _updateChartData();
                      });
                    }
                  },
                ),
                ChoiceChip(
                  label: Text(l10n.training),
                  selected: _selectedType == 'Training',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedType = 'Training';
                        _updateChartData();
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Number of chronos slider
            Row(
              children: [
                Text(l10n.showRecords(_numberOfChronos), style: theme.textTheme.bodyMedium),
                Expanded(
                  child: Slider(
                    value: _numberOfChronos.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: _numberOfChronos.toString(),
                    onChanged: (value) {
                      setState(() {
                        _numberOfChronos = value.round();
                        _updateChartData();
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(AppLocalizations l10n, ThemeData theme) {
    final visibleChartLines = _chartLines
        .where((line) => _visibleLines.contains(line.chrono.id))
        .toList();

    if (visibleChartLines.isEmpty) {
      return Card(
        child: Container(
          height: 300,
          alignment: Alignment.center,
          child: Text(
            l10n.noVisibleLines,
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Calculate axis bounds
    final allSpots = visibleChartLines.expand((line) => line.spots).toList();
    final maxX = allSpots.map((s) => s.x).reduce(math.max);
    final minY = allSpots.map((s) => s.y).reduce(math.min); // Will be 0 now
    final maxY = allSpots.map((s) => s.y).reduce(math.max);
    
    // FIXED: Prevent zero interval when all times are the same
    // Since minY is now always 0, we use maxY for calculations
    final yRange = maxY - minY;
    final yPadding = yRange > 0 ? yRange * 0.05 : maxY * 0.1; // Reduced padding since we start from 0
    final horizontalInterval = yRange > 0 ? yRange / 5 : maxY / 5;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.splitAnalysis, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: horizontalInterval,
                    verticalInterval: maxX / 5,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: theme.dividerColor,
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: theme.dividerColor,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: Text(l10n.distanceMeters, style: theme.textTheme.bodySmall),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: _selectedDistance != null ? (_selectedDistance! / 4) : 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: theme.textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: Text(l10n.timeSeconds, style: theme.textTheme.bodySmall),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        interval: horizontalInterval,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: theme.textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: theme.dividerColor),
                  ),
                  minX: 0,
                  maxX: maxX,
                  minY: 0, // FIXED: Always start Y axis from 0
                  maxY: maxY + yPadding,
                  lineBarsData: visibleChartLines.map((lineData) {
                    return LineChartBarData(
                      spots: lineData.spots,
                      isCurved: true,
                      color: lineData.color,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: lineData.color,
                            strokeWidth: 2,
                            strokeColor: theme.colorScheme.surface,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(show: false),
                    );
                  }).toList(),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final chrono = visibleChartLines[spot.barIndex].chrono;
                          return LineTooltipItem(
                            '${spot.x.toInt()}m\n${Chrono.formatMillisecondsToTime((spot.y * 1000).round())}\n${_formatDate(chrono.date)}',
                            TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendCard(AppLocalizations l10n, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.legend, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            ..._chartLines.map((lineData) {
              final isVisible = _visibleLines.contains(lineData.chrono.id);
              return CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: isVisible,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _visibleLines.add(lineData.chrono.id);
                    } else {
                      _visibleLines.remove(lineData.chrono.id);
                    }
                  });
                },
                title: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 3,
                      decoration: BoxDecoration(
                        color: lineData.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_formatDate(lineData.chrono.date)} - ${lineData.chrono.finalTime}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

/// Data class to hold chart line information
class ChartLineData {
  final Chrono chrono;
  final List<FlSpot> spots;
  final Color color;

  ChartLineData({
    required this.chrono,
    required this.spots,
    required this.color,
  });
}