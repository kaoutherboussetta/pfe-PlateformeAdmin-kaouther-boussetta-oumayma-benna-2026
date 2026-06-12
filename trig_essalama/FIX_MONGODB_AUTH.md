# Fix MongoDB Authentication Error

## 🔴 Error: "bad auth : authentication failed"

This error occurs when MongoDB cannot authenticate with the provided credentials.

## ✅ Solution Steps

### Step 1: Check your `.env` file

Open your `.env` file in the root directory and verify your MongoDB configuration.

### Step 2: If using MONGODB_DSN (Recommended for MongoDB Atlas)

Your `.env` should have:

```env
DB_CONNECTION=mongodb
MONGODB_DSN=mongodb+srv://USERNAME:PASSWORD@cluster0.xxxxx.mongodb.net/
MONGODB_DATABASE=trig_essalama
MONGODB_AUTHENTICATION_DATABASE=admin
```

**⚠️ IMPORTANT:**
- Replace `USERNAME` with your MongoDB Atlas username
- Replace `PASSWORD` with your MongoDB Atlas password
- Replace `cluster0.xxxxx.mongodb.net` with your actual cluster URL
- **If your password contains special characters, you MUST URL-encode them:**
  - `@` → `%40`
  - `#` → `%23`
  - `$` → `%24`
  - `%` → `%25`
  - `&` → `%26`
  - `+` → `%2B`
  - `=` → `%3D`
  - `?` → `%3F`
  - `/` → `%2F`
  - Space → `%20`

**Example:**
If your password is `My@Pass#123`, the DSN should be:
```
MONGODB_DSN=mongodb+srv://username:My%40Pass%23123@cluster0.xxxxx.mongodb.net/
```

### Step 3: If using individual settings (Alternative)

If you prefer not to use DSN, use these settings:

```env
DB_CONNECTION=mongodb
MONGODB_HOST=cluster0.xxxxx.mongodb.net
MONGODB_PORT=27017
MONGODB_USERNAME=your_username
MONGODB_PASSWORD=your_password
MONGODB_DATABASE=trig_essalama
MONGODB_AUTHENTICATION_DATABASE=admin
```

### Step 4: Clear Laravel cache

After updating `.env`, run these commands:

```bash
php artisan config:clear
php artisan cache:clear
```

### Step 5: Test the connection

Test your MongoDB connection using Tinker:

```bash
php artisan tinker
```

Then in Tinker:
```php
DB::connection()->getDatabaseName();
```

You should see: `"trig_essalama"`

If you get an authentication error, double-check:
1. Username and password are correct
2. Password is URL-encoded if using DSN
3. Your IP is whitelisted in MongoDB Atlas (Network Access)
4. The user has proper permissions in MongoDB Atlas

### Step 6: Verify MongoDB Atlas settings

1. **Database Access:**
   - Go to MongoDB Atlas → Database Access
   - Verify your user exists and has the correct password
   - Ensure the user has "Atlas admin" or "Read and write to any database" permissions

2. **Network Access:**
   - Go to MongoDB Atlas → Network Access
   - Ensure your IP address is whitelisted (or use `0.0.0.0/0` for development)

## 🔍 Common Issues

### Issue 1: Password contains special characters
**Solution:** URL-encode the password in the DSN string.

### Issue 2: Wrong authentication database
**Solution:** Set `MONGODB_AUTHENTICATION_DATABASE=admin` in your `.env`

### Issue 3: IP not whitelisted
**Solution:** Add your IP address in MongoDB Atlas → Network Access

### Issue 4: User doesn't have permissions
**Solution:** In MongoDB Atlas → Database Access, ensure the user has proper permissions

## 📝 Quick Checklist

- [ ] `.env` file has correct `MONGODB_DSN` or individual MongoDB settings
- [ ] Password is URL-encoded if it contains special characters
- [ ] `MONGODB_AUTHENTICATION_DATABASE=admin` is set
- [ ] IP address is whitelisted in MongoDB Atlas
- [ ] User has proper permissions in MongoDB Atlas
- [ ] Ran `php artisan config:clear` after updating `.env`
- [ ] Tested connection with `php artisan tinker`

## 🆘 Still having issues?

1. Check Laravel logs: `storage/logs/laravel.log`
2. Verify MongoDB extension is installed: `php -m | grep mongodb`
3. Test connection directly with MongoDB client if available
