#import "CDVParsePlugin.h"
#import <Cordova/CDV.h>
#import <Parse/Parse.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <Gimbal/Gimbal.h>

@implementation CDVParsePlugin

- (void)initialize: (CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    NSString *appId = [command.arguments objectAtIndex:0];
    NSString *clientKey = [command.arguments objectAtIndex:1];
    [Parse setApplicationId:appId clientKey:clientKey];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getInstallationId:(CDVInvokedUrlCommand*) command
{
    [self.commandDelegate runInBackground:^{
        CDVPluginResult* pluginResult = nil;
        PFInstallation *currentInstallation = [PFInstallation currentInstallation];
        NSString *installationId = currentInstallation.installationId;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:installationId];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)getInstallationObjectId:(CDVInvokedUrlCommand*) command
{
    [self.commandDelegate runInBackground:^{
        CDVPluginResult* pluginResult = nil;
        PFInstallation *currentInstallation = [PFInstallation currentInstallation];
        NSString *objectId = currentInstallation.objectId;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:objectId];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)getSubscriptions: (CDVInvokedUrlCommand *)command
{
    NSArray *channels = [PFInstallation currentInstallation].channels;
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:channels];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)subscribe: (CDVInvokedUrlCommand *)command
{
    // Not sure if this is necessary
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings *settings =
        [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert |
                                                     UIUserNotificationTypeBadge |
                                                     UIUserNotificationTypeSound
                                          categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
    else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
            UIRemoteNotificationTypeBadge |
            UIRemoteNotificationTypeAlert |
            UIRemoteNotificationTypeSound];
    }

    CDVPluginResult* pluginResult = nil;
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    NSString *channel = [command.arguments objectAtIndex:0];
    [currentInstallation addUniqueObject:channel forKey:@"channels"];
    [currentInstallation saveInBackground];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)unsubscribe: (CDVInvokedUrlCommand *)command
{
    CDVPluginResult* pluginResult = nil;
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    NSString *channel = [command.arguments objectAtIndex:0];
    [currentInstallation removeObject:channel forKey:@"channels"];
    [currentInstallation saveInBackground];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void)getnotifications:(CDVInvokedUrlCommand *)command

{
    NSUserDefaults *usserde=[NSUserDefaults standardUserDefaults];
    NSArray *ar=[usserde valueForKey:@"pushMessage"];
    
    NSError *error;
    NSMutableArray *finalArray=[[NSMutableArray alloc]init];
    for(NSDictionary *dict in ar)
    {
        NSData * jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                            options:NSJSONWritingPrettyPrinted
                                                              error:&error];
        NSString *jsonString= [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
        [finalArray addObject:jsonString];
    }
    
    
   // NSData *json = [NSJSONSerialization dataWithJSONObject:array options:0 error:nil];
    
    //back
 
    
   
   CDVPluginResult* pluginResult = nil;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:finalArray];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


-(void)updateReadmessage:(CDVInvokedUrlCommand *)command
{
    NSUserDefaults *usserde=[NSUserDefaults standardUserDefaults];
    NSArray *ar=[usserde valueForKey:@"pushMessage"];
    
    NSString *readFlag =[command.arguments objectAtIndex:1];
    NSString *rowId=[command.arguments objectAtIndex:0];
    for(NSDictionary *dict in ar)
    {
        NSString *rowValue=[NSString stringWithFormat:@"%@",[dict valueForKey:@"flag"]];
        if( [rowValue isEqualToString:rowId])
        {
          [dict setValue:readFlag forKey:@"flag"];
//            [usserde setObject:dict forKey:@"PushMesasge"];
//            [usserde synchronize];
          
            [usserde removeObjectForKey:@"pushMessage"];
            [usserde setObject:ar forKey:@"pushMessage"];
            [usserde synchronize];
            return;
        }
        
    }
    CDVPluginResult* pluginResult = nil;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
@end

@implementation AppDelegate (CDVParsePlugin)

void MethodSwizzle(Class c, SEL originalSelector) {
    NSString *selectorString = NSStringFromSelector(originalSelector);
    SEL newSelector = NSSelectorFromString([@"swizzled_" stringByAppendingString:selectorString]);
    SEL noopSelector = NSSelectorFromString([@"noop_" stringByAppendingString:selectorString]);
    Method originalMethod, newMethod, noop;
    originalMethod = class_getInstanceMethod(c, originalSelector);
    newMethod = class_getInstanceMethod(c, newSelector);
    noop = class_getInstanceMethod(c, noopSelector);
    if (class_addMethod(c, originalSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod(c, newSelector, method_getImplementation(originalMethod) ?: method_getImplementation(noop), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, newMethod);
    }
}

+ (void)load
{
    MethodSwizzle([self class], @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:));
    MethodSwizzle([self class], @selector(application:didReceiveRemoteNotification:));
}

- (void)noop_application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken
{
}

- (void)swizzled_application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken
{
    // Call existing method
    [self swizzled_application:application didRegisterForRemoteNotificationsWithDeviceToken:newDeviceToken];
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:newDeviceToken];
    [currentInstallation saveInBackground];
}

- (void)noop_application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
}


- (void)swizzled_application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [self swizzled_application:application didReceiveRemoteNotification:userInfo];
    [PFPush handlePush:userInfo];
    NSDictionary *apsInfo = [userInfo objectForKey:@"aps"];
    NSString *pushMessage = [apsInfo objectForKey:@"alert"];
    NSString *navigatepath =[userInfo objectForKey:@"navigate"];
    if(pushMessage && pushMessage.length>0)
    {
        NSUserDefaults *userdefault=[NSUserDefaults standardUserDefaults];
        NSMutableArray *ar=[[NSMutableArray alloc]init];
        if(![userdefault valueForKey:@"pushMessage"])
        {
            NSMutableDictionary *jSONDict=[[NSMutableDictionary alloc]init];
            [jSONDict setObject:[NSNumber numberWithInteger:[ar count]] forKey:@"id"];
            [jSONDict setObject:pushMessage forKey:@"message"];
            [jSONDict setObject:@"0" forKey:@"flag"];
            [jSONDict setObject:navigatepath forKey:@"navigate"];
            [jSONDict setObject:@"false" forKey:@"btnstatus"];
            [ar addObject:jSONDict];
        }
        else
        {
            for(NSDictionary *dict in [userdefault valueForKey:@"pushMessage"])
            {
                [ar addObject:dict];
            }
            NSMutableArray *newarrau=[[NSMutableArray alloc]initWithArray:ar];
            [ar removeAllObjects];
            [ar addObjectsFromArray:newarrau];
            NSMutableDictionary *jSONDict=[[NSMutableDictionary alloc]init];
            [jSONDict setObject:[NSNumber numberWithInteger:[ar count]] forKey:@"id"];
            [jSONDict setObject:pushMessage forKey:@"message"];
            [jSONDict setObject:@"0" forKey:@"flag"];
            [jSONDict setObject:navigatepath forKey:@"navigate"];
            [jSONDict setObject:@"false" forKey:@"btnstatus"];
            [ar addObject:jSONDict];

        }
        [userdefault setValue:ar forKey:@"pushMessage"];
        [userdefault synchronize];
    }
}
-(void)applicationDidBecomeActive:(UIApplication *)application
{
    [[UIApplication sharedApplication]setApplicationIconBadgeNumber:0];
}

@end
