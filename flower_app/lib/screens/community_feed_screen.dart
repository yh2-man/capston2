import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/season_theme.dart';
import '../services/community_api_service.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  List<CommunityPost> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';
    final posts = await CommunityApiService.getPosts(token);
    if (mounted) setState(() { _posts = posts; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final colors = SeasonTheme.getColors();
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colors.primary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('커뮤니티', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: colors.primary),
            onPressed: () => _showNewPostDialog(context, colors),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colors.primary))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _posts.length,
              itemBuilder: (context, index) => _buildPostCard(_posts[index], colors, index),
            ),
    );
  }

  Widget _buildPostCard(CommunityPost post, SeasonColors colors, int index) {
    final flowerColors = [
      const Color(0xFFFFB7C5), const Color(0xFFFFE082),
      const Color(0xFFE8A0BF), const Color(0xFFF5F5F5), const Color(0xFFFF6B6B),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: colors.primary.withAlpha(15), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colors.primary.withAlpha(25),
                  child: Text(post.avatar, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.user, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Row(children: [
                        if (post.location != null) ...[
                          Icon(Icons.location_on, size: 12, color: Colors.grey[400]),
                          const SizedBox(width: 2),
                          Text(post.location!, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                          const SizedBox(width: 8),
                        ],
                        Text(post.time, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                      ]),
                    ],
                  ),
                ),
                if (post.flowerSpecies != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: colors.primary.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                    child: Text(post.flowerSpecies!, style: TextStyle(fontSize: 11, color: colors.primary, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          Container(
            height: 200, width: double.infinity,
            color: flowerColors[index % flowerColors.length].withAlpha(80),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(post.avatar, style: const TextStyle(fontSize: 60)),
                  const SizedBox(height: 4),
                  Text('${post.flowerSpecies ?? ''} 사진', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(post.content, style: const TextStyle(fontSize: 14, height: 1.5)),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 14, bottom: 10),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    post.liked ? Icons.favorite : Icons.favorite_border,
                    color: post.liked ? Colors.red[400] : Colors.grey[400], size: 22,
                  ),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString('accessToken') ?? '';
                    await CommunityApiService.likePost(token, post.id);
                    setState(() {
                      post.liked = !post.liked;
                    });
                  },
                ),
                Text('${post.likeCount}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                const SizedBox(width: 16),
                Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey[400]),
                const Spacer(),
                Icon(Icons.bookmark_border, size: 22, color: Colors.grey[400]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNewPostDialog(BuildContext context, SeasonColors colors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('새 게시글', style: TextStyle(color: colors.primary)),
        content: const Text('게시글 작성 기능은 백엔드 서버 연동 후 사용 가능합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인', style: TextStyle(color: colors.primary)),
          ),
        ],
      ),
    );
  }
}
