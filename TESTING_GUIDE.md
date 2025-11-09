# Testing Divine Quotes Feature - Quick Guide

## Prerequisites

1. **Backend Running**: Spring Boot API at `http://localhost:8080`
2. **Database**: PostgreSQL with V35 migration applied
3. **Admin User**: Manually assigned ADMIN role

## Step 1: Assign Admin Role

Connect to PostgreSQL and run:

```sql
-- Replace with your admin email
UPDATE "user" SET role = 'ADMIN' WHERE email = 'your-admin@example.com';

-- Verify the update
SELECT id, email, role, is_active FROM "user" WHERE role = 'ADMIN';
```

## Step 2: Get Firebase JWT Token

### Option A: Using Firebase Console

1. Go to Firebase Console → Authentication
2. Copy the UID of your admin user
3. Use Firebase Admin SDK to create custom token (if needed)

### Option B: Using Flutter App

1. Run the main Satsang OTT app
2. Login with admin credentials
3. Use DevTools to inspect network requests and copy the JWT token from headers

### Option C: Using Firebase Auth REST API

```bash
# Get ID token via email/password
curl -X POST "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "your-admin@example.com",
    "password": "your-password",
    "returnSecureToken": true
  }'

# Response will contain: { "idToken": "...", ... }
```

**Find API Key**:
- Flutter: `lib/firebase_options.dart` → `apiKey`
- Firebase Console: Project Settings → Web API Key

## Step 3: Test Backend Endpoints

Export your JWT token for convenience:

```bash
# PowerShell
$TOKEN = "your-firebase-jwt-token-here"

# OR Bash
export TOKEN="your-firebase-jwt-token-here"
```

### 3.1 Verify Admin Access

```bash
curl -X GET "http://localhost:8080/api/admin/auth/verify" `
  -H "Authorization: Bearer $TOKEN"

# Expected: { "success": true, "data": { "isAdmin": true, "role": "ADMIN" } }
```

### 3.2 List Quotes (Empty at first)

```bash
curl -X GET "http://localhost:8080/api/admin/quotes?page=0&size=20" `
  -H "Authorization: Bearer $TOKEN"

# Expected: { "success": true, "data": { "content": [], "totalElements": 0 } }
```

### 3.3 Create a Quote

```bash
curl -X POST "http://localhost:8080/api/admin/quotes" `
  -H "Authorization: Bearer $TOKEN" `
  -H "Content-Type: application/json" `
  -d '{
    "textDevanagari": "योगः कर्मसु कौशलम्",
    "textTransliteration": "yogaḥ karmasu kauśalam",
    "textEnglishMeaning": "Yoga is skill in action",
    "sourceBook": "Bhagavad Gita",
    "sourceBookHindi": "श्रीमद्भगवद्गीता",
    "chapterReference": "2",
    "verseNumber": "50",
    "category": "KARMA",
    "mood": "NEUTRAL",
    "isActive": true,
    "displayPriority": 75
  }'

# Expected: { "success": true, "data": { "id": 1, ... } }
# Note the ID returned!
```

### 3.4 Get Quote by ID

```bash
curl -X GET "http://localhost:8080/api/admin/quotes/1" `
  -H "Authorization: Bearer $TOKEN"

# Expected: { "success": true, "data": { "id": 1, ... } }
```

### 3.5 Update Quote

```bash
curl -X PUT "http://localhost:8080/api/admin/quotes/1" `
  -H "Authorization: Bearer $TOKEN" `
  -H "Content-Type: application/json" `
  -d '{
    "textDevanagari": "योगः कर्मसु कौशलम्",
    "textTransliteration": "yogaḥ karmasu kauśalam",
    "textEnglishMeaning": "Yoga is skillfulness in action (UPDATED)",
    "sourceBook": "Bhagavad Gita",
    "chapterReference": "2",
    "verseNumber": "50",
    "category": "KARMA",
    "mood": "NEUTRAL",
    "isActive": true,
    "displayPriority": 80
  }'

