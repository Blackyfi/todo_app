# Task Sharing Feature

## Overview
The Todo App now supports comprehensive task sharing functionality, allowing users to share tasks via email, WhatsApp, Instagram, Telegram, and other apps through the native share sheet.

## Features

### 1. Share Single Task
- Open any task details screen
- Tap the **Share** icon in the app bar
- Choose encryption option (optional)
- Select sharing method from native share sheet

### 2. Share Multiple Tasks (Batch Selection)
From the home screen:
1. Tap the **three-dot menu** in the app bar
2. Select **"Select Tasks"**
3. Tap tasks to select them (checkboxes appear)
4. Use **Select All** button to select all visible tasks
5. Tap the **Share** icon in the app bar
6. Configure sharing options and share

To exit selection mode:
- Tap the **X** button in the app bar
- Or complete a share action (exits automatically)

### 3. Share All Tasks
From the home screen:
1. Tap the **three-dot menu** in the app bar
2. Select **"Share All Tasks"**
3. Configure sharing options and share

## Sharing Options

### Encryption (Optional)
- Toggle **"Encrypt with password"** in the share dialog
- Enter a strong password (minimum 6 characters)
- Uses AES-256-GCM encryption with PBKDF2 key derivation
- Recipient will need the same password to decrypt

### File Format
- **Unencrypted**: `.json` file with readable task data
- **Encrypted**: `.encrypted` file with secure encrypted data

### Estimated Size
The share dialog shows the estimated file size before sharing.

## Sharing Methods
Tasks can be shared through any app that supports file sharing:
- **Email**: Attach task file to email
- **WhatsApp**: Send as document
- **Telegram**: Share as file
- **Instagram**: Limited support (check platform capabilities)
- **Other apps**: Any app supporting file sharing

## Selection Mode UI

When in selection mode:
- App bar shows selected count (e.g., "3 selected")
- Close button (X) replaces the back button
- Checkboxes appear on all task cards
- Selected tasks are highlighted with a light background
- **Select All** / **Deselect All** button in app bar
- **Share** button in app bar

## Technical Details

### Data Structure
Tasks are exported using the `ShareData` model:
- **Single Task**: `ShareDataType.task`
- **Multiple Tasks**: `ShareDataType.taskList`
- **All Tasks**: `ShareDataType.allTasks`

### Encryption
- Algorithm: AES-256-GCM
- Key Derivation: PBKDF2 with 100,000 iterations
- Salt: Random 32 bytes
- Nonce: Random 12 bytes (96 bits)
- Tag: 16 bytes (128 bits)

### Share Package
Uses `share_plus` package for native platform integration:
- iOS: UIActivityViewController
- Android: Intent.ACTION_SEND
- Desktop: Native share dialogs (where available)

## Import Feature
While not part of this implementation, the app supports:
- Importing shared task files
- Decrypting encrypted files with password
- QR code sharing (for small datasets)

Refer to existing documentation for import functionality.

## Best Practices

1. **Security**: Use encryption when sharing sensitive task data
2. **Password Strength**: Use passwords with at least 8 characters, mixing letters, numbers, and symbols
3. **Verify Recipients**: Ensure you're sharing with intended recipients
4. **Backup**: Keep a local copy of important tasks before sharing
5. **File Size**: Large task lists may be better suited for file sharing than messaging apps

## Limitations

- QR codes limited to ~2900 bytes (use file sharing for larger datasets)
- Instagram may have limited file sharing capabilities
- Some platforms may not support .encrypted file extension

## Troubleshooting

**Issue**: Share button doesn't appear
- **Solution**: Ensure you're in selection mode or viewing a task details screen

**Issue**: Can't select tasks
- **Solution**: Enter selection mode via the three-dot menu → "Select Tasks"

**Issue**: Encryption password rejected
- **Solution**: Password must be at least 6 characters long

**Issue**: Share fails
- **Solution**: Check app permissions for the target sharing app
