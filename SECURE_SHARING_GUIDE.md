# Secure Sharing Implementation Guide

## Overview

This guide explains how to use the secure sharing feature for tasks and shopping lists in your Todo App. The implementation supports **encrypted file sharing** and **encrypted QR code sharing**.

---

## Features

✅ **Password-Protected Encryption** (AES-256-GCM)
✅ **File-Based Sharing** (export/import)
✅ **QR Code Sharing** (for quick sharing)
✅ **Flexible Data Types** (single task, multiple tasks, shopping lists, etc.)
✅ **Offline Support** (no backend required)
✅ **Privacy-First** (encryption happens locally)

---

## Architecture

```
┌─────────────────────────────────────────────┐
│         ShareData Models                     │
│  (Task, TaskList, ShoppingList, etc.)       │
└─────────────────┬───────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│      SecureSharingService                   │
│  • AES-256-GCM encryption                   │
│  • PBKDF2 key derivation (100k iterations)  │
│  • Password or key-based encryption         │
└─────────────────┬───────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│        SharingManager                       │
│  • Export to file (encrypted/plain)         │
│  • Share via native share sheet            │
│  • Generate QR codes                        │
│  • Import from file/QR/string               │
└─────────────────┬───────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│           UI Widgets                        │
│  • ShareDialog (file sharing)               │
│  • ImportDialog (import data)               │
│  • QrShareDialog (QR code sharing)          │
└─────────────────────────────────────────────┘
```

---

## Quick Start

### 1. Basic File Sharing (No Encryption)

```dart
import 'package:todo_app/core/sharing/models/share_data.dart';
import 'package:todo_app/core/sharing/widgets/share_dialog.dart';

// Share a single task
Future<void> shareTask(BuildContext context, Task task) async {
  final shareData = ShareData.fromTask(task);

  await showDialog(
    context: context,
    builder: (context) => ShareDialog(
      shareData: shareData,
      title: 'Share Task',
    ),
  );
}
```

### 2. Encrypted File Sharing

```dart
// Share with encryption enabled
// User will be prompted to set a password in the dialog
await showDialog(
  context: context,
  builder: (context) => ShareDialog(
    shareData: ShareData.fromTask(task),
    title: 'Share Encrypted Task',
  ),
);

// The dialog automatically handles:
// - Password input
// - Encryption
// - File export
// - Native share sheet
```

### 3. Import Shared Data

```dart
import 'package:todo_app/core/sharing/widgets/import_dialog.dart';
import 'package:file_picker/file_picker.dart';

Future<void> importSharedData(BuildContext context) async {
  // Pick a file
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json', 'encrypted'],
  );

  if (result != null && result.files.single.path != null) {
    final filePath = result.files.single.path!;

    // Show import dialog
    final shareData = await showDialog<ShareData>(
      context: context,
      builder: (context) => ImportDialog(filePath: filePath),
    );

    if (shareData != null) {
      // Handle imported data
      await _handleImportedData(shareData);
    }
  }
}

Future<void> _handleImportedData(ShareData shareData) async {
  switch (shareData.type) {
    case ShareDataType.task:
      final task = shareData.extractTask();
      if (task != null) {
        await TaskRepository().insertTask(task);
      }
      break;

    case ShareDataType.taskList:
      final tasks = shareData.extractTaskList();
      for (final task in tasks) {
        await TaskRepository().insertTask(task);
      }
      break;

    case ShareDataType.shoppingListWithItems:
      final list = shareData.extractShoppingList();
      final items = shareData.extractGroceryItems();
      if (list != null) {
        final listId = await ShoppingRepository().insertShoppingList(list);
        for (final item in items) {
          await ShoppingRepository().insertGroceryItem(
            item.copyWith(shoppingListId: listId),
          );
        }
      }
      break;

    // Handle other types...
  }
}
```

---

## Usage Examples

### Example 1: Share Single Task

```dart
// In your task details screen
IconButton(
  icon: const Icon(Icons.share),
  onPressed: () async {
    final shareData = ShareData.fromTask(currentTask);
    await showDialog(
      context: context,
      builder: (context) => ShareDialog(
        shareData: shareData,
        title: 'Share "${currentTask.title}"',
      ),
    );
  },
)
```

### Example 2: Share Multiple Tasks

```dart
// Share selected tasks
Future<void> shareSelectedTasks(List<Task> tasks) async {
  final shareData = ShareData.fromTaskList(tasks);

  await showDialog(
    context: context,
    builder: (context) => ShareDialog(
      shareData: shareData,
      title: 'Share ${tasks.length} Tasks',
    ),
  );
}
```

