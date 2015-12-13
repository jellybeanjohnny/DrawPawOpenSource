//
//  RACurrentGamesTableViewController.h
//  RidiculousAnimals
//
//  Created by Matt Amerige on 11/29/14.
//  Copyright (c) 2014 Matt Amerige. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>

typedef enum ChallengeDataType
{
  AllChallenges,
  FromFriends
  
} ChallengeDataType;

@interface RAAnimalActivityFeedTableViewController : PFQueryTableViewController

@property (nonatomic, assign) ChallengeDataType dataType;

@end
