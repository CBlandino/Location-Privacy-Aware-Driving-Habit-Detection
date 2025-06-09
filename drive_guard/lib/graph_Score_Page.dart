import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';


// TODO: make graph have options for: past week, month, year, etc


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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
              color: Color.fromARGB(255, 99, 185, 255)
            ),
          ),

          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,      // graphs range displayed is 0-100
                maxY: 100,
                titlesData: _buildFlTitlesData(),       // Title information in graph
                borderData: _buildFlBorderData(),       // Border around the graph
                gridData: _buildFlGridData(),           // Graph grid
                lineBarsData: [                         // Controls actual function being displayed in graph (controls color, points, etc)
                  _buildLineChartBarData()
                ],
                lineTouchData: _buildLineTouchData(),   // Controls data that pops up when you click on a point
              ),
            ),
          ),
        ],
      ),
      
    );
  }

  // data that appears when you touch a data point
  LineTouchData _buildLineTouchData() {
  return LineTouchData(
    enabled: true,
    handleBuiltInTouches: true,
    touchTooltipData: LineTouchTooltipData(
      tooltipRoundedRadius: 12,
      tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      tooltipMargin: 16,
      tooltipBorder: BorderSide(color: Color.fromARGB(255, 99, 185, 255), width: 0),
      getTooltipColor: (TouchedSpot) => Color.fromARGB(255, 99, 185, 255),
      getTooltipItems: (touchedSpots) {
        return touchedSpots.map((spot) {
          return LineTooltipItem(
            'Trip ${spot.x.toInt() + 1}\nScore: ${spot.y.toStringAsFixed(0)}%',
            TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          );
        }).toList();
      },
    ),
  );
}


  // allows for editing of title data
  FlTitlesData _buildFlTitlesData() {

    // show title above graph, show none for all other sides
    return FlTitlesData(
      show: true,
      rightTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: false,
        )
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: false,
          reservedSize: 40,
          interval: 20,
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
      // Turns score list into data points
      spots: scores
          .asMap()
          .entries
          .map((e) => FlSpot(e.key.toDouble(), e.value))
          .toList(),
      isCurved: true,
      color: Colors.yellow,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 3,
            color: const Color.fromARGB(255, 99, 185, 255),
           
          );
        },
      ),
      // Creates a gradient for graph color
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