### Example 3: Export All Tasks

```dart
// Backup all tasks to encrypted file
Future<void> backupAllTasks() async {
  final tasks = await TaskRepository().getAllTasks();
  final shareData = ShareData.fromAllTasks(tasks);

  await showDialog(
    context: context,
    builder: (context) => ShareDialog(
      shareData: shareData,
      title: 'Backup All Tasks',
    ),
  );
}
```

### Example 4: Share Shopping List with Items

```dart
// Share shopping list with all items
Future<void> shareShoppingList(
  ShoppingList list,
  List<GroceryItem> items,
) async {
  final shareData = ShareData.fromShoppingListWithItems(list, items);

  await showDialog(
    context: context,
    builder: (context) => ShareDialog(
      shareData: shareData,
      title: 'Share "${list.name}"',
    ),
  );
}
```

### Example 5: QR Code Sharing

```dart
import 'package:todo_app/core/sharing/widgets/qr_share_dialog.dart';

// Share via QR code (good for small data like single tasks)
Future<void> shareViaQr(Task task) async {
  final shareData = ShareData.fromTask(task);

  await showDialog(
    context: context,
    builder: (context) => QrShareDialog(
      shareData: shareData,
      title: 'Share via QR Code',
    ),
  );
}
```

**Note:** For QR code display, add this to `pubspec.yaml`:
```yaml
dependencies:
  qr_flutter: ^4.1.0
  mobile_scanner: ^3.5.0  # For scanning QR codes
```

### Example 6: Programmatic Sharing (No UI)

```dart
import 'package:todo_app/core/sharing/services/sharing_manager.dart';

final sharingManager = SharingManager();

// Export encrypted file
final filePath = await sharingManager.exportToFile(
  shareData: ShareData.fromTask(task),
  password: 'mySecurePassword123',
  fileName: 'my_task_backup.encrypted',
);

print('File exported to: $filePath');

// Later, import it
final importedData = await sharingManager.importFromFile(
  filePath: filePath,
  password: 'mySecurePassword123',
);

final task = importedData.extractTask();
```

---

## Security Features

### Encryption Details

- **Algorithm**: AES-256-GCM (Authenticated Encryption)
- **Key Derivation**: PBKDF2-HMAC-SHA256 with 100,000 iterations
- **Authentication**: Built-in authentication tag to detect tampering
- **Salt**: Random 32-byte salt per encryption
- **Nonce**: Random 12-byte nonce (IV) per encryption

### Encrypted File Format

```json
{
  "version": "1.0",
  "algorithm": "AES-256-GCM",
  "iterations": 100000,
  "salt": "base64-encoded-salt",
  "nonce": "base64-encoded-nonce",
  "ciphertext": "base64-encoded-encrypted-data",
  "tag": "base64-encoded-auth-tag"
}
```

### Password Recommendations

✅ **Good passwords:**
- At least 12 characters
- Mix of letters, numbers, symbols
- Examples: `Grocery#2024!List`, `MyTasks_Dec2024`

❌ **Weak passwords:**
- Short passwords (< 6 chars)
- Common words: `password`, `123456`
- Predictable patterns

---

## Integration with Existing Screens

### Add to Task Details Screen

```dart
// lib/features/tasks/screens/task_details_screen.dart

import 'package:todo_app/core/sharing/widgets/share_dialog.dart';
import 'package:todo_app/core/sharing/models/share_data.dart';

// In your AppBar actions:
AppBar(
  actions: [
    IconButton(
      icon: const Icon(Icons.share),
      tooltip: 'Share task',
      onPressed: () async {
        final shareData = ShareData.fromTask(widget.task);
        await showDialog(
          context: context,
          builder: (context) => ShareDialog(
            shareData: shareData,
            title: 'Share Task',
          ),
        );
      },
    ),
  ],
)
```

### Add to Shopping List Screen

```dart
// lib/features/shopping/screens/shopping_lists_screen.dart

import 'package:todo_app/core/sharing/widgets/share_dialog.dart';
import 'package:todo_app/core/sharing/models/share_data.dart';

// Long press menu
PopupMenuButton(
  itemBuilder: (context) => [
    const PopupMenuItem(
      value: 'share',
      child: ListTile(
        leading: Icon(Icons.share),
        title: Text('Share'),
      ),
    ),
  ],
  onSelected: (value) async {
    if (value == 'share') {
      final items = await ShoppingRepository().getGroceryItemsByList(list.id!);
      final shareData = ShareData.fromShoppingListWithItems(list, items);

      await showDialog(
        context: context,
        builder: (context) => ShareDialog(
          shareData: shareData,
          title: 'Share "${list.name}"',
        ),
      );
    }
  },
)
```

