import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'trace_list_screen.dart';
import 'register_animal_screen.dart';
import 'slaughter_animal_screen.dart';
import 'scan_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeContent(),
    TraceListScreen(),
    ScanHistoryScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timeline),
            label: 'Traces',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // App Bar with branding
        SliverAppBar(
          expandedHeight: 200.0,
          floating: false,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: const Text('MeatTrace'),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4CAF50),
                    Color(0xFF2196F3),
                  ],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.restaurant,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),

        // Quick Actions Grid
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildActionCard(
                      context,
                      'Scan QR',
                      Icons.qr_code_scanner,
                      () => context.go('/qr-scanner'),
                      const Color(0xFF4CAF50),
                    ),
                    _buildActionCard(
                      context,
                      'Register Animal',
                      Icons.pets,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterAnimalScreen(),
                          ),
                        );
                      },
                      const Color(0xFF2196F3),
                    ),
                    _buildActionCard(
                      context,
                      'Create Product',
                      Icons.inventory,
                      () => context.go('/create-product'),
                      const Color(0xFFFF9800),
                    ),
                    _buildActionCard(
                      context,
                      'Manage Categories',
                      Icons.category,
                      () => context.go('/categories'),
                      const Color(0xFF9C27B0),
                    ),
                    _buildActionCard(
                      context,
                      'API Test',
                      Icons.api,
                      () => context.go('/api-test'),
                      const Color(0xFFE91E63),
                    ),
                    _buildActionCard(
                      context,
                      'Slaughter Animal',
                      Icons.agriculture,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SlaughterAnimalScreen(),
                          ),
                        );
                      },
                      const Color(0xFF795548),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Recent Activity
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                _buildRecentActivityCard(
                  'Product #1234 scanned',
                  '2 hours ago',
                  Icons.check_circle,
                  Colors.green,
                ),
                const SizedBox(height: 8),
                _buildRecentActivityCard(
                  'Animal registered',
                  '1 day ago',
                  Icons.pets,
                  Colors.blue,
                ),
                const SizedBox(height: 8),
                _buildRecentActivityCard(
                  'Batch processed',
                  '2 days ago',
                  Icons.factory,
                  Colors.orange,
                ),
              ],
            ),
          ),
        ),

        // Stats Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statistics',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard('Total Scans', '1,234', Icons.qr_code),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard('Active Traces', '89', Icons.timeline),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard('Products', '456', Icons.inventory),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard('Animals', '234', Icons.pets),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard(
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(time),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: const Color(0xFF4CAF50)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF757575),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

