//
//  AppDelegate.m
//  Pebble
//
//  Created by Charley Chen on 9/18/15.
//  Copyright © 2015 Charley Chen. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "MyAnnotation.h"

#import <PebbleKit/PebbleKit.h>
#import <MapKit/MapKit.h>

@interface AppDelegate () <CLLocationManagerDelegate,PBPebbleCentralDelegate> {
    CLLocationCoordinate2D coor;
}

@property (strong, nonatomic) CLLocationManager *locManager;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    //set up location manager
    _locManager = [[CLLocationManager alloc]init];
    [_locManager requestAlwaysAuthorization];
    _locManager.desiredAccuracy = kCLLocationAccuracyBest;
    _locManager.delegate = self;
    [_locManager startUpdatingLocation];
    
    //set up pebble center
    [[PBPebbleCentral defaultCentral] setDelegate:self];
    
    uuid_t myAppUUIDbytes;
    NSUUID *myAppUUID = [[NSUUID alloc] initWithUUIDString:@"4d943355-7f44-4cf4-92cc-532334a19250"];
    [myAppUUID getUUIDBytes:myAppUUIDbytes];
    
    [[PBPebbleCentral defaultCentral] setAppUUID:[NSData dataWithBytes:myAppUUIDbytes length:16]];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    if (self.vc)
        coor = self.annot.coordinate;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

-(void) sendLocationInfo {
    
    //get the angle
    double dx = self.annot.coordinate.longitude - self.location.coordinate.longitude;
    double dy = self.annot.coordinate.latitude - self.location.coordinate.latitude;
    int angle = (int)atan2(dx, dy)/3.14*180;
    if (angle<0) {
        angle = 360+angle;
    }
    int distance = (int)[self.location distanceFromLocation:[[CLLocation alloc] initWithLatitude:self.annot.coordinate.latitude longitude:self.annot.coordinate.longitude]];
    
    //send
    [self.connectedWatch appMessagesPushUpdate:@{@0:[NSNumber numberWithInt:angle], @1:[NSNumber numberWithInt:distance]} onSent:^(PBWatch *watch, NSDictionary *update, NSError *error) {
        if (!error) {
            NSLog(@"Successfully sent message.");
        }
        else {
            NSLog(@"Error sending message: %@", error);
        }
    }];
    
}

#pragma CLLocationManager

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    //update location and set the map region centered there
    _location = locations.lastObject;
    if (self.vc) {
        [self.vc locationUpdatedTo:manager.location];
    }
    [self sendLocationInfo];
    if ([self.location distanceFromLocation:[[CLLocation alloc]initWithLatitude:self.annot.coordinate.latitude longitude:self.annot.coordinate.longitude]] < 20) {
        [self.vc toNextWaypoint];
    }
}

-(void)locationManger:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"didFailWithError: %@", error);
}

#pragma pebble stuff

- (void)pebbleCentral:(PBPebbleCentral*)central watchDidConnect:(PBWatch*)watch isNew:(BOOL)isNew {
    NSLog(@"Pebble connected: %@", [watch name]);
    self.connectedWatch = watch;
    [self.connectedWatch appMessagesLaunch:^(PBWatch *watch, NSError *error) {
        if (!error) {
            NSLog(@"Successfully launched app.");
        }
        else {
            NSLog(@"Error launching app - Error: %@", error);
        }
    }];
    [self.connectedWatch appMessagesGetIsSupported:^(PBWatch *watch, BOOL isAppMessagesSupported) {
        if (isAppMessagesSupported) {
            NSLog(@"This Pebble supports app message!");
        }
        else {
            NSLog(@":( - This Pebble does not support app message!");
        }
    }];
    [self.connectedWatch appMessagesAddReceiveUpdateHandler:^BOOL(PBWatch *watch, NSDictionary *update) {
        
        if (self.vc && update) {
            if (update[@11]) {
                //switch forward
                [self.vc toNextWaypoint];
            } else if (update[@12]) {
                [self.vc toPreviousWaypoint];
            }
        }
        
        return YES;
    }];
}

- (void)pebbleCentral:(PBPebbleCentral*)central watchDidDisconnect:(PBWatch*)watch {
    NSLog(@"Pebble disconnected: %@", [watch name]);
    
    if (self.connectedWatch == watch || [watch isEqual:self.connectedWatch]) {
        self.connectedWatch = nil;
    }
}

@end
