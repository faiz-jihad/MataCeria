// lib/screens/prediction_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/eye_refraction_provider.dart';
import '../services/api_service.dart';
import '../models/prediction_model.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/empty_state.dart';
import '../l10n/app_strings.dart';

class PredictionTab extends StatefulWidget {
  const PredictionTab({super.key});

  @override
  State<PredictionTab> createState() => _PredictionTabState();
}

class _PredictionTabState extends State<PredictionTab>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<Prediction> _predictions = [];
  bool _isLoading = true;
  late AnimationController _refreshController;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _loadPredictions();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadPredictions() async {
    setState(() => _isLoading = true);
    _refreshController.repeat();

    try {
      final response = await _apiService.getPredictions();
      debugPrint('HISTORY_DEBUG: Raw Reports from Backend: $response');
      setState(() {
        _predictions = response.map((p) => Prediction.fromJson(p)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('report_error'.tr(context));
    }

    _refreshController.stop();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final mlProvider = Provider.of<EyeRefractionProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'report_title'.tr(context),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPredictions,
        color: const Color(0xFF2563EB),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLatestPredictionCard(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Deteksi',
                      '${_predictions.length}',
                      Icons.history,
                      const Color(0xFFE0F2FE),
                      const Color(0xFF0369A1),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'ai_status'.tr(context),
                      mlProvider.serviceHealthy ? 'active'.tr(context) : 'offline'.tr(context),
                      Icons.memory,
                      const Color(0xFFF0FDF4),
                      const Color(0xFF15803D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Text(
                'latest_report'.tr(context),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              _isLoading && _predictions.isEmpty
                  ? Column(
                      children: List.generate(3, (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: SkeletonLoader(
                          width: double.infinity,
                          height: 80,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      )),
                    )
                  : _predictions.isEmpty
                      ? _buildEmptyState()
                      : _buildReportList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLatestPredictionCard() {
    if (_predictions.isEmpty) return const SizedBox.shrink();
    
    final latest = _predictions.first;
    
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE0F2FE), Colors.white],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.blue.shade50),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: latest.fullImageUrl.isNotEmpty
                ? Opacity(
                    opacity: 0.15,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.network(
                        latest.fullImageUrl,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          _getConditionIcon(latest.resultClass),
                          size: 150,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  )
                : Opacity(
                    opacity: 0.1,
                    child: Icon(
                      _getConditionIcon(latest.resultClass),
                      size: 150,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Latest Prediction',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1E3A8A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatDate(latest.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  latest.className,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.analytics, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Confidence: ${latest.confidencePercent}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (latest.visualAcuity != null) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          latest.visualAcuity!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          _buildWavePainter(),
        ],
      ),
    );
  }

  Widget _buildWavePainter() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 60,
      child: CustomPaint(
        painter: WavePainter(color: const Color(0xFF3B82F6).withOpacity(0.1)),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: iconColor.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _predictions.length > 5 ? 5 : _predictions.length,
      itemBuilder: (context, index) {
        final prediction = _predictions[index];
        return _buildReportItem(prediction);
      },
    );
  }

  Widget _buildReportItem(Prediction prediction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: prediction.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            clipBehavior: Clip.antiAlias,
            child: prediction.fullImageUrl.isNotEmpty
                ? Image.network(
                    prediction.fullImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      _getConditionIcon(prediction.resultClass),
                      color: prediction.color,
                      size: 24,
                    ),
                  )
                : Icon(
                    _getConditionIcon(prediction.resultClass),
                    color: prediction.color,
                    size: 24,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prediction.className,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Row(
                   children: [
                     Text(
                        '${'confidence'.tr(context)}: ${prediction.confidencePercent}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      if (prediction.visualAcuity != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '•  ${prediction.visualAcuity}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                   ],
                ),
                if (prediction.recommendation != null && prediction.recommendation!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    prediction.recommendation!,
                    style: TextStyle(
                      color: prediction.actionRequired ? Colors.red.shade700 : Colors.grey.shade600,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatDate(prediction.createdAt),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey.shade300),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      title: 'report_empty'.tr(context),
      message: 'no_reports_msg'.tr(context),
      icon: Icons.assignment_outlined,
      actionLabel: 'start_detection'.tr(context),
      onAction: () => Navigator.pushNamed(context, '/refraction_test'),
    );
  }

  IconData _getConditionIcon(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('normal')) return Icons.check_circle;
    if (c.contains('mild')) return Icons.visibility_outlined;
    if (c.contains('myopia') || c.contains('miopi')) return Icons.remove_red_eye;
    if (c.contains('severe')) return Icons.warning_rounded;
    if (c.contains('hiper')) return Icons.visibility;
    if (c.contains('astig')) return Icons.blur_on;
    return Icons.help_outline;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) return '${difference.inMinutes}m ${'ago'.tr(context)}';
      return '${difference.inHours}h ${'ago'.tr(context)}';
    } else if (difference.inDays == 1) {
      return 'yesterday'.tr(context);
    } else {
      return '${date.day}/${date.month}';
    }
  }
}

class WavePainter extends CustomPainter {
  WavePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    
    // Create a series of curves for a wave effect
    for (double i = 0; i <= size.width; i += 20) {
      path.quadraticBezierTo(
        i + 10, 
        size.height * (i % 40 == 0 ? 0.7 : 0.9),
        i + 20, 
        size.height * 0.8
      );
    }
    
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}