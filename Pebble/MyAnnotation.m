//
//  MyAnnotation.m
//  Pebble
//
//  Created by Charley Chen on 9/18/15.
//  Copyright © 2015 Charley Chen. All rights reserved.
//

#import "MyAnnotation.h"

@implementation MyAnnotation

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate{
    self = [super init];
    if (self) {
        
        _coordinate = coordinate;
        
        return self;
    }
    return nil;
}

-(void)setCoordinate:(CLLocationCoordinate2D)newCoordinate {
    _coordinate = newCoordinate;
}

@end
