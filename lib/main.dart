import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const ForexGameApp());
}

class ForexGameApp extends StatelessWidget {
  const ForexGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Forex Trader Simulator',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF12161A),
        cardColor: const Color(0xFF1E2329),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0ECB81), // Green
          secondary: Color(0xFFF6465D), // Red
        ),
      ),
      home: const ForexScreen(),
    );
  }
}

class TradePosition {
  final String id;
  final String type; // 'BUY' or 'SELL'
  final double entryPrice;
  final double amount;

  TradePosition({
    required this.id,
    required this.type,
    required this.entryPrice,
    required this.amount,
  });
}

class ForexScreen extends StatefulWidget {
  const ForexScreen({super.key});

  @override
  State<ForexScreen> createState() => _ForexScreenState();
}

class _ForexScreenState extends State<ForexScreen> {
  double _balance = 1000.00;
  double _currentPrice = 1.0850; // EUR/USD initial price
  final List<double> _priceHistory = [];
  final List<TradePosition> _openPositions = [];
  final Random _random = Random();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Initialize price history
    double price = _currentPrice;
    for (int i = 0; i < 30; i++) {
      price += (_random.nextDouble() - 0.49) * 0.0008;
      _priceHistory.add(price);
    }
    _currentPrice = price;

    // Start market ticks (updates every 800ms)
    _timer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      _updateMarketPrice();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateMarketPrice() {
    setState(() {
      // Simulate price movements
      double change = (_random.nextDouble() - 0.495) * 0.0012;
      _currentPrice += change;
      if (_currentPrice < 0.5) _currentPrice = 0.5;

      _priceHistory.add(_currentPrice);
      if (_priceHistory.length > 40) {
        _priceHistory.removeAt(0);
      }
    });
  }

  void _openTrade(String type) {
    if (_balance < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Недостаточно баланса! Нужно минимум $100')),
      );
      return;
    }

    setState(() {
      _balance -= 100; // Fixed trade lot size of $100
      _openPositions.add(
        TradePosition(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: type,
          entryPrice: _currentPrice,
          amount: 100,
        ),
      );
    });
  }

  void _closeTrade(TradePosition trade) {
    double pnl = _calculatePnL(trade);
    setState(() {
      _balance += trade.amount + pnl;
      _openPositions.removeWhere((p) => p.id == trade.id);
    });
  }

  double _calculatePnL(TradePosition trade) {
    double diff = _currentPrice - trade.entryPrice;
    if (trade.type == 'SELL') diff = -diff;
    return (diff / trade.entryPrice) * trade.amount * 50; // 50x Leverage effect
  }

  double _getTotalUnrealizedPnL() {
    return _openPositions.fold(0.0, (sum, trade) => sum + _calculatePnL(trade));
  }

  @override
  Widget build(BuildContext context) {
    final unrealizedPnL = _getTotalUnrealizedPnL();
    final totalEquity = _balance + _openPositions.length * 100 + unrealizedPnL;

    return Scaffold(
      appBar: AppBar(
        title: const Text('EUR/USD Forex Simulator', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E2329),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _balance = 1000.0;
                _openPositions.clear();
              });
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Header Stats
          Container(
            padding: const EdgeInsets.all(16.0),
            color: const Color(0xFF1E2329),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatColumn('Свободный Баланс', '\$${_balance.toStringAsFixed(2)}'),
                _buildStatColumn('Общий Капитал', '\$${totalEquity.toStringAsFixed(2)}',
                    color: totalEquity >= 1000 ? const Color(0xFF0ECB81) : const Color(0xFFF6465D)),
                _buildStatColumn('Текущий P&L', '\$${unrealizedPnL.toStringAsFixed(2)}',
                    color: unrealizedPnL >= 0 ? const Color(0xFF0ECB81) : const Color(0xFFF6465D)),
              ],
            ),
          ),

          // Price Header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('EUR / USD', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(
                  _currentPrice.toStringAsFixed(4),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: _priceHistory.length > 1 && _currentPrice >= _priceHistory[_priceHistory.length - 2]
                        ? const Color(0xFF0ECB81)
                        : const Color(0xFFF6465D),
                  ),
                ),
              ],
            ),
          ),

          // Custom Chart
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2329),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomPaint(
                painter: ChartPainter(_priceHistory),
                child: Container(),
              ),
            ),
          ),

          // Open Positions Section
          const Padding(
            padding: EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Открытые сделки', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            flex: 2,
            child: _openPositions.isEmpty
                ? const Center(child: Text('Нет открытых позиций', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: _openPositions.length,
                    itemBuilder: (context, index) {
                      final trade = _openPositions[index];
                      final pnl = _calculatePnL(trade);
                      final isProfitable = pnl >= 0;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2329),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: trade.type == 'BUY' ? const Color(0xFF0ECB81) : const Color(0xFFF6465D),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${trade.type} (\$100)',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: trade.type == 'BUY' ? const Color(0xFF0ECB81) : const Color(0xFFF6465D))),
                                Text('Вход: ${trade.entryPrice.toStringAsFixed(4)}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                            Text(
                              '${isProfitable ? '+' : ''}\$${pnl.toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isProfitable ? const Color(0xFF0ECB81) : const Color(0xFFF6465D)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[800],
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              ),
                              onPressed: () => _closeTrade(trade),
                              child: const Text('Закрыть', style: TextStyle(color: Colors.white)),
                            )
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Control Trading Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0ECB81),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _openTrade('BUY'),
                      child: const Text('ВВЕРХ (BUY)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF6465D),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _openTrade('SELL'),
                      child: const Text('ВНИЗ (SELL)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, {Color color = Colors.white}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

// Custom Painter for rendering live Forex Chart Line
class ChartPainter extends CustomPainter {
  final List<double> prices;

  ChartPainter(this.prices);

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.length < 2) return;

    final minPrice = prices.reduce(min);
    final maxPrice = prices.reduce(max);
    final range = (maxPrice - minPrice) == 0 ? 1 : (maxPrice - minPrice);

    final linePaint = Paint()
      ..color = prices.last >= prices.first ? const Color(0xFF0ECB81) : const Color(0xFFF6465D)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          (prices.last >= prices.first ? const Color(0xFF0ECB81) : const Color(0xFFF6465D)).withOpacity(0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    double stepX = size.width / (prices.length - 1);

    for (int i = 0; i < prices.length; i++) {
      double x = i * stepX;
      double normalizedY = (prices[i] - minPrice) / range;
      double y = size.height - (normalizedY * (size.height - 20)) - 10;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      if (i == prices.length - 1) {
        fillPath.lineTo(x, size.height);
        fillPath.close();

        // Draw last price point dot
        canvas.drawCircle(Offset(x, y), 4, Paint()..color = linePaint.color);
      }
    }

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant ChartPainter oldDelegate) => true;
}
