### Rule structure of project agent need to following

lib/
│
├── core/ # Chuyển các phần cấu hình chung ra ngoài
│ ├── constants/ # Thay vì viết sai chính tả "constance.dart"
│ │ └── api_endpoints.dart # Lưu Base URL của OpenAlex API
│ └── utils/
│ └── formatters.dart # Hàm format số lượt trích dẫn, ngày tháng
│
├── views/ # Thư mục tổng chứa toàn bộ phần hiển thị & xử lý trạng thái
│ │
│ ├── models/ # PHẢI CÓ: Định nghĩa cấu trúc dữ liệu từ OpenAlex API
│ │ └── publication_model.dart  
│ │
│ ├── services/ # PHẢI CÓ: Nơi gọi API, xử lý JSON bất đồng bộ
│ │ └── openalex_api_service.dart
│ │
│ ├── state_management/ # PHẢI CÓ: Chứa các ValueNotifier xử lý logic
│ │ ├── search_notifier.dart # Quản lý bộ lọc và kết quả tìm kiếm bài báo
│ │ ├── trend_notifier.dart # Quản lý dữ liệu vẽ biểu đồ xu hướng
│ │ └── dashboard_notifier.dart # Quản lý các số liệu tổng quan của Dashboard
│ │
│ ├── pages/ # 4 Màn hình bắt buộc theo đề bài
│ │ ├── search_page.dart # Màn hình tìm kiếm đề tài
│ │ ├── detail_page.dart # Màn hình chi tiết bài báo (DOI, Abstract...)
│ │ ├── trend_page.dart # Màn hình vẽ biểu đồ xu hướng theo năm
│ │ └── dashboard_page.dart # Màn hình bảng điều khiển tổng quan
│ │
│ └── widgets/ # PHẢI CÓ: Các UI components dùng chung
│ ├── publication_card.dart # Thẻ hiển thị tóm tắt bài báo
│ └── analytic_box.dart # Hộp hiển thị số liệu trên Dashboard
│
├── widget_tree.dart # Quản lý điều hướng/Cấu trúc widget chính của app
└── main.dart # Điểm khởi chạy ứng dụng Flutter

-------------------------------------------------
### Design System

# AI Agent Rules: UI Design System & Component Architecture

# Follow of rule material design system 

## color use for app : b
Thành phần UI,Mã Hex,Mã RGB,Vai trò / Trải nghiệm
Background (Nền),#75A6D7,"rgb(117, 166, 215)",Màu nền chính bạn đã chọn.
Primary Text (Chữ chính),#0B2545,"rgb(11, 37, 69)","Xanh hải quân đậm. Dùng cho tiêu đề, nội dung chính (Độ tương phản xuất sắc)."
Secondary Text (Chữ phụ),#243A57,"rgb(36, 58, 87)","Sắc độ xám xanh. Dùng cho subtitle, nhãn thông tin phụ, ngày tháng."
Large Text / Icon,#FFFFFF,"rgb(255, 255, 255)","Trắng. Chỉ dùng cho nút bấm (Button), icon lớn hoặc tiêu đề cỡ đại."

## 1. Global Architectural Overview

You must build and map the user interface elements according to the custom layout within the `lib/views/` and `lib/core/` folders. Every feature requested must maintain a strict separation of concerns through the assigned structural pattern.

The application consists of **5 interconnected screens**:

1. **`widget_tree.dart` / Main Navigation Page** (The application hub)


2. **`search_page.dart`** (Data gateway)


3. **`detail_page.dart`** (Deep-dive information)


4. **`trend_page.dart`** (Temporal data visualization)


5. **`dashboard_page.dart`** (Strategic analytics overview)

## 2. Shared State & Global UX Flow

* **Unified State Rule:** When a user triggers a keyword query on the `SearchPage`, the active keyword string must be persisted inside a globally accessible/shared state container or passed down cleanly using an architecture-compliant `ValueNotifier`.

* **Reactive Fetching Rule:** Switching tabs to `TrendPage` or `DashboardPage` must automatically consume the active shared keyword state. The respective state management controllers must execute remote OpenAlex API calls and process analytics implicitly without prompting the user to type the topic query again.

3. Comprehensive Screen Design Specifications

 3.1 Giao diện gốc: Main Navigation Page (`lib/widget_tree.dart`)

