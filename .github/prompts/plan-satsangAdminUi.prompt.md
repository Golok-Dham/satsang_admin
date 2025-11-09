# Plan: Satsang Admin UI Development

Building a separate Flutter-based admin panel for managing content, users, sankalpas, quotes, and analytics, using the existing Spring Boot backend with enhanced role-based access control.

## Steps

### 1. Add role-based access control to backend
Create Flyway migration adding `role` column to `user` table, update `User` entity with ENUM (USER, ADMIN, MODERATOR), create admin seeder script, and add `@PreAuthorize("hasRole('ADMIN')")` to new admin endpoints

**Implementation Details:**
- Create migration file: `V35__Add_User_Role_Column.sql`
- Add ENUM type: `CREATE TYPE user_role AS ENUM ('USER', 'ADMIN', 'MODERATOR')`
- Add column: `ALTER TABLE "user" ADD COLUMN role VARCHAR(20) DEFAULT 'USER'`
- Create index: `CREATE INDEX idx_user_role ON "user"(role)`
- Update `User.java` entity with `@Enumerated(EnumType.STRING) private UserRole role`
- Create `UserRole` enum class
- Create admin seeder script for initial admin user

### 2. Create admin REST endpoints in existing Spring Boot project
Add `AdminContentController`, `AdminCategoryController`, `AdminUserController`, `AdminPlaylistController`, and `AdminAnalyticsController` under `/api/admin/*` paths with proper authorization guards

**Endpoint Structure:**
```
/api/admin/content/*          - Content CRUD with vdoCipher integration
  POST   /api/admin/content            - Create new content
  PUT    /api/admin/content/{id}       - Update content
  DELETE /api/admin/content/{id}       - Delete content
  PUT    /api/admin/content/{id}/publish - Publish content
  PUT    /api/admin/content/{id}/unpublish - Unpublish content

/api/admin/categories/*        - Category management
  POST   /api/admin/categories         - Create category
  PUT    /api/admin/categories/{id}    - Update category
  DELETE /api/admin/categories/{id}    - Delete category
  PUT    /api/admin/categories/reorder - Reorder categories

/api/admin/users/*             - User management
  GET    /api/admin/users              - List all users (paginated)
  GET    /api/admin/users/{id}         - Get user details
  PUT    /api/admin/users/{id}/suspend - Suspend user
  PUT    /api/admin/users/{id}/activate - Activate user
  PUT    /api/admin/users/{id}/subscription - Update subscription
  PUT    /api/admin/users/{id}/verify  - Verify user

/api/admin/playlists/system/*  - System playlist management
  POST   /api/admin/playlists/system   - Create system playlist
  PUT    /api/admin/playlists/system/{id} - Update system playlist
  DELETE /api/admin/playlists/system/{id} - Delete system playlist
  PUT    /api/admin/playlists/system/{id}/feature - Feature playlist

/api/admin/sankalpas/templates/* - Sankalp template management
  POST   /api/admin/sankalpas/templates - Create template
  PUT    /api/admin/sankalpas/templates/{id} - Update template
  DELETE /api/admin/sankalpas/templates/{id} - Delete template

/api/admin/quotes/*            - Divine quotes management
  POST   /api/admin/quotes             - Create quote
  PUT    /api/admin/quotes/{id}        - Update quote
  DELETE /api/admin/quotes/{id}        - Delete quote
  PUT    /api/admin/quotes/{id}/categorize - Update categories

/api/admin/analytics/*         - Dashboard stats
  GET    /api/admin/analytics/dashboard - Dashboard overview
  GET    /api/admin/analytics/users    - User statistics
  GET    /api/admin/analytics/content  - Content statistics
  GET    /api/admin/analytics/trending - Trending content
```

**Security Pattern:**
```java
@RestController
@RequestMapping("/api/admin")
public class AdminContentController {
    
    @PostMapping("/content")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<ContentResponse>> createContent(
        @RequestBody CreateContentRequest request
    ) {
        // Admin-only content creation
    }
}
```

