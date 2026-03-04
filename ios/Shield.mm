#import "Shield.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import <TrustKit/TrustKit.h>
#import <UIKit/UIKit.h>
#import <ifaddrs.h>
#import <mach-o/dyld.h>
#import <net/if.h>
#import <sys/sysctl.h>

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

- (NSNumber *)isEmulator {
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_SIMULATOR
  return @YES;
#else
  return @NO;
#endif
}

- (NSNumber *)isDebuggerAttached {
  int junk;
  int mib[4];
  struct kinfo_proc info;
  size_t size;

  info.kp_proc.p_flag = 0;

  mib[0] = CTL_KERN;
  mib[1] = KERN_PROC;
  mib[2] = KERN_PROC_PID;
  mib[3] = getpid();

  size = sizeof(info);
  junk = sysctl(mib, sizeof(mib) / sizeof(*mib), &info, &size, NULL, 0);
  assert(junk == 0);

  return @((info.kp_proc.p_flag & P_TRACED) != 0);
}

- (NSNumber *)verifySignature:(NSString *)expectedHash {
  // Basic check for iOS: if embedded.mobileprovision exists in a release app,
  // it might imply the app was resigned with a non-App Store cert.
  NSString *provisionPath =
      [[NSBundle mainBundle] pathForResource:@"embedded"
                                      ofType:@"mobileprovision"];
  if (provisionPath) {
    // It exists. If this is supposed to be a production App Store build, this
    // is suspicious. We return NO (invalid/tampered) if it exists, but
    // typically developers need flexibility here. For this method, we return
    // YES if the provision file is *missing* (App Store standard).
    return @NO;
  }
  return @YES;
}

- (NSNumber *)isHooked {
  uint32_t count = _dyld_image_count();
  for (uint32_t i = 0; i < count; i++) {
    const char *name = _dyld_get_image_name(i);
    if (name) {
      NSString *imageName = [NSString stringWithUTF8String:name];
      if ([imageName localizedCaseInsensitiveContainsString:@"Substrate"] ||
          [imageName localizedCaseInsensitiveContainsString:@"Frida"] ||
          [imageName localizedCaseInsensitiveContainsString:@"cycript"] ||
          [imageName localizedCaseInsensitiveContainsString:@"SSLKillSwitch"] ||
          [imageName
              localizedCaseInsensitiveContainsString:@"MobileSubstrate"]) {
        return @YES;
      }
    }
  }
  return @NO;
}

- (NSNumber *)isDeveloperModeEnabled {
  // Not applicable on iOS in the same way as Android settings.
  return @NO;
}

- (NSNumber *)isVPNDetected {
  struct ifaddrs *interfaces;
  if (getifaddrs(&interfaces) == 0) {
    struct ifaddrs *temp = interfaces;
    while (temp != NULL) {
      if (temp->ifa_name != NULL) {
        NSString *name = [NSString stringWithUTF8String:temp->ifa_name];
        if ([name containsString:@"tap"] || [name containsString:@"tun"] ||
            [name containsString:@"ppp"] || [name containsString:@"utun"] ||
            [name containsString:@"ipsec"]) {
          freeifaddrs(interfaces);
          return @YES;
        }
      }
      temp = temp->ifa_next;
    }
  }
  freeifaddrs(interfaces);
  return @NO;
}

- (void)protectClipboard:(BOOL)protect
                 resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (protect) {
      [[NSNotificationCenter defaultCenter]
          addObserver:self
             selector:@selector(clearClipboard)
                 name:UIApplicationDidEnterBackgroundNotification
               object:nil];
    } else {
      [[NSNotificationCenter defaultCenter]
          removeObserver:self
                    name:UIApplicationDidEnterBackgroundNotification
                  object:nil];
    }
    resolve(nil);
  });
}

- (void)clearClipboard {
  [UIPasteboard generalPasteboard].string = @"";
}

- (void)authenticateWithBiometrics:(NSString *)promptMessage
                           resolve:(RCTPromiseResolveBlock)resolve
                            reject:(RCTPromiseRejectBlock)reject {
  LAContext *context = [[LAContext alloc] init];
  NSError *error = nil;

  if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                           error:&error]) {
    [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
            localizedReason:promptMessage
                      reply:^(BOOL success, NSError *_Nullable evalError) {
                        if (success) {
                          resolve(@YES);
                        } else {
                          resolve(@NO);
                        }
                      }];
  } else {
    // Fallback to passcode or just return false
    resolve(@NO);
  }
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

- (void)updateSSLPins:(NSString *)domain
      publicKeyHashes:(NSArray *)publicKeyHashes
              resolve:(RCTPromiseResolveBlock)resolve
               reject:(RCTPromiseRejectBlock)reject {
  // TrustKit does not support runtime reconfiguration without exception.
  // In a fully dynamic scenario, developers should store pins in JS and pass
  // them to addSSLPinning on app launch. This method serves as a stub
  // to align with the Android API where OkHttp allows factory overrides.
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
      // Create a secure text field to mask content during screen
      // recording/AirPlay
      UITextField *secureField = (UITextField *)[window viewWithTag:9999];
      if (!secureField) {
        secureField = [[UITextField alloc] init];
        secureField.secureTextEntry = YES;
        secureField.userInteractionEnabled = NO;
        secureField.tag = 9999;

        // Ensure it covers the window but stays out of the way of touches
        secureField.frame = window.bounds;
        secureField.autoresizingMask =
            UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        secureField.backgroundColor = [UIColor clearColor];

        [window addSubview:secureField];
        [window sendSubviewToBack:secureField];

        // Critical step: Make the window's main layer a sublayer of the secure
        // field's layer This is the known hack to hide content from screen
        // recording on iOS 13+
        [window.layer.superlayer addSublayer:secureField.layer];
        [[secureField.layer.sublayers firstObject] addSublayer:window.layer];
      }

      // Add Blur Observers for multitasking/background privacy
      [[NSNotificationCenter defaultCenter]
          addObserver:self
             selector:@selector(appWillResignActive)
                 name:UIApplicationWillResignActiveNotification
               object:nil];
      [[NSNotificationCenter defaultCenter]
          addObserver:self
             selector:@selector(appDidBecomeActive)
                 name:UIApplicationDidBecomeActiveNotification
               object:nil];

    } else {
      // Remove Observers
      [[NSNotificationCenter defaultCenter]
          removeObserver:self
                    name:UIApplicationWillResignActiveNotification
                  object:nil];
      [[NSNotificationCenter defaultCenter]
          removeObserver:self
                    name:UIApplicationDidBecomeActiveNotification
                  object:nil];

      // Remove any active blur
      [self appDidBecomeActive];

      // Remove secure field layer manipulation
      UITextField *secureField = (UITextField *)[window viewWithTag:9999];
      if (secureField) {
        // Restore window layer to its original hierarchy
        [secureField.layer.superlayer addSublayer:window.layer];
        [secureField removeFromSuperview];
      }
    }
    resolve(nil);
  });
}

// Background Blur Logic
- (void)appWillResignActive {
  UIWindow *window = [UIApplication sharedApplication].keyWindow;
  if (![window viewWithTag:12345]) {
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
}

- (void)appDidBecomeActive {
  UIWindow *window = [UIApplication sharedApplication].keyWindow;
  UIView *blurView = [window viewWithTag:12345];
  if (blurView) {
    [blurView removeFromSuperview];
  }
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
