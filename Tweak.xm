#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

FOUNDATION_EXTERN CFTypeRef MGCopyAnswer(CFStringRef property);

static NSString *kVersion = @"17.0";
static NSString *kBuild = @"21A329";

%hook UIDevice

- (NSString *)systemVersion {
    return kVersion;
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
    return [NSString stringWithFormat:@"Version %@ (Build %@)", kVersion, kBuild];
}

%end


%hook NSDictionary

+ (NSDictionary *)dictionaryWithContentsOfFile:(NSString *)path {

    NSDictionary *orig = %orig;

    if (![path hasSuffix:@"SystemVersion.plist"]) {
        return orig;
    }

    NSMutableDictionary *fake =
        orig ? [orig mutableCopy] : [NSMutableDictionary new];

    fake[@"ProductVersion"] = kVersion;
    fake[@"ProductBuildVersion"] = kBuild;

    return fake;
}

%end


%hook NSBundle

- (NSDictionary *)infoDictionary {

    NSMutableDictionary *dict = [[%orig ?: @{}] mutableCopy];

    if (dict[@"MinimumOSVersion"]) {
        dict[@"MinimumOSVersion"] = @"1.0";
    }

    return dict;
}

%end


%hook MIBundle

- (BOOL)_isMinimumOSVersion:(id)arg1
       applicableToOSVersion:(id)arg2
                  requiredOS:(id *)arg3
                       error:(id *)arg4 {

    return YES;
}

%end


%ctor {

    %init;

    MSHookFunction(
        (void *)MGCopyAnswer,
        (void *)^(CFStringRef property) {

            if (property) {

                NSString *key = (__bridge NSString *)property;

                if ([key isEqualToString:@"ProductVersion"]) {
                    return (CFTypeRef)CFBridgingRetain(kVersion);
                }

                if ([key isEqualToString:@"ProductBuildVersion"]) {
                    return (CFTypeRef)CFBridgingRetain(kBuild);
                }
            }

            return MGCopyAnswer(property);

        },
        NULL
    );
}
