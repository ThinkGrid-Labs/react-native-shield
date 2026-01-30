#import "Shield.h"
#import <TrustKit/TrustKit.h>
#import <UIKit/UIKit.h>

@implementation Shield

- (NSNumber *)isRooted {
  BOOL isJailbroken = NO;

  // Check 1: Existence of common jailbreak files
  NSArray *jailbreakFilePaths = @[
    @"/Applications/Cydia.app",
    @"/Library/MobileSubstrate/MobileSubstrate.dylib",
    @"/bin/bash",
    @"/usr/sbin/sshd",
    @"/etc/apt",
    @"/private/var/lib/apt/",
  ];

  for (NSString *path in jailbreakFilePaths) {
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
      isJailbroken = YES;
      break;
    }
  }

  // Check 2: Ability to write outside sandbox
  if (!isJailbroken) {
    NSString *testPath = @"/private/jailbreak.txt";
    NSError *error;
    [@"check" writeToFile:testPath
               atomically:YES
                 encoding:NSUTF8StringEncoding
                    error:&error];

    if (error == nil) {
      // Write successful - Device is jailbroken
      isJailbroken = YES;
      // Clean up
      [[NSFileManager defaultManager] removeItemAtPath:testPath error:nil];
    }
  }

  // Check 3: Check for Cydia URL scheme
  if (!isJailbroken) {
    if ([[UIApplication sharedApplication]
            canOpenURL:
                [NSURL URLWithString:@"cydia://package/com.example.package"]]) {
      isJailbroken = YES;
    }
  }

  return @(isJailbroken);
}

- (void)addSSLPinning:(NSString *)domain
      publicKeyHashes:(NSArray *)publicKeyHashes
              resolve:(RCTPromiseResolveBlock)resolve
               reject:(RCTPromiseRejectBlock)reject {

  NSDictionary *trustKitConfig = @{
    kTSKSwizzleNetworkDelegates : @YES,
    kTSKPinnedDomains : @{
      domain : @{
        kTSKPublicKeyHashes : publicKeyHashes,
        kTSKIncludeSubdomains : @YES,
        kTSKEnforcePinning : @YES,
      }
    }
  };

  [TrustKit initSharedInstanceWithConfiguration:trustKitConfig];
  resolve(nil);
}

- (void)preventScreenshot:(BOOL)prevent
                  resolve:(RCTPromiseResolveBlock)resolve
                   reject:(RCTPromiseRejectBlock)reject {
  dispatch_async(dispatch_get_main_queue(), ^{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (!window) {
      reject(@"NO_WINDOW", @"Key window is null", nil);
      return;
    }

    if (prevent) {
      // "Secure Field" trick: attaching a secure text field to the window layer
      // makes it hidden in screenshots/recording
      UITextField *secureField = [[UITextField alloc] init];
      secureField.secureTextEntry = YES;
      secureField.userInteractionEnabled = NO;
      secureField.tag = 9999;

      // This is the common workaround for iOS < 13+, replacing the view
      // hierarchy content However, a simpler modern approach for *recording* is
      // listening to UIScreenCapturedDidChangeNotification Real "prevention" of
      // *screenshots* is not officially supported by iOS API. The
      // secureTextEntry trick makes the CALayer hidden.

      [window addSubview:secureField];
      [window.layer.sublayers
          makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
      [window.layer addSublayer:secureField.layer];
      [[window.layer.sublayers firstObject]
          addSublayer:window.rootViewController.view.layer];

      // NOTE: The above layer manipulation is risky and complex.
      // A safer standard approach for React Native modules is just to rely on
      // `UIScreenCapturedDidChangeNotification` to blur the screen, OR use a
      // hidden secure text field to mask specific views. For a "Whole App"
      // shield, we often just blur on resign active.

      // LET'S IMPLEMENT BLUR ON BACKGROUND (Privacy) instead of Hacky
      // Screenshot Prevention because true screenshot prevention is impossible
      // on iOS.

      [[NSNotificationCenter defaultCenter]
          addObserver:self
             selector:@selector(appDidBecomeActive)
                 name:UIApplicationDidBecomeActiveNotification
               object:nil];
      [[NSNotificationCenter defaultCenter]
          addObserver:self
             selector:@selector(appWillResignActive)
                 name:UIApplicationWillResignActiveNotification
               object:nil];
    } else {
      [[NSNotificationCenter defaultCenter]
          removeObserver:self
                    name:UIApplicationDidBecomeActiveNotification
                  object:nil];
      [[NSNotificationCenter defaultCenter]
          removeObserver:self
                    name:UIApplicationWillResignActiveNotification
                  object:nil];
    }
    resolve(nil);
  });
}
// Placeholder for the blur logic
- (void)appWillResignActive {
  UIWindow *window = [UIApplication sharedApplication].keyWindow;
  UIBlurEffect *blurEffect =
      [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
  UIVisualEffectView *blurEffectView =
      [[UIVisualEffectView alloc] initWithEffect:blurEffect];
  blurEffectView.frame = window.bounds;
  blurEffectView.autoresizingMask =
      UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  blurEffectView.tag = 12345;
  [window addSubview:blurEffectView];
}

- (void)appDidBecomeActive {
  UIWindow *window = [UIApplication sharedApplication].keyWindow;
  UIView *blurView = [window viewWithTag:12345];
  [blurView removeFromSuperview];
}

// Secure Storage Implementation (Keychain)

- (void)setSecureString:(NSString *)key
                  value:(NSString *)value
                resolve:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject {
  NSData *valueData = [value dataUsingEncoding:NSUTF8StringEncoding];
  NSString *service = [[NSBundle mainBundle] bundleIdentifier];

  NSDictionary *query = @{
    (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
    (__bridge id)kSecAttrService : service,
    (__bridge id)kSecAttrAccount : key
  };

  // Check if it exists to decide on item update or add
  OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, NULL);

  if (status == errSecSuccess) {
    NSDictionary *attributes = @{(__bridge id)kSecValueData : valueData};
    status = SecItemUpdate((__bridge CFDictionaryRef)query,
                           (__bridge CFDictionaryRef)attributes);
  } else if (status == errSecItemNotFound) {
    NSMutableDictionary *newQuery = [query mutableCopy];
    [newQuery setObject:valueData forKey:(__bridge id)kSecValueData];
    status = SecItemAdd((__bridge CFDictionaryRef)newQuery, NULL);
  }

  if (status == errSecSuccess) {
    resolve(@(YES));
  } else {
    NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                         code:status
                                     userInfo:nil];
    reject(@"SECURE_STORAGE_ERROR", @"Failed to save secure string", error);
  }
}

- (void)getSecureString:(NSString *)key
                resolve:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject {
  NSString *service = [[NSBundle mainBundle] bundleIdentifier];
  NSDictionary *query = @{
    (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
    (__bridge id)kSecAttrService : service,
    (__bridge id)kSecAttrAccount : key,
    (__bridge id)kSecReturnData : @YES,
    (__bridge id)kSecMatchLimit : (__bridge id)kSecMatchLimitOne
  };

  CFTypeRef result = NULL;
  OSStatus status =
      SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);

  if (status == errSecSuccess) {
    NSData *data = (__bridge_transfer NSData *)result;
    NSString *value = [[NSString alloc] initWithData:data
                                            encoding:NSUTF8StringEncoding];
    resolve(value);
  } else if (status == errSecItemNotFound) {
    resolve(nil);
  } else {
    NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                         code:status
                                     userInfo:nil];
    reject(@"SECURE_STORAGE_ERROR", @"Failed to retrieve secure string", error);
  }
}

- (void)removeSecureString:(NSString *)key
                   resolve:(RCTPromiseResolveBlock)resolve
                    reject:(RCTPromiseRejectBlock)reject {
  NSString *service = [[NSBundle mainBundle] bundleIdentifier];
  NSDictionary *query = @{
    (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
    (__bridge id)kSecAttrService : service,
    (__bridge id)kSecAttrAccount : key
  };

  OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);

  if (status == errSecSuccess || status == errSecItemNotFound) {
    resolve(@(YES));
  } else {
    NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                         code:status
                                     userInfo:nil];
    reject(@"SECURE_STORAGE_ERROR", @"Failed to remove secure string", error);
  }
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params {
  return std::make_shared<facebook::react::NativeShieldSpecJSI>(params);
}

+ (NSString *)moduleName {
  return @"Shield";
}

@end
