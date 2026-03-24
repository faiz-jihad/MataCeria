// lib/screens/analytics_screen.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/analytics_model.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/empty_state.dart';


class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  UserAnalytics? _userAnalytics;
  QueryCategories? _categories;
  List<FrequentQuery> _frequentQueries = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      // Load user analytics
      final userResponse = await _apiService.getUserAnalytics();
      if (userResponse['success']) {
        setState(() {
          _userAnalytics = UserAnalytics.fromJson(userResponse['data']);
        });
      }

      // Load categories
      final categoriesResponse = await _apiService.getQueryCategories();
      if (categoriesResponse['success']) {
        setState(() {
          _categories = QueryCategories.fromJson(categoriesResponse['data']);
        });
      }

      // Load frequent queries
      final queriesResponse = await _apiService.getFrequentQueries();
      if (queriesResponse['success']) {
        setState(() {
          _frequentQueries = (queriesResponse['data'] as List)
              .map((q) => FrequentQuery.fromJson(q))
              .toList();
        });
      }
    } catch (e) {
      print('Error loading analytics: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analitik Chatbot'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SkeletonLoader(width: double.infinity, height: 200, borderRadius: BorderRadius.circular(16)),
                  const SizedBox(height: 20),
                  SkeletonLoader(width: double.infinity, height: 250, borderRadius: BorderRadius.circular(16)),
                  const SizedBox(height: 20),
                  SkeletonLoader(width: double.infinity, height: 300, borderRadius: BorderRadius.circular(16)),
                ],
              ),
            )
          : (_userAnalytics == null && _categories == null && _frequentQueries.isEmpty)
              ? EmptyState(
                  title: 'Data Belum Tersedia',
                  message: 'Mulai mengobrol dengan asisten AI kami untuk melihat analisis penggunaan Anda.',
                  icon: Icons.analytics_outlined,
                  actionLabel: 'Mulai Chat',
                  onAction: () => Navigator.pushReplacementNamed(context, '/chat'),
                )
              : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Stats Card
                  if (_userAnalytics != null)
                    _buildUserStatsCard(),
                  
                  const SizedBox(height: 20),
                  
                  // Categories Chart
                  if (_categories != null)
                    _buildCategoriesCard(),
                  
                  const SizedBox(height: 20),
                  
                  // Frequent Queries
                  if (_frequentQueries.isNotEmpty)
                    _buildFrequentQueriesCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildUserStatsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Statistik Pribadi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  '${_userAnalytics!.totalQueries}',
                  'Total Chat',
                  Icons.chat,
                  Colors.blue,
                ),
                _buildStatItem(
                  '${_userAnalytics!.totalSessions}',
                  'Sesi',
                  Icons.history,
                  Colors.green,
                ),
                _buildStatItem(
                  '${_userAnalytics!.feedbackRate}%',
                  'Feedback Positif',
                  Icons.thumb_up,
                  Colors.orange,
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            const Divider(),
            
            const SizedBox(height: 10),
            
            const Text(
              'Pertanyaan Teratas Anda:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 10),
            
            ..._userAnalytics!.topQueries.map((q) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${_userAnalytics!.topQueries.indexOf(q) + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      q.message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${q.count}x',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesCard() {
    final total = _categories!.total;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.pie_chart,
                    color: Colors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Kategori Pertanyaan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            _buildCategoryBar(
              'Rekomendasi',
              _categories!.recommendation,
              total,
              Colors.blue,
            ),
            _buildCategoryBar(
              'Obat',
              _categories!.medicine,
              total,
              Colors.green,
            ),
            _buildCategoryBar(
              'Makanan',
              _categories!.food,
              total,
              Colors.orange,
            ),
            _buildCategoryBar(
              'Darurat',
              _categories!.emergency,
              total,
              Colors.red,
            ),
            _buildCategoryBar(
              'Umum',
              _categories!.general,
              total,
              Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBar(String label, int value, int total, Color color) {
    final percentage = total > 0 ? (value / total * 100) : 0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}% ($value)',
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / total,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequentQueriesCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Pertanyaan Paling Sering',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            ..._frequentQueries.take(10).map((q) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _frequentQueries.indexOf(q) == 0
                          ? Colors.amber
                          : _frequentQueries.indexOf(q) == 1
                              ? Colors.grey
                              : _frequentQueries.indexOf(q) == 2
                                  ? Colors.brown
                                  : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${_frequentQueries.indexOf(q) + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _frequentQueries.indexOf(q) < 3
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      q.message,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${q.count}x',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}