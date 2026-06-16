# Journal Trend Analyzer - Tài liệu mô tả source code

## 1. Tổng quan

**Journal Trend Analyzer** là ứng dụng mobile được xây dựng bằng Flutter. Ứng dụng sử dụng **OpenAlex API** để tìm kiếm và phân tích dữ liệu bài báo khoa học theo chủ đề nghiên cứu.

Các chức năng chính:

- Tìm kiếm publication theo keyword/topic.
- Xem chi tiết publication: title, authors, publication year, journal name, citation count, DOI, abstract.
- Phân tích xu hướng publication theo năm.
- Hiển thị top influential papers theo citation count.
- Hiển thị top research journals và top contributing authors.
- Dashboard tổng hợp: total publications, average citation count, most active publication year, top journal, top author, most influential paper.

## 2. Cấu trúc source code

```text
lib/
  main.dart
  widget_tree.dart
  core/
    constants/
      api_endpoints.dart
    theme/
      app_colors.dart
      app_text_styles.dart
      app_theme.dart
    utils/
      error_middleware.dart
      error_translator.dart
      formatters.dart
  views/
    models/
      publication_model.dart
      dashboard_stats_model.dart
    services/
      openalex_client.dart
      openalex_api_service.dart
      search_api_service.dart
      trend_api_service.dart
      dashboard_api_service.dart
    state_management/
      shared_state.dart
      home_notifier.dart
      search_notifier.dart
      trend_notifier.dart
      dashboard_notifier.dart
    pages/
      home_page.dart
      search_page.dart
      detail_page.dart
      trend_page.dart
      dashboard_page.dart
    widgets/
      analytic_box.dart
      custom_bottom_nav_bar.dart
      glass_card.dart
      publication_card.dart
      search_active_filters.dart
      search_filter_bottom_sheet.dart
      search_input_field.dart
      search_results_list.dart
      topic_selector_bottom_sheet.dart
      works_list_bottom_sheet.dart
```

## 3. Mô tả các thành phần chính

| Thành phần | Vai trò |
|---|---|
| `main.dart` | Khởi tạo Flutter app, load `.env`, cấu hình theme và error middleware. |
| `widget_tree.dart` | Quản lý điều hướng chính giữa các màn hình bằng bottom navigation. |
| `core/constants` | Chứa cấu hình endpoint, mail OpenAlex, API key nếu có. |
| `core/theme` | Quản lý màu sắc, text style, light/dark theme. |
| `core/utils` | Chứa formatter, error translator và error middleware. |
| `views/models` | Định nghĩa model dữ liệu như `Publication`, `DashboardStats`. |
| `views/services` | Gọi OpenAlex API, xử lý HTTP response và parse JSON. |
| `views/state_management` | Quản lý state, loading, error, dữ liệu đã xử lý cho UI. |
| `views/pages` | Các màn hình chính của ứng dụng. |
| `views/widgets` | Các widget tái sử dụng trong nhiều màn hình. |

## 4. Luồng xử lý chính

```text
Người dùng nhập topic
  -> SharedState.activeQueryNotifier cập nhật topic toàn cục
  -> SearchNotifier / TrendNotifier / DashboardNotifier lắng nghe thay đổi
  -> Service gọi OpenAlex API
  -> Parse JSON thành model
  -> UI render dữ liệu, loading state hoặc error state
```

`SharedState` giúp đồng bộ topic đang chọn giữa các màn hình Search, Trend và Dashboard.

## 5. Các kỹ thuật sử dụng

- **Flutter & Dart**: xây dựng ứng dụng mobile đa nền tảng.
- **REST API integration**: gọi OpenAlex API bằng package `http`.
- **OpenAlex API**: nguồn dữ liệu chính cho publication, author, journal, citation và trend.
- **Asynchronous programming**: dùng `Future`, `async`, `await`, `Future.wait`.
- **State management nhẹ**: dùng `ChangeNotifier`, `ValueNotifier`, `ListenableBuilder`.
- **JSON parsing**: chuyển response từ OpenAlex thành model `Publication` và `DashboardStats`.
- **Data visualization**: dùng `fl_chart` để vẽ biểu đồ publication theo năm.
- **Error handling**: `ErrorTranslator` chuyển lỗi kỹ thuật thành thông báo thân thiện.
- **Environment config**: dùng `flutter_dotenv` để đọc file `.env`.
- **External link handling**: dùng `url_launcher` để mở DOI.
- **Theme switching**: hỗ trợ light/dark mode qua `SharedState.themeModeNotifier`.
- **Reusable widgets**: tách `PublicationCard`, `AnalyticBox`, `GlassCard`, search widgets để dễ bảo trì.

## 6. Mapping với Functional Requirements

| Requirement | File/Module triển khai |
|---|---|
| Topic Search | `search_page.dart`, `search_notifier.dart`, `openalex_api_service.dart` |
| Publication Details | `detail_page.dart`, `publication_model.dart` |
| Publication Trend Analysis | `trend_page.dart`, `trend_notifier.dart`, `trend_api_service.dart` |
| Top Influential Papers | `trend_api_service.dart`, `trend_page.dart` |
| Top Research Journals | `trend_api_service.dart`, `trend_notifier.dart` |
| Top Contributing Authors | `trend_api_service.dart`, `trend_notifier.dart` |
| Research Trend Dashboard | `dashboard_page.dart`, `dashboard_notifier.dart`, `dashboard_api_service.dart`, `dashboard_stats_model.dart` |

## 7. Các API OpenAlex sử dụng

Ứng dụng sử dụng chủ yếu endpoint **List Works** của OpenAlex:

```text
GET https://api.openalex.org/works
```

