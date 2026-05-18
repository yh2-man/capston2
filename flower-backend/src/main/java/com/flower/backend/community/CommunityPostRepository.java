package com.flower.backend.community;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

public interface CommunityPostRepository extends JpaRepository<CommunityPost, Long> {

    @Query("SELECT p FROM CommunityPost p ORDER BY p.createdAt DESC")
    List<CommunityPost> findFeed(Pageable pageable);

    @Query("SELECT p FROM CommunityPost p WHERE p.id < :cursor ORDER BY p.createdAt DESC")
    List<CommunityPost> findFeedByCursor(@Param("cursor") Long cursor, Pageable pageable);

    @Query("SELECT p FROM CommunityPost p WHERE p.postType = 'FLOWER_SPOT' AND p.createdAt >= :since ORDER BY p.createdAt DESC")
    List<CommunityPost> findFlowerSpots(@Param("since") LocalDateTime since, Pageable pageable);

    @Query("SELECT p FROM CommunityPost p WHERE p.postType = 'FLOWER_SPOT' AND p.id < :cursor AND p.createdAt >= :since ORDER BY p.createdAt DESC")
    List<CommunityPost> findFlowerSpotsByCursor(@Param("cursor") Long cursor, @Param("since") LocalDateTime since, Pageable pageable);

    @Query("""
        SELECT p FROM CommunityPost p
        WHERE LOWER(p.content) LIKE LOWER(CONCAT('%', :keyword, '%'))
           OR LOWER(p.flowerSpecies) LIKE LOWER(CONCAT('%', :keyword, '%'))
        ORDER BY p.createdAt DESC
    """)
    List<CommunityPost> searchByKeyword(@Param("keyword") String keyword, Pageable pageable);

    @Modifying
    @Query("UPDATE CommunityPost p SET p.commentCount = p.commentCount + 1 WHERE p.id = :postId")
    int incrementCommentCount(@Param("postId") Long postId);

    @Modifying
    @Query("UPDATE CommunityPost p SET p.commentCount = CASE WHEN p.commentCount > 0 THEN p.commentCount - 1 ELSE 0 END WHERE p.id = :postId")
    int decrementCommentCount(@Param("postId") Long postId);
}
