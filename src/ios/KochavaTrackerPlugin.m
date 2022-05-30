//
//  KochavaTracker (Cordova)
//
//  Copyright (c) 2013 - 2021 Kochava, Inc. All rights reserved.
//

#pragma mark - Import

#import "KochavaTrackerPlugin.h"

#pragma mark - Util

// Interface for the kochavaTrackerUtil
@interface KochavaTrackerUtil : NSObject

@end

// Common utility functions used by all of the wrappers.
// Any changes to the methods in here must be propagated to the other wrappers.
@implementation KochavaTrackerUtil

// Log a message to the console.
+ (void)log:(nonnull NSString *)message {
    NSLog(@"Kochava/Tracker: %@", message);
}

// Attempts to read an NSDictionary and returns nil if not one.
+ (nullable NSDictionary *)readNSDictionary:(nullable id)valueId {
    return [[NSDictionary class] performSelector:@selector(kva_fromObject:) withObject:valueId];
}

// Attempts to read an NSArray and returns nil if not one.
+ (nullable NSArray *)readNSArray:(nullable id)valueId {
    return [[NSArray class] performSelector:@selector(kva_fromObject:) withObject:valueId];
}

// Attempts to read an NSNumber and returns nil if not one.
+ (nullable NSNumber *)readNSNumber:(nullable id)valueId {
    return [[NSNumber class] performSelector:@selector(kva_fromObject:) withObject:valueId];
}

// Attempts to read an NSString and returns nil if not one.
+ (nullable NSString *)readNSString:(nullable id)valueId {
    return [NSString kva_fromObject:valueId];
}

// Converts an NSNumber to a double with fallback to a default value.
+ (double)convertNumberToDouble:(nullable NSNumber *)number defaultValue:(double)defaultValue {
    if(number != nil) {
        return [number doubleValue];
    }
    return defaultValue;
}

// Converts an NSNumber to a bool with fallback to a default value.
+ (BOOL)convertNumberToBool:(nullable NSNumber *)number defaultValue:(BOOL)defaultValue {
    if(number != nil) {
        return [number boolValue];
    }
    return defaultValue;
}

// Converts the deeplink result into an NSDictionary.
+ (nonnull NSDictionary *)convertDeeplinkToDictionary:(nonnull KVADeeplink *)deeplink {
    NSObject *object = [deeplink kva_asForContextObjectWithContext:KVAContext.host];
    return [object isKindOfClass:NSDictionary.class] ? (NSDictionary *)object : @{};
}

// Converts the install attribution result into an NSDictionary.
+ (nonnull NSDictionary *)convertInstallAttributionToDictionary:(nonnull KVAAttributionResult *)installAttribution {
    if (KVATracker.shared.startedBool) {
        NSObject *object = [installAttribution kva_asForContextObjectWithContext:KVAContext.host];
        return [object isKindOfClass:NSDictionary.class] ? (NSDictionary *)object : @{};
    } else {
        return @{
                @"retrieved": @(NO),
                @"raw": @{},
                @"attributed": @(NO),
                @"firstInstall": @(NO),
        };
    }
}

// Serialize an NSDictionary into a json serialized NSString.
+ (nullable NSString *)serializeJsonObject:(nullable NSDictionary *)dictionary {
    return [NSString kva_stringFromJSONObject:dictionary prettyPrintBool:NO];
}

// Parse a json serialized NSString into an NSArray.
+ (nullable NSArray *)parseJsonArray:(nullable NSString *)string {
    NSObject *object = string.kva_serializedJSONObject;
    return ([object isKindOfClass:NSArray.class] ? (NSArray *) object : nil);
}

// Parse a json serialized NSString into an NSDictionary.
+ (nullable NSDictionary *)parseJsonObject:(nullable NSString *)string {
    NSObject *object = string.kva_serializedJSONObject;
    return [object isKindOfClass:NSDictionary.class] ? (NSDictionary *) object : nil;
}

// Builds and sends an event given an event info dictionary.
+ (void)buildAndSendEvent:(nullable NSDictionary *)eventInfo {
    if(eventInfo == nil) {
        return;
    }
    NSString *name = [KochavaTrackerUtil readNSString:eventInfo[@"name"]];
    NSDictionary *data = [KochavaTrackerUtil readNSDictionary:eventInfo[@"data"]];
    NSString *iosAppStoreReceiptBase64String = [KochavaTrackerUtil readNSString:eventInfo[@"iosAppStoreReceiptBase64String"]];
    if (name.length > 0) {
        KVAEvent *event = [KVAEvent customEventWithNameString:name];
        if (data != nil) {
            event.infoDictionary = data;
        }
        if (iosAppStoreReceiptBase64String.length > 0) {
            event.appStoreReceiptBase64EncodedString = iosAppStoreReceiptBase64String;
        }
        [event send];
    } else {
        [KochavaTrackerUtil log:@"Warn: sendEventWithEvent invalid input"];
    }
}

