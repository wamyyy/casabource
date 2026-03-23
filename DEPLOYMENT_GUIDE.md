# WAMY — Guide de Déploiement Complet
## De zéro au site live + APK en 30 minutes

---

## ÉTAPE 1 — Configurer Supabase (5 min)

### 1.1 Exécuter le schéma SQL
1. Va sur https://supabase.com/dashboard
2. Ouvre ton projet → **SQL Editor**
3. Colle et exécute `supabase/migrations/001_initial_schema.sql`
4. Colle et exécute `supabase/migrations/002_seed_stocks.sql`

### 1.2 Récupérer le Service Role Key (pour le cron)
1. **Project Settings** → **API**
2. Copie la clé `service_role` (⚠️ ne jamais exposer côté client)

### 1.3 Activer Google Auth
1. **Authentication** → **Providers** → **Google** → Enable
2. Ajoute les URLs autorisées dans **Authentication** → **URL Configuration**:
   - Site URL: `https://ton-projet.vercel.app`
   - Redirect URLs: `https://ton-projet.vercel.app`

---

## ÉTAPE 2 — Déployer sur GitHub + Vercel (10 min)

### 2.1 Créer le repo GitHub
```bash
cd wamy-project
git init
git add .
git commit -m "Initial commit — WAMY v1.0"
git branch -M main
git remote add origin https://github.com/TON-USERNAME/wamy.git
git push -u origin main
```

### 2.2 Déployer sur Vercel
1. Va sur https://vercel.com → **New Project**
2. Importe ton repo GitHub `wamy`
3. **Framework Preset**: Other (ou Static)
4. **Root Directory**: `.` (laisser par défaut)

### 2.3 Ajouter les variables d'environnement
Dans Vercel → Project → **Settings** → **Environment Variables**, ajoute:

| Key | Value |
|-----|-------|
| `SUPABASE_URL` | `https://uvxrsdybplnndwuzixef.supabase.co` |
| `SUPABASE_ANON_KEY` | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` |
| `SUPABASE_SERVICE_ROLE_KEY` | `ta-service-role-key-ici` |
| `UPDATE_SECRET` | `un-secret-random-long` |

### 2.4 Re-déployer après avoir ajouté les vars
```bash
vercel --prod
```

---

## ÉTAPE 3 — Tester le Cron (2 min)

### Test manuel
```
GET https://ton-projet.vercel.app/api/update?secret=ton-secret
```
Tu dois voir: `{"ok":true,"stocksUpdated":78,...}`

### Vérifier dans Supabase
Table `stock_prices` → tu vois les données insérées ✅
Table `update_log` → tu vois le log "ok" ✅

### Schedule automatique
Le fichier `vercel.json` configure le cron:
```json
"schedule": "30 14 * * 1-5"
```
= Tous les jours de semaine à 14h30 UTC = 15h30 Rabat (juste après la clôture du marché)

---

## ÉTAPE 4 — Créer l'APK Android (15 min)

### 4.1 Installer Android Studio
- Télécharger: https://developer.android.com/studio

### 4.2 Créer le projet
1. **New Project** → **Empty Views Activity**
2. Name: `WAMY`
3. Package: `com.wamy.bourse`
4. Language: `Kotlin`
5. Min SDK: API 24 (Android 7.0)

### 4.3 MainActivity.kt
```kotlin
package com.wamy.bourse

import android.os.Bundle
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {
    private lateinit var webView: WebView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Full screen — hide status bar
        window.decorView.systemUiVisibility = (
            android.view.View.SYSTEM_UI_FLAG_FULLSCREEN or
            android.view.View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
            android.view.View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
        )
        
        webView = WebView(this)
        setContentView(webView)
        
        webView.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true        // needed for localStorage
            databaseEnabled = true
            loadWithOverviewMode = true
            useWideViewPort = true
            setSupportZoom(false)
            displayZoomControls = false
            builtInZoomControls = false
            allowFileAccess = true
        }
        
        // Stay in app — no external browser
        webView.webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
                view.loadUrl(request.url.toString())
                return true
            }
        }
        
        // Load your Vercel site
        webView.loadUrl("https://ton-projet.vercel.app")
    }
    
    override fun onBackPressed() {
        if (webView.canGoBack()) webView.goBack()
        else super.onBackPressed()
    }
}
```

### 4.4 AndroidManifest.xml — ajouter la permission internet
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### 4.5 Générer l'APK
1. **Build** → **Build Bundle(s) / APK(s)** → **Build APK(s)**
2. L'APK est dans `app/build/outputs/apk/debug/app-debug.apk`
3. Installe sur ton téléphone: `adb install app-debug.apk`

### 4.6 Optionnel — Splash Screen
Crée `res/drawable/splash.xml` et ajoute dans `styles.xml`:
```xml
<style name="SplashTheme" parent="Theme.AppCompat.NoActionBar">
    <item name="android:windowBackground">@drawable/splash</item>
</style>
```

---

## ÉTAPE 5 — Mettre à jour les données manuellement

### Via SQL dans Supabase
```sql
-- Mettre à jour un prix
INSERT INTO stock_prices (ticker, price, change_pct, volume, cap, ytd, trade_date)
VALUES ('ATW', 705.00, +1.88, '45.2M', '152.0B', -5.22, CURRENT_DATE)
ON CONFLICT (ticker, trade_date) DO UPDATE SET
  price      = EXCLUDED.price,
  change_pct = EXCLUDED.change_pct,
  volume     = EXCLUDED.volume,
  updated_at = NOW();
```

### Via le cron automatique
Le script `/api/update.js` scrape la BVC et met tout à jour automatiquement.

---

## RÉCAPITULATIF — Architecture finale

```
User ouvre APK
    ↓
WebView charge https://wamy.vercel.app
    ↓
index.html + style.css + app.js se chargent
    ↓
app.js appelle Supabase → latest_prices view
    ↓
Affiche les 78 actions avec données live
    ↓
[Chaque jour 15h30] Vercel Cron → /api/update
    ↓
Scrape BVC → upsert dans stock_prices
    ↓
Prochaine ouverture app → données fraîches ✅
```

---

## PROBLÈMES COURANTS

| Problème | Solution |
|----------|----------|
| "No live data" au démarrage | Exécuter les 2 scripts SQL dans Supabase |
| Google Auth ne marche pas | Vérifier les URLs dans Supabase Auth → URL Config |
| Cron ne se déclenche pas | Vercel Pro requis pour cron < 1/jour |
| APK bloque JS | Vérifier `javaScriptEnabled = true` |
| localStorage vide dans APK | Vérifier `domStorageEnabled = true` |
