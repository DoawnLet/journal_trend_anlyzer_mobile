# AI Agent Rules: Publisher Cross-Screen Filtering & Deep Linking Implementation

## 1. Objective & Context
You must implement a deep-linking and filtering feature that connects the **Publishers Tab** on the `HomePage` to the functional execution core of the `SearchPage`. When a user interacts with a specific publisher entity on the landing hub, the application must automatically transition to the lookup stream and restrict output rows exclusively to that publisher's inventory.

---

## 2. API Implementation Details (OpenAlex Specification)

### 2.1 Keyword Query (Standard State)
When executing standard text inputs, utilize the traditional parameter mapping:
`https://api.openalex.org/works?search={query_string}`

### 2.2 Publisher Filtering (Triggered State)
When filtering by a selected publisher entity, extract the unique entity ID (e.g., `https://openalex.org/P4310319965`) from the publisher dataset. You must modify the dynamic request string to integrate the OpenAlex nested attribute `filter` logic:
`https://api.openalex.org/works?filter=primary_location.source.host_organization:{publisher_id}`

---

## 3. Engineering & State Management Requirements

### 3.1 State Modifications (`lib/views/state_management/`)
Within the global search state manager (e.g., `SearchNotifier` or equivalent pattern inside your state framework), integrate the following tracking properties:
* `String? selectedPublisherId;` - Stores the raw unique URL/ID string of the active publisher filter.
* `String? selectedPublisherName;` - Stores the text label for frontend presentation layers.

Implement a core controller function:
```dart
void setPublisherFilter(String id, String name) {
  state = state.copyWith(
    selectedPublisherId: id,
    selectedPublisherName: name,
    searchQuery: '', // Flush traditional query strings to avoid conflict
  );
  executeWorksFetchPipeline(); // Trigger immediate HTTP dispatch
}

void clearPublisherFilter() {
  state = state.copyWith(
    selectedPublisherId: null,
    selectedPublisherName: null,
  );
  executeWorksFetchPipeline();
}