### 3. Initialize separate Flutter admin project
Create `satsang_admin_panel` Flutter project with Material Design 3 (consistent with main app), configure Firebase Auth (same project), add `fl_chart` for analytics. Copy essential models and services from main app (no submodules/dependencies - keep it simple)

**Project Setup:**
```bash
# Create new Flutter project
flutter create satsang_admin_panel --org in.golokdham.satsang --platforms web

# Add dependencies
flutter pub add flutter_riverpod
flutter pub add riverpod_annotation
flutter pub add firebase_auth
flutter pub add firebase_core
flutter pub add dio
flutter pub add go_router
flutter pub add fl_chart
flutter pub add file_picker
flutter pub add image_picker

flutter pub add --dev riverpod_generator
flutter pub add --dev build_runner
flutter pub add --dev riverpod_lint
flutter pub add --dev custom_lint
```

**Directory Structure:**
```
satsang_admin_panel/
├── lib/
│   ├── app/
│   │   ├── router.dart          # GoRouter config
│   │   ├── theme.dart           # Material Design 3 theme
│   │   └── constants.dart       # API URLs, environment config
│   ├── core/
│   │   ├── models/              # Copied from main app (Content, User, Category, etc.)
│   │   ├── providers/           # Admin-specific providers
│   │   ├── services/            # api_service.dart (Dio), auth_service.dart
│   │   └── utils/               # snackbar_helper.dart, validators.dart
│   ├── features/
│   │   ├── auth/                # Admin login with role verification
│   │   ├── dashboard/           # Analytics dashboard
│   │   ├── content/             # Content management (CRUD)
│   │   ├── categories/          # Category management
│   │   ├── users/               # User management
│   │   ├── playlists/           # Playlist management
│   │   ├── sankalpas/           # Sankalp templates
│   │   └── quotes/              # Quote management
│   └── main.dart
├── web/
│   ├── index.html               # Firebase config, CSP
│   └── manifest.json
└── pubspec.yaml
```

**Files to Copy from Main App (~500-1000 lines):**
```
Copy from satsang_ott_flutter/lib/core/models/:
- content_model.dart
- user_model.dart
- category_model.dart
- playlist_model.dart
- sankalp_model.dart
- divine_quote_model.dart
- api_response.dart

Copy from satsang_ott_flutter/lib/core/services/:
- api_service.dart (Dio setup with Firebase Auth interceptor)

Copy from satsang_ott_flutter/lib/core/utils/:
- snackbar_helper.dart
- validators.dart

Copy from satsang_ott_flutter/lib/app/:
- constants.dart (API base URLs)

Total: ~10-15 files, minimal duplication, zero complexity
```

### 4. Implement admin UI core modules
Build login screen with role verification, dashboard with analytics cards (users, content, views), sidebar navigation (Content, Categories, Users, Playlists, Sankalpas, Quotes, Analytics), and content management screens with CRUD operations including vdoCipher video upload integration

**Key Features:**

**A. Authentication Flow:**
```dart
// Admin login with role check
@riverpod
class AdminAuth extends _$AdminAuth {
  @override
  Future<User?> build() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return null;
    
    // Verify admin role from backend
    final token = await firebaseUser.getIdToken();
    final response = await dio.get('/api/admin/verify', 
      options: Options(headers: {'Authorization': 'Bearer $token'})
    );
    
    if (response.data['role'] != 'ADMIN') {
      throw Exception('Unauthorized: Admin access required');
    }
    
    return User.fromFirebase(firebaseUser);
  }
}
```

