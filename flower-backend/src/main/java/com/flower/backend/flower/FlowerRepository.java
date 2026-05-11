package com.flower.backend.flower;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface FlowerRepository extends JpaRepository<Flower, Long> {

    Optional<Flower> findByDataNo(String dataNo);

    // 꽃 이름 검색 (카테고리 내 전체)
    @Query("""
        SELECT f FROM Flower f
        WHERE f.category.id = :categoryId
        ORDER BY f.bloomMonth, f.bloomDay
    """)
    List<Flower> findByCategoryId(@Param("categoryId") Long categoryId);

    // 이름으로 검색 (포괄 카테고리 포함)
    @Query("""
        SELECT f FROM Flower f
        WHERE f.name LIKE %:keyword%
           OR f.category.name LIKE %:keyword%
        ORDER BY f.bloomMonth, f.bloomDay
    """)
    List<Flower> searchByKeyword(@Param("keyword") String keyword);

    // 개화월로 조회
    List<Flower> findByBloomMonthOrderByBloomDay(Integer bloomMonth);

    // 학명으로 조회 (Plant.id 매칭용)
    Optional<Flower> findByScientificNameIgnoreCase(String scientificName);

    // 속명(학명 첫 단어)으로 검색
    @Query("SELECT f FROM Flower f WHERE f.scientificName LIKE :genus%")
    List<Flower> findByGenus(@Param("genus") String genus);
}
