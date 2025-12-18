# Pantheos - Divine Fantasy MMORPG Website

Official website for Pantheos MMORPG game.

## 🌐 Live Website

Visit: [Your GitHub Pages URL will be here]

## 🎮 Features

- **Game Download**: Download the game client
- **Account System**: Create and manage accounts
- **Responsive Design**: Works on desktop and mobile
- **Modern UI**: Pixel-art themed with smooth animations

## 📁 Structure

```
website/
├── pantheos-optimized.html  # Main landing page
├── index.html               # (copy of pantheos-optimized.html)
├── downloads/               # Game downloads
│   └── Pantheos-Game.zip   # Game client (add via GitHub Releases)
├── api/                     # Backend API (PHP)
│   ├── account.php         # Account management
│   └── config.php          # Database config (not in repo)
├── Pic1.png                # Hero image
├── logo.png                # Logo
└── README.md               # This file
```

## 🚀 Setup

### For GitHub Pages

1. **Fork or clone this repository**
2. **Enable GitHub Pages**:
   - Go to Settings → Pages
   - Source: Deploy from branch
   - Branch: main / root
   - Save

3. **Add game download**:
   - Create a GitHub Release
   - Upload `Pantheos-Game.zip`
   - Update download link in `pantheos-optimized.html`

### For Custom Hosting

1. **Upload files** via FTP
2. **Configure database**:
   - Create `api/config.php` with your database credentials
   - Import database schema
3. **Set permissions**:
   - Files: 644
   - Folders: 755

## 🔧 Configuration

### Database Connection

The website connects to your game's database for account management.

**Important**: The `api/config.php` file is NOT included in the repository for security. You need to create it:

```php
<?php
// api/config.php
$host = 'your-database-host';
$dbname = 'mmorpg_game';
$username = 'your-username';
$password = 'your-password';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    die("Connection failed: " . $e->getMessage());
}
?>
```

### Game Download Link

Update the download link in `pantheos-optimized.html`:

```html
<!-- For GitHub Releases -->
<a href="https://github.com/yourusername/pantheos-website/releases/download/v1.0.0/Pantheos-Game.zip" 
   class="btn-primary" download>Play Game</a>

<!-- For direct hosting -->
<a href="downloads/Pantheos-Game.zip" class="btn-primary" download>Play Game</a>
```

## 🎯 GitHub Pages Limitations

**What Works:**
- ✅ Static HTML/CSS/JavaScript
- ✅ Game downloads (via GitHub Releases)
- ✅ Responsive design
- ✅ Animations

**What Doesn't Work:**
- ❌ PHP files (GitHub Pages is static only)
- ❌ Database connections from GitHub Pages

**Solution for Account System:**
- Host the API separately (see below)
- Or use GitHub Pages for website + separate server for API

## 🌍 Hosting Options

### Option 1: GitHub Pages (Website) + Separate API Server

**Website (GitHub Pages):**
- Free hosting
- Fast CDN
- HTTPS included
- Perfect for static content

**API Server (Separate):**
- Railway.app (free tier)
- Render.com (free tier)
- Your own VPS

Update API URLs in the game to point to your API server.

### Option 2: Full Hosting (Website + API)

Host everything together on:
- Hostinger ($2-5/month)
- Bluehost ($3-10/month)
- DigitalOcean ($5/month)

## 📦 Game Distribution

### Via GitHub Releases (Recommended)

1. **Create Release**:
   - Go to Releases → Create new release
   - Tag: v1.0.0
   - Title: Pantheos v1.0.0
   - Upload: `Pantheos-Game.zip`

2. **Update Download Link**:
   ```html
   <a href="https://github.com/yourusername/pantheos-website/releases/download/v1.0.0/Pantheos-Game.zip">
   ```

3. **Benefits**:
   - Free hosting for large files
   - Version control
   - Download statistics
   - No bandwidth limits

### Via Direct Hosting

If you have your own hosting:
1. Upload `Pantheos-Game.zip` to `downloads/` folder
2. Link works as-is: `downloads/Pantheos-Game.zip`

## 🔒 Security Notes

**Never commit:**
- ❌ Database passwords (`api/config.php`)
- ❌ API keys
- ❌ Sensitive credentials

**Always:**
- ✅ Use `.gitignore` for sensitive files
- ✅ Use environment variables for production
- ✅ Enable HTTPS
- ✅ Validate user input

## 📱 Browser Support

- ✅ Chrome/Edge (latest)
- ✅ Firefox (latest)
- ✅ Safari (latest)
- ✅ Mobile browsers

## 🎨 Customization

### Colors

Edit CSS variables in `pantheos-optimized.html`:
```css
:root {
    --deep-purple: #2D1B69;
    --celestial-gold: #FFD700;
    /* ... */
}
```

### Images

Replace:
- `Pic1.png` - Hero background
- `logo.png` - Logo

### Content

Edit text in `pantheos-optimized.html`:
- Hero section
- Features
- About section

## 📞 Support

For issues or questions:
- GitHub Issues: [Your repo URL]
- Email: [Your email]
- Discord: [Your Discord]

## 📄 License

[Your License Here]

## 🙏 Credits

- Game Engine: Godot
- Fonts: Google Fonts
- Design: Custom

---

Made with ❤️ for the Pantheos community