**B. Dashboard Layout:**
```dart
// Material Design 3 Navigation Rail + Drawer (responsive)
Scaffold(
  appBar: AppBar(
    title: Text('Satsang Admin Panel'),
    actions: [
      IconButton(icon: Icon(Icons.notifications), onPressed: () {}),
      IconButton(icon: Icon(Icons.account_circle), onPressed: () {}),
    ],
  ),
  drawer: NavigationDrawer(
    selectedIndex: _selectedIndex,
    onDestinationSelected: (index) => setState(() => _selectedIndex = index),
    children: [
      DrawerHeader(child: Text('Satsang Admin')),
      NavigationDrawerDestination(icon: Icon(Icons.dashboard), label: Text('Dashboard')),
      NavigationDrawerDestination(icon: Icon(Icons.video_library), label: Text('Content')),
      NavigationDrawerDestination(icon: Icon(Icons.category), label: Text('Categories')),
      NavigationDrawerDestination(icon: Icon(Icons.people), label: Text('Users')),
      NavigationDrawerDestination(icon: Icon(Icons.playlist_play), label: Text('Playlists')),
      NavigationDrawerDestination(icon: Icon(Icons.self_improvement), label: Text('Sankalpas')),
      NavigationDrawerDestination(icon: Icon(Icons.format_quote), label: Text('Quotes')),
      NavigationDrawerDestination(icon: Icon(Icons.analytics), label: Text('Analytics')),
    ],
  ),
  body: _pages[_selectedIndex],
)
```

**C. Content Management Screen:**
```dart
// Material DataTable with pagination, sorting, filtering
PaginatedDataTable(
  header: Text('Content Management'),
  columns: [
    DataColumn(label: Text('Title')),
    DataColumn(label: Text('Type')),
    DataColumn(label: Text('Status')),
    DataColumn(label: Text('Views'), numeric: true),
    DataColumn(label: Text('Actions')),
  ],
  source: ContentDataTableSource(contentList),
  rowsPerPage: 10,
  showCheckboxColumn: true,
)
```

**D. Content Creation Form:**
```dart
// Form with vdoCipher ID input (manual upload to vdoCipher dashboard)
Column(
  children: [
    TextFormField(
      decoration: InputDecoration(
        labelText: 'Title',
        helperText: 'Enter content title',
      ),
    ),
    TextFormField(
      decoration: InputDecoration(labelText: 'Description'),
      maxLines: 5,
    ),
    DropdownButtonFormField(
      decoration: InputDecoration(labelText: 'Type'),
      items: [
        DropdownMenuItem(value: 'VIDEO', child: Text('Video')),
        DropdownMenuItem(value: 'AUDIO', child: Text('Audio')),
      ],
    ),
    TextFormField(
      decoration: InputDecoration(
        labelText: 'vdoCipher Video ID',
        helperText: 'Upload video to vdoCipher dashboard first, then paste ID here',
      ),
      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
    ),
    TextFormField(
      decoration: InputDecoration(
        labelText: 'Audio Stream URL',
        helperText: 'Cloudflare R2 URL for audio content',
      ),
    ),
    FilePicker(
      label: 'Thumbnail Image',
      onPicked: (file) => uploadThumbnail(file),
    ),
    CategoryMultiSelect(),
    TagInput(),
    ElevatedButton(
      onPressed: createContent,
      child: Text('Create Content'),
    ),
  ],
)
```

**E. Analytics Dashboard:**
```dart
// Dashboard with stats cards and charts
GridView.count(
  crossAxisCount: 4,
  children: [
    Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.people, size: 48),
            Text('12,345', style: Theme.of(context).textTheme.headlineMedium),
            Text('Total Users'),
          ],
        ),
      ),
    ),
    Card(child: StatsCard(title: 'Total Content', value: '456', icon: Icons.video_library)),
    Card(child: StatsCard(title: 'Total Views', value: '1.2M', icon: Icons.visibility)),
    Card(child: StatsCard(title: 'Active Sessions', value: '89', icon: Icons.play_circle)),
  ],
),
LineChart(/* User growth chart */),
BarChart(/* Content by category */),
```

