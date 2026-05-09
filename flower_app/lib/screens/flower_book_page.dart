import 'package:flutter/material.dart';
import '../theme/season_theme.dart';
import '../services/flower_api_service.dart';

class FlowerBookPage extends StatefulWidget {
  const FlowerBookPage({super.key});

  @override
  State<FlowerBookPage> createState() => _FlowerBookPageState();
}

class _FlowerBookPageState extends State<FlowerBookPage> {
  final FlowerApiService _api = FlowerApiService();
  List<FlowerData> _flowers = [];
  bool _isLoading = true;
  String? _error;
  int _selectedMonth = DateTime.now().month;

  final List<FlowerData> _mockFlowers = [
    FlowerData(dataNo: '1', flowNm: '벚꽃', fMonth: 4, fDay: 1, flowLang: '정신적 아름다움, 순결',
        imgUrl1: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e5/Cherry_blossoms_in_Vancouver_3_crop.jpg/320px-Cherry_blossoms_in_Vancouver_3_crop.jpg'),
    FlowerData(dataNo: '2', flowNm: '튤립', fMonth: 3, fDay: 25, flowLang: '박애, 사랑의 고백',
        imgUrl1: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/44/Tulip_-_florescence.jpg/320px-Tulip_-_florescence.jpg'),
    FlowerData(dataNo: '3', flowNm: '동백', fMonth: 1, fDay: 15, flowLang: '겸손한 매력',
        imgUrl1: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/Camellia_japonica_flower_2.jpg/320px-Camellia_japonica_flower_2.jpg'),
    FlowerData(dataNo: '4', flowNm: '장미', fMonth: 5, fDay: 10, flowLang: '사랑, 아름다움',
        imgUrl1: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e6/Rosa_rubiginosa_1.jpg/320px-Rosa_rubiginosa_1.jpg'),
    FlowerData(dataNo: '5', flowNm: '수국', fMonth: 6, fDay: 20, flowLang: '변덕, 진심',
        imgUrl1: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Hydrangea_macrophylla_-_Bigleaf_hydrangea.jpg/320px-Hydrangea_macrophylla_-_Bigleaf_hydrangea.jpg'),
    FlowerData(dataNo: '6', flowNm: '코스모스', fMonth: 9, fDay: 15, flowLang: '소녀의 순정',
        imgUrl1: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6e/Cosmos_bipinnatus_2.jpg/320px-Cosmos_bipinnatus_2.jpg'),
    FlowerData(dataNo: '7', flowNm: '해바라기', fMonth: 7, fDay: 5, flowLang: '숭배, 그리움',
        imgUrl1: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/40/Sunflower_sky_backdrop.jpg/320px-Sunflower_sky_backdrop.jpg'),
    FlowerData(dataNo: '8', flowNm: '라벤더', fMonth: 6, fDay: 1, flowLang: '침묵, 기대',
        imgUrl1: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/60/Single_laridge_702702.jpg/320px-Single_laridge_702702.jpg'),
    FlowerData(dataNo: '9', flowNm: '무궁화', fMonth: 8, fDay: 15, flowLang: '은근과 끈기',
        imgUrl1: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/17/Hibiscus_syriacus_%28Korean_National_Flower%29.jpg/320px-Hibiscus_syriacus_%28Korean_National_Flower%29.jpg'),
    FlowerData(dataNo: '10', flowNm: '매화', fMonth: 2, fDay: 10, flowLang: '고결, 인내',
        imgUrl1: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3b/Plum_blossom3.jpg/320px-Plum_blossom3.jpg'),
    FlowerData(dataNo: '11', flowNm: '진달래', fMonth: 4, fDay: 8, flowLang: '사랑의 기쁨',
        imgUrl1: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a0/RhsijokRhododendron_schlippenbachii2.jpg/320px-RhsijokRhododendron_schlippenbachii2.jpg'),
    FlowerData(dataNo: '12', flowNm: '국화', fMonth: 10, fDay: 14, flowLang: '고결, 성실',
        imgUrl1: 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fc/Chrysanthemum_November_2007.jpg/320px-Chrysanthemum_November_2007.jpg'),
  ];

  @override
  void initState() {
    super.initState();
    _loadFlowers();
  }

  Future<void> _loadFlowers() async {
    setState(() { _isLoading = true; _error = null; });
    if (!FlowerApiService.isApiKeySet) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) setState(() { _flowers = _mockFlowers; _isLoading = false; });
      return;
    }
    try {
      final flowers = await _api.getFlowerList(month: _selectedMonth);
      if (mounted) setState(() { _flowers = flowers; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; _flowers = _mockFlowers; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = SeasonTheme.getColors();
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colors.primary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('꽃 도감', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
        actions: [
          if (!FlowerApiService.isApiKeySet)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: const Text('Mock 데이터', style: TextStyle(fontSize: 10)),
                backgroundColor: Colors.orange.withAlpha(30),
                labelStyle: TextStyle(color: Colors.orange[800]),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildMonthSelector(colors),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: colors.primary))
                : _error != null && _flowers.isEmpty
                    ? _buildErrorView(colors)
                    : _buildFlowerGrid(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(SeasonColors colors) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: 12,
        itemBuilder: (context, i) {
          final m = i + 1;
          final isSelected = m == _selectedMonth;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedMonth = m);
              if (FlowerApiService.isApiKeySet) _loadFlowers();
            },
            child: Container(
              width: 44,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: isSelected ? colors.primary : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: isSelected
                    ? [BoxShadow(color: colors.primary.withAlpha(40), blurRadius: 8)]
                    : [BoxShadow(color: Colors.grey.withAlpha(20), blurRadius: 4)],
              ),
              child: Center(
                child: Text('${m}월', style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.grey[600],
                )),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFlowerGrid(SeasonColors colors) {
    final displayFlowers = _flowers.isEmpty ? _mockFlowers : _flowers;
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, childAspectRatio: 0.68, crossAxisSpacing: 8, mainAxisSpacing: 8,
      ),
      itemCount: displayFlowers.length,
      itemBuilder: (context, i) => _buildFlowerCard(displayFlowers[i], colors),
    );
  }

  Widget _buildFlowerCard(FlowerData flower, SeasonColors colors) {
    final emoji = _flowerEmoji(flower.flowNm);
    final cardColor = _flowerColor(flower.flowNm);

    return GestureDetector(
      onTap: () => _showFlowerDetail(flower, colors),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: cardColor.withAlpha(30), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cardColor.withAlpha(30),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: flower.mainImageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                        child: Image.network(flower.mainImageUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(child: Text(emoji, style: const TextStyle(fontSize: 32))),
                        ),
                      )
                    : Center(child: Text(emoji, style: const TextStyle(fontSize: 32))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(flower.flowNm, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 1),
                  Text(flower.flowLang, style: TextStyle(fontSize: 9, color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFlowerDetail(FlowerData flower, SeasonColors colors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FlowerDetailSheet(
        flower: flower, colors: colors,
        emoji: _flowerEmoji(flower.flowNm),
        cardColor: _flowerColor(flower.flowNm),
        api: FlowerApiService.isApiKeySet ? _api : null,
      ),
    );
  }

  String _flowerEmoji(String name) {
    if (name.contains('벚꽃') || name.contains('벚나무')) return '🌸';
    if (name.contains('장미')) return '🌹';
    if (name.contains('튤립')) return '🌷';
    if (name.contains('해바라기')) return '🌻';
    if (name.contains('국화')) return '🏵️';
    if (name.contains('코스모스')) return '🌼';
    if (name.contains('수국')) return '💜';
    if (name.contains('동백')) return '🔴';
    if (name.contains('라벤더')) return '💐';
    if (name.contains('무궁화')) return '🌺';
    if (name.contains('매화')) return '⚪';
    if (name.contains('진달래')) return '🩷';
    return '🌿';
  }

  Color _flowerColor(String name) {
    if (name.contains('벚꽃') || name.contains('벚나무')) return const Color(0xFFFFB7C5);
    if (name.contains('장미')) return const Color(0xFFEC407A);
    if (name.contains('튤립')) return const Color(0xFFFF6B6B);
    if (name.contains('해바라기')) return const Color(0xFFFFCA28);
    if (name.contains('국화')) return const Color(0xFFFFA726);
    if (name.contains('코스모스')) return const Color(0xFFFF8A65);
    if (name.contains('수국')) return const Color(0xFF7E57C2);
    if (name.contains('동백')) return const Color(0xFFE53935);
    if (name.contains('라벤더')) return const Color(0xFFAB47BC);
    if (name.contains('무궁화')) return const Color(0xFFE91E63);
    if (name.contains('매화')) return const Color(0xFFBDBDBD);
    if (name.contains('진달래')) return const Color(0xFFE8A0BF);
    return const Color(0xFF81C784);
  }

  Widget _buildErrorView(SeasonColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text('데이터를 불러오지 못했습니다', style: TextStyle(color: Colors.grey[500])),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadFlowers,
            style: ElevatedButton.styleFrom(backgroundColor: colors.primary),
            child: const Text('다시 시도', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _FlowerDetailSheet extends StatefulWidget {
  final FlowerData flower;
  final SeasonColors colors;
  final String emoji;
  final Color cardColor;
  final FlowerApiService? api;

  const _FlowerDetailSheet({
    required this.flower, required this.colors, required this.emoji,
    required this.cardColor, this.api,
  });

  @override
  State<_FlowerDetailSheet> createState() => _FlowerDetailSheetState();
}

class _FlowerDetailSheetState extends State<_FlowerDetailSheet> {
  FlowerDetail? _detail;
  bool _loadingDetail = false;

  @override
  void initState() {
    super.initState();
    if (widget.api != null) _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _loadingDetail = true);
    try {
      final detail = await widget.api!.getFlowerDetail(widget.flower.dataNo);
      if (mounted) setState(() { _detail = detail; _loadingDetail = false; });
    } catch (e) {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          Container(
            width: double.infinity, height: 160,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: widget.cardColor.withAlpha(40), borderRadius: BorderRadius.circular(20)),
            child: widget.flower.mainImageUrl.isNotEmpty
                ? ClipRRect(borderRadius: BorderRadius.circular(20),
                    child: Image.network(widget.flower.mainImageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(child: Text(widget.emoji, style: const TextStyle(fontSize: 72)))))
                : Center(child: Text(widget.emoji, style: const TextStyle(fontSize: 72))),
          ),
          Expanded(
            child: _loadingDetail
                ? Center(child: CircularProgressIndicator(color: widget.colors.primary))
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      Text(_detail?.flowNm ?? widget.flower.flowNm, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      if (_detail?.sciNm.isNotEmpty == true)
                        Text(_detail!.sciNm, style: TextStyle(fontSize: 14, color: Colors.grey[500], fontStyle: FontStyle.italic)),
                      const SizedBox(height: 12),
                      _infoChip(Icons.format_quote, '꽃말', _detail?.flowLang ?? widget.flower.flowLang),
                      _infoChip(Icons.calendar_today, '오늘의 꽃', widget.flower.dateString),
                      if (_detail?.fContent.isNotEmpty == true) ...[
                        const SizedBox(height: 16), _sectionTitle('꽃 이야기'),
                        Text(_detail!.fContent, style: const TextStyle(fontSize: 14, height: 1.6)),
                      ],
                      if (_detail?.fUse.isNotEmpty == true) ...[
                        const SizedBox(height: 16), _sectionTitle('이용 방법'),
                        Text(_detail!.fUse, style: const TextStyle(fontSize: 14, height: 1.6)),
                      ],
                      if (_detail?.fGrow.isNotEmpty == true) ...[
                        const SizedBox(height: 16), _sectionTitle('기르기'),
                        Text(_detail!.fGrow, style: const TextStyle(fontSize: 14, height: 1.6)),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: widget.colors.primary),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: widget.colors.primary)),
    );
  }
}