### Add Import Feature to Home Screen

```dart
// lib/features/tasks/screens/home_screen.dart

FloatingActionButton(
  onPressed: () async {
    // Show options: Create Task or Import
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Create New Task'),
            onTap: () => Navigator.pop(context, 'create'),
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Import Shared Tasks'),
            onTap: () => Navigator.pop(context, 'import'),
          ),
        ],
      ),
    );

    if (action == 'import') {
      await _showImportDialog();
    }
  },
)
```

---

## Testing Guide

### Test 1: Basic File Sharing

1. Open a task
2. Tap share button
3. Leave encryption OFF
4. Tap "Share"
5. Save the file
6. Import the file in another device/app instance
7. Verify task is imported correctly

### Test 2: Encrypted Sharing

1. Share a task with encryption ENABLED
2. Set password: `TestPassword123`
3. Save the encrypted file
4. Try importing WITHOUT password → Should fail
5. Import WITH correct password → Should succeed
6. Try importing with WRONG password → Should fail

### Test 3: QR Code Sharing

1. Share a small task via QR
2. Enable encryption with password
3. Generate QR code
4. Scan QR code on another device
5. Enter password to decrypt
6. Verify task imports correctly

### Test 4: Large Data

1. Create 50+ tasks
2. Try sharing all via QR code → Should warn "too large"
3. Share via file instead → Should work
4. Import the file → All tasks should be present

---

## Troubleshooting

### Problem: "Data too large for QR code"

**Solution:** Use file sharing instead. QR codes are limited to ~3KB.

```dart
// Check before sharing
final canFitInQr = await sharingManager.canFitInQrCode(
  shareData: shareData,
  password: password,
);

if (canFitInQr) {
  // Use QR
} else {
  // Use file sharing
}
```

### Problem: "Authentication failed" when importing

**Solution:** This means the password is incorrect or the file was tampered with.

- Double-check the password
- Ensure the file wasn't modified
- Re-export and try again

### Problem: Import dialog doesn't show

**Solution:** Make sure you're handling the file picker result correctly:

```dart
if (result != null && result.files.single.path != null) {
  // ✅ Path exists
  final path = result.files.single.path!;
  // Show dialog...
}
```

---

## Advanced Usage

### Custom Export Location

```dart
import 'dart:io';

final filePath = await sharingManager.exportToFile(
  shareData: shareData,
  password: 'myPassword',
);

// Move to custom location
final customDir = Directory('/path/to/backups');
if (!await customDir.exists()) {
  await customDir.create(recursive: true);
}

final file = File(filePath);
await file.copy('${customDir.path}/backup.encrypted');
```

### Batch Import

```dart
Future<void> importMultipleFiles(List<String> filePaths) async {
  for (final path in filePaths) {
    try {
      final shareData = await sharingManager.importFromFile(
        filePath: path,
        password: null, // Or prompt for password
      );

      await _handleImportedData(shareData);
    } catch (e) {
      print('Failed to import $path: $e');
    }
  }
}
```

### Scheduled Backups

```dart
import 'package:workmanager/workmanager.dart';

// Register daily backup
Workmanager().registerPeriodicTask(
  'daily-backup',
  'backup',
  frequency: const Duration(days: 1),
);

// In background task handler
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'backup') {
      final tasks = await TaskRepository().getAllTasks();
      final shareData = ShareData.fromAllTasks(tasks);

      await SharingManager().exportToFile(
        shareData: shareData,
        password: 'auto-backup-password',
        fileName: 'daily_backup.encrypted',
      );
    }
    return Future.value(true);
  });
}
```

---

## Security Best Practices

1. **Always use encryption** for sensitive tasks
2. **Use strong passwords** (12+ characters)
3. **Don't share passwords** in the same channel as the file
4. **Verify recipients** before sharing
5. **Delete shared files** after recipient confirms receipt
6. **Regular backups** with different passwords
7. **Test recovery** process periodically

---

## File Extensions

- `.json` - Unencrypted share data
- `.encrypted` - Password-protected encrypted data
- `.todoapp` - Custom extension (optional, same as .encrypted)

---

## Next Steps

1. ✅ Integration complete - Now add to your UI
2. 📱 (Optional) Add QR scanning with `mobile_scanner`
3. ☁️ (Optional) Add cloud storage integration
4. 🔄 (Optional) Add auto-sync features

---

## Questions?

Check the code documentation in:
- `lib/core/sharing/services/secure_sharing_service.dart`
- `lib/core/sharing/services/sharing_manager.dart`
- `lib/core/sharing/models/share_data.dart`
