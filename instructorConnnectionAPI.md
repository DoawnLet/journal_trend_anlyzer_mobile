Dưới đây là nội dung tài liệu hướng dẫn được thiết kế dưới dạng file cấu hình `.md` (`ai-agent-api-guide.md`). Bạn có thể lưu file này hoặc cung cấp trực tiếp cho AI Agent của mình để đảm bảo hệ thống tự động sinh mã nguồn kết nối OpenAlex API chính xác theo cấu trúc `views/` và đáp ứng trọn vẹn các yêu cầu chức năng của bài Lab.

---

# AI Agent Rules: OpenAlex API Integration Guide

## 1. Core API Integration Constraints

* 
**Sole Data Source:** You must use the OpenAlex API as the **sole external data source** for retrieving publication information and performing trend analysis. The use of hard-coded datasets is explicitly prohibited.


* 
**Direct Mobile Client Consumption:** The application must consume OpenAlex data **directly from the mobile client** using Dart's asynchronous programming without introducing additional backend or custom REST API components.


* 
**Architecture Compliance:** All network operations must be isolated inside `lib/views/services/` and payloads managed through `lib/views/state_management/` via `ValueNotifier`.



---

## 2. API Endpoint & Technical Parameters

* **Base URL (Works Entity):** `https://api.openalex.org/works`
* **Polite Pool Optimization:** Every endpoint string request constructed must append the `mailto` parameter containing the developer's academic mail context (`&mailto=your_student_email@fpt.edu.vn`) to secure prioritized server queues and fast response times.
* **Pagination Control:** Append `&per_page=20` to search queries to limit memory consumption and ensure smooth local UI rendering performance.

---

## 3. Core Functional Query Mappings

You must construct the API network requests matching these exact requirements defined in the Lab specification:

### 3.1 Topic Search & Publication Records (Requirement 4.1 & 4.2)

To search for research publications dynamically by entering a topic keyword typed by the user:

* **Query Format:** `https://api.openalex.org/works?search={keyword}&per_page=20&mailto=...`
* 
**UI Data Mapping Requirements:** The JSON mapper must extract the following data primitives from the response object arrays to satisfy the UI criteria:


* Title $\rightarrow$ `json['title']` 


* Publication Year $\rightarrow$ `json['publication_year']` 


* Citation Count $\rightarrow$ `json['cited_by_count']` 


* Journal Name $\rightarrow$ `json['primary_location']['source']['display_name']` 


* DOI $\rightarrow$ `json['doi']` 


* Authors List $\rightarrow$ Loop through `json['authorships']` to extract `author['display_name']` 


* Abstract Text $\rightarrow$ Unpack `json['abstract_inverted_index']` if available (convert the inverted index map back into a continuous text string).





### 3.2 Publication Trend Analysis (Requirement 4.3)

To analyze publication activity over time grouped by publication year:

* **Query Format:** `https://api.openalex.org/works?search={keyword}&group_by=publication_year&mailto=...`
* **Processing Rule:** The API returns a structural breakdown of year nodes and their respective counts. Pass this mapped data block directly to the `TrendNotifier` to compute chart plotting weights using `fl_chart` or `syncfusion_flutter_charts`.



### 3.3 Top Influential Papers (Requirement 4.4)

To display the most influential publications ranked from highest to lowest citation count:

* **Query Format:** `https://api.openalex.org/works?search={keyword}&sort=cited_by_count:desc&per_page=20&mailto=...`

---

## 4. Analytical Calculations for Research Dashboard (Requirement 4.7)

The **Research Dashboard Screen** requires aggregated insights. Instead of executing separate network queries, pull a large data cluster (e.g., top 50-100 results) using `https://api.openalex.org/works?search={keyword}&per_page=50` and evaluate these metrics natively inside the `DashboardNotifier` controller:

* 
**Total Publications:** Extract total record property from API metadata or target local array length.


* 
**Average Citation Count:** Sum the `cited_by_count` values across all fetched records and divide by the total count.


* 
**Most Active Publication Year:** Evaluate occurrences of `publication_year` keys and isolate the modal value.


* 
**Top Journal:** Analyze occurrences of `journalName` strings within the list and extract the highest value.


* 
**Top Author:** Parse the collection of `authors` nested arrays, count total individual name matches, and display the highest frequency author.


* 
**Most Influential Paper:** Isolate the work instance reflecting the absolute maximum value of `cited_by_count`.



---

## 5. Robust Error Handling & State Safety Rules

* **Try-Catch Encapsulation:** Wrap HTTP request blocks inside clear `try-catch` structures to catch SocketExceptions (No internet connection), TimeoutExceptions, or FormatExceptions (JSON parsing breakdown).
* **HTTP Status Code Validation:** Explicitly assert `response.statusCode == 200`. If any 4xx or 5xx failures occur, format a clean localized error string into the state instead of leaking stack traces to the UI layout.
* 
**Loading and Graceful Empty States:** Ensure `isLoading = true` states are dispatched instantly via the notifier upon search invocation, and verify that empty arrays (`[]`) default gracefully to clear "No results found" UI placeholders instead of crashing runtime widgets.