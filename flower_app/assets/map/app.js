(function () {
  'use strict';

  const config = window.MAP_CONFIG || {};
  const statusLabels = window.STATUS_LABELS || {
    before: 'Before',
    blooming: 'Blooming',
    done: 'Finished',
  };
  const speciesColors = window.SPECIES_COLORS || {
    'Cherry Blossom': '#ff7aa2',
    Azalea: '#d879e8',
    Forsythia: '#f2c84b',
    Tulip: '#ee6b6e',
    default: '#6a9c89',
  };
  const state = {
    map: null,
    flowers: [],
    filtered: [],
    festivals: [],
    posts: [],
    viewMode: 'festival',
    currentPosition: null,
    radius: config.DEFAULT_RADIUS || 5000,
    selectedSpecies: null,
    selectedStatus: null,
    search: '',
    kakaoReady: false,
    mapError: null,
    markers: [],
    festivalMarkers: [],
    postMarkers: [],
    routePolyline: null,
    routeStartMarker: null,
    routeEndMarker: null,
    routeSteps: [],
    _festivalCache: null,
    _festivalCacheTime: 0,
  };

  // Mock 게시글 데이터 (Phase 2에서 Supabase로 교체)
  var mockPosts = [
    { id: 1, nickname: '꽃사랑봄', species: '벚꽃', content: '여의도에서 만개한 벚꽃을 발견했어요! 🌸', lat: 37.5219, lng: 126.9245, location: '여의도 한강공원', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e5/Cherry_blossoms_in_Vancouver_3_crop.jpg/320px-Cherry_blossoms_in_Vancouver_3_crop.jpg', likesCount: 42, createdAt: '2026-04-01' },
    { id: 2, nickname: '산책매니아', species: '개나리', content: '산책길에 노란 개나리가 활짝 폈네요!', lat: 37.5512, lng: 126.9882, location: '남산 둘레길', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/19/Forsythia_koreana_1.JPG/320px-Forsythia_koreana_1.JPG', likesCount: 28, createdAt: '2026-04-02' },
    { id: 3, nickname: '플라워헌터', species: '진달래', content: '관악산 등산로에서 진달래 군락지를 발견! ✅', lat: 37.4418, lng: 126.9637, location: '관악산 등산로', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a0/RhsijokRhododendron_schlippenbachii2.jpg/320px-RhsijokRhododendron_schlippenbachii2.jpg', likesCount: 56, createdAt: '2026-04-03' },
    { id: 4, nickname: '정원사킴', species: '튤립', content: '올림픽공원 튤립 정원이 정말 화려해요! 🌷', lat: 37.5207, lng: 127.1214, location: '올림픽공원', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/44/Tulip_-_florescence.jpg/320px-Tulip_-_florescence.jpg', likesCount: 35, createdAt: '2026-04-04' },
    { id: 5, nickname: '자연탐험가', species: '벚꽃', content: '석촌호수 벚꽃길이 환상적이에요!', lat: 37.5085, lng: 127.1020, location: '석촌호수', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e5/Cherry_blossoms_in_Vancouver_3_crop.jpg/320px-Cherry_blossoms_in_Vancouver_3_crop.jpg', likesCount: 89, createdAt: '2026-04-05' },
  ];

  const $ = (selector) => document.querySelector(selector);

  function init() {
    bindControls();
    bindKakaoEvents();
    initGeolocation();
    loadFlowers();
    loadFestivals();
  }

  function bindKakaoEvents() {
    document.addEventListener('kakao-map-ready', () => {
      state.kakaoReady = true;
      state.mapError = null;
      renderMap();
    });

    document.addEventListener('kakao-map-error', () => {
      state.kakaoReady = false;
      state.mapError = 'Kakao Maps SDK could not be loaded. Check the JavaScript key, platform domain, and network access.';
      renderMap();
    });
  }

  async function loadFlowers() {
    const apiFlowers = await fetchFlowersFromApi();
    state.flowers = apiFlowers || [];
    renderFilters();
    applyFilters();
  }

  async function loadFestivals() {
    var cacheAge = Date.now() - state._festivalCacheTime;
    if (state._festivalCache && cacheAge < 300000) {
      state.festivals = state._festivalCache;
      renderMap();
      renderFestivalList();
      return;
    }
    const tourKey = config.TOUR_API_KEY;
    if (!tourKey) {
      console.log('[Festival] TOUR_API_KEY not set, skipping.');
      return;
    }
    console.log('[Festival] Loading festivals with key:', tourKey.substring(0, 8) + '...');
    try {
      const now = new Date();
      const eventStartDate = now.getFullYear() +
        String(now.getMonth() + 1).padStart(2, '0') +
        String(now.getDate()).padStart(2, '0');
      const params = new URLSearchParams({
        numOfRows: '50',
        pageNo: '1',
        MobileOS: 'ETC',
        MobileApp: 'FlowerApp',
        _type: 'json',
        eventStartDate: eventStartDate,
      });
      // serviceKey는 URLSearchParams가 이중 인코딩하면 안 되므로 직접 붙인다
      const url = 'https://apis.data.go.kr/B551011/KorService2/searchFestival2?serviceKey=' + tourKey + '&' + params.toString();
      console.log('[Festival] Fetching:', url.substring(0, 100) + '...');
      const response = await fetch(url);
      console.log('[Festival] Response status:', response.status);
      if (!response.ok) {
        const text = await response.text();
        console.warn('[Festival] API error response:', text.substring(0, 300));
        return;
      }
      const text = await response.text();
      console.log('[Festival] Raw response (first 500 chars):', text.substring(0, 500));

      // XML 에러 응답 감지
      if (text.trim().startsWith('<')) {
        console.warn('[Festival] Received XML instead of JSON. Check API key or _type parameter.');
        return;
      }

      const data = JSON.parse(text);
      const resultCode = data?.response?.header?.resultCode;
      const resultMsg = data?.response?.header?.resultMsg;
      console.log('[Festival] resultCode:', resultCode, 'resultMsg:', resultMsg);

      const items = data?.response?.body?.items?.item;
      if (!items) {
        console.log('[Festival] No items in response. body:', JSON.stringify(data?.response?.body).substring(0, 200));
        state.festivals = [];
        renderMap();
        return;
      }

      // item이 1개일 때 배열이 아닌 경우 처리
      const itemList = Array.isArray(items) ? items : [items];
      console.log('[Festival] Total festivals from API:', itemList.length);

      state.festivals = itemList
        .filter(function (item) {
          var mapX = Number(item.mapx || 0);
          var mapY = Number(item.mapy || 0);
          return mapX !== 0 && mapY !== 0;
        })
        .map(function (item) {
          return {
            contentId: item.contentid || '',
            title: item.title || '',
            addr1: item.addr1 || '',
            addr2: item.addr2 || '',
            mapX: Number(item.mapx),
            mapY: Number(item.mapy),
            firstImage: item.firstimage || '',
            firstImage2: item.firstimage2 || '',
            tel: item.tel || '',
            eventStartDate: item.eventstartdate || '',
            eventEndDate: item.eventenddate || '',
          };
        });
      state._festivalCache = state.festivals.slice();
      state._festivalCacheTime = Date.now();
      console.log('[Festival] Festivals with coordinates:', state.festivals.length);
      if (state.festivals.length > 0) {
        console.log('[Festival] First festival:', state.festivals[0].title, state.festivals[0].mapY, state.festivals[0].mapX);
      }
      renderMap();
      renderFestivalList();
    } catch (error) {
      console.warn('[Festival] Load error:', error);
    }
  }

  async function fetchFlowersFromApi() {
    const baseUrl = config.API_BASE_URL;
    if (!baseUrl) return null;

    try {
      const center = state.currentPosition || config.DEFAULT_CENTER || { lat: 37.5665, lng: 126.9780 };
      const params = new URLSearchParams({
        lat: center.lat,
        lng: center.lng,
        radius: state.radius,
        limit: config.DEFAULT_LIMIT || 50
      });

      const response = await fetch(`${baseUrl}/flowers?${params.toString()}`);
      if (!response.ok) return null;
      const body = await response.json();
      const data = Array.isArray(body) ? body : body.data;
      return normalizeFlowers(data || []);
    } catch (error) {
      console.warn('Flower API is unavailable.', error);
      return null;
    }
  }

  function normalizeFlowers(flowers) {
    return flowers.map((flower) => {
      const lat = flower.location?.lat ?? flower.lat ?? flower.mapY;
      const lng = flower.location?.lng ?? flower.lng ?? flower.mapX;
      return {
        flower_id: flower.flower_id ?? flower.flowerId ?? flower.id,
        name: flower.name,
        species: flower.species,
        description: flower.description || '',
        address: flower.address || '',
        location: { lat: Number(lat), lng: Number(lng) },
        status: flower.status || 'blooming',
        bloom_start: flower.bloom_start ?? flower.bloomStart,
        bloom_end: flower.bloom_end ?? flower.bloomEnd,
        thumbnail_url: flower.thumbnail_url ?? flower.thumbnailUrl ?? '',
        images: flower.images || [],
        community_count: flower.community_count ?? flower.communityCount ?? 0,
        distance_m: flower.distance_m ?? flower.distanceM
      };
    }).filter((flower) => Number.isFinite(flower.location.lat) && Number.isFinite(flower.location.lng));
  }

  function renderFilters() {
    const species = [...new Set(state.flowers.map((flower) => flower.species).filter(Boolean))];
    const speciesFilter = $('#species-filter');
    speciesFilter.innerHTML = '';
    speciesFilter.appendChild(createChip('All', !state.selectedSpecies, () => {
      state.selectedSpecies = null;
      renderFilters();
      applyFilters();
    }));

    species.forEach((name) => {
      speciesFilter.appendChild(createChip(name, state.selectedSpecies === name, () => {
        state.selectedSpecies = state.selectedSpecies === name ? null : name;
        renderFilters();
        applyFilters();
      }, getSpeciesColor(name)));
    });

    const statuses = [
      ['blooming', 'Blooming'],
      ['before', 'Before'],
      ['done', 'Finished']
    ];
    const statusFilter = $('#status-filter');
    statusFilter.innerHTML = '';
    statuses.forEach(([key, label]) => {
      statusFilter.appendChild(createChip(label, state.selectedStatus === key, () => {
        state.selectedStatus = state.selectedStatus === key ? null : key;
        renderFilters();
        applyFilters();
      }));
    });
  }

  function createChip(label, active, onClick, color) {
    const button = document.createElement('button');
    button.type = 'button';
    button.className = `chip${active ? ' active' : ''}`;
    if (color) {
      const dot = document.createElement('span');
      dot.className = 'dot';
      dot.style.background = color;
      button.appendChild(dot);
    }
    button.appendChild(document.createTextNode(label));
    button.addEventListener('click', onClick);
    return button;
  }

  function applyFilters() {
    const query = state.search.toLowerCase();
    const center = state.currentPosition;
    state.filtered = state.flowers.filter((flower) => {
      if (state.selectedSpecies && flower.species !== state.selectedSpecies) return false;
      if (state.selectedStatus && flower.status !== state.selectedStatus) return false;
      if (query && !`${flower.name} ${flower.species} ${flower.address}`.toLowerCase().includes(query)) return false;
      if (center) {
        flower.distance_m = Math.round(distanceMeters(center.lat, center.lng, flower.location.lat, flower.location.lng));
        if (flower.distance_m > state.radius) return false;
      }
      return true;
    });

    renderMap();
    updateBadge();
    renderFestivalList();
  }

  function renderFestivalList() {
    var listEl = $('#festival-list');
    var itemsEl = $('#festival-items');
    var countEl = $('#festival-count');
    var headerEl = listEl ? listEl.querySelector('.festival-list-header strong') : null;
    if (!listEl || !itemsEl) return;

    if (state.viewMode === 'flower') {
      // 꽃 모드: 주변 게시글 목록
      if (headerEl) headerEl.textContent = '📍 주변 꽃들';
      loadPosts();
      if (state.posts.length === 0) {
        listEl.hidden = true;
        return;
      }
      countEl.textContent = state.posts.length + '건';
      itemsEl.innerHTML = '';

      state.posts.forEach(function (p) {
        var el = document.createElement('div');
        el.className = 'festival-item';

        var thumbHtml = p.imageUrl
          ? '<img class="festival-item-thumb" src="' + escapeHtml(p.imageUrl) + '" alt="">'
          : '<div class="festival-item-thumb" style="display:grid;place-items:center;font-size:20px;">📷</div>';

        var distText = p._dist !== null ? formatDistance(p._dist) : '';

        el.innerHTML = thumbHtml
          + '<div class="festival-item-info">'
          + '  <div class="festival-item-title">' + escapeHtml(p.species + ' · ' + p.nickname) + '</div>'
          + '  <div class="festival-item-sub">' + escapeHtml(p.location || p.content) + '</div>'
          + '</div>'
          + (distText ? '<div class="festival-item-dist">' + distText + '</div>' : '');

        el.addEventListener('click', function () { openPostSheet(p); });
        itemsEl.appendChild(el);
      });
      listEl.hidden = false;
    } else {
      // 축제 모드: 주변 축제 목록
      if (headerEl) headerEl.textContent = '🌸 주변 축제';
      if (state.festivals.length === 0) {
        listEl.hidden = true;
        return;
      }

      var center = state.currentPosition;
      var sorted = state.festivals.map(function (f) {
        var dist = center
          ? Math.round(distanceMeters(center.lat, center.lng, f.mapY, f.mapX))
          : null;
        return Object.assign({}, f, { _dist: dist });
      });
      if (center) {
        sorted.sort(function (a, b) { return a._dist - b._dist; });
      }

      countEl.textContent = sorted.length + '건';
      itemsEl.innerHTML = '';

      sorted.forEach(function (f) {
        var el = document.createElement('div');
        el.className = 'festival-item';

        var imgSrc = f.firstImage || f.firstImage2 || '';
        var thumbHtml = imgSrc
          ? '<img class="festival-item-thumb" src="' + escapeHtml(imgSrc) + '" alt="">'
          : '<div class="festival-item-thumb" style="display:grid;place-items:center;font-size:20px;">🌸</div>';

        var distText = f._dist !== null ? formatDistance(f._dist) : '';
        var addr = ((f.addr1 || '') + ' ' + (f.addr2 || '')).trim();

        el.innerHTML = thumbHtml
          + '<div class="festival-item-info">'
          + '  <div class="festival-item-title">' + escapeHtml(f.title) + '</div>'
          + '  <div class="festival-item-sub">' + escapeHtml(addr) + '</div>'
          + '</div>'
          + (distText ? '<div class="festival-item-dist">' + distText + '</div>' : '');

        el.addEventListener('click', function () { openFestivalSheet(f); });
        itemsEl.appendChild(el);
      });
      listEl.hidden = false;
    }
  }

  function renderMap() {
    if (state.mapError) {
      showMapError(state.mapError);
      return;
    }

    if (!config.KAKAO_APP_KEY || config.KAKAO_APP_KEY === 'YOUR_KAKAO_JS_KEY_HERE') {
      showMapError('Kakao Maps JavaScript key is not configured. Run Flutter with --dart-define=KAKAO_MAP_KEY=...');
      return;
    }

    if (
      state.kakaoReady &&
      window.kakao?.maps &&
      config.KAKAO_APP_KEY !== 'YOUR_KAKAO_JS_KEY_HERE'
    ) {
      if (renderKakaoMap()) return;
      state.kakaoReady = false;
      state.map = null;
      clearKakaoMarkers();
      showMapError('Kakao map could not be rendered. Check the JavaScript key domain settings and WebView origin.');
      return;
    }

    showMapStatus('Loading Kakao map...');
  }

  function clearKakaoMarkers() {
    state.markers.forEach((marker) => marker.setMap(null));
    state.markers = [];
    state.festivalMarkers.forEach((marker) => marker.setMap(null));
    state.festivalMarkers = [];
    state.postMarkers.forEach((marker) => marker.setMap(null));
    state.postMarkers = [];
  }

  function createFestivalMarkerImage() {
    try {
      var svg = '<svg xmlns="http://www.w3.org/2000/svg" width="36" height="44" viewBox="0 0 36 44">'
        + '<path d="M18 0C8.06 0 0 8.06 0 18c0 12.6 18 26 18 26s18-13.4 18-26C36 8.06 27.94 0 18 0z" fill="%23e74c8b"/>'
        + '<circle cx="18" cy="16" r="9" fill="white" opacity="0.9"/>'
        + '<text x="18" y="20" text-anchor="middle" font-size="13" font-weight="bold" fill="%23e74c8b">&#x1F338;</text>'
        + '</svg>';
      var size = new kakao.maps.Size(36, 44);
      var option = { offset: new kakao.maps.Point(18, 44) };
      return new kakao.maps.MarkerImage(
        'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(svg.replace(/%23/g, '#')),
        size, option
      );
    } catch (e) {
      return null;
    }
  }

  function createPostMarkerImage() {
    try {
      var svg = '<svg xmlns="http://www.w3.org/2000/svg" width="36" height="44" viewBox="0 0 36 44">'
        + '<path d="M18 0C8.06 0 0 8.06 0 18c0 12.6 18 26 18 26s18-13.4 18-26C36 8.06 27.94 0 18 0z" fill="%234CAF50"/>'
        + '<circle cx="18" cy="16" r="9" fill="white" opacity="0.9"/>'
        + '<text x="18" y="20" text-anchor="middle" font-size="14" font-weight="bold" fill="%234CAF50">&#x1F4F7;</text>'
        + '</svg>';
      var size = new kakao.maps.Size(36, 44);
      var option = { offset: new kakao.maps.Point(18, 44) };
      return new kakao.maps.MarkerImage(
        'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(svg.replace(/%23/g, '#')),
        size, option
      );
    } catch (e) {
      return null;
    }
  }

  function updateViewMode() {
    if (!state.map) return;
    var level = state.map.getLevel();
    var newMode = level <= 5 ? 'flower' : 'festival';
    if (newMode !== state.viewMode) {
      state.viewMode = newMode;
      console.log('[Map] View mode changed to:', newMode, '(zoom level:', level, ')');
      renderMapMarkers();
      renderFestivalList();
    }
  }

  function loadPosts() {
    // Phase 2에서 Supabase REST API로 교체
    var center = state.currentPosition;
    state.posts = mockPosts.map(function (p) {
      var dist = center ? Math.round(distanceMeters(center.lat, center.lng, p.lat, p.lng)) : null;
      return Object.assign({}, p, { _dist: dist });
    });
    if (center) {
      state.posts.sort(function (a, b) { return a._dist - b._dist; });
    }
  }

  function renderKakaoMap() {
    try {
      if (!state.map) {
        const center = config.DEFAULT_CENTER || { lat: 37.5665, lng: 126.9780 };
        state.map = new kakao.maps.Map($('#map'), {
          center: new kakao.maps.LatLng(center.lat, center.lng),
          level: config.DEFAULT_ZOOM_LEVEL || 5
        });

        // 줌 변경 이벤트 리스너
        kakao.maps.event.addListener(state.map, 'zoom_changed', function () {
          var level = state.map.getLevel();
          var newMode = level <= 5 ? 'flower' : 'festival';
          console.log('[Map] zoom_changed → level:', level, 'mode:', newMode);
          state.viewMode = newMode;
          loadPosts();
          renderMapMarkers();
          renderFestivalList();
        });

        // 초기 viewMode 설정
        var initLevel = state.map.getLevel();
        state.viewMode = initLevel <= 5 ? 'flower' : 'festival';
        console.log('[Map] Initial zoom level:', initLevel, 'mode:', state.viewMode);
        loadPosts();
      }

      renderMapMarkers();
      renderFestivalList();
      return true;
    } catch (error) {
      console.error('Kakao Maps could not be rendered.', error);
      return false;
    }
  }

  function renderMapMarkers() {
    if (!state.map) return;
    clearKakaoMarkers();

    // 꽃 데이터(백엔드) 마커는 항상 표시
    state.filtered.forEach(function (flower) {
      var position = new kakao.maps.LatLng(flower.location.lat, flower.location.lng);
      var marker = new kakao.maps.Marker({ position: position });
      marker.setMap(state.map);
      kakao.maps.event.addListener(marker, 'click', function () { openBottomSheet(flower); });
      state.markers.push(marker);
    });

    if (state.viewMode === 'festival') {
      // 축제 모드: 축제 마커 표시
      var festivalImage = createFestivalMarkerImage();
      state.festivals.forEach(function (festival) {
        var position = new kakao.maps.LatLng(festival.mapY, festival.mapX);
        var markerOpts = { position: position };
        if (festivalImage) markerOpts.image = festivalImage;
        var marker = new kakao.maps.Marker(markerOpts);
        marker.setMap(state.map);
        kakao.maps.event.addListener(marker, 'click', function () {
          openFestivalSheet(festival);
        });
        state.festivalMarkers.push(marker);
      });
    } else {
      // 꽃 모드: 게시글 마커 표시
      var postImage = createPostMarkerImage();
      state.posts.forEach(function (post) {
        var position = new kakao.maps.LatLng(post.lat, post.lng);
        var markerOpts = { position: position };
        if (postImage) markerOpts.image = postImage;
        var marker = new kakao.maps.Marker(markerOpts);
        marker.setMap(state.map);
        kakao.maps.event.addListener(marker, 'click', function () {
          openPostSheet(post);
        });
        state.postMarkers.push(marker);
      });
    }
  }

  function zoomMap(delta) {
    if (state.map && state.kakaoReady && window.kakao?.maps) {
      const nextLevel = Math.max(1, Math.min(14, state.map.getLevel() + delta));
      state.map.setLevel(nextLevel);
      return;
    }
  }

  function showMapStatus(message) {
    const map = $('#map');
    clearKakaoMarkers();
    map.innerHTML = `<div class="map-message">${escapeHtml(message)}</div>`;
  }

  function showMapError(message) {
    const map = $('#map');
    clearKakaoMarkers();
    map.innerHTML = `<div class="map-message error">${escapeHtml(message)}</div>`;
  }

  function bindControls() {
    var debouncedFilter = debounce(function () { applyFilters(); }, 300);
    $('#search-input').addEventListener('input', function (event) {
      state.search = event.target.value.trim();
      debouncedFilter();
    });

    var debouncedRadius = debounce(function () { applyFilters(); }, 200);
    $('#radius-slider').addEventListener('input', function (event) {
      state.radius = Number(event.target.value);
      updateRadiusLabel();
      debouncedRadius();
    });

    $('#btn-gps').addEventListener('click', initGeolocation);
    $('#btn-zoom-in').addEventListener('click', () => zoomMap(-1));
    $('#btn-zoom-out').addEventListener('click', () => zoomMap(1));
    $('#bottom-sheet-overlay').addEventListener('click', closeBottomSheet);
    updateRadiusLabel();
  }

  function initGeolocation() {
    if (!navigator.geolocation) return;
    navigator.geolocation.getCurrentPosition((position) => {
      state.currentPosition = {
        lat: position.coords.latitude,
        lng: position.coords.longitude
      };
      loadFlowers();
    }, () => {
      state.currentPosition = null;
      applyFilters();
    }, { enableHighAccuracy: true, timeout: 8000 });
  }

  function openBottomSheet(flower) {
    const content = $('#flower-detail-content');
    content.innerHTML = `
      <div class="detail-title-row">
        <h2>${escapeHtml(flower.name)}</h2>
        <strong>${escapeHtml(statusLabels[flower.status] || flower.status)}</strong>
      </div>
      <p class="detail-meta">${escapeHtml(flower.description || 'No description yet.')}</p>
      <p class="detail-meta">${escapeHtml(flower.address)}</p>
      <div class="detail-grid">
        <div class="detail-card"><span>Species</span>${escapeHtml(flower.species || '-')}</div>
        <div class="detail-card"><span>Distance</span>${formatDistance(flower.distance_m)}</div>
        <div class="detail-card"><span>Bloom start</span>${escapeHtml(flower.bloom_start || '-')}</div>
        <div class="detail-card"><span>Bloom end</span>${escapeHtml(flower.bloom_end || '-')}</div>
      </div>
      <div class="action-row">
        <button class="action-btn" id="btn-navigate" type="button">Directions</button>
        <button class="action-btn secondary" id="btn-close" type="button">Close</button>
      </div>
    `;
    $('#btn-navigate').addEventListener('click', () => navigateToFlower(flower));
    $('#btn-close').addEventListener('click', closeBottomSheet);
    $('#bottom-sheet-overlay').classList.add('visible');
    $('#bottom-sheet').classList.add('visible');
  }

  function closeBottomSheet() {
    $('#bottom-sheet-overlay').classList.remove('visible');
    $('#bottom-sheet').classList.remove('visible');
  }

  function formatFestivalDate(yyyymmdd) {
    if (!yyyymmdd || yyyymmdd.length !== 8) return yyyymmdd || '-';
    return yyyymmdd.substring(0, 4) + '.' + yyyymmdd.substring(4, 6) + '.' + yyyymmdd.substring(6, 8);
  }

  function openPostSheet(post) {
    var content = $('#flower-detail-content');
    var imageHtml = post.imageUrl
      ? '<img src="' + escapeHtml(post.imageUrl) + '" alt="' + escapeHtml(post.species) + '" style="width:100%;max-height:180px;object-fit:cover;border-radius:12px;margin-bottom:12px;">'
      : '';
    var distText = post._dist !== null ? formatDistance(post._dist) : '-';
    content.innerHTML = imageHtml
      + '<div class="detail-title-row">'
      + '  <h2>' + escapeHtml(post.species) + '</h2>'
      + '  <strong style="color:#4CAF50;">게시글</strong>'
      + '</div>'
      + '<p class="detail-meta">' + escapeHtml(post.content) + '</p>'
      + '<div class="detail-grid">'
      + '  <div class="detail-card"><span>위치</span>' + escapeHtml(post.location || '-') + '</div>'
      + '  <div class="detail-card"><span>거리</span>' + distText + '</div>'
      + '  <div class="detail-card"><span>작성자</span>' + escapeHtml(post.nickname) + '</div>'
      + '  <div class="detail-card"><span>좋아요</span>❤️ ' + (post.likesCount || 0) + '</div>'
      + '</div>'
      + '<div class="action-row">'
      + '  <button class="action-btn" id="btn-navigate-post" type="button">길찾기</button>'
      + '  <button class="action-btn secondary" id="btn-close" type="button">닫기</button>'
      + '</div>';
    $('#btn-navigate-post').addEventListener('click', function () {
      navigateInApp(post.lat, post.lng, post.location || post.species);
    });
    $('#btn-close').addEventListener('click', closeBottomSheet);
    $('#bottom-sheet-overlay').classList.add('visible');
    $('#bottom-sheet').classList.add('visible');
  }

  function openFestivalSheet(festival) {
    var content = $('#flower-detail-content');
    var period = formatFestivalDate(festival.eventStartDate) + ' ~ ' + formatFestivalDate(festival.eventEndDate);
    var address = ((festival.addr1 || '') + ' ' + (festival.addr2 || '')).trim();
    var imageHtml = festival.firstImage
      ? '<img src="' + escapeHtml(festival.firstImage) + '" alt="' + escapeHtml(festival.title) + '" style="width:100%;max-height:180px;object-fit:cover;border-radius:12px;margin-bottom:12px;">'
      : '';
    content.innerHTML = imageHtml
      + '<div class="detail-title-row">'
      + '  <h2>\uD83C\uDF38 ' + escapeHtml(festival.title) + '</h2>'
      + '  <strong style="color:#e74c8b;">축제</strong>'
      + '</div>'
      + '<p class="detail-meta">' + escapeHtml(address || '주소 정보 없음') + '</p>'
      + '<div class="detail-grid">'
      + '  <div class="detail-card"><span>기간</span>' + escapeHtml(period) + '</div>'
      + '  <div class="detail-card"><span>연락처</span>' + escapeHtml(festival.tel || '-') + '</div>'
      + '</div>'
      + '<div class="action-row">'
      + '  <button class="action-btn" id="btn-navigate-festival" type="button">길찾기</button>'
      + '  <button class="action-btn secondary" id="btn-close" type="button">닫기</button>'
      + '</div>';
    $('#btn-navigate-festival').addEventListener('click', function () {
      navigateInApp(festival.mapY, festival.mapX, festival.title);
    });
    $('#btn-close').addEventListener('click', closeBottomSheet);
    $('#bottom-sheet-overlay').classList.add('visible');
    $('#bottom-sheet').classList.add('visible');
  }

  function navigateToFlower(flower) {
    navigateInApp(flower.location.lat, flower.location.lng, flower.name);
  }

  function updateBadge() {
    $('#info-badge .count').textContent = state.filtered.length;
    $('#no-results').hidden = state.filtered.length !== 0;
  }

  function updateRadiusLabel() {
    $('#radius-value').textContent = state.radius >= 1000
      ? `${(state.radius / 1000).toFixed(1)} km`
      : `${state.radius} m`;
  }

  function getSpeciesColor(species) {
    return speciesColors[species] || speciesColors.default;
  }

  function distanceMeters(lat1, lng1, lat2, lng2) {
    const radius = 6371000;
    const dLat = toRadians(lat2 - lat1);
    const dLng = toRadians(lng2 - lng1);
    const a = Math.sin(dLat / 2) ** 2
      + Math.cos(toRadians(lat1)) * Math.cos(toRadians(lat2)) * Math.sin(dLng / 2) ** 2;
    return radius * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  }

  function toRadians(value) {
    return value * Math.PI / 180;
  }

  function formatDistance(meters) {
    if (!Number.isFinite(Number(meters))) return '-';
    return meters >= 1000 ? `${(meters / 1000).toFixed(1)} km` : `${Math.round(meters)} m`;
  }

  function escapeHtml(value) {
    return String(value ?? '').replace(/[&<>"']/g, (char) => ({
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#039;'
    }[char]));
  }

  // ── Utility ──
  function debounce(fn, delay) {
    var timer = null;
    return function () {
      var args = arguments;
      var ctx = this;
      clearTimeout(timer);
      timer = setTimeout(function () { fn.apply(ctx, args); }, delay);
    };
  }

  // ── In-app walking route ──
  async function navigateInApp(destLat, destLng, destName) {
    closeBottomSheet();
    if (!state.currentPosition) {
      try {
        await new Promise(function (resolve, reject) {
          if (!navigator.geolocation) return reject(new Error('GPS 미지원'));
          navigator.geolocation.getCurrentPosition(
            function (pos) {
              state.currentPosition = { lat: pos.coords.latitude, lng: pos.coords.longitude };
              resolve();
            },
            function () { reject(new Error('위치 권한 거부')); },
            { enableHighAccuracy: true, timeout: 8000 }
          );
        });
      } catch (e) {
        showRouteError('현재 위치를 확인할 수 없습니다. GPS를 켜주세요.');
        return;
      }
    }
    showRouteLoading(destName);
    try {
      var route = await fetchWalkingRoute(
        state.currentPosition.lat, state.currentPosition.lng,
        destLat, destLng
      );
      drawRouteOnMap(route.coordinates, state.currentPosition, { lat: destLat, lng: destLng });
      state.routeSteps = route.steps || [];
      showRoutePanel(route.distance, route.duration, destName, route.steps || []);
    } catch (e) {
      console.warn('[Route] error:', e);
      showRouteError('경로를 찾을 수 없습니다.');
    }
  }

  async function fetchWalkingRoute(startLat, startLng, endLat, endLng) {
    var url = 'https://router.project-osrm.org/route/v1/foot/'
      + startLng + ',' + startLat + ';'
      + endLng + ',' + endLat
      + '?overview=full&geometries=geojson&steps=true';
    var res = await fetch(url);
    if (!res.ok) throw new Error('API ' + res.status);
    var data = await res.json();
    if (!data.routes || data.routes.length === 0) throw new Error('경로 없음');
    var route = data.routes[0];
    var steps = [];
    if (route.legs && route.legs.length > 0) {
      route.legs.forEach(function (leg) {
        if (leg.steps) {
          leg.steps.forEach(function (step) {
            if (step.maneuver && step.distance > 0) {
              steps.push({
                instruction: translateManeuver(step.maneuver.type, step.maneuver.modifier, step.name),
                distance: step.distance,
                duration: step.duration,
                name: step.name || ''
              });
            }
          });
        }
      });
    }
    return {
      coordinates: route.geometry.coordinates,
      distance: route.distance,
      duration: route.duration,
      steps: steps
    };
  }

  function translateManeuver(type, modifier, name) {
    var road = name ? ' (' + name + ')' : '';
    var map = {
      'depart': '출발',
      'arrive': '도착',
      'turn-left': '좌회전', 'turn-right': '우회전',
      'turn-slight left': '살짝 좌회전', 'turn-slight right': '살짝 우회전',
      'turn-sharp left': '크게 좌회전', 'turn-sharp right': '크게 우회전',
      'continue-straight': '직진', 'continue-': '직진',
      'fork-left': '왼쪽 갈림길', 'fork-right': '오른쪽 갈림길',
      'roundabout-': '로타리 진입',
      'end of road-left': '길 끝에서 좌회전', 'end of road-right': '길 끝에서 우회전',
      'new name-': '길을 따라 이동'
    };
    var key = type + '-' + (modifier || '');
    var label = map[key] || map[type + '-'] || type + (modifier ? ' ' + modifier : '');
    return label + road;
  }

  function drawRouteOnMap(geojsonCoords, startPos, endPos) {
    clearRoute();
    if (!state.map || !state.kakaoReady) return;
    var path = geojsonCoords.map(function (c) {
      return new kakao.maps.LatLng(c[1], c[0]);
    });
    // 경로 외곽선 (두꺼운 흰색)
    state.routePolyline = new kakao.maps.Polyline({
      path: path,
      strokeWeight: 7,
      strokeColor: '#4285F4',
      strokeOpacity: 0.9,
      strokeStyle: 'solid'
    });
    state.routePolyline.setMap(state.map);
    try {
      // 출발 마커 (파란 원)
      var startSvg = '<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32">'
        + '<circle cx="16" cy="16" r="13" fill="#4285F4" stroke="white" stroke-width="3"/>'
        + '<circle cx="16" cy="16" r="5" fill="white"/></svg>';
      state.routeStartMarker = new kakao.maps.Marker({
        position: new kakao.maps.LatLng(startPos.lat, startPos.lng),
        image: new kakao.maps.MarkerImage(
          'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(startSvg),
          new kakao.maps.Size(32, 32),
          { offset: new kakao.maps.Point(16, 16) }
        )
      });
      state.routeStartMarker.setMap(state.map);
      // 도착 마커 (빨간 핀)
      var endSvg = '<svg xmlns="http://www.w3.org/2000/svg" width="36" height="44" viewBox="0 0 36 44">'
        + '<path d="M18 0C8.06 0 0 8.06 0 18c0 12.6 18 26 18 26s18-13.4 18-26C36 8.06 27.94 0 18 0z" fill="#EA4335"/>'
        + '<circle cx="18" cy="16" r="7" fill="white"/></svg>';
      state.routeEndMarker = new kakao.maps.Marker({
        position: new kakao.maps.LatLng(endPos.lat, endPos.lng),
        image: new kakao.maps.MarkerImage(
          'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(endSvg),
          new kakao.maps.Size(36, 44),
          { offset: new kakao.maps.Point(18, 44) }
        )
      });
      state.routeEndMarker.setMap(state.map);
    } catch (e) { /* ignore */ }
    var bounds = new kakao.maps.LatLngBounds();
    path.forEach(function (p) { bounds.extend(p); });
    state.map.setBounds(bounds);
  }

  function clearRoute() {
    if (state.routePolyline) { state.routePolyline.setMap(null); state.routePolyline = null; }
    if (state.routeStartMarker) { state.routeStartMarker.setMap(null); state.routeStartMarker = null; }
    if (state.routeEndMarker) { state.routeEndMarker.setMap(null); state.routeEndMarker = null; }
    state.routeSteps = [];
    var panel = document.getElementById('route-panel');
    if (panel) panel.remove();
  }

  function showRoutePanel(distM, durS, destName, steps) {
    var old = document.getElementById('route-panel');
    if (old) old.remove();
    var dist = distM >= 1000 ? (distM / 1000).toFixed(1) + ' km' : Math.round(distM) + ' m';
    var mins = Math.ceil(durS / 60);
    var time = mins >= 60 ? Math.floor(mins / 60) + '시간 ' + (mins % 60) + '분' : mins + '분';
    var panel = document.createElement('div');
    panel.id = 'route-panel';
    panel.className = 'route-panel';
    // 상단 요약
    var html = '<div class="route-panel-row">'
      + '<span class="route-icon">🚶</span>'
      + '<div class="route-info">'
      + '  <strong>' + escapeHtml(destName) + '</strong>'
      + '  <span>📏 ' + dist + ' &nbsp; ⏱ 도보 ' + time + '</span>'
      + '</div>'
      + '<button id="btn-toggle-steps" class="route-toggle">▼</button>'
      + '<button id="btn-close-route" class="route-close">✕</button>'
      + '</div>';
    // 턴바이턴 안내 목록
    if (steps && steps.length > 0) {
      html += '<div id="route-steps" class="route-steps" style="display:none;">';
      steps.forEach(function (s, i) {
        var sDist = s.distance >= 1000 ? (s.distance / 1000).toFixed(1) + 'km' : Math.round(s.distance) + 'm';
        var icon = getStepIcon(s.instruction);
        html += '<div class="route-step">'
          + '<span class="step-num">' + icon + '</span>'
          + '<span class="step-text">' + escapeHtml(s.instruction) + '</span>'
          + '<span class="step-dist">' + sDist + '</span>'
          + '</div>';
      });
      html += '</div>';
    }
    panel.innerHTML = html;
    document.getElementById('map-shell').appendChild(panel);
    document.getElementById('btn-close-route').addEventListener('click', clearRoute);
    var toggleBtn = document.getElementById('btn-toggle-steps');
    if (toggleBtn && steps && steps.length > 0) {
      toggleBtn.addEventListener('click', function () {
        var stepsEl = document.getElementById('route-steps');
        if (!stepsEl) return;
        var hidden = stepsEl.style.display === 'none';
        stepsEl.style.display = hidden ? 'block' : 'none';
        toggleBtn.textContent = hidden ? '▲' : '▼';
      });
    }
  }

  function getStepIcon(instruction) {
    if (instruction.indexOf('좌회전') >= 0) return '↰';
    if (instruction.indexOf('우회전') >= 0) return '↱';
    if (instruction.indexOf('직진') >= 0) return '↑';
    if (instruction.indexOf('출발') >= 0) return '🏁';
    if (instruction.indexOf('도착') >= 0) return '📍';
    if (instruction.indexOf('갈림길') >= 0) return '⑂';
    if (instruction.indexOf('로타리') >= 0) return '↻';
    return '→';
  }

  function showRouteLoading(destName) {
    var old = document.getElementById('route-panel');
    if (old) old.remove();
    var panel = document.createElement('div');
    panel.id = 'route-panel';
    panel.className = 'route-panel';
    panel.innerHTML =
      '<div class="route-panel-row">'
      + '<span class="route-icon">⏳</span>'
      + '<div class="route-info"><strong>' + escapeHtml(destName) + '</strong>'
      + '<span>경로 검색 중...</span></div></div>';
    document.getElementById('map-shell').appendChild(panel);
  }

  function showRouteError(msg) {
    var old = document.getElementById('route-panel');
    if (old) old.remove();
    var panel = document.createElement('div');
    panel.id = 'route-panel';
    panel.className = 'route-panel route-error';
    panel.innerHTML =
      '<div class="route-panel-row">'
      + '<span class="route-icon">⚠️</span>'
      + '<div class="route-info"><span>' + escapeHtml(msg) + '</span></div>'
      + '<button id="btn-close-route" class="route-close">✕</button>'
      + '</div>';
    document.getElementById('map-shell').appendChild(panel);
    document.getElementById('btn-close-route').addEventListener('click', clearRoute);
  }

  document.addEventListener('DOMContentLoaded', init);
})();