Theo tài liệu OpenAlex, endpoint này hỗ trợ các tham số chính như `search`, `filter`, `sort`, `group_by`, `per_page`, `page`, `cursor`, `select`, `api_key`.

Tài liệu tham khảo:

```text
https://developers.openalex.org/api-reference/works/list-works#parameter-search
```

### 7.1 Topic Search

Dùng để tìm danh sách publication theo keyword/topic.

```text
GET https://api.openalex.org/works?search={keyword}&per_page=20
```

Ví dụ:

```text
https://api.openalex.org/works?search=Computer%20Science&per_page=20
```

Response được dùng để lấy:

- `title`
- `publication_year`
- `cited_by_count`
- `primary_location.source.display_name`
- `doi`
- `authorships`
- `abstract_inverted_index`

File triển khai:

- `openalex_api_service.dart`
- `search_notifier.dart`
- `publication_model.dart`

### 7.2 Search với filter

Dùng khi người dùng lọc theo author, concept/topic hoặc sắp xếp.

```text
GET https://api.openalex.org/works?search={keyword}&filter={filter}&sort={sort}&per_page=20
```

Một số filter/sort app sử dụng:

```text
filter=authorships.author.id:{authorId}
filter=concepts.id:{conceptId}
filter=primary_topic.id:{topicId}
sort=publication_date:desc
sort=publication_date:asc
```

File triển khai:

- `openalex_api_service.dart`
- `search_filter_bottom_sheet.dart`
- `search_notifier.dart`

### 7.3 Publication Trend Analysis

Dùng để gom số lượng publication theo năm.

```text
GET https://api.openalex.org/works?search={keyword}&group_by=publication_year
```

Ví dụ:

```text
https://api.openalex.org/works?search=Computer%20Science&group_by=publication_year
```

Response cần có:

```json
"group_by": [
  {
    "key": "2024",
    "key_display_name": "2024",
    "count": 123
  }
]
```

File triển khai:

- `trend_api_service.dart`
- `trend_notifier.dart`
- `trend_page.dart`

### 7.4 Top Influential Papers

Dùng để lấy các publication có citation count cao nhất.

```text
GET https://api.openalex.org/works?search={keyword}&sort=cited_by_count:desc&per_page=20
```

Ví dụ:

```text
https://api.openalex.org/works?search=Computer%20Science&sort=cited_by_count:desc&per_page=20
```

File triển khai:

- `trend_api_service.dart`
- `trend_page.dart`

### 7.5 Top Research Journals

Dùng `group_by` theo journal/source.

```text
GET https://api.openalex.org/works?search={keyword}&group_by=primary_location.source.id
```

Ví dụ:

```text
https://api.openalex.org/works?search=Computer%20Science&group_by=primary_location.source.id
```

Response dùng:

- `key`
- `key_display_name`
- `count`

File triển khai:

- `trend_api_service.dart`
- `dashboard_api_service.dart`

### 7.6 Top Contributing Authors

Dùng `group_by` theo author.

```text
GET https://api.openalex.org/works?search={keyword}&group_by=authorships.author.id
```

Ví dụ:

```text
https://api.openalex.org/works?search=Computer%20Science&group_by=authorships.author.id
```

File triển khai:

- `trend_api_service.dart`
- `dashboard_api_service.dart`

### 7.7 Research Trend Dashboard

Dashboard kết hợp nhiều API:

```text
GET /works?search={keyword}&per_page=1
```

Dùng `meta.count` để lấy total publications.

```text
GET /works?search={keyword}&group_by=publication_year
```

Dùng để lấy most active publication year.

```text
GET /works?search={keyword}&sort=cited_by_count:desc&per_page=1
```

Dùng để lấy most influential paper.

```text
GET /works?search={keyword}&group_by=primary_location.source.id
GET /works?search={keyword}&group_by=authorships.author.id
```

Dùng để lấy top journal và top author.

File triển khai:

- `dashboard_api_service.dart`
- `dashboard_notifier.dart`
- `dashboard_page.dart`

### 7.8 API key và mailto

OpenAlex hỗ trợ API key miễn phí. Trong app, API key và email học thuật được cấu hình qua:

```text
lib/core/constants/api_endpoints.dart
.env
```

Request có thể kèm:

```text
api_key={OPENALEX_API_KEY}
mailto={ACADEMIC_MAIL}
```

## 8. Ảnh chụp các màn hình chính

Lưu ảnh chụp vào thư mục:

```text
docs/screenshots/
```

Tên file đề xuất:

| Màn hình | File ảnh |
|---|---|
| Home Screen | `docs/screenshots/home_screen.png` |
| Search Screen | `docs/screenshots/search_screen.png` |
| Publication Detail Screen | `docs/screenshots/detail_screen.png` |
| Trend Analysis Screen | `docs/screenshots/trend_screen.png` |
| Research Dashboard Screen | `docs/screenshots/dashboard_screen.png` |

### Home Screen

![Home Screen](screenshots/home_screen.png)

### Search Screen

![Search Screen](screenshots/search_screen.png)

### Publication Detail Screen

![Publication Detail Screen](screenshots/detail_screen.png)

### Trend Analysis Screen

![Trend Analysis Screen](screenshots/trend_screen.png)

### Research Dashboard Screen

![Research Dashboard Screen](screenshots/dashboard_screen.png)

## 9. Ghi chú

- Ứng dụng gọi trực tiếp OpenAlex API từ mobile client, không sử dụng backend riêng.
- Trend và Dashboard ưu tiên dữ liệu `group_by` từ OpenAlex; nếu request phụ lỗi hoặc timeout, app có fallback để giảm lỗi toàn màn hình.
- Timeout HTTP được cấu hình trong `OpenAlexClient`.
- Các thông báo lỗi hiển thị cho người dùng được xử lý qua `ErrorTranslator`.
