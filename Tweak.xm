#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <unistd.h>
#include <string.h>

FOUNDATION_EXTERN CFTypeRef MGCopyAnswer(CFStringRef property);

%group ThirdPartyAppHooks

%hook NSDictionary
+ (NSDictionary *)dictionaryWithContentsOfFile:(NSString *)path {
    NSDictionary *orig = %orig;

    if (path && [path hasSuffix:@"SystemVersion.plist"]) {
        NSMutableDictionary *fake = [orig mutableCopy];

        if (!fake) {
            fake = [NSMutableDictionary dictionary];
        }

        fake[@"ProductVersion"] = @"17.0";
        fake[@"ProductBuildVersion"] = @"21A329";

        return fake;
    }

    return orig;
}
%end


%hook NSProcessInfo

- (NSOperatingSystemVersion)operatingSystemVersion {
    NSOperatingSystemVersion v;

    v.majorVersion = 17;
    v.minorVersion = 0;
    v.patchVersion = 0;

    return v;
}

- (NSString *)operatingSystemVersionString {
    return @"Version 17.0 (Build 21A329)";
}

%end


%hook UIDevice

- (NSString *)systemVersion {
    return @"17.0";
}

%end


%hookf(CFTypeRef, MGCopyAnswer, CFStringRef property) {

    if (property) {

        NSString *key = (__bridge NSString *)property;

        if ([key isEqualToString:@"ProductVersion"]) {
            return CFBridgingRetain(@"17.0");
        }

        if ([key isEqualToString:@"ProductBuildVersion"]) {
            return CFBridgingRetain(@"21A329");
        }
    }

    return %orig(property);
}

%end


%group InstallerHooks

%hook MIBundle

- (BOOL)_isMinimumOSVersion:(id)arg1
       applicableToOSVersion:(id)arg2
                  requiredOS:(id *)arg3
                       error:(id *)arg4 {
    return YES;
}

%end

%end


%ctor {
    @autoreleasepool {

        const char *procName = getprogname();
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];

        if (procName && strcmp(procName, "installd") == 0) {
            %init(InstallerHooks);
        } else if (bundleID && ![bundleID hasPrefix:@"com.apple."]) {
            %init(ThirdPartyAppHooks);
        }
    }
}
