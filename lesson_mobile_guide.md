# 📱 Hướng Dẫn Triển Khai Mobile — Trang Bài Học (Lesson)

> **Backend**: Firebase Firestore (trực tiếp, không qua REST API trung gian)  
> **Auth**: Firebase Authentication (Email/Password)  
> **SDK gợi ý cho Mobile**: `firebase_dart` (Flutter) hoặc Firebase JS SDK (React Native)

---

## 🗂️ Mục Lục

1. [Kiến Trúc Tổng Quan](#1-kiến-trúc-tổng-quan)
2. [Firestore Collections Schema](#2-firestore-collections-schema)
3. [Data Models](#3-data-models)
4. [API — Lesson Service](#4-api--lesson-service)
5. [API — SRS Service](#5-api--srs-service)
6. [API — History Service](#6-api--history-service)
7. [Luồng Màn Hình Bài Học](#7-luồng-màn-hình-bài-học)
8. [UI — LessonView (Chi Tiết Bài Học)](#8-ui--lessonview-chi-tiết-bài-học)
9. [UI — Study (Flashcard)](#9-ui--study-flashcard)
10. [UI — TestPage (Kiểm Tra)](#10-ui--testpage-kiểm-tra)
11. [UI — SRSReviewPage (Ôn Tập SRS)](#11-ui--srsreviewpage-ôn-tập-srs)
12. [SRS Algorithm — SM-2](#12-srs-algorithm--sm-2)
13. [Trạng Thái & Điều Hướng](#13-trạng-thái--điều-hướng)

---

## 1. Kiến Trúc Tổng Quan

```
Firebase Auth
     │  (uid, email, displayName)
     ▼
Firebase Firestore
     ├── lessons/          ← metadata bài học
     ├── vocabularies/     ← danh sách từ của từng bài
     ├── srsCards/         ← thẻ SRS mỗi user
     ├── reviewSessions/   ← log phiên ôn tập SRS
     └── history/{uid}/aggregate/
             ├── studyStats   ← thống kê tổng hợp
             └── dailyLog     ← heatmap hoạt động theo ngày
```

**Lưu ý quan trọng:**
- Không có REST backend — mobile connect trực tiếp tới Firestore
- Yêu cầu user đã đăng nhập (Firebase Auth) trước khi truy cập bất kỳ bài học nào
- `creator` field trong lesson lưu **username** (không phải `uid`)

---

## 2. Firestore Collections Schema

### `lessons` collection

| Field | Type | Mô tả |
|---|---|---|
| `id` | string | Document ID (auto) |
| `title` | string | Tên bài học |
| `creator` | string | Username của người tạo |
| `vocabId` | string | ID của document trong `vocabularies` |
| `createdAt` | Timestamp | Thời gian tạo |
| `description` | string | Mô tả bài học |
| `wordCount` | number | Số lượng từ |
| `isPrivate` | boolean | Ẩn/công khai |
| `isOfficial` | boolean | Bài học chính thức (do admin tạo) |
| `folderId` | string \| null | ID thư mục (nếu có) |

### `vocabularies` collection

| Field | Type | Mô tả |
|---|---|---|
| `id` | string | Document ID (= `lesson.vocabId`) |
| `words` | VocabItem[] | Mảng từ vựng |
| `createdAt` | Timestamp | |

#### VocabItem object
```
{
  word:       string,   // Từ tiếng Anh
  definition: string,   // Nghĩa tiếng Việt
  ipa?:       string,   // Phiên âm quốc tế  /wɜːrd/
  wordType?:  string,   // noun, verb, adj, adv, ...
  exampleEn?: string,   // Câu ví dụ tiếng Anh
  exampleVi?: string,   // Dịch câu ví dụ
}
```

### `srsCards` collection

| Field | Type | Mô tả |
|---|---|---|
| `wordId` | string | `{lessonId}_{word}` |
| `word` | string | Từ tiếng Anh |
| `definition` | string | Nghĩa |
| `easeFactor` | number | 1.3–2.5 (mặc định 2.5) |
| `interval` | number | Số ngày tới lần ôn tiếp |
| `repetitions` | number | Số lần ôn thành công liên tiếp |
| `nextReview` | Timestamp | Ngày ôn tiếp theo |
| `lastReview` | Timestamp? | Ngày ôn cuối |
| `totalReviews` | number | Tổng số lần review |
| `correctCount` | number | Số lần đúng |
| `incorrectCount` | number | Số lần sai |
| `streak` | number | Streak đúng hiện tại |
| `lessonId` | string | ID bài học |
| `userId` | string | UID của user |
| `createdAt` | Timestamp | |
| `updatedAt` | Timestamp | |

### `history/{uid}/aggregate/studyStats`

```
{
  flashcard: { sessions, totalTime, lastStudied },
  review:    { sessions, totalTime, lastStudied },
  test:      { sessions, totalTime, lastStudied },
  totalSessions: number,
  totalTime:     number,   // seconds
  updatedAt:     Timestamp,
  migrated:      boolean,
}
```

### `history/{uid}/aggregate/dailyLog`

```
{
  "2026-09-01": number,   // số phiên học ngày đó
  "2026-09-02": number,
  ...
}
```

---

## 3. Data Models

### Lesson
```dart
class Lesson {
  String id;
  String title;
  String creator;       // username (không phải uid)
  String vocabId;
  DateTime createdAt;
  String description;
  int wordCount;
  bool isPrivate;
  bool isOfficial;
  String? folderId;
  List<VocabItem>? vocabulary;  // populated khi getLesson()
}
```

### VocabItem
```dart
class VocabItem {
  String word;
  String definition;
  String? ipa;
  String? wordType;
  String? exampleEn;
  String? exampleVi;
}
```

### SRSCard
```dart
class SRSCard {
  String? id;           // Firestore document ID
  String wordId;        // "{lessonId}_{word}"
  String word;
  String definition;
  double easeFactor;    // 1.3 – 2.5
  int interval;         // days
  int repetitions;
  DateTime nextReview;
  DateTime? lastReview;
  int totalReviews;
  int correctCount;
  int incorrectCount;
  int streak;
  String lessonId;
  String userId;
  DateTime createdAt;
  DateTime updatedAt;
}
```

### ReviewRating
```dart
enum ReviewRating { again, hard, good, easy }
// Mapping quality score: again=0, hard=3, good=4, easy=5
```

---

## 4. API — Lesson Service

### 4.1 Lấy chi tiết một bài học (kèm từ vựng)
```
getLesson(lessonId: string) → Lesson
```

**Firestore operations:**
1. `getDoc("lessons/{lessonId}")` — lấy metadata
2. `getDoc("vocabularies/{lesson.vocabId}")` — lấy từ vựng

**Lưu ý:** Dùng `getDocFromServer` (bypass cache) để tránh dữ liệu cũ.

**Response:**
```json
{
  "id": "abc123",
  "title": "Unit 1: Family",
  "creator": "admin",
  "vocabId": "xyz456",
  "createdAt": "2026-08-01T00:00:00Z",
  "description": "Từ vựng về gia đình",
  "wordCount": 20,
  "isOfficial": true,
  "isPrivate": false,
  "folderId": null,
  "vocabulary": [
    {
      "word": "family",
      "definition": "gia đình",
      "ipa": "ˈfæmɪli",
      "wordType": "noun",
      "exampleEn": "My family has five members.",
      "exampleVi": "Gia đình tôi có năm thành viên."
    }
  ]
}
```

---

### 4.2 Lấy danh sách bài học công khai (có phân trang)
```
getLessonsPaginated(pageSize, lastVisibleDoc?, skipCount?) → PaginatedLessonsResult
```

**Firestore query:**
```
collection("lessons")
  .where("isPrivate", "==", false)
  .orderBy("createdAt", "desc")
  .limit(pageSize + 1)  // +1 để biết còn trang tiếp
  [.startAfter(lastVisibleDoc)]  // nếu load more
```

**Response:**
```json
{
  "lessons": [...],
  "hasMore": true,
  "total": 0
}
```

---

### 4.3 Lấy bài học của tôi
```
getMyLessons(creator: string, folderId?: string | null) → Lesson[]
```

**Firestore query:**
```
collection("lessons")
  .where("creator", "==", username)
  [.where("folderId", "==", folderId)]
```

> **Lưu ý:** `creator` là **username**, không phải `uid`. Cần lấy `username` từ session/storage sau khi login.

---

### 4.4 Tìm kiếm bài học
```
searchLessons(term: string) → Lesson[]
```

**Cơ chế:** Fetch toàn bộ bài học công khai, filter in-memory theo:
- `title.toLowerCase().includes(term)`
- `description.toLowerCase().includes(term)`
- `creator.toLowerCase().includes(term)`

> ⚠️ Không hỗ trợ full-text search server-side. Với data lớn nên tích hợp Algolia.

---

### 4.5 Tạo bài học
```
createLesson(title, creator, vocabList, description?, isPrivate?, folderId?, isOfficial?) → { lessonId, vocabId }
```

**Firestore operations (2 bước):**
1. `addDoc("vocabularies", { words: vocabList, createdAt })` → vocabId
2. `addDoc("lessons", { title, creator, vocabId, wordCount, ... })`

---

### 4.6 Cập nhật bài học
```
updateLesson(lessonId, title, vocabList, description?, isPrivate?, folderId?) → void
```

**Firestore operations:**
1. `updateDoc("vocabularies/{vocabId}", { words: vocabList })`
2. `updateDoc("lessons/{lessonId}", { title, description, wordCount, ... })`

---

### 4.7 Xóa bài học
```
deleteLessonById(lessonId) → void
```

**Firestore operations:**
1. `getDoc("lessons/{lessonId}")` → lấy `vocabId`
2. `deleteDoc("lessons/{lessonId}")`
3. `deleteDoc("vocabularies/{vocabId}")`

---

### 4.8 Lấy từ vựng riêng lẻ
```
getVocabulary(vocabId: string) → VocabItem[]
```

```
getDoc("vocabularies/{vocabId}") → data.words
```

---

## 5. API — SRS Service

### 5.1 Khởi tạo SRS cards cho bài học
```
initializeCardsForLesson(lessonId, userId, vocabulary) → void
```

**Điều kiện:** Chỉ tạo nếu chưa có cards (`srsCards` chưa có doc nào thỏa `lessonId == X && userId == Y`).

**Firestore:**
```
batch.set(srsCards/{newId}, {
  wordId:     "{lessonId}_{word}",
  word, definition,
  easeFactor: 2.5,
  interval:   1,
  repetitions: 0,
  nextReview: Timestamp.now(),
  totalReviews: 0, correctCount: 0, incorrectCount: 0, streak: 0,
  lessonId, userId,
  createdAt, updatedAt: Timestamp.now()
})
```

> **Khi nào gọi?** Sau khi user hoàn thành phiên Flashcard đầu tiên của bài học.

---

### 5.2 Lấy cards đến hạn ôn hôm nay
```
getDueCardsForUser(userId) → SRSCard[]
```

**Logic:**
```
getUserCards(userId)          // lấy tất cả cards
  → filter(card => card.nextReview <= now)  // getDueCards()
```

**Firestore query:**
```
collection("srsCards")
  .where("userId", "==", userId)
  .orderBy("nextReview", "asc")
```

---

### 5.3 Lấy cards của bài học cụ thể
```
getCardsForLesson(lessonId, userId) → SRSCard[]
```

```
collection("srsCards")
  .where("lessonId", "==", lessonId)
  .where("userId", "==", userId)
```

---

### 5.4 Review một thẻ SRS
```
reviewCard(cardId, rating: ReviewRating) → SRSCard
```

**Tính toán SM-2 (xem section 12) → cập nhật Firestore:**
```
updateDoc("srsCards/{cardId}", {
  easeFactor, interval, repetitions,
  nextReview: Timestamp,
  lastReview: Timestamp,
  updatedAt:  Timestamp,
  totalReviews: increment(1),
  correctCount: increment(isCorrect ? 1 : 0),
  incorrectCount: increment(isCorrect ? 0 : 1),
  streak: newStreak,
})
```

---

### 5.5 Bắt đầu phiên ôn
```
startReviewSession(userId, lessonId?) → sessionId: string
```

```
addDoc("reviewSessions", {
  userId, lessonId?,
  startTime: Timestamp,
  cardsReviewed: 0, correctCount: 0, incorrectCount: 0,
  totalTime: 0, averageTime: 0
})
```

---

### 5.6 Kết thúc phiên ôn
```
endReviewSession(sessionId, stats) → void
```

```
updateDoc("reviewSessions/{sessionId}", {
  endTime: Timestamp.now(),
  cardsReviewed, correctCount, incorrectCount,
  totalTime, averageTime: totalTime / cardsReviewed
})
```

---

## 6. API — History Service

### 6.1 Ghi nhận phiên học
```
incrementStudyStats(userId, mode: "flashcard"|"review"|"test", timeSpent: number) → void
```

**Ghi 2 document song song:**

**`studyStats`:**
```
setDoc("history/{userId}/aggregate/studyStats", {
  [mode]: {
    sessions:    increment(1),
    totalTime:   increment(timeSpent),
    lastStudied: serverTimestamp()
  },
  totalSessions: increment(1),
  totalTime:     increment(timeSpent),
  updatedAt:     serverTimestamp()
}, { merge: true })
```

**`dailyLog`:**
```
dateKey = "YYYY-MM-DD"  (today)
setDoc("history/{userId}/aggregate/dailyLog", {
  [dateKey]: increment(1)
}, { merge: true })
```

---

### 6.2 Lấy thống kê tổng hợp
```
getStudyAggregateStats(userId) → StudyAggregateStats | null
```

```
getDoc("history/{userId}/aggregate/studyStats")
```

**Response:**
```json
{
  "flashcard": { "sessions": 10, "totalTime": 3600, "lastStudied": "..." },
  "review":    { "sessions": 5,  "totalTime": 1800, "lastStudied": "..." },
  "test":      { "sessions": 3,  "totalTime": 900,  "lastStudied": "..." },
  "totalSessions": 18,
  "totalTime": 6300,
  "updatedAt": "..."
}
```

---

### 6.3 Lấy heatmap hoạt động
```
getUserDailyActivity(userId) → Record<"YYYY-MM-DD", number>
```

```
getDoc("history/{userId}/aggregate/dailyLog")
```

---

## 7. Luồng Màn Hình Bài Học

```
Home / My Lessons
     │
     ▼
LessonView (/lesson/:lessonId)
     │── getLesson(lessonId)
     │── Hiển thị: title, description, creator, wordCount, isOfficial badge
     │── Action buttons:
     │       ├── [Flashcards] → Study (/study/:lessonId)
     │       ├── [Ôn tập]    → ExerciseSelectionModal → ReviewPage / SRSReviewPage
     │       ├── [Kiểm tra]  → TestPage (/test/:lessonId)
     │       ├── [Game]      → AsteroidMatch (/asteroid-match/:lessonId)
     │       └── [Chỉnh sửa] → Edit (chỉ hiện nếu isOwner)
     │── Vocabulary table: word, ipa, wordType, definition, exampleEn/Vi
     │
     ├──► Study (Flashcard)
     │       ├── getLesson(lessonId) → vocabulary[]
     │       ├── Hiển thị từng flashcard (term → definition)
     │       ├── User mark: "Đã thuộc" | "Chưa thuộc"
     │       ├── Progress bar theo số từ đã thuộc
     │       ├── Khi hoàn thành (all "know"):
     │       │       ├── historyService.incrementStudyStats(uid, "flashcard", timeSpent)
     │       │       └── srsService.initializeCardsForLesson(lessonId, uid, vocabulary)
     │       └── CompletionScreen → [Ôn tập lại | Kiểm tra | Quay lại]
     │
     ├──► TestPage (Kiểm Tra)
     │       ├── getLesson(lessonId) → vocabulary (shuffle)
     │       ├── Hiển thị definition (tiếng Việt) → user gõ từ tiếng Anh
     │       ├── Gợi ý: show ký tự đã đúng theo vị trí
     │       ├── Khi hoàn thành:
     │       │       └── historyService.incrementStudyStats(uid, "test", timeSpent)
     │       └── ResultScreen → score%, sai/đúng, làm lại câu sai
     │
     └──► SRSReviewPage (Ôn SRS)
             ├── srsService.getDueCardsForUser(uid) → dueCards[]
             ├── Nếu > 200 thẻ → CatchupModal (học 20 thẻ trước | học hết)
             ├── Hiển thị card → [Hiện đáp án] → [Again | Hard | Good | Easy]
             ├── Logic queue:
             │       ├── Đúng (hard/good/easy): remove khỏi queue + persist Firestore
             │       └── Sai (again): push xuống cuối queue (local, không persist)
             ├── Khi xong:
             │       ├── srsService.endReviewSession(sessionId, stats)
             │       └── historyService.incrementStudyStats(uid, "review", totalTime)
             └── Navigate về Home
```

---

## 8. UI — LessonView (Chi Tiết Bài Học)

### Màn hình & Thành phần

#### Header Banner
- Background gradient: `stone-800 → stone-900` (official) | `stone-700 → stone-800` (community)
- Icon bài học (BookOpen)
- **Title + Official badge** (nếu `isOfficial == true`)
- Description text
- Meta: `Tạo bởi: {creator} · Cập nhật: {date}`
- Word count badge (góc phải)

#### Action Bar (thanh hành động)

| Button | Màu | Route |
|---|---|---|
| Flashcards | Blue | `/study/:lessonId` |
| Ôn tập | Green | Modal chọn loại ôn |
| Kiểm tra | Amber/Orange | `/test/:lessonId` |
| Game | Default | `/asteroid-match/:lessonId` |
| Chỉnh sửa | Gray (chỉ owner) | `/edit/:lessonId` |

#### Vocabulary Table
Cột: **Từ vựng** | **Phiên âm** | **Loại từ** | **Nghĩa** | **Ví dụ**

- IPA hiển thị dạng mono-font trong badge xanh: `/wɜːrd/`
- WordType dạng badge vàng: `noun`, `verb`...
- Ví dụ: italic tiếng Anh + dịch tiếng Việt nhỏ bên dưới

#### Loading State
Skeleton placeholders cho header, action bar, table rows.

#### Error State
- `getLesson()` throw → toast error + navigate về Home

#### isOwner check
```
isOwner = (currentUser.username === lesson.creator)
          || (currentUser.email === lesson.creator)
```

---

## 9. UI — Study (Flashcard)

### Luồng

```
Loading → Flashcard hiện tại → [Đã thuộc ✓] | [Chưa thuộc ✗]
       → Chuyển thẻ (skip "know" cards)
       → Khi all "know" → CompletionScreen
```

### FlashcardData model (local state)
```dart
class FlashcardData {
  String id;          // "{vocabId}-{index}"
  String term;        // word
  String definition;
  String? ipa;
  String? wordType;
  String? exampleEn;
  String? exampleVi;
  String? status;     // null | "know" | "still_learning"
}
```

### Progress Bar
```
progressPercent = (knowCount / total) * 100
```

### Navigation logic
- Sau khi mark "know": tìm thẻ tiếp theo không phải "know"
- Nếu không còn thẻ chưa biết → `isCompleted = true`
- Thẻ wrap around (quay vòng) nếu đã qua hết

### Completion Screen
- Hiển thị: số từ đã thuộc / số từ chưa thuộc
- Buttons: `[Ôn tập lại]` `[Kiểm tra]` `[Quay lại]`

### Side effects khi hoàn thành
```
timeSpent = (Date.now() - startTime) / 1000   // seconds
historyService.incrementStudyStats(uid, "flashcard", timeSpent)
srsService.initializeCardsForLesson(lessonId, uid, vocabulary)
  // chỉ gọi nếu lessonId có, và chưa có cards (idempotent)
```

---

## 10. UI — TestPage (Kiểm Tra)

### Cơ chế kiểm tra
- **Input:** Hiển thị `definition` (nghĩa tiếng Việt) → user gõ từ tiếng Anh
- **Gợi ý visual:** Mỗi ký tự của từ hiển thị dạng `_`, khi user gõ đúng ký tự theo vị trí thì hiện ra
- Chấm điểm: case-insensitive exact match
- **Hint:** `"Từ có {n} ký tự"`

### Trạng thái
```
loading → quiz → results
```

### TestResult model
```dart
class TestResult {
  String term;
  String definition;
  String userAnswer;
  bool isCorrect;
}
```

### Luồng
1. Load lesson (shuffle vocabulary)
2. Hiển thị câu hỏi: definition → nhập từ
3. Submit / Skip → next question
4. Khi hết → ShowResults
5. ResultScreen: % đúng, danh sách sai, nút "Làm lại câu sai"

### Lưu lịch sử
```
// Chỉ lưu lần đầu (không lưu khi "Làm lại câu sai")
historyService.incrementStudyStats(uid, "test", timeSpent)
```

### ResultScreen
- Score badge lớn (%)
- Correct/Incorrect count
- Danh sách từ sai: `definition → đáp án đúng | câu trả lời của user`
- Buttons: `[Làm lại từ đầu]` `[Làm lại câu sai]` `[Về bài học]`

---

## 11. UI — SRSReviewPage (Ôn Tập SRS)

### Ngưỡng & hằng số
```
CATCHUP_THRESHOLD = 200   // Nếu > 200 thẻ → hiện modal catchup
BATCH_SIZE = 20           // Batch nhỏ khi catchup
```

### Luồng session queue
```
dueCards[] → sessionQueue[]
  ↓
Hiện card → [Hiện đáp án]
  ↓
User chọn: Again | Hard | Good | Easy
  ↓
Đúng (hard/good/easy):
  - Persist Firestore (chỉ lần đầu đúng)
  - Remove khỏi queue
  
Sai (again):
  - Push xuống cuối queue (local chỉ)
  - KHÔNG persist (tránh ô nhiễm data)
  ↓
Queue rỗng → finishSession()
```

### ReviewCard UI
- Mặt trước: `word` (từ tiếng Anh)
- Mặt sau (sau khi nhấn "Hiện đáp án"): `definition`, `ipa`, stats (streak, intervals...)
- 4 nút rating: **Again** (đỏ) | **Hard** (cam) | **Good** (xanh lá) | **Easy** (xanh dương)

### Header Stats
```
{correctCount} đúng | {incorrectCount} sai | {pendingCount} còn lại
```
Kèm progress bar: `(correctCount / totalUniqueCards) * 100%`

### Catchup Modal
- Hiện khi `dueCards.length > 200`
- Buttons:
  - "Học 20 thẻ trước" → slice đầu 20
  - "Học hết {n} thẻ"

### Kết thúc session
```
srsService.endReviewSession(sessionId, {
  cardsReviewed, correctCount, incorrectCount, totalTime
})
historyService.incrementStudyStats(uid, "review", totalTime)
→ Navigate về Home
```

---

## 12. SRS Algorithm — SM-2

### Rating → Quality score
| Rating | Quality | Mô tả |
|---|---|---|
| `again` | 0 | Hoàn toàn quên |
| `hard` | 3 | Nhớ nhưng khó |
| `good` | 4 | Nhớ tốt |
| `easy` | 5 | Dễ dàng |

### Tính EaseFactor mới
```
newEF = clamp(
  oldEF + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)),
  min = 1.3,
  max = 2.8
)
```

### Tính Interval mới
```dart
if (rating == "again") {
  interval = 1
  repetitions = 0
  // EF giảm nhưng không quá thấp
} else {
  if (repetitions == 0) interval = 1
  else if (repetitions == 1) interval = 6
  else interval = round(oldInterval * newEF)
  
  repetitions += 1
}
nextReview = now + interval days
```

### Streak
```
streak = isCorrect ? streak + 1 : 0
```

---

## 13. Trạng Thái & Điều Hướng

### Route Map

| Screen | Route | Auth Required |
|---|---|---|
| Home | `/` | ✅ |
| Lesson Detail | `/lesson/:lessonId` | ✅ |
| Flashcard Study | `/study/:lessonId` | ✅ |
| Test | `/test/:lessonId` | ✅ |
| SRS Review | `/srs-review` | ✅ |
| Review (Quiz) | `/review/:lessonId` | ✅ |
| Game (Asteroid) | `/asteroid-match/:lessonId` | ✅ |
| My Lessons | `/my-lessons` | ✅ |
| Folder View | `/folder/:folderId` | ✅ |
| Create Lesson | `/create-lesson` | ✅ |
| Edit Lesson | `/edit/:lessonId` | ✅ (chỉ owner) |
| Study History | `/study-history` | ✅ |
| Profile | `/profile` | ✅ |
| Leaderboard | `/leaderboard` | ✅ |

### Navigation State (truyền qua route)
Khi navigate từ LessonView → Study/Test/Game, truyền kèm:
```json
{
  "from": "/lesson/:lessonId"
}
```
Dùng để nút "Quay lại" biết về đâu (lesson detail, thư mục, hay trang chủ).

### User Session
User info được lưu trong `sessionStorage["user"]`:
```json
{
  "email": "user@example.com",
  "username": "myusername",
  "uid": "firebase-uid"
}
```
**Mobile:** Tương đương lưu vào `SharedPreferences` / `SecureStorage`.

---

## ✅ Checklist Implement Mobile

- [ ] Firebase Auth (login/logout/register)
- [ ] Lưu user session (uid + username + email)
- [ ] `getLesson(lessonId)` — fetch lesson + vocab
- [ ] `getLessonsPaginated()` — danh sách bài học
- [ ] LessonView UI (header, action bar, vocab table)
- [ ] Study/Flashcard flow (mark know/still_learning, progress)
- [ ] `initializeCardsForLesson()` — khởi tạo SRS sau flashcard
- [ ] TestPage flow (quiz, submit, results)
- [ ] SRSReviewPage + SM-2 algorithm
- [ ] `incrementStudyStats()` — ghi lịch sử sau mỗi loại học
- [ ] StudyHistory/Dashboard — đọc stats + heatmap
- [ ] isOwner check → hiện/ẩn nút Edit
- [ ] Catchup modal SRS (> 200 thẻ)
