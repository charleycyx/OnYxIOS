//
//  AppDelegate.h
//  Pebble
//
//  Created by Charley Chen on 9/18/15.
//  Copyright © 2015 Charley Chen. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CLLocation;
@class ViewController;
@class PBWatch;
@class MyAnnotation;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) CLLocation *location;
@property (strong, nonatomic) MyAnnotation *annot;
@property (weak, nonatomic) ViewController *vc;
@property (strong, nonatomic) PBWatch *connectedWatch;

-(void) sendLocationInfo;

@end

