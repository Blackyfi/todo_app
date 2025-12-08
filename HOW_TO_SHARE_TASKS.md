# 📤 How to Share Tasks - User Guide

## ✅ **Sharing is Now Active!**

You can now share tasks directly from your Todo App with optional password encryption!

---

## 📱 **How to Share a Task**

### Step 1: Open Task Details
1. Tap on any task in your task list
2. This opens the **Task Details** screen

### Step 2: Tap the Share Button
- Look at the **top-right corner**
- You'll see three icons: **Share** (📤), **Edit** (✏️), **Delete** (🗑️)
- **Tap the Share icon** (📤)

### Step 3: Choose Encryption (Optional)
A dialog will appear with these options:

**Option A: Share Without Encryption** (Default)
- Leave the "Encrypt with password" toggle **OFF**
- Tap **"Share"**
- Choose where to send it (Email, Messages, Files, etc.)
- The recipient can import it directly (no password needed)

**Option B: Share With Encryption** (Recommended for sensitive tasks)
- Toggle "Encrypt with password" **ON**
- Enter a **strong password** (minimum 6 characters)
  - Good examples: `MyTasks2024!`, `GroceryList#123`
  - Weak examples: `123456`, `password`
- Tap **"Share"**
- Choose where to send it
- **IMPORTANT**: Send the password to the recipient separately (not in the same message!)

---

## 🔒 **Security Features**

When you enable encryption:

✅ **Military-grade encryption** (AES-256-GCM)
✅ **Same security** as Signal, WhatsApp, banking apps
✅ **Password protection** - only recipient with password can open
✅ **Tamper detection** - file can't be modified without detection
✅ **100% local** - encryption happens on your device
✅ **No internet needed** - works completely offline

**File formats:**
- Without encryption: `.json` file (readable as text)
- With encryption: `.encrypted` file (secure binary data)

---

## 📥 **Receiving a Shared Task**

### If You Received an Unencrypted Task (.json file):
1. Open the file (implementation coming soon)
2. The task will be imported automatically

### If You Received an Encrypted Task (.encrypted file):
1. Open the file (implementation coming soon)
2. You'll be prompted to enter the password
3. Enter the password the sender gave you
4. The task will be decrypted and imported

---

## 💡 **Tips & Best Practices**

### Passwords:
- ✅ **DO**: Use at least 12 characters
- ✅ **DO**: Mix letters, numbers, and symbols
- ✅ **DO**: Send password separately from the file
- ❌ **DON'T**: Use simple passwords like "123456"
- ❌ **DON'T**: Include password in same email as file

### When to Encrypt:
- ✅ Sharing sensitive work tasks
- ✅ Sharing personal information
- ✅ Sharing financial tasks
- ✅ Sharing via unsecure channels (email, messages)
- ❌ Sharing with family (your choice)
- ❌ Sharing simple shopping lists (your choice)

### File Sizes:
- Single task: ~200-500 bytes
- Encrypted task: ~300-700 bytes (slightly larger)
- Both are very small and easy to share!

---

## 🚀 **Advanced: Sharing Multiple Tasks (Coming Soon)**

Future features planned:
- Share all tasks at once (backup)
- Share selected tasks
- QR code sharing (for quick in-person sharing)
- Import functionality with file picker

---

## 🛡️ **Technical Details**

For those interested in the security:

**Encryption Specification:**
- **Algorithm**: AES-256-GCM
- **Key Derivation**: PBKDF2-HMAC-SHA256
- **Iterations**: 100,000 (industry standard)
- **Salt**: 32 bytes (random per encryption)
- **Nonce**: 12 bytes (random per encryption)
- **Authentication Tag**: 16 bytes (prevents tampering)

This is the **same level of security** used by:
- Signal (encrypted messaging)
- 1Password (password manager)
- Banking apps
- Government communications

**Privacy Guarantee:**
- ✅ All encryption happens **locally** on your device
- ✅ **No data sent to servers**
- ✅ **No cloud storage** required
- ✅ **No internet** connection needed
- ✅ **100% private** - only you and your recipient can access

---

## ❓ **FAQ**

**Q: What if I forget the password?**
A: Unfortunately, if you forget the password, the encrypted file cannot be opened. There is no recovery mechanism (this is what makes it secure). Always remember your passwords or store them in a password manager.

**Q: Can someone hack the encrypted file?**
A: With AES-256-GCM and a strong password, the file is effectively impossible to crack with current technology. The same encryption protects your bank account and government secrets.

**Q: Can I share tasks between iOS and Android?**
A: Yes! The encryption is cross-platform. You can share from iOS to Android, Android to iOS, or any combination.

**Q: What if the file gets corrupted or modified?**
A: The encryption includes tamper detection. If anyone tries to modify the encrypted file, it will fail to decrypt and show an error.

**Q: Does this work offline?**
A: Yes! Everything works offline. Encryption, file creation, and sharing all happen locally on your device.

**Q: Is my password stored anywhere?**
A: No! The password is only used to encrypt/decrypt the file. It's never stored or transmitted anywhere.

---

## 🎯 **Quick Start Guide**

**Simplest way to try it:**

1. Open any task
2. Tap Share icon (📤) in top-right
3. Leave encryption OFF (for first try)
4. Tap Share
5. Choose "Save to Files" or "Email to myself"
6. Done! The file is created

**Try with encryption:**

1. Open any task
2. Tap Share icon (📤)
3. Toggle encryption ON
4. Enter password: `test123`
5. Tap Share
6. Save the file
7. Remember the password to test import later!

---

**Enjoy secure task sharing! 🎉**
