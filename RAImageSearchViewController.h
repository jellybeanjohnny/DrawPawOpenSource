//
//  RAImageSearchViewController.h
//  RidiculousAnimals
//
//  Created by Matt Amerige on 6/8/14.
//  Copyright (c) 2014 Matt Amerige. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RAImageSearchDelegate <NSObject>

@optional
- (void)imageSearchPhotoWasSelected:(UIImage *)photo;

@end

@interface RAImageSearchViewController : UIViewController

@property (nonatomic, strong) id<RAImageSearchDelegate> delegate;

@end
