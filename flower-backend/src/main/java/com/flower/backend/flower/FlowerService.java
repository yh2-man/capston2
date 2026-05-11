package com.flower.backend.flower;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class FlowerService {

    private final FlowerRepository flowerRepository;
    private final FlowerCategoryRepository categoryRepository;
    private final FlowerSpeciesMappingRepository mappingRepository;

    // 카테고리 전체 목록
    public List<FlowerDto.CategoryResponse> getCategories() {
        return categoryRepository.findAll().stream()
                .map(c -> FlowerDto.CategoryResponse.from(c,
                        flowerRepository.findByCategoryId(c.getId()).size()))
                .toList();
    }

    // 카테고리별 꽃 목록
    public List<FlowerDto.FlowerSummary> getFlowersByCategory(Long categoryId) {
        return flowerRepository.findByCategoryId(categoryId).stream()
                .map(FlowerDto.FlowerSummary::from)
                .toList();
    }

    // 이번 달 꽃 목록
    public List<FlowerDto.FlowerSummary> getFlowersByMonth(int month) {
        return flowerRepository.findByBloomMonthOrderByBloomDay(month).stream()
                .map(FlowerDto.FlowerSummary::from)
                .toList();
    }

    // 꽃 상세
    public FlowerDto.FlowerDetail getFlowerDetail(Long id) {
        Flower flower = flowerRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("꽃을 찾을 수 없습니다."));
        return FlowerDto.FlowerDetail.from(flower);
    }

    // 키워드 검색 (이름 or 카테고리명)
    public FlowerDto.SearchResult search(String keyword) {
        List<FlowerDto.FlowerSummary> results = flowerRepository.searchByKeyword(keyword).stream()
                .map(FlowerDto.FlowerSummary::from)
                .toList();
        return FlowerDto.SearchResult.builder()
                .keyword(keyword)
                .flowers(results)
                .total(results.size())
                .build();
    }

    // Plant.id 학명으로 카테고리 매칭 (3단계)
    public FlowerDto.MatchResult matchByScientificName(String scientificName, double confidence) {
        // 1단계: 학명 완전 일치
        Optional<Flower> exactFlower = flowerRepository.findByScientificNameIgnoreCase(scientificName);
        if (exactFlower.isPresent()) {
            Flower f = exactFlower.get();
            return buildMatchResult(f.getCategory(), f, confidence, true);
        }

        // 2단계: 속명(첫 단어)만 일치
        String genus = scientificName.split(" ")[0];
        Optional<FlowerSpeciesMapping> genusMapping = mappingRepository.findByAiNameIgnoreCase(genus);
        if (genusMapping.isPresent()) {
            return buildMatchResult(genusMapping.get().getCategory(), null, confidence, true);
        }

        // 3단계: 매핑 테이블에서 부분 일치
        Optional<FlowerSpeciesMapping> partialMapping = mappingRepository.findByGenusMatch(scientificName);
        if (partialMapping.isPresent()) {
            return buildMatchResult(partialMapping.get().getCategory(), null, confidence, true);
        }

        // 매칭 실패 → 기타 카테고리
        FlowerCategory etc = categoryRepository.findByName("기타").orElse(null);
        return FlowerDto.MatchResult.builder()
                .categoryId(etc != null ? etc.getId() : null)
                .categoryName("기타")
                .categoryEmoji("🌿")
                .confidence(confidence)
                .matched(false)
                .build();
    }

    private FlowerDto.MatchResult buildMatchResult(FlowerCategory category, Flower flower,
                                                    double confidence, boolean matched) {
        return FlowerDto.MatchResult.builder()
                .categoryId(category != null ? category.getId() : null)
                .categoryName(category != null ? category.getName() : null)
                .categoryEmoji(category != null ? category.getEmoji() : null)
                .flowerId(flower != null ? flower.getId() : null)
                .flowerName(flower != null ? flower.getName() : null)
                .confidence(confidence)
                .matched(matched)
                .build();
    }
}
