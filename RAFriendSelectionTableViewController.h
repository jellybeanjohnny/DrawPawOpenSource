//
//  FriendSelectionViewController.h
//  RidiculousAnimals
//
//  Created by Matt Amerige on 7/14/14.
//  Copyright (c) 2014 Matt Amerige. All rights reserved.
//

#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>

@protocol RAFriendSelectionDelegate <NSObject>

@optional
/**
 @abstract Calls the delegate with an array of selected friends (PFUser objects)
 */
- (void)friendsSelected:(NSArray *)selectedFriends;

@end

@interface RAFriendSelectionTableViewController : PFQueryTableViewController

/**
 @abstract Array of PFUser objects that are the player's selected friends to send an animal challenge to
 */
@property (nonatomic, strong) NSArray *selectedFriends;


@property (nonatomic, strong) id<RAFriendSelectionDelegate> delegate;

@end
