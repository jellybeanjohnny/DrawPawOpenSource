//
//  FriendSelectionViewController.m
//  RidiculousAnimals
//
//  Created by Matt Amerige on 7/14/14.
//  Copyright (c) 2014 Matt Amerige. All rights reserved.
//

#import "RAFriendSelectionTableViewController.h"
#import "RAConstants.h"
#import "RAAnimal.h"
#import "RAAddCheckButton.h"
#import "RAFriendSelectionTableViewCell.h"
#import "RACache.h"
#import "RABouncyButton.h"
#import "UIView+ViewShadow.h"
#import "RAInvitationManager.h"
#import "RAFont.h"
#import "RAColors.h"
#import "RAPOPAnimation.h"

#define kSelectCellIdentifer @"SELECT CELL"

@interface RAFriendSelectionTableViewController () <RAFriendSelectionTableViewCellDelegate>
{
  // Header properties
  @private
  UILabel *_messageLabel;
  NSArray *_selectedFriends;
  RAFriendSelectionTableViewCell *_selectedCell;
  id<RAFriendSelectionDelegate> _delegate;
  
  // Internal
  NSMutableDictionary *_selectedFriendsDictionary;
  
  __weak IBOutlet UIView *_footerView;
  __weak IBOutlet UIButton *_donebutton;
  
  

}
@end

@implementation RAFriendSelectionTableViewController
@synthesize selectedFriends = _selectedFriends;
@synthesize delegate = _delegate;


- (id)initWithCoder:(NSCoder *)aCoder
{
    self = [super initWithCoder:aCoder];
    if (self) {

        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = YES;
        
        // Whether the built-in pagination is enabled
        self.paginationEnabled = YES;
        
        // The number of objects to show per page
        self.objectsPerPage = 25;
      
      self.loadingViewEnabled = NO;
    }
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  
  // Create the dictionary if it doesn't exist yet
  if (!_selectedFriendsDictionary) {
    _selectedFriendsDictionary = [[NSMutableDictionary alloc] init];
  }
  [self _toggleDoneButton];

}

- (void)_toggleDoneButton
{
  // Allow player to press done only if they have selected a friend
  if (_selectedFriendsDictionary.count > 0) {
    if (!_donebutton.enabled) {
      _donebutton.enabled = YES;
      _donebutton.alpha = 1.0f;
      [[[RAPOPAnimation alloc] init] spring_bounceView:_donebutton springSpeed:6 bounciness:20 scaleSize:CGSizeMake(1.1, 1.1)];
      
    }
      }
  else {
    _donebutton.enabled = NO;
    _donebutton.alpha = 0.5f;
  }
}

- (void)setSelectedFriends:(NSArray *)selectedFriends
{
  if (!_selectedFriendsDictionary) {
    _selectedFriendsDictionary = [[NSMutableDictionary alloc] init];
  }
  for (PFUser *friend in selectedFriends) {
    [_selectedFriendsDictionary setObject:friend forKey:friend.objectId];
  }
}


