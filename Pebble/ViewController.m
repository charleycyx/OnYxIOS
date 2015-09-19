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
@property (weak, nonatomic) AppDelegate *appDel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
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

#pragma Location update

-(void)locationUpdatedTo:(CLLocation*)newLocation {
    [self.map setRegion:MKCoordinateRegionMakeWithDistance(self.appDel.location.coordinate,1000,1000)];
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
        
        [self.appDel sendLocationInfoFromVC];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id < MKAnnotation >)annotation {
    MKPinAnnotationView *pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"DETAILPIN_ID"];
    [pinView setAnimatesDrop:YES];
    [pinView setCanShowCallout:NO];
    return pinView;
}

@end
