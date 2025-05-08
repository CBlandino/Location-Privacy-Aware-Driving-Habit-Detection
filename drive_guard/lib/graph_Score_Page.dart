import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';



class MiniScoreGraph extends StatelessWidget {
  // Possibly change to FlSPot instead of double
  final List<double> scores;    // Scores over time
  final List<String> dates;     // Dates and time for trips
  final double height;          // height of graph container
  


  const MiniScoreGraph({super.key, required this.scores, required this.dates, required this.height});


  @override
  Widget build(BuildContext context) {

    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Trip Score Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          Expanded(
            child: LineChart(
              LineChartData(
                titlesData: _buildFlTitlesData(),
                borderData: _buildFlBorderData(),
                gridData: _buildFlGridData(),
                lineBarsData: [
                  _buildLineChartBarData()
                ],
                lineTouchData: _buildLineTouchData(),
              ),
            ),
          ),
        ],
      ),
      
    );
  }

  LineTouchData _buildLineTouchData() {

    return LineTouchData(
      enabled: true,
      touchTooltipData: LineTouchTooltipData(
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((spot) {
            return LineTooltipItem(
              'Trip ${spot.x.toInt() + 1}\nScore: ${spot.y.toStringAsFixed(1)}',
              const TextStyle(
                color: Colors.white
              ),
            );
          }).toList();
        },
      ),
      handleBuiltInTouches: true,
    );
  }



  FlTitlesData _buildFlTitlesData() {

    return FlTitlesData(
      show: true,
      rightTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: false,
        )
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          interval: 100,
          minIncluded: true,
        )
      ),
      topTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: false,
        )
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: false,
        )
      ),


    );
  }



  // Control Graphs Border
  FlBorderData _buildFlBorderData() {

    return FlBorderData(
      show: false,
      border: Border.all(
        color: Colors.black
      ),
    );
  }



  // Controls what you want shown for grid lines
  FlGridData _buildFlGridData() {
    return FlGridData(
      show: false

    );
  }


  // Builds actual graph with data points, etc
  LineChartBarData _buildLineChartBarData() {

    return LineChartBarData(
      spots: scores
          .asMap()
          .entries
          .map((e) => FlSpot(e.key.toDouble(), e.value))
          .toList(),
      isCurved: true,
      color: Colors.yellow,
      barWidth: 4,
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.yellow,
            Color.fromRGBO(255, 255, 220, 1),
          ],
        )
      )
    );

  }




}