Acts as the structural foundation and root context wrapper for navigation within the shell layout.

* **UI Components:** Implement a Material 3 `BottomNavigationBar` (or a `NavigationRail` for wide form factors).


* **Operational Mechanism:** Enable fluent, immediate tab switches among the three primary operational workspaces: Search $\leftrightarrow$ Trend Analysis $\leftrightarrow$ Dashboard, tracking a single active research topic globally.



 3.2 Màn hình 1: Search Page (`lib/views/pages/search_page.dart`)
Serves as the data entry point allowing users to query topics dynamically from the OpenAlex API.

* **UI Components:**
* An optimized Material 3 input box (`TextField` or `SearchBar`) coupled with a localized submission `IconButton` or `ElevatedButton`.

* A centering `CircularProgressIndicator` that dynamically overlays the viewport when the underlying state reflects active API communications (`isLoading == true`).

* A scrollable result stream (`ListView.builder`) containing modular semantic `Card` widgets.


* **Card Metadata Requirements:** Each item cell must cleanly organize: **Publication Title**, **Publication Year**, **Citation Count**, and **Journal/Host Venue Name**.

* **UX Flow:** Tapping any card tile must dispatch a router transition (`Navigator.push`) targeting the explicit `DetailPage` of that specific node.


 3.3 Màn hình 2: Publication Detail Page (`lib/views/pages/detail_page.dart`)

Renders comprehensive, deep-dive academic insights regarding a singular work selected from search result frames.

* **UI Components:**
* Highly prominent header zone using clean typography tokens (`Theme.of(context).textTheme.headlineMedium` or `titleLarge`).

* Structured text block or scroll item rendering the complete, delimited list of contributing **Authors**.

* Clean, grouped contextual tag units (`Chip` or `Badge` elements) to explicitly state the **Publication Year**, **Journal Name**, and **Citation Count**.

* Interactive Digital Object Identifier tracking element using a styled clickable link wrapper (`Text` with link theme or a dedicated `Linkify` implementation) targeting the paper's **DOI**.

* An abstracted semantic container block reserved for the publication's **Abstract text**, displaying placeholder fallback views gracefully if abstract payloads are missing.

* **UX Flow:** Provide an explicit dismissive or directional "Back" action toggle inside the local `AppBar` to seamlessly navigate the viewport back to the search registry list.



 3.4 Màn hình 3: Trend Analysis Page (`lib/views/pages/trend_page.dart`)

Devoted entirely to processing raw historic results and rendering visual expressions of publication density variations across years.

* **UI Components:**
* **Interactive Line Chart or Bar Chart:** Map distribution curves tracing the macro-level expansion or contraction of work totals recorded under the current topic grouped natively by publication year.


* **Top Influential Papers List:** A ranked layout prioritizing works from highest to lowest according to explicit citation tallies.


* **Top Research Journals Segment:** A specialized ranked list or secondary categorical mini-chart breaking down the distribution of source venues providing the highest contribution index.


* **Top Contributing Authors Segment:** Visual ledger matching developer names to total output metrics registered against the chosen academic subset.

 3.5 Màn hình 4: Research Dashboard Page (`lib/views/pages/dashboard_page.dart`)

Synthesizes bulk response payloads into highly scannable, operational high-level metrics to deliver an analytics snapshot.

* **UI Components:**
* Standard structural grid (`GridView.count` or modular flex layouts) implementing custom stateless component atoms (`AnalyticStatBox`) to frame high-priority variables:


* **Total Publications Count**

* **Average Citation Count**

* **Most Active Publication Year**



* Standalone stylized showcase blocks built explicitly to isolate specific outliers:


* **Top Journal Unit**

* **Top Author Unit**

* **Most Influential Paper Card**

4. Code Generation Rules

When the user asks to generate any layout components or page widgets based on this system description:

1. **Never write inline data parsing logic inside the View:** Delegate all calculations (averages, sort functions, map groupings) to the respective state controllers in `lib/views/state_management/`.


2. **Strictly enforce M3 guidelines:** Use standardized styling tokens (`Theme.of(context).colorScheme`) and encapsulate structural child blocks inside clean, extractable custom component classes located in `lib/views/widgets/`.