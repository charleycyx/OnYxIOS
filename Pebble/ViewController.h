//
//  ViewController.h
//  Pebble
//
//  Created by Charley Chen on 9/18/15.
//  Copyright © 2015 Charley Chen. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CLLocation;
@class MyAnnotation;

@interface ViewController : UIViewController

-(void)locationUpdatedTo:(CLLocation*)newLocation;

-(void)toNextWaypoint;

-(void)toPreviousWaypoint;

@end

