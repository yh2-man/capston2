package com.flower.backend.community;

import com.flower.backend.auth.User;
import com.flower.backend.auth.UserRepository;
import com.flower.backend.community.CommunityDto.*;
import com.flower.backend.storage.StorageService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CommunityService {

    private final CommunityPostRepository postRepository;
    private final PostLikeRepository likeRepository;
    private final SavedPostRepository savedPostRepository;
    private final UserRepository userRepository;
    private final StorageService storageService;

    @Transactional(readOnly = true)
    public FeedResponse getFeed(Long userId, Long cursor, int limit) {
        var pageable = PageRequest.of(0, limit + 1);
        List<CommunityPost> posts = cursor == null
                ? postRepository.findFeed(pageable)
                : postRepository.findFeedByCursor(cursor, pageable);

        boolean hasNext = posts.size() > limit;
        if (hasNext) posts = posts.subList(0, limit);

        Long nextCursor = hasNext ? posts.get(posts.size() - 1).getId() : null;

        return FeedResponse.builder()
                .posts(posts.stream().map(p -> toResponse(p, userId)).collect(Collectors.toList()))
                .nextCursor(nextCursor)
                .hasNext(hasNext)
                .build();
    }

    @Transactional
    public PostResponse createPost(Long userId, String content, String flowerSpecies,
                                   MultipartFile image, Double latitude, Double longitude, String address) {
        User user = userRepository.findById(userId).orElseThrow();

        String imageUrl = null;
        if (image != null && !image.isEmpty()) {
            imageUrl = storageService.upload(image);
        }

        CommunityPost post = CommunityPost.builder()
                .user(user)
                .content(content)
                .flowerSpecies(flowerSpecies)
                .imageUrl(imageUrl)
                .latitude(latitude)
                .longitude(longitude)
                .address(address)
                .build();

        return toResponse(postRepository.save(post), userId);
    }

    @Transactional
    public Map<String, Object> toggleLike(Long userId, Long postId) {
        PostLikeId likeId = new PostLikeId(userId, postId);
        CommunityPost post = postRepository.findById(postId).orElseThrow();

        boolean liked;
        if (likeRepository.existsById(likeId)) {
            likeRepository.deleteById(likeId);
            post.decreaseLikeCount();
            liked = false;
        } else {
            likeRepository.save(new PostLike(likeId));
            post.increaseLikeCount();
            liked = true;
        }
        postRepository.save(post);
        return Map.of("liked", liked, "likeCount", post.getLikeCount());
    }

    @Transactional
    public Map<String, Object> toggleSave(Long userId, Long postId) {
        SavedPostId savedId = new SavedPostId(userId, postId);

        boolean saved;
        if (savedPostRepository.existsById(savedId)) {
            savedPostRepository.deleteById(savedId);
            saved = false;
        } else {
            savedPostRepository.save(new SavedPost(savedId));
            saved = true;
        }
        return Map.of("saved", saved);
    }

    private PostResponse toResponse(CommunityPost post, Long userId) {
        return PostResponse.builder()
                .id(post.getId())
                .userId(post.getUser().getId())
                .nickname(post.getUser().getNickname())
                .profileImageUrl(post.getUser().getProfileImageUrl())
                .content(post.getContent())
                .flowerSpecies(post.getFlowerSpecies())
                .imageUrl(post.getImageUrl())
                .address(post.getAddress())
                .latitude(post.getLatitude())
                .longitude(post.getLongitude())
                .likeCount(post.getLikeCount())
                .liked(likeRepository.existsById(new PostLikeId(userId, post.getId())))
                .saved(savedPostRepository.existsById(new SavedPostId(userId, post.getId())))
                .createdAt(post.getCreatedAt() != null ? post.getCreatedAt().toString() : "")
                .build();
    }
}
