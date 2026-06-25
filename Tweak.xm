
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>

FOUNDATION_EXTERN CFTypeRef MGCopyAnswer(CFStringRef property);

static NSString *kVersion = @"17.0";
static NSString *kBuild   = @"21A329";

static CFTypeRef (*orig_MGCopyAnswer)(CFStringRef property);

static CFTypeRef replaced_MGCopyAnswer(CFStringRef property) {
    if (!property) return orig_MGCopyAnswer(property);

    NSString *key = (__bridge NSString *)property;

    if ([key isEqualToString:@"ProductVersion"])
        return CFBridgingRetain(kVersion);

    if ([key isEqualToString:@"ProductBuildVersion"])
        return CFBridgingRetain(kBuild);

    return orig_MGCopyAnswer(property);
}



%hook UIDevice
- (NSString *)systemVersion { return kVersion; }
%end



%hook NSProcessInfo
- (NSOperatingSystemVersion)operatingSystemVersion {
    return (NSOperatingSystemVersion){ 17, 0, 0 };
}
- (NSString *)operatingSystemVersionString {
    return [NSString stringWithFormat:@"Version %@ (Build %@)", kVersion, kBuild];
}
%end



%hook NSDictionary
+ (NSDictionary *)dictionaryWithContentsOfFile:(NSString *)path {
    NSDictionary *orig = %orig;
    if (![path hasSuffix:@"SystemVersion.plist"]) return orig;

    NSMutableDictionary *fake = orig
        ? [orig mutableCopy]
        : [[NSMutableDictionary alloc] init];

    fake[@"ProductVersion"]      = kVersion;
    fake[@"ProductBuildVersion"] = kBuild;
    return fake;
}
%end



%hook NSBundle
- (NSDictionary *)infoDictionary {
    NSDictionary *orig = %orig;
    NSMutableDictionary *d = orig ? [orig mutableCopy] : [[NSMutableDictionary alloc] init];
    if (d[@"MinimumOSVersion"]) d[@"MinimumOSVersion"] = @"1.0";
    return d;
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
        (void *)&MGCopyAnswer,
        (void *)replaced_MGCopyAnswer,
        (void **)&orig_MGCopyAnswer
    );
}