### 5. Deploy admin panel to production
Configure `admin.satsang.golokdham.in` subdomain in Cloudflare DNS, build Flutter web with `flutter build web --web-renderer canvaskit`, deploy to Cloudflare Pages with separate project, update Caddy reverse proxy config for admin subdomain routing

**Deployment Steps:**

**A. Build Flutter Web:**
```bash
flutter build web --web-renderer canvaskit --release
```

**B. Cloudflare Pages Setup:**
1. Create new Cloudflare Pages project: `satsang-admin-panel`
2. Connect to Git repository (separate repo or monorepo)
3. Build settings:
   - Build command: `flutter build web --web-renderer canvaskit --release`
   - Build output directory: `build/web`
   - Environment variables: `FLUTTER_VERSION=3.24.0`

**C. Cloudflare DNS:**
```
admin.satsang.golokdham.in → CNAME → satsang-admin-panel.pages.dev
```

**D. Caddy Configuration (if self-hosted):**
```caddyfile
admin.satsang.golokdham.in {
    reverse_proxy localhost:8080 {
        header_up Host {host}
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
    }
}
```

**E. Firebase Configuration:**
Update Firebase authorized domains:
- Add `admin.satsang.golokdham.in`
- Configure redirect URLs for OAuth

## Further Considerations

### 1. Technology stack decision
Flutter with Material Design 3 (consistent with main app) for admin panel. No need for Fluent UI or complex data table libraries - standard Material widgets are sufficient for CRUD operations.

**CONFIRMED:** Flutter + Material Design 3

**Why Flutter + Material Design 3:**
- ✅ Code reuse: Share 60-70% of codebase (models, repositories, providers)
- ✅ Team expertise: Existing Flutter/Riverpod knowledge
- ✅ Unified auth: Same Firebase + JWT flow
- ✅ Lower maintenance: Single language (Dart)
- ✅ Consistent UI: Same Material Design 3 theme as main app
- ✅ Standard widgets sufficient: PaginatedDataTable, Form widgets, Cards
- ✅ No file upload complexity: vdoCipher ID input only (text field)

### 2. Code duplication approach (SIMPLIFIED)
Copy essential models and services directly into admin panel project. No submodules, no monorepo, no path dependencies. Keep it simple.

**CONFIRMED APPROACH: Direct Copy (No Sharing Mechanism)**

**Why Simple Copy Wins:**
- ✅ **Zero Build Complexity**: No submodules, no monorepo tools, no path dependencies
- ✅ **Independent Deployment**: Admin panel repo can be completely separate
- ✅ **Faster Development**: No "sync shared code" overhead
- ✅ **Easier Debugging**: No ambiguity about which version of shared code
- ✅ **Team Onboarding**: New devs understand admin panel in isolation
- ✅ **Freedom to Diverge**: Admin UI can evolve differently from main app

**What to Copy (One-Time):**
```bash
# Copy models (~10-15 files)
cp -r satsang_ott_flutter/lib/core/models/* satsang_admin_panel/lib/core/models/

# Copy API service
cp satsang_ott_flutter/lib/core/services/api_service.dart satsang_admin_panel/lib/core/services/

# Copy utilities
cp satsang_ott_flutter/lib/core/utils/snackbar_helper.dart satsang_admin_panel/lib/core/utils/
cp satsang_ott_flutter/lib/app/constants.dart satsang_admin_panel/lib/app/
```

**Estimated Duplication:**
- Models: ~500 lines (Content, User, Category, Playlist, Sankalp, Quote DTOs)
- API Service: ~150 lines (Dio setup, interceptors)
- Utils: ~100 lines (SnackBarHelper, validators)
- **Total: ~750 lines** (trivial compared to 50,000+ lines in main app)

**When to Sync:**
- Only when backend API changes (rare)
- Only when model fields change (infrequent)
- Copy-paste updates take 5 minutes max

**NO submodules, NO path dependencies, NO monorepo = Simple and maintainable**

