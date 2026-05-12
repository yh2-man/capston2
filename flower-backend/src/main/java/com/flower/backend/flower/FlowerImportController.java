package com.flower.backend.flower;

import com.flower.backend.common.response.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/admin/flowers")
@RequiredArgsConstructor
public class FlowerImportController {

    private final NongsaroImportService importService;

    // POST /api/v1/admin/flowers/import
    // 농사로 API에서 꽃 데이터 전체 수집
    @PostMapping("/import")
    public ApiResponse<NongsaroImportService.ImportResult> importFromNongsaro() {
        NongsaroImportService.ImportResult result = importService.importAll();
        return ApiResponse.ok(result);
    }
}