- (void)objectsDidLoad:(NSError *)error
{
  if (!error) {
    if (self.objects.count == 0) {
      // No friends! get rid of the done button
      NSLog(@"no friends!");
      _footerView.hidden = YES;
      [self _addNotFoundMessage];
    }
    else {
      _footerView.hidden = NO;
      [self _removeNotFoundMessage];
    }
  }
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
#pragma mark - PFQueryTableViewController

 // Override to customize what kind of query to perform on the class. The default is to query for
 // all objects ordered by createdAt descending.
 - (PFQuery *)queryForTable
{
  PFQuery *query = [PFUser query];
  NSArray *friendsArray = [[RACache sharedCache] facebookFriends];
  NSLog(@"friends Array: %@", friendsArray);
  
  [query whereKey:kRAFacebookIdKey containedIn:[[RACache sharedCache] facebookFriends]];
  
  // If Pull To Refresh is enabled, query against the network by default.
  if (self.pullToRefreshEnabled) {
      query.cachePolicy = kPFCachePolicyNetworkOnly;
  }
  
  // If no objects are loaded in memory, we look to the cache first to fill the table
  // and then subsequently do a query against the network.
  if (self.objects.count == 0) {
      query.cachePolicy = kPFCachePolicyCacheThenNetwork;
  }
  
  [query orderByDescending:@"createdAt"];
  
  return query;
}

 // Override to customize the look of a cell representing an object. The default is to display
 // a UITableViewCellStyleDefault style cell with the label being the textKey in the object,
 // and the imageView being the imageKey in the object.
 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object
{
  static NSString *CellIdentifier = kSelectCellIdentifer;

  RAFriendSelectionTableViewCell *cell = (RAFriendSelectionTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
      cell = [[RAFriendSelectionTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }
  
  PFUser *friend = (PFUser *)object;

  [self _configureCell:cell forParseUser:friend];
  
  if ([_selectedFriendsDictionary objectForKey:friend.objectId]) {
    // This friend is in the selected dictionary, so we want this cell to show a check mark
    [cell.addButton setupButtonForState:checkmark];
    _selectedCell = cell;
  }
  
  
  return cell;
}

- (void)_configureCell:(RAFriendSelectionTableViewCell *)cell forParseUser:(PFUser *)friend
{
  cell.delegate = self;
  cell.usernameLabel.text = friend[kRAUserFullName];
  cell.user = friend;
  cell.profileImageView.file = friend[kRAUserProfilePicture];
  [cell.profileImageView loadInBackground];
}

#pragma mark - Plus Button

- (void)addButtonPressedForCell:(RAFriendSelectionTableViewCell *)cell
{

  
  if (cell.addButton.buttonState == checkmark) {
    // Going from Plus Sign to check mark -- Adding a friend
    [self _addSelectedUser:cell.user];
    NSLog(@"Adding user");
    
    RAFriendSelectionTableViewCell *previousCell = _selectedCell;
    _selectedCell = cell;
    
    if (previousCell) {
      // Remove the previous cell
      [previousCell.addButton animateButtonToState:plusSign];
      [self _removeSelectedUser:previousCell.user];
    }

  }
  else {
    // Going from Check mark to Plus sign -- Removing a friend
    [self _removeSelectedUser:cell.user];
    _selectedCell = nil;
    NSLog(@"Removing user");
  }
  [self _toggleDoneButton];
}

- (void)_removeSelectedUser:(PFUser *)user
{
  if ([_selectedFriendsDictionary objectForKey:user.objectId]) {
    [_selectedFriendsDictionary removeObjectForKey:user.objectId];
  }
  else {
    NSLog(@"Selected Friends Dictionary does not contain this user");
  }
}

- (void)_addSelectedUser:(PFUser *)user
{
    if (![_selectedFriendsDictionary objectForKey:user.objectId]) {
      [_selectedFriendsDictionary setObject:user forKey:user.objectId];
    }
    else {
        NSLog(@"Selected Friends Array already contains this user");
    }
}

#pragma mark - Done Button
- (IBAction)_doneButtonPressed:(id)sender
{
  // Alert the delegate
  if (_delegate && [_delegate respondsToSelector:@selector(friendsSelected:)]) {
    [_delegate friendsSelected:[_selectedFriendsDictionary allValues]];
  }
  // Pop to root
  [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - Inviting Friends
- (IBAction)_inviteFriends:(id)sender
{
  // Invite Friends
  [[RAInvitationManager sharedManager] inviteFriendsWithPresentingViewController:self];
}

#pragma mark - Add/Remove background message

- (void)_addNotFoundMessage
{
  _messageLabel = [[UILabel alloc] init];
  
  _messageLabel.text = @"None of your friends are using DrawPaw! Try inviting friends up top.";
  
  _messageLabel.textColor = [RAColors sharedColors].primaryAppColor;
  _messageLabel.numberOfLines = 0;
  _messageLabel.textAlignment = NSTextAlignmentCenter;
  _messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
  _messageLabel.font = [RAFont sharedFonts].titleFont;
  [_messageLabel sizeToFit];
  self.tableView.backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
  [self.tableView.backgroundView addSubview:_messageLabel];
  
  
  NSDictionary *views = @{@"label" : _messageLabel};
  
  NSArray *marginConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|-12-[label]-12-|"
                                                                       options:0
                                                                       metrics:nil
                                                                         views:views];
  [self.tableView.backgroundView addConstraints:marginConstraints];
  
  
  NSLayoutConstraint *centerYConstraint = [NSLayoutConstraint constraintWithItem:_messageLabel
                                                                       attribute:NSLayoutAttributeCenterY
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.tableView.backgroundView
                                                                       attribute:NSLayoutAttributeCenterY
                                                                      multiplier:0.8
                                                                        constant:0];
  [self.tableView.backgroundView addConstraint:centerYConstraint];
  
  
  
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

}

- (void)_removeNotFoundMessage
{
  self.tableView.backgroundView = nil;
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}




@end