### 3. Admin user provisioning
Initial admin user creation strategy: Option A: Direct database insert with hashed credentials, Option B: Firebase custom claims script, Option C: Master admin account with invite system

**Options:**

**Option A: Direct Database Insert**
```sql
-- Manual SQL insert
INSERT INTO "user" (firebase_uid, email, role, status)
VALUES ('admin-firebase-uid', 'admin@satsang.golokdham.in', 'ADMIN', 'ACTIVE');
```
- ✅ Simple for first admin
- ❌ Manual process
- ❌ No audit trail

**Option B: Firebase Custom Claims Script**
```javascript
// Node.js script
const admin = require('firebase-admin');
admin.initializeApp();

async function setAdminRole(uid) {
  await admin.auth().setCustomUserClaims(uid, { admin: true, role: 'ADMIN' });
  console.log(`Admin role set for ${uid}`);
}

setAdminRole('user-firebase-uid');
```
- ✅ Leverages Firebase
- ✅ Works with existing auth flow
- ❌ Requires Node.js script
- ❌ Custom claims not in database

**Option C: Master Admin + Invite System**
```java
@PostMapping("/api/admin/users/invite")
@PreAuthorize("hasRole('ADMIN')")
public ResponseEntity<Void> inviteAdmin(@RequestBody InviteRequest request) {
    // Send invite email with signup link
    // Upon signup, auto-assign ADMIN role
}
```
- ✅ Self-service admin creation
- ✅ Audit trail of who invited whom
- ✅ Scalable for multiple admins
- ❌ Requires email service
- ❌ More complex implementation

**Recommendation:** Option B (Firebase Custom Claims) for initial setup, then implement Option C (Invite System) for ongoing admin management.

### 4. Audit logging scope
Should we implement comprehensive audit logs for all admin actions (who created/updated/deleted what and when) from day one, or start with basic logging and enhance later? This affects database schema and controller implementation

**Full Audit Logging (Recommended):**

**Schema:**
```sql
CREATE TABLE admin_audit_log (
    id BIGSERIAL PRIMARY KEY,
    admin_user_id BIGINT NOT NULL REFERENCES "user"(id),
    action VARCHAR(50) NOT NULL, -- CREATE, UPDATE, DELETE, PUBLISH, SUSPEND
    entity_type VARCHAR(50) NOT NULL, -- CONTENT, USER, CATEGORY, etc.
    entity_id BIGINT,
    changes JSONB, -- Before/after values
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_admin_user ON admin_audit_log(admin_user_id);
CREATE INDEX idx_audit_entity ON admin_audit_log(entity_type, entity_id);
CREATE INDEX idx_audit_created_at ON admin_audit_log(created_at);
```

**Implementation (AOP Aspect):**
```java
@Aspect
@Component
public class AdminAuditAspect {
    
    @AfterReturning(pointcut = "@annotation(auditLog)", returning = "result")
    public void logAdminAction(JoinPoint joinPoint, AuditLog auditLog, Object result) {
        User admin = currentUserService.getCurrentUser();
        HttpServletRequest request = getCurrentRequest();
        
        AdminAuditLogEntry entry = AdminAuditLogEntry.builder()
            .adminUserId(admin.getId())
            .action(auditLog.action())
            .entityType(auditLog.entityType())
            .entityId(extractEntityId(result))
            .changes(buildChangesJson(joinPoint.getArgs(), result))
            .ipAddress(request.getRemoteAddr())
            .userAgent(request.getHeader("User-Agent"))
            .build();
            
        auditLogRepository.save(entry);
    }
}

// Usage
@PutMapping("/content/{id}")
@PreAuthorize("hasRole('ADMIN')")
@AuditLog(action = "UPDATE", entityType = "CONTENT")
public ResponseEntity<ContentResponse> updateContent(@PathVariable Long id, @RequestBody ContentRequest request) {
    // Update logic
}
```

