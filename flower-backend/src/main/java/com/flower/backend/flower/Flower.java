package com.flower.backend.flower;

import jakarta.persistence.*;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Entity
@Table(name = "flowers")
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Flower {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, length = 20)
    private String dataNo;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(length = 200)
    private String scientificName;

    private Integer bloomMonth;
    private Integer bloomDay;

    @Column(columnDefinition = "TEXT")
    private String flowerLanguage;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(columnDefinition = "TEXT")
    private String growTips;

    @Column(length = 1024)
    private String imageUrl;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id")
    private FlowerCategory category;
}
