//
//  ViewController.m
//  Pebble
//
//  Created by Charley Chen on 9/18/15.
//  Copyright © 2015 Charley Chen. All rights reserved.
//

#import "ViewController.h"

#import <PebbleKit/PebbleKit.h>
#import <MapKit/MapKit.h>
#import "MyAnnotation.h"
#import "AppDelegate.h"

@interface ViewController () <MKMapViewDelegate,CLLocationManagerDelegate,PBPebbleCentralDelegate>

@property (strong, nonatomic) IBOutlet MKMapView *map;
@property (strong, nonatomic) MyAnnotation *annot;
@property (strong, nonatomic) PBWatch *connectedWatch;
@property (weak, nonatomic) AppDelegate *appDel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //set up pebble center
    [[PBPebbleCentral defaultCentral] setDelegate:self];
    
    uuid_t myAppUUIDbytes;
    NSUUID *myAppUUID = [[NSUUID alloc] initWithUUIDString:@"4d943355-7f44-4cf4-92cc-532334a19250"];
    [myAppUUID getUUIDBytes:myAppUUIDbytes];
    
    [[PBPebbleCentral defaultCentral] setAppUUID:[NSData dataWithBytes:myAppUUIDbytes length:16]];
    
    //get app delegate
    _appDel = [UIApplication sharedApplication].delegate;
    _appDel.vc = self;
    
    //configure map view
    self.map.delegate = self;
    UITapGestureRecognizer *tapRecg = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(mapTapped:)];
    [self.map addGestureRecognizer:tapRecg];
    [self.map setRegion:MKCoordinateRegionMakeWithDistance(self.appDel.location.coordinate,1000,1000)];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)finalize {
    [super finalize];
    self.appDel.vc = nil;
}

-(void) sendLocationInfo {
    //get the angle
    double dx = self.annot.coordinate.longitude - self.appDel.location.coordinate.longitude;
    double dy = self.annot.coordinate.latitude - self.appDel.location.coordinate.latitude;
    int angle = (int)atan2(dx, dy)/3.14*180;
    if (angle<0) {
        angle = 360+angle;
    }
    int distance = (int)[self.appDel.location distanceFromLocation:[[CLLocation alloc] initWithLatitude:self.annot.coordinate.latitude longitude:self.annot.coordinate.longitude]];
    
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

#pragma Location update

-(void)locationUpdatedTo:(CLLocation*)newLocation {
    [self.map setRegion:MKCoordinateRegionMakeWithDistance(self.appDel.location.coordinate,1000,1000)];
    [self sendLocationInfo];
}

#pragma map stuff

-(void)mapTapped:(UITapGestureRecognizer*)recog {
    if(recog.state == UIGestureRecognizerStateRecognized)
    {
        CGPoint point = [recog locationInView:recog.view];
        
        //make or update annotation
        if (!self.annot) {
            _annot =  [[MyAnnotation alloc] initWithCoordinate:[self.map convertPoint:point toCoordinateFromView:self.map]];
            [self.map addAnnotation:self.annot];
        } else {
            self.annot.coordinate = [self.map convertPoint:point toCoordinateFromView:self.map];
        }
        
        [self sendLocationInfo];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id < MKAnnotation >)annotation {
    MKPinAnnotationView *pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"DETAILPIN_ID"];
    [pinView setAnimatesDrop:YES];
    [pinView setCanShowCallout:NO];
    return pinView;
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
}

- (void)pebbleCentral:(PBPebbleCentral*)central watchDidDisconnect:(PBWatch*)watch {
    NSLog(@"Pebble disconnected: %@", [watch name]);
    
    if (self.connectedWatch == watch || [watch isEqual:self.connectedWatch]) {
        self.connectedWatch = nil;
    }
}

@end