**Benefits:**
- ✅ Complete accountability
- ✅ Compliance and security
- ✅ Debugging aid (who changed what)
- ✅ Analytics on admin activity

**Costs:**
- ❌ Additional database storage
- ❌ Slight performance overhead
- ❌ More complex implementation

**Recommendation:** Implement from day one for security and compliance. Use AOP (Aspect-Oriented Programming) to minimize code duplication.

### 5. File upload strategy
Video uploads via vdoCipher dashboard (external workflow). Audio processing via local CLI tool for chunking and HLS stream generation, then upload to Cloudflare R2.

**Video Upload Workflow (CONFIRMED):**

**Manual vdoCipher Upload + ID Entry**
```
1. Admin logs into vdoCipher dashboard (https://www.vdocipher.com)
2. Uploads video file manually
3. Copies video_id from vdoCipher
4. Opens Satsang Admin Panel
5. Creates new Content record
6. Pastes vdoCipher video_id into form field
7. Fills other metadata (title, description, categories, etc.)
8. Saves content
```

**Admin Panel Implementation:**
```dart
TextFormField(
  controller: _vdoCipherIdController,
  decoration: InputDecoration(
    labelText: 'vdoCipher Video ID',
    helperText: 'Upload video to vdoCipher dashboard first, then paste ID here',
    prefixIcon: Icon(Icons.videocam),
    suffixIcon: IconButton(
      icon: Icon(Icons.open_in_new),
      onPressed: () => launchUrl('https://www.vdocipher.com/dashboard'),
      tooltip: 'Open vdoCipher Dashboard',
    ),
  ),
  validator: (value) {
    if (value?.isEmpty ?? true) return 'vdoCipher ID is required';
    if (!RegExp(r'^[a-zA-Z0-9]{32}$').hasMatch(value!)) {
      return 'Invalid vdoCipher ID format';
    }
    return null;
  },
)
```

- ✅ No vdoCipher API integration complexity
- ✅ Simple admin panel implementation
- ✅ Leverages vdoCipher's optimized upload UI
- ✅ No server resources consumed for video upload

**Audio Processing Workflow (LOCAL CLI TOOL):**

**Separate Audio Processing Service (Recommended)**

Create a standalone Node.js/Python CLI tool that runs locally on admin's machine:

```bash
# audio-processor-cli
audio-processor process input.mp3 --output ./output --format hls --chunk-duration 10

# What it does:
1. Takes input MP3/WAV file
2. Converts to multiple bitrates (128kbps, 256kbps, 320kbps)
3. Splits into HLS chunks (10-second segments)
4. Generates .m3u8 playlist files
5. Uploads chunks to Cloudflare R2
6. Returns R2 CDN URL for .m3u8 master playlist
```

**Tool Architecture:**
```
audio-processor-cli/
├── src/
│   ├── audio-converter.js     # FFmpeg wrapper for audio conversion
│   ├── hls-generator.js       # HLS chunking logic
│   ├── r2-uploader.js         # Cloudflare R2 SDK integration
│   └── cli.js                 # CLI entry point
├── package.json
├── .env.example               # R2 credentials template
└── README.md
```

**Dependencies:**
- `fluent-ffmpeg` (audio processing)
- `@aws-sdk/client-s3` (R2 upload, S3-compatible)
- `commander` (CLI framework)
- `chalk` (pretty console output)
- `ora` (loading spinners)

**Sample Usage:**
```bash
# Install globally
npm install -g @satsang/audio-processor

# Configure R2 credentials (one-time)
audio-processor configure --r2-account-id xxx --r2-access-key xxx --r2-secret-key xxx

# Process audio file
audio-processor process bhajan-001.mp3 \
  --output-dir ./processed \
  --chunk-duration 10 \
  --bitrates 128,256,320 \
  --upload

# Output:
✓ Converting to HLS format...
✓ Generating 128kbps stream...
✓ Generating 256kbps stream...
✓ Generating 320kbps stream...
✓ Uploading to R2...
✓ Done! Master playlist URL: https://pub.r2.dev/audio/bhajan-001/master.m3u8

# Copy URL and paste into Admin Panel
```