@end

#pragma mark - Methods

@implementation KochavaTrackerPlugin

// void executeAdvancedInstruction(string name, string value)
- (void)executeAdvancedInstruction:(nonnull CDVInvokedUrlCommand *)invokedUrlCommand {
    NSString *name = [KochavaTrackerUtil readNSString:invokedUrlCommand.arguments[0]];
    NSString *value = [KochavaTrackerUtil readNSString:invokedUrlCommand.arguments[1]];
    
    [KVATracker.shared executeAdvancedInstructionWithIdentifierString:name valueObject:value];
}

// void setLogLevel(LogLevel logLevel)
- (void)setLogLevel:(nonnull CDVInvokedUrlCommand *)invokedUrlCommand {
    NSString *logLevel = [KochavaTrackerUtil readNSString:invokedUrlCommand.arguments[0]];

    KVALog.shared.level = [KVALogLevel kva_fromObject:logLevel];
}

// void setSleep(bool sleep)
- (void)setSleep:(nonnull CDVInvokedUrlCommand *)invokedUrlCommand {
    BOOL sleep = [KochavaTrackerUtil convertNumberToBool:[KochavaTrackerUtil readNSNumber:invokedUrlCommand.arguments[0]] defaultValue:false];

    KVATracker.shared.sleepBool = sleep;
}

// void setAppLimitAdTracking(bool appLimitAdTracking)
- (void)setAppLimitAdTracking:(nonnull CDVInvokedUrlCommand *)invokedUrlCommand {
    BOOL appLimitAdTracking = [KochavaTrackerUtil convertNumberToBool:[KochavaTrackerUtil readNSNumber:invokedUrlCommand.arguments[0]] defaultValue:false];
    
    [KVATracker.shared setAppLimitAdTrackingBool:appLimitAdTracking];
}

// void registerCustomDeviceIdentifier(string name, string value)
- (void)registerCustomDeviceIdentifier:(nonnull CDVInvokedUrlCommand *)invokedUrlCommand {
    NSString *name = [KochavaTrackerUtil readNSString:invokedUrlCommand.arguments[0]];
    NSString *value = [KochavaTrackerUtil readNSString:invokedUrlCommand.arguments[1]];
    
    if(name.length > 0 && value.length > 0) {
        [KVATracker.shared.customIdentifiers registerWithNameString:name identifierString:value];
    } else {
        [KochavaTrackerUtil log:@"Warn: Invalid Custom Device Identifier"];
    }
}

// void registerIdentityLink(string name, string value)
- (void)registerIdentityLink:(nonnull CDVInvokedUrlCommand *)invokedUrlCommand {
    NSString *name = [KochavaTrackerUtil readNSString:invokedUrlCommand.arguments[0]];
    NSString *value = [KochavaTrackerUtil readNSString:invokedUrlCommand.arguments[1]];

    if(name.length > 0 && value.length > 0) {
        [KVATracker.shared.identityLink registerWithNameString:name identifierString:value];
    } else {
        [KochavaTrackerUtil log:@"Warn: Invalid Identity Link"];
    }
}

// void enableAndroidInstantApps(string instantAppGuid)
- (void)enableAndroidInstantApps:(nonnull CDVInvokedUrlCommand *)invokedUrlCommand {
    [KochavaTrackerUtil log:@"enableAndroidInstantApps API is not available on this platform."];
}

// void enableIosAppClips(string identifier)
- (void)enableIosAppClips:(nonnull CDVInvokedUrlCommand *)invokedUrlCommand {
    NSString *identifier = [KochavaTrackerUtil readNSString:invokedUrlCommand.arguments[0]];
    
    KVAAppGroups.shared.deviceAppGroupIdentifierString = identifier;
}

// void enableIosAtt()
- (void)enableIosAtt:(nonnull CDVInvokedUrlCommand *)invokedUrlCommand {
    KVATracker.shared.appTrackingTransparency.enabledBool = true;
}

// void setIosAttAuthorizationWaitTime(double waitTime)
- (void)setIosAttAuthorizationWaitTime:(nonnull CDVInvokedUrlCommand *)invokedUrlCommand {
    double waitTime = [KochavaTrackerUtil convertNumberToDouble:[KochavaTrackerUtil readNSNumber:invokedUrlCommand.arguments[0]] defaultValue:30.0];
    
    KVATracker.shared.appTrackingTransparency.authorizationStatusWaitTimeInterval = waitTime;
}

// void setIosAttAuthorizationAutoRequest(bool autoRequest)
- (void)setIosAttAuthorizationAutoRequest:(nonnull CDVInvokedUrlCommand *)invokedUrlCommand {
    BOOL autoRequest = [KochavaTrackerUtil convertNumberToBool:[KochavaTrackerUtil readNSNumber:invokedUrlCommand.arguments[0]] defaultValue:true];
    
    KVATracker.shared.appTrackingTransparency.autoRequestTrackingAuthorizationBool = autoRequest;
}

// void registerPrivacyProfile(string name, string[] keys)
- (void)registerPrivacyProfile:(nonnull CDVInvokedUrlCommand *)invokedUrlCommand {
    NSString *name = [KochavaTrackerUtil readNSString:invokedUrlCommand.arguments[0]];
    NSArray *keys = [KochavaTrackerUtil readNSArray:invokedUrlCommand.arguments[1]];
    
    [KVAPrivacyProfile registerWithNameString:name payloadKeyStringArray:keys];
}

// void setPrivacyProfileEnabled(string name, bool enabled)
- (void)setPrivacyProfileEnabled:(nonnull CDVInvokedUrlCommand *)invokedUrlCommand {
    NSString *name = [KochavaTrackerUtil readNSString:invokedUrlCommand.arguments[0]];
    BOOL enabled = [KochavaTrackerUtil convertNumberToBool:[KochavaTrackerUtil readNSNumber:invokedUrlCommand.arguments[1]] defaultValue:true];
    
    [KVATracker.shared.privacy setEnabledBoolForProfileNameString:name enabledBool:enabled];
}

// bool getStarted()
- (void)getStarted:(nonnull CDVInvokedUrlCommand *)invokedUrlCommand {
    NSString *started = KVATracker.shared.startedBool ? @"true" : @"false";
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:started];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:invokedUrlCommand.callbackId];
}

// void start(string androidAppGuid, string iosAppGuid, string partnerName)
- (void)start:(nonnull CDVInvokedUrlCommand *)invokedUrlCommand {
    // arg 0 is androidAppGuid
    NSString *iosAppGuid = [KochavaTrackerUtil readNSString:invokedUrlCommand.arguments[1]];
    NSString *partnerName = [KochavaTrackerUtil readNSString:invokedUrlCommand.arguments[2]];

    // Disable osLog and force the use of NSLog.
    KVALog.shared.osLogEnabledBool = false;

    // Register the AdNetwork module. This may eventually not be required but for now include it prior to starting.
    [KVAAdNetworkProduct.shared register];

    if (iosAppGuid.length > 0) {
        [KVATracker.shared startWithAppGUIDString:iosAppGuid];
    } else if (partnerName.length > 0) {
        [KVATracker.shared startWithPartnerNameString:partnerName];
    } else {
        [KochavaTrackerUtil log:@"No App Guid or Partner Name was registered."];
    }
}

// shutdown(bool deleteData)
- (void)shutdown:(nonnull CDVInvokedUrlCommand *)invokedUrlCommand {
    BOOL deleteData = [KochavaTrackerUtil convertNumberToBool:[KochavaTrackerUtil readNSNumber:invokedUrlCommand.arguments[0]] defaultValue:true];
    
    [KVATrackerProduct.shared shutdownWithDeleteLocalDataBool:deleteData completionClosure:nil];
}

// string getDeviceId()
- (void)getDeviceId:(nonnull CDVInvokedUrlCommand *)invokedUrlCommand {
    NSString *deviceId = @"";
    if(KVATracker.shared.startedBool) {
        deviceId = KVATracker.shared.deviceIdString ?: @"";
    }
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:deviceId];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:invokedUrlCommand.callbackId];
}

// InstallAttribution getInstallAttribution()
- (void)getInstallAttribution:(nonnull CDVInvokedUrlCommand *)invokedUrlCommand {
    NSDictionary *attributionDictionary = [KochavaTrackerUtil convertInstallAttributionToDictionary:KVATracker.shared.attribution.result];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:attributionDictionary];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:invokedUrlCommand.callbackId];
}

//void retrieveInstallAttribution(Callback<InstallAttribution> callback)
- (void)retrieveInstallAttribution:(nonnull CDVInvokedUrlCommand *)invokedUrlCommand {
    [KVATracker.shared.attribution retrieveResultWithCompletionHandler:^(KVAAttributionResult * attribution) {
        NSDictionary *attributionDictionary = [KochavaTrackerUtil convertInstallAttributionToDictionary:attribution];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:attributionDictionary];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:invokedUrlCommand.callbackId];
    }];
}

// void processDeeplink(string path, Callback<Deeplink> callback)
- (void)processDeeplink:(nonnull CDVInvokedUrlCommand *)invokedUrlCommand {
    NSURL *path = [NSURL URLWithString:[KochavaTrackerUtil readNSString:invokedUrlCommand.arguments[0]]];
    
    [KVADeeplink processWithURL:path completionHandler:^(KVADeeplink * _Nonnull deeplink) {
        NSDictionary *deeplinkDictionary = [KochavaTrackerUtil convertDeeplinkToDictionary:deeplink];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:deeplinkDictionary];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:invokedUrlCommand.callbackId];
    }];
}

// void processDeeplinkWithOverrideTimeout(string path, double timeout, Callback<Deeplink> callback)
- (void)processDeeplinkWithOverrideTimeout:(nonnull CDVInvokedUrlCommand *)invokedUrlCommand {
    NSURL *path = [NSURL URLWithString:[KochavaTrackerUtil readNSString:invokedUrlCommand.arguments[0]]];
    double timeout = [KochavaTrackerUtil convertNumberToDouble:[KochavaTrackerUtil readNSNumber:invokedUrlCommand.arguments[1]] defaultValue:10];
    
    [KVADeeplink processWithURL:path timeoutTimeInterval:timeout completionHandler:^(KVADeeplink * _Nonnull deeplink) {
        NSDictionary *deeplinkDictionary = [KochavaTrackerUtil convertDeeplinkToDictionary:deeplink];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:deeplinkDictionary];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:invokedUrlCommand.callbackId];
    }];
}

// void registerPushToken(string token)
- (void)registerPushToken:(nonnull CDVInvokedUrlCommand *)invokedUrlCommand {
    NSString *token = [KochavaTrackerUtil readNSString:invokedUrlCommand.arguments[0]];
    [KVAPushNotificationsToken registerWithDataHexString:token];
}

// void setPushEnabled(bool enabled)
- (void)setPushEnabled:(nonnull CDVInvokedUrlCommand *)invokedUrlCommand {
    BOOL enabled = [KochavaTrackerUtil convertNumberToBool:[KochavaTrackerUtil readNSNumber:invokedUrlCommand.arguments[0]] defaultValue:false];
    KVATracker.shared.pushNotifications.enabledBool = enabled;
}

// void sendEvent(string name)
- (void)sendEvent:(nonnull CDVInvokedUrlCommand *)invokedUrlCommand {
    NSString *name = [KochavaTrackerUtil readNSString:invokedUrlCommand.arguments[0]];
    
    if(name.length > 0) {
        [KVAEvent sendCustomWithNameString:name];
    } else {
        [KochavaTrackerUtil log:@"Warn: sendEvent invalid input"];
    }
}

// void sendEventWithString(string name, string data)
- (void)sendEventWithString:(nonnull CDVInvokedUrlCommand *)invokedUrlCommand {
    NSString *name = [KochavaTrackerUtil readNSString:invokedUrlCommand.arguments[0]];
    NSString *data = [KochavaTrackerUtil readNSString:invokedUrlCommand.arguments[1]];
    
    if(name.length > 0) {
        [KVAEvent sendCustomWithNameString:name infoString:data];
    } else {
        [KochavaTrackerUtil log:@"Warn: sendEventWithString invalid input"];
    }
}

// void sendEventWithDictionary(string name, object data)
- (void)sendEventWithDictionary:(nonnull CDVInvokedUrlCommand *)invokedUrlCommand {
    NSString *name = [KochavaTrackerUtil readNSString:invokedUrlCommand.arguments[0]];
    NSDictionary *data = [KochavaTrackerUtil readNSDictionary:invokedUrlCommand.arguments[1]];
    
    if(name.length > 0) {
        [KVAEvent sendCustomWithNameString:name infoDictionary:data];
    } else {
        [KochavaTrackerUtil log:@"Warn: sendEventWithDictionary invalid input"];
    }
}

// void sendEventWithEvent(Event event)
- (void)sendEventWithEvent:(nonnull CDVInvokedUrlCommand *)invokedUrlCommand {
    NSDictionary *eventInfo = [KochavaTrackerUtil readNSDictionary:invokedUrlCommand.arguments[0]];
    
    [KochavaTrackerUtil buildAndSendEvent:eventInfo];
}

@end
