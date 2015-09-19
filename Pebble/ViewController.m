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

@interface ViewController () <MKMapViewDelegate,CLLocationManagerDelegate,PBPebbleCentralDelegate> {
    bool centered;
}

@property (strong, nonatomic) IBOutlet MKMapView *map;
@property (strong, nonatomic) IBOutlet UIButton *hotelButton;
@property (strong, nonatomic) IBOutlet UIButton *cornellButton;


@property (weak, nonatomic) AppDelegate *appDel;
//this is supposed to be a array of hotel annotations
@property (strong, nonatomic) NSMutableArray *hotelArray;
@property (strong, nonatomic) NSMutableArray *cornellArray;

@property (strong, nonatomic) MyAnnotation *pinAnnot;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //get app delegate
    _appDel = [UIApplication sharedApplication].delegate;
    _appDel.vc = self;
    
    //set up storages for annotations
    _hotelArray = [[NSMutableArray alloc]init];
    _cornellArray = [[NSMutableArray alloc]init];
    
    //configure map view
    self.map.delegate = self;
    UILongPressGestureRecognizer *tapRecg = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(mapTapped:)];
    tapRecg.minimumPressDuration = 0.8;
    [self.map addGestureRecognizer:tapRecg];
    [self.map setRegion:MKCoordinateRegionMakeWithDistance(self.appDel.location.coordinate,1000,1000)];
    self.map.showsUserLocation = YES;
    
//    self.selfAnnot = [[MyAnnotation alloc]initWithCoordinate: self.appDel.location.coordinate];
//    [self.map addAnnotation:self.selfAnnot];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)finalize {
    [super finalize];
    self.appDel.vc = nil;
}

#pragma mark Location update

-(void)locationUpdatedTo:(CLLocation*)newLocation {
    if (!centered) {
        [self.map setRegion:MKCoordinateRegionMakeWithDistance(self.appDel.location.coordinate,1000,1000)];
        centered = true;
    }
//    self.selfAnnot.coordinate = newLocation.coordinate;
}

#pragma mark map stuff

-(void)mapTapped:(UITapGestureRecognizer*)recog {
    if(recog.state == UIGestureRecognizerStateRecognized)
    {
        CGPoint point = [recog locationInView:recog.view];
        
        //make or update annotation
        if (self.pinAnnot)
            [self.map removeAnnotation:self.pinAnnot];
        self.pinAnnot =  [[MyAnnotation alloc] initWithCoordinate:[self.map convertPoint:point toCoordinateFromView:self.map]];
        [self.map addAnnotation:self.pinAnnot];

        
        //put this onto the appDel annotation
        self.appDel.annot = self.pinAnnot;
        [self.appDel sendLocationInfo];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id < MKAnnotation >)annotation {
    
    //if the anotation represent user him/herself use blue dot
    if (annotation==self.map.userLocation) {
        MKAnnotationView *annotView = [[MKAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:@"SELFPIN"];
        annotView.image = [UIImage imageNamed:@"youarehere"];
        return annotView;
    }
    
    MKPinAnnotationView *pinView = (MKPinAnnotationView*)[self.map dequeueReusableAnnotationViewWithIdentifier:@"DETAILPIN_ID"];
    if (!pinView) pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"DETAILPIN_ID"];
    if ([self.hotelArray containsObject:annotation]) {
        pinView.pinColor = MKPinAnnotationColorGreen;
    }
    if ([self.cornellArray containsObject:annotation]) {
        pinView.pinColor = MKPinAnnotationColorRed;
    }
    if (annotation == self.pinAnnot) {
        pinView.pinColor = MKPinAnnotationColorPurple;
    }
    
    [pinView setAnimatesDrop:YES];
    [pinView setCanShowCallout:YES];
    return pinView;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    self.appDel.annot = view.annotation;
    [self.appDel sendLocationInfo];
}

#pragma mark Button Clicks

- (IBAction)hotelButtonClicked:(id)sender {
    /////////////////////////////////
    //request and get data into a dictionary
    ////////////////////////////////
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://onyxbackend.mybluemix.net/priceline/%f,%f",self.appDel.location.coordinate.latitude,self.appDel.location.coordinate.longitude]]
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:10.0];
    [request setHTTPMethod:@"GET"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                    if (error) {
                                                        NSLog(@"%@", error);
                                                    } else {
                                                        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                                                        NSLog(@"%@", httpResponse);
                                                        NSError *error;
                                                        NSArray *hotelJsonArray = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
                                                        NSLog(@"%@",hotelJsonArray);
                                                        [self fillArray:self.hotelArray WithJsonArray:hotelJsonArray];
                                                        [self dropPin:self.hotelArray];
                                                    }
                                                }];
    [dataTask resume];
}
- (IBAction)cornellButtonClicked:(id)sender {
    
    /////////////////////////////////
    //request and get data into a dictionary
    ////////////////////////////////
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://onyxbackend.mybluemix.net/cornell"]
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:10.0];
    [request setHTTPMethod:@"GET"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                    if (error) {
                                                        NSLog(@"%@", error);
                                                    } else {
                                                        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                                                        NSLog(@"%@", httpResponse);
                                                        NSError *error;
                                                        NSArray *hotelJsonArray = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
                                                        NSLog(@"%@",hotelJsonArray);
                                                        [self fillArray:self.cornellArray WithJsonArray:hotelJsonArray];
                                                        [self dropPin:self.cornellArray];
                                                    }
                                                }];
    [dataTask resume];
    
}

//supposedly an array of MyAnnotation that should be dropped
-(void)dropPin:(NSArray*)array{
    [self.map addAnnotations:array];
}

#pragma helpers

-(void)fillArray:(NSMutableArray*)arrayToFill WithJsonArray:(NSArray*)array {
    for (NSDictionary *dic in array) {
        MyAnnotation *an = [[MyAnnotation alloc]initWithCoordinate:CLLocationCoordinate2DMake([(NSNumber*)dic[@"Lat"] doubleValue], [(NSNumber*)dic[@"Lon"] doubleValue])];
        an.title = dic[@"Name"];
        [arrayToFill addObject:an];
    }
}

@end