**Admin Panel Integration:**
```dart
TextFormField(
  controller: _audioStreamUrlController,
  decoration: InputDecoration(
    labelText: 'Audio Stream URL (.m3u8)',
    helperText: 'Process audio with local CLI tool, then paste R2 URL here',
    prefixIcon: Icon(Icons.audiotrack),
  ),
  validator: (value) {
    if (value?.isEmpty ?? true) return 'Audio stream URL is required';
    if (!value!.endsWith('.m3u8')) return 'Must be HLS playlist (.m3u8)';
    return null;
  },
)
```

**Why Local CLI Tool?**
- ✅ No server resources consumed (CPU-intensive audio processing)
- ✅ One-time operation per audio file
- ✅ Admin controls processing (can monitor progress locally)
- ✅ Simple to debug (logs visible locally)
- ✅ Can process in batches overnight
- ✅ No backend deployment needed for processing logic
- ❌ Admin needs Node.js/Python installed (but only once)
- ❌ Manual step (not automated in UI)

**Alternative: Server-Side Processing (NOT RECOMMENDED)**

If you still want server-side audio processing:

```java
@PostMapping("/api/admin/content/process-audio")
@PreAuthorize("hasRole('ADMIN')")
public ResponseEntity<AudioProcessingJob> processAudio(@RequestParam MultipartFile audioFile) {
    // This will consume significant server resources!
    String jobId = audioProcessingService.queueJob(audioFile);
    return ResponseEntity.accepted().body(new AudioProcessingJob(jobId));
}
```

- ❌ High CPU usage (FFmpeg audio conversion)
- ❌ High memory usage (large audio files in memory)
- ❌ Slow response (processing can take 5-10 minutes for 1-hour audio)
- ❌ Need job queue (Redis/RabbitMQ) for async processing
- ❌ Complex error handling (timeouts, retries)
- ✅ Fully automated (upload from admin panel → done)

**RECOMMENDATION:** Use local CLI tool for audio processing. Server resources should be reserved for serving content, not processing it.

## Summary

**CONFIRMED Architecture:**
- **Technology**: Flutter Admin Panel with Material Design 3 (separate web-only project)
- **Backend**: Unified Spring Boot API with `/api/admin/*` endpoints
- **Deployment**: Cloudflare Pages (`admin.satsang.golokdham.in`)
- **Code Sharing**: **NONE** - Direct copy of models/services (simple approach, no submodules/dependencies)
- **Admin Provisioning**: Firebase custom claims for first admin, then invite system
- **Audit Logging**: Full implementation from day one using AOP
- **Video Uploads**: Manual upload to vdoCipher dashboard → paste ID into admin panel (text field)
- **Audio Processing**: Local CLI tool (`audio-processor-cli`) for HLS chunking → upload to R2 → paste URL into admin panel
- **Focus**: Data management UI (CRUD operations for all backend entities)
- **Principle**: **Keep It Simple** - Avoid premature optimization, no complex sharing mechanisms

**Development Timeline:**
- **Phase 1 (2-3 weeks)**: Backend role management + basic admin endpoints + Flutter project setup
- **Phase 2 (3-4 weeks)**: Core CRUD screens (Content, Categories, Users)
- **Phase 3 (2-3 weeks)**: Advanced features (Playlists, Sankalpas, Quotes, Analytics)
- **Phase 4 (1-2 weeks)**: Polish, testing, production deployment

**Total Estimated Time**: 8-12 weeks (2-3 months)

**Next Immediate Actions:**
1. Confirm technology choice (Flutter vs React)
2. Create Flyway migration for user roles
3. Set up separate Flutter project
4. Implement first admin endpoint (`/api/admin/verify` for role check)
5. Build admin login screen with role verification