# Expected: { "success": true, "data": { "id": 1, "displayPriority": 80, ... } }
```

### 3.6 Toggle Active Status

```bash
curl -X PUT "http://localhost:8080/api/admin/quotes/1/toggle-active" `
  -H "Authorization: Bearer $TOKEN"

# Expected: { "success": true, "data": { "id": 1, "isActive": false, ... } }

# Toggle again to reactivate
curl -X PUT "http://localhost:8080/api/admin/quotes/1/toggle-active" `
  -H "Authorization: Bearer $TOKEN"

# Expected: { "success": true, "data": { "id": 1, "isActive": true, ... } }
```

### 3.7 Update Category

```bash
curl -X PUT "http://localhost:8080/api/admin/quotes/1/category?category=BHAKTI" `
  -H "Authorization: Bearer $TOKEN"

# Expected: { "success": true, "data": { "id": 1, "category": "BHAKTI", ... } }
```

### 3.8 Filter by Category

```bash
curl -X GET "http://localhost:8080/api/admin/quotes?category=BHAKTI&isActive=true" `
  -H "Authorization: Bearer $TOKEN"

# Expected: { "success": true, "data": { "content": [ { "id": 1, ... } ] } }
```

### 3.9 Delete Quote

```bash
curl -X DELETE "http://localhost:8080/api/admin/quotes/1" `
  -H "Authorization: Bearer $TOKEN"

# Expected: { "success": true, "message": "Quote deleted successfully" }
```

## Step 4: Test Frontend (Flutter Admin Panel)

### 4.1 Start Backend

```bash
cd d:\development\projectRepo\GitHub\satsang-api
./mvnw spring-boot:run
```

Wait for: `Started SatsangApiApplication in X seconds`

### 4.2 Start Flutter Admin Panel

```bash
cd d:\development\projectRepo\GitHub\satsang_admin
flutter run -d chrome --web-port 8081
```

### 4.3 Login

1. Navigate to `http://localhost:8081`
2. Login with your admin credentials (same as backend test)
3. Should redirect to dashboard

### 4.4 Navigate to Quotes

1. Click hamburger menu (top-left)
2. Click "Quotes" menu item
3. Should see quotes list screen (empty or with test data)

### 4.5 Create Quote

1. Click FAB (+ Create Quote button)
2. Fill in required fields:
   - Devanagari Text: `श्रद्धावान् लभते ज्ञानं`
   - English Meaning: `A person with faith attains knowledge`
   - Category: `GYAAN`
   - Mood: `NEUTRAL`
3. Optional fields:
   - Transliteration: `śraddhāvān labhate jñānaṁ`
   - Source Book: `Bhagavad Gita`
   - Chapter: `4`, Verse: `39`
4. Adjust Display Priority slider (0-100)
5. Ensure Active toggle is ON
6. Click "Create Quote"
7. Should show success snackbar and navigate back to list

### 4.6 Verify Quote in List

1. Quote should appear in DataTable
2. Check all columns: ID, Text, Source, Category, Status, Priority, Actions

### 4.7 Filter Quotes

1. Select Category dropdown → "GYAAN"
2. List should update to show only GYAAN quotes
3. Select Status dropdown → "Active"
4. List should update to show only active GYAAN quotes

### 4.8 Toggle Active Status

1. Click the Switch widget in Status column
2. Should toggle to OFF (inactive)
3. Success snackbar should appear
4. Click again to toggle back to ON (active)

### 4.9 Edit Quote

1. Click Edit button (pencil icon)
2. Form should pre-populate with quote data
3. Modify English Meaning: append " (EDITED)"
4. Click "Update Quote"
5. Should show success snackbar and navigate back to list
6. Verify updated text in list

### 4.10 Delete Quote

1. Click Delete button (trash icon)
2. Confirmation dialog should appear
3. Click "Delete"
4. Quote should disappear from list
5. Success snackbar should appear

### 4.11 Test Pagination

1. Create 25 quotes (using backend curl or UI)
2. Verify only 20 appear on page 1
3. Click right arrow (→) for next page
4. Verify remaining 5 appear on page 2
5. Click left arrow (←) to go back

