package com.flower.backend.flower;

import com.flower.backend.common.response.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/flowers")
@RequiredArgsConstructor
public class FlowerController {

    private final FlowerService flowerService;

    // 카테고리 목록
    @GetMapping("/categories")
    public ApiResponse<List<FlowerDto.CategoryResponse>> getCategories() {
        return ApiResponse.ok(flowerService.getCategories());
    }

    // 카테고리별 꽃 목록
    @GetMapping("/categories/{categoryId}")
    public ApiResponse<List<FlowerDto.FlowerSummary>> getByCategory(@PathVariable Long categoryId) {
        return ApiResponse.ok(flowerService.getFlowersByCategory(categoryId));
    }

    // 이번 달 꽃
    @GetMapping("/monthly/{month}")
    public ApiResponse<List<FlowerDto.FlowerSummary>> getByMonth(@PathVariable int month) {
        return ApiResponse.ok(flowerService.getFlowersByMonth(month));
    }

    // 꽃 상세
    @GetMapping("/{id}")
    public ApiResponse<FlowerDto.FlowerDetail> getDetail(@PathVariable Long id) {
        return ApiResponse.ok(flowerService.getFlowerDetail(id));
    }

    // 검색
    @GetMapping("/search")
    public ApiResponse<FlowerDto.SearchResult> search(@RequestParam String keyword) {
        return ApiResponse.ok(flowerService.search(keyword));
    }

    // Plant.id 학명 매칭
    @GetMapping("/match")
    public ApiResponse<FlowerDto.MatchResult> match(
            @RequestParam String scientificName,
            @RequestParam(defaultValue = "0.0") double confidence) {
        return ApiResponse.ok(flowerService.matchByScientificName(scientificName, confidence));
    }
}
