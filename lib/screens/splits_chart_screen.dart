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
  
  // Touch interaction state
  int? _highlightedLineIndex;
  
  // Tooltip display mode
  bool _showCompactTooltip = true; // true = compact, false = detailed segment

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
      // Servono almeno 2 punti: il primo è sempre l'origine (0,0) aggiunta
      // da _createSpotsForChrono, quindi con isNotEmpty passavano anche
      // linee senza alcuno split reale (causando maxX/maxY = 0 e crash).
      if (spots.length >= 2) {
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
      // Reset: le linee sono cambiate, l'highlight sarebbe scorretto
      _highlightedLineIndex = null;
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
    
    // Always start from origin (0, 0)
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
              style: TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                    semanticFormatterCallback: (double value) => value.round().toString(),
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
            const SizedBox(height: 16),
            
            // Tooltip mode switch
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.tooltipMode, style: theme.textTheme.bodyMedium),
              subtitle: Text(
                _showCompactTooltip ? l10n.compactData : l10n.detailedData,
                style: theme.textTheme.bodySmall,
              ),
              value: !_showCompactTooltip, // Inverted: OFF=compact, ON=detailed
              onChanged: (value) {
                setState(() {
                  _showCompactTooltip = !value;

                  // 🔄 Sync visible lines when switching modes:
                  // - In compact mode (checkboxes): show all lines
                  // - In detailed mode (radio buttons): show only the first line
                  if (_showCompactTooltip) {
                    _visibleLines = _chartLines.map((l) => l.chrono.id).toSet();
                  } else {
                    if (_chartLines.isNotEmpty) {
                      _visibleLines = {_chartLines.first.chrono.id};
                    }
                  }
                  // L'highlight indicizza le linee visibili: al cambio di
                  // visibilità punterebbe alla linea sbagliata.
                  _highlightedLineIndex = null;
                });
              },
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
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
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
    
    // Prevent zero interval when all times are the same
    // Since minY is now always 0, we use maxY for calculations
    final yRange = maxY - minY;
    final yPadding = yRange > 0 ? yRange * 0.05 : maxY * 0.1; // Reduced padding since we start from 0
    // Clamp a un minimo positivo: fl_chart lancia un'assertion se
    // l'intervallo della griglia è 0.
    final horizontalInterval =
        math.max(yRange > 0 ? yRange / 5 : maxY / 5, 0.001);
    final verticalInterval = math.max(maxX / 5, 0.001);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.splitAnalysis, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            
            // Info text for detailed mode
            if (!_showCompactTooltip)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  l10n.selectSingleLineForDetails,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: horizontalInterval,
                    verticalInterval: verticalInterval,
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
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
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
                  minY: 0, // Always start Y axis from 0
                  maxY: maxY + yPadding,
                  lineBarsData: visibleChartLines.asMap().entries.map((entry) {
                    final index = entry.key;
                    final lineData = entry.value;
                    final isHighlighted = _highlightedLineIndex == index;
                    
                    return LineChartBarData(
                      spots: lineData.spots,
                      isCurved: false,
                      // FIXED: Use withValues instead of deprecated withOpacity
                      color: lineData.color.withValues(
                        alpha: isHighlighted ? 1.0 : (_highlightedLineIndex == null ? 1.0 : 0.3),
                      ),
                      barWidth: isHighlighted ? 4 : 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: isHighlighted ? 5 : 4,
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
                    enabled: true,
                    handleBuiltInTouches: true,
                    // FIXED: Reset highlight when touch ends
                    touchCallback: (event, response) {
                      if (!mounted) return;
                      
                      setState(() {
                        // Try multiple event types for touch end detection
                        if (event is FlTapUpEvent || 
                            event is FlPanEndEvent || 
                            event is FlLongPressEnd ||
                            response == null ||
                            response.lineBarSpots == null ||
                            response.lineBarSpots!.isEmpty) {
                          _highlightedLineIndex = null;
                        } else {
                          _highlightedLineIndex = response.lineBarSpots!.first.barIndex;
                        }
                      });
                    },
                    touchTooltipData: LineTouchTooltipData(
                      maxContentWidth: 220,
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipColor: (touchedSpot) => theme.colorScheme.surfaceContainerHighest,
                      tooltipBorder: BorderSide(color: theme.dividerColor, width: 1),
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 10,
                      tooltipHorizontalAlignment: FLHorizontalAlignment.left, // Allinea a destra del dito
                      tooltipHorizontalOffset: -50, // Alternativa/Aggiunta: Sposta ulteriormente a destra
                      // FIXED: Return exactly ONE item per touchedSpot
                      // CORRECT: Switch between compact and detailed tooltip modes

                      getTooltipItems: (touchedSpots) {
                        if (touchedSpots.isEmpty) return [];
                        // *** FIX: Chiama la funzione helper corretta in base allo switch ***
                        if (_showCompactTooltip) {
                          // COMPACT MODE: Show all lines at same distance
                          return _buildCompactTooltip(touchedSpots, visibleChartLines, theme);
                        } else {
                          // DETAILED MODE: Show segment info for closest line
                          return _buildDetailedTooltip(touchedSpots, visibleChartLines, theme, l10n);
                        }
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

            // ============================================================
            // Line visibility controls (detailed / compact modes)
            // ============================================================

            // Detailed mode: use RadioListTile (single selection)
            if (!_showCompactTooltip)
              RadioGroup<String>(
                // Valore attuale selezionato (usiamo il primo se none)
                groupValue: _visibleLines.length == 1 ? _visibleLines.first : _chartLines.first.chrono.id,
                onChanged: (String? selectedId) {
                  setState(() {
                    if (selectedId != null) {
                      // Seleziona solo questa linea
                      _visibleLines = {selectedId};
                    } else {
                      // Non permettiamo “nessuna selezione”: mantieni la precedente
                      if (_visibleLines.isEmpty && _chartLines.isNotEmpty) {
                        _visibleLines = {_chartLines.first.chrono.id};
                      }
                    }
                    // Reset: l'highlight indicizza le linee visibili
                    _highlightedLineIndex = null;
                  });
                },
                child: Column(
                  children: _chartLines.map((lineData) {
                    final isSelected = _visibleLines.contains(lineData.chrono.id);
                    return RadioListTile<String>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: lineData.chrono.id,
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
                              '${_formatDate(lineData.chrono.date)} - ${lineData.chrono.displayTime}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Compact mode: use CheckboxListTile (multiple selection)
            if (_showCompactTooltip)
              ..._chartLines.map((lineData) {
                final isVisible = _visibleLines.contains(lineData.chrono.id);

                return CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: isVisible,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _visibleLines.add(lineData.chrono.id);
                      } else {
                        _visibleLines.remove(lineData.chrono.id);
                      }
                      // Reset: l'highlight indicizza le linee visibili
                      _highlightedLineIndex = null;
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
                          '${_formatDate(lineData.chrono.date)} - ${lineData.chrono.displayTime}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isVisible ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Build compact tooltip: shows all lines at same distance
  List<LineTooltipItem> _buildCompactTooltip(
    List<LineBarSpot> touchedSpots,
    List<ChartLineData> visibleLines,
    ThemeData theme,
  ) {
    // If multiple lines at same point, show all with single tooltip
    if (touchedSpots.length > 1) {
      final distance = touchedSpots.first.x.toInt();
      final buffer = StringBuffer('${distance}m\n');
      
      for (int i = 0; i < touchedSpots.length; i++) {
        final spot = touchedSpots[i];
        final lineData = visibleLines[spot.barIndex];
        final timeStr = Chrono.formatMillisecondsToTime((spot.y * 1000).round());
        final dateStr = '${lineData.chrono.date.day.toString().padLeft(2, '0')}/${lineData.chrono.date.month.toString().padLeft(2, '0')}';
        buffer.write('● $timeStr ($dateStr)');
        if (i < touchedSpots.length - 1) buffer.write('\n');
      }
      
      // Return one item per spot, but only first has text
      return touchedSpots.asMap().entries.map((entry) {
        final isFirst = entry.key == 0;
        return LineTooltipItem(
          isFirst ? buffer.toString() : '',
          TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 11,
            height: 1.3,
          ),
        );
      }).toList();
    }
    
    // Single line - simple display
    return touchedSpots.map((spot) {
      final lineData = visibleLines[spot.barIndex];
      final distance = spot.x.toInt();
      final timeStr = Chrono.formatMillisecondsToTime((spot.y * 1000).round());
      final dateStr = '${lineData.chrono.date.day.toString().padLeft(2, '0')}/${lineData.chrono.date.month.toString().padLeft(2, '0')}';
      
      return LineTooltipItem(
        '${distance}m\n● $timeStr\n($dateStr)',
        TextStyle(
          color: lineData.color,
          fontSize: 12,
          height: 1.3,
        ),
      );
    }).toList();
  }

  /// Build detailed tooltip: shows segment info for the selected line
  /// Works best when only one line is visible in the legend
  List<LineTooltipItem?> _buildDetailedTooltip(
    List<LineBarSpot> touchedSpots,
    List<ChartLineData> visibleLines,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    if (touchedSpots.isEmpty) return [];

    // Take only the first touched spot (works best with single line selected)
    final selectedSpot = touchedSpots.first;
    final lineData = visibleLines[selectedSpot.barIndex];
    final touchedX = selectedSpot.x;

    // Find the index of the touched point on the line
    int pointIndex = -1;
    for (int i = 0; i < lineData.spots.length; i++) {
      if ((lineData.spots[i].x - touchedX).abs() < 0.1) {
        pointIndex = i;
        break;
      }
    }

    // Return list with same length as touchedSpots, but only show tooltip for selected spot
    return touchedSpots.map((spot) {
      if (spot != selectedSpot) return null;

      // Special case: starting point
      if (pointIndex <= 0 || touchedX < 0.1) {
        return LineTooltipItem(
          l10n.startLabel,
          TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        );
      }

      // Calculate segment data
      final currentSpot = lineData.spots[pointIndex];
      final previousSpot = lineData.spots[pointIndex - 1];

      final segmentStart = previousSpot.x.toInt();
      final segmentEnd = currentSpot.x.toInt();
      final splitTimeMs = ((currentSpot.y - previousSpot.y) * 1000).round();
      final cumulativeTimeMs = (currentSpot.y * 1000).round();
      final dateStr =
          '${lineData.chrono.date.day.toString().padLeft(2, '0')}/${lineData.chrono.date.month.toString().padLeft(2, '0')}/${lineData.chrono.date.year}';

      return LineTooltipItem(
        // main text: segment (will appear first). Apply bold style here.
        '${l10n.segment}: $segmentStart-${segmentEnd}m\n',
        TextStyle(
          color: lineData.color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          height: 1.4,
        ),
        // children appended after main text: put the rest here, with normal weight
        children: [
          TextSpan(
            text:
                '${l10n.splitLabel} ${Chrono.formatMillisecondsToTime(splitTimeMs)}\n'
                '${l10n.cumulative}: ${Chrono.formatMillisecondsToTime(cumulativeTimeMs)}\n'
                '$dateStr',
            style: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 11, // puoi adattare la dimensione se vuoi
            ),
          ),
        ],
      );
    }).toList();
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