## Step 5: Error Handling Tests

### 5.1 Test Non-Admin User

```bash
# Create a regular user (non-admin)
# Get JWT token for that user
curl -X GET "http://localhost:8080/api/admin/auth/verify" `
  -H "Authorization: Bearer $NON_ADMIN_TOKEN"

# Expected: 403 Forbidden
# { "success": false, "message": "Access denied: Admin privileges required" }
```

### 5.2 Test Invalid Token

```bash
curl -X GET "http://localhost:8080/api/admin/quotes" `
  -H "Authorization: Bearer invalid-token-123"

# Expected: 401 Unauthorized
```

### 5.3 Test Missing Token

```bash
curl -X GET "http://localhost:8080/api/admin/quotes"

# Expected: 401 Unauthorized
```

### 5.4 Test Not Found

```bash
curl -X GET "http://localhost:8080/api/admin/quotes/999999" `
  -H "Authorization: Bearer $TOKEN"

# Expected: 404 Not Found
```

### 5.5 Test Validation Errors (Frontend)

1. Click "Create Quote"
2. Leave Devanagari Text empty
3. Leave English Meaning empty
4. Click "Create Quote"
5. Should show validation errors (red text)

## Step 6: Database Verification

After creating/updating quotes via API or UI:

```sql
-- View all quotes
SELECT id, text_english_meaning, category, is_active, display_priority, created_at
FROM divine_quote
ORDER BY created_at DESC;

-- Count by category
SELECT category, COUNT(*) as count
FROM divine_quote
GROUP BY category;

-- Check active vs inactive
SELECT is_active, COUNT(*) as count
FROM divine_quote
GROUP BY is_active;
```

## Common Issues & Solutions

### Issue: 403 Forbidden on admin endpoints

**Solution**: Verify admin role is assigned in database:
```sql
SELECT email, role FROM "user" WHERE email = 'your-email@example.com';
```

### Issue: 401 Unauthorized

**Solution**: 
1. Check JWT token is valid (not expired)
2. Verify `Authorization: Bearer` header is present
3. Get a fresh token from Firebase

### Issue: Frontend shows "Failed to load quotes"

**Solution**:
1. Check backend is running (`http://localhost:8080`)
2. Check browser console for errors (F12)
3. Verify API URL in `lib/app/constants.dart`:
   ```dart
   static const String baseUrl = 'http://localhost:8080';
   ```

### Issue: CORS errors in browser

**Solution**: Backend should have CORS configured. Check `SecurityConfig.java`:
```java
.cors(cors -> cors.configurationSource(corsConfigurationSource()))
```

### Issue: Quotes not appearing after creation

**Solution**:
1. Check browser console for errors
2. Verify provider invalidation: `ref.invalidate(quotesListProvider)`
3. Manually refresh page

### Issue: Database migration not applied

**Solution**:
```bash
# Check migration status
psql -U postgres -d satsang_ott

# List migrations
SELECT version, description, success FROM flyway_schema_history;

# If V35 is missing, backend will auto-apply on next startup
```

## Success Criteria

✅ Backend admin verification returns `isAdmin: true`  
✅ Can create quote via curl (returns 201 Created)  
✅ Can list quotes via curl (returns data array)  
✅ Can update quote via curl (returns updated data)  
✅ Can delete quote via curl (returns success)  
✅ Frontend shows login screen  
✅ Can login with admin credentials  
✅ Dashboard loads successfully  
✅ Quotes menu item visible in drawer  
✅ Quotes list screen loads (empty or with data)  
✅ Can create quote via UI (form validates and submits)  
✅ Quote appears in DataTable after creation  
✅ Can edit quote via UI (form pre-populates)  
✅ Changes appear in list after edit  
✅ Can toggle active status via switch  
✅ Can delete quote with confirmation  
✅ Filtering works (category, status)  
✅ Pagination works (if >20 quotes exist)  
✅ Error snackbars appear on failures  
✅ Success snackbars appear on success  

---

**After successful testing**, proceed with implementing the next admin feature (Categories or Content Management).
