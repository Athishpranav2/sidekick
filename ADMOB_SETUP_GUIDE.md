# Google AdMob Setup Guide for Sidekick App

## 🚀 Quick Setup Steps

### 1. Create Google AdMob Account

1. Go to [AdMob Console](https://admob.google.com/)
2. Sign in with your Google account
3. Click "Create Account"
4. Fill in your app details:
   - App name: "Sidekick"
   - Platform: Android
   - App store: Google Play (or "Not in store" for testing)

### 2. Get Your Ad Unit IDs

After creating your account, you'll get:

- **App ID**: `ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX`
- **Banner Ad Unit ID**: `ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX`
- **Interstitial Ad Unit ID**: `ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX`

### 3. Update Your Code

Replace the placeholder IDs in `lib/core/services/admob_service.dart`:

```dart
// Replace these with your real ad unit IDs
static String get bannerAdUnitId {
  if (kDebugMode) {
    return 'ca-app-pub-3940256099942544/6300978111'; // Test ID
  } else {
    return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX'; // Your real banner ID
  }
}
```

### 4. Update Android Manifest

Replace the test app ID in `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX" />
```

## 📱 Ad Types Available

### Banner Ads (Currently Implemented)

- **Location**: Feed positions 3, 7, 12
- **Size**: 320x50 (standard banner)
- **Revenue**: ~$0.10-$0.50 per 1000 impressions

### Interstitial Ads (Ready to Implement)

- **Location**: Between screens, after actions
- **Revenue**: ~$2-$10 per 1000 impressions
- **Usage**: Show after user completes actions

### Rewarded Ads (Ready to Implement)

- **Location**: Premium features, extra content
- **Revenue**: ~$5-$20 per 1000 impressions
- **Usage**: Users watch ad to unlock features

## 💰 Expected Revenue

### Small App (1K-10K users)

- **Banner ads**: $10-$100/month
- **Interstitial ads**: $50-$500/month
- **Total potential**: $100-$1000/month

### Growth Tips

1. **Start with test ads** during development
2. **Gradually increase ad frequency** as you grow
3. **A/B test ad placements** for best performance
4. **Monitor user feedback** and adjust accordingly

## 🔧 Implementation Status

✅ **Banner Ads**: Integrated into feed
✅ **AdMob Service**: Complete with all ad types
✅ **Android Configuration**: Ready
⏳ **iOS Configuration**: Need to add (if you have iOS users)
⏳ **Interstitial Ads**: Ready to implement
⏳ **Rewarded Ads**: Ready to implement

## 🎯 Next Steps

1. **Create AdMob account** and get real ad unit IDs
2. **Replace test IDs** with your real IDs
3. **Test with real ads** in production
4. **Monitor performance** in AdMob console
5. **Add interstitial ads** for higher revenue
6. **Consider rewarded ads** for premium features

## 📊 Revenue Optimization

### Best Practices:

- **Don't overwhelm users** - keep ads minimal
- **Place ads naturally** in user flow
- **Test different positions** for best performance
- **Monitor user retention** after adding ads
- **Start conservatively** and increase gradually

### Ad Placement Strategy:

- **Banner ads**: Every 3-5 posts in feed
- **Interstitial ads**: After completing actions (posting, matching)
- **Rewarded ads**: For premium features (extra matches, advanced filters)

## 🚨 Important Notes

1. **Test ads work in development** - you'll see test ads until you publish
2. **Real ads require app approval** - Google reviews your app
3. **Revenue takes time** - it builds up as you get more users
4. **User experience first** - don't sacrifice UX for ad revenue

## 📞 Support

- **AdMob Help**: https://support.google.com/admob
- **Flutter AdMob Plugin**: https://pub.dev/packages/google_mobile_ads
- **Google AdMob Console**: https://admob.google.com/

---

**Remember**: Start small, test thoroughly, and prioritize user experience over ad revenue!
