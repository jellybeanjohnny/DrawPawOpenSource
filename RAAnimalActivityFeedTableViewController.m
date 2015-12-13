//
//  RACurrentGamesTableViewController.m
//  RidiculousAnimals
//
//  Created by Matt Amerige on 11/29/14.
//  Copyright (c) 2014 Matt Amerige. All rights reserved.
//

#import "RAAnimalActivityFeedTableViewController.h"
#import "RAAnimalFeedTableViewCell.h"
#import "RAConstants.h"
#import "RACanvasViewController.h"
#import "NSDate+RARelativeDate.h"
#import "UIView+ViewShadow.h"
#import "RAAnimalPhotoDetailViewController.h"
#import "RAAnimal.h"
#import "RAColors.h"
#import "RAFont.h"
#import "RAActionSentenceConstructor.h"
#import "RAAnimalCreationTableViewController.h"
#import "RAAnimalDescriptionComposer.h"
#import "RAIcon.h"
#import "RACache.h"
#import "RAAlertManager.h"
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "RAActivity.h"


#define kRACellIdentifierAnimalDescription @"AnimalDescriptionCell"
#define kRACellIdentifierAnimalPhotoCell   @"AnimalPhotoCell"
#define kRACellIdentifierUserPhotoCell     @"CurrentUserPhotoCell"

@interface RAAnimalActivityFeedTableViewController () <UIGestureRecognizerDelegate, RATableViewCellDelegate>
{
  UILabel *_messageLabel;
  
  NSMutableDictionary *_cellHeightCache;
  
  NSInteger _userSelectedIndex;
  NSMutableDictionary *_otherUserProfileIconDictionary;
  NSMutableDictionary *_randomSentenceDictionary;
  ChallengeDataType _dataType;
}

@end

@implementation RAAnimalActivityFeedTableViewController
@synthesize  dataType = _dataType;
- (id)initWithStyle:(UITableViewStyle)style
{
  self = [super initWithStyle:style];
  if (self) {
    
    
    // Whether the built-in pull-to-refresh is enabled
    self.pullToRefreshEnabled = YES;
    
    // Whether the built-in pagination is enabled
    self.paginationEnabled = NO;
    
    // The number of objects to show per page
    self.objectsPerPage = 30;
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self _setupAppearance];
  [self _registerForNotifications];
  _cellHeightCache = [[NSMutableDictionary alloc] init];
  _otherUserProfileIconDictionary = [[NSMutableDictionary alloc] init];
  _randomSentenceDictionary = [[NSMutableDictionary alloc] init];
  
  _userSelectedIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"UserIconIndex"];
  
  self.tableView.rowHeight = UITableViewAutomaticDimension;  
}

- (void)_registerForNotifications
{

  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(_loginDidDismiss)
                                               name:@"ShouldLoadObjects"
                                             object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(_refreshTableView)
                                               name:kRANotificationCenterRefreshAnimalFeed
                                             object:nil];
}

- (void)_loginDidDismiss
{
  [self _refreshTableView];
}

- (void)_setupAppearance
{
  // Refresh Control Appearance
  self.refreshControl.tintColor = [RAColors sharedColors].primaryAppColor;
}


#pragma mark - PFQueryTableViewController

- (void)objectsWillLoad
{
  [super objectsWillLoad];
  
  // This method is called before a PFQuery is fired to get more objects
}

- (void)objectsDidLoad:(NSError *)error
{
  [super objectsDidLoad:error];
  
  // This method is called every time objects are loaded from Parse via the PFQuery
  if (self.objects.count == 0) {
    [self _addNotFoundMessage];
  }
  else if (self.tableView.backgroundView) {
    [self _removeNotFoundMessage];
  }
  // Reload tableViewData
  [self.tableView reloadData];
}

#pragma mark - Queries

- (PFQuery *)queryForTable
{
  if (![PFUser currentUser]) {
    return nil;
  }
  
  NSLog(@"running query...");

  PFQuery *query;
  if (_dataType == FromFriends) {
    query = [self _fromFriendsQuery];
  }
  else if (_dataType == AllChallenges) {
    query = [self _allChallengesQuery];
  }
  
  if (!query) {
    [self _addNotFoundMessage];
    [self clear];
  }
  
   // If Pull To Refresh is enabled, query against the network by default.
   if (self.pullToRefreshEnabled) {
     query.cachePolicy = kPFCachePolicyNetworkOnly;
   }
   
   // If no objects are loaded in memory, we look to the cache first to fill the table
   // and then subsequently do a query against the network.
   if (self.objects.count == 0) {
     query.cachePolicy = kPFCachePolicyCacheThenNetwork;
   }
   
   [query orderByDescending:@"updatedAt"];
   
   return query;
}


- (PFQuery *)_fromFriendsQuery
{
  // Friends query
  PFQuery *friendsQuery = [PFUser query];
  NSArray *facebookFriends = [[RACache sharedCache] facebookFriends];
  
  if (!facebookFriends) {
    return nil;
  }
  
  [friendsQuery whereKey:kRAFacebookIdKey containedIn:facebookFriends];

  PFQuery *meQuery = [PFUser query];
  [meQuery whereKey:kRAObjectIdKey equalTo:[PFUser currentUser].objectId];
  
  PFQuery *userQuery = [PFQuery orQueryWithSubqueries:@[friendsQuery]];

  
  // Constrain the query by exluding animals that you are following
  PFQuery *followingQuery = [RAActivity query];
  [followingQuery whereKey:kRAActivityFromUserKey equalTo:[PFUser currentUser]];
  [followingQuery whereKey:kRAActivityTypeKey equalTo:kRAActivityTypeFollow];
  
  // Drawing challenges
  PFQuery *challengesQuery = [RAAnimal query];
  [challengesQuery whereKey:kRAAnimalIdKey doesNotMatchKey:kRAAnimalIdKey inQuery:followingQuery];
  [challengesQuery whereKey:kRAtargetUser equalTo:[PFUser currentUser]];
  [challengesQuery whereKeyDoesNotExist:kRAAnimalDrawingFileKey];
  [challengesQuery whereKeyExists:kRAanimalDescription];
  [challengesQuery whereKey:kRAAnimalCreatedBy matchesQuery:userQuery];
  [challengesQuery includeKey:kRAAnimalCreatedBy];
  [challengesQuery includeKey:kRAparentAnimal];
  [challengesQuery includeKey:kRAtargetUser];

  return challengesQuery;
}

- (PFQuery *)_allChallengesQuery
{
  // Constrain the query by exluding animals that you are following
  PFQuery *followingQuery = [RAActivity query];
  [followingQuery whereKey:kRAActivityFromUserKey equalTo:[PFUser currentUser]];
  [followingQuery whereKey:kRAActivityTypeKey equalTo:kRAActivityTypeFollow];
  
  // All animal challenges
  PFQuery *preChallengeQuery= [RAAnimal query];
  [preChallengeQuery whereKey:kRAAnimalIdKey doesNotMatchKey:kRAAnimalIdKey inQuery:followingQuery];
  [preChallengeQuery whereKeyDoesNotExist:kRAAnimalDrawingFileKey];
  [preChallengeQuery whereKeyExists:kRAanimalDescription];
  [preChallengeQuery whereKeyDoesNotExist:kRAtargetUser];
  [preChallengeQuery whereKey:kRAAnimalCreatedBy notEqualTo:[PFUser currentUser]];

  PFQuery *challengeQueryOne = [self _appendCurrentUserConstraintToQuery:preChallengeQuery];
  PFQuery *challengeQueryTwo = [self _appendNilConstraintToQuery:preChallengeQuery];
  
  PFQuery *challengesQuery = [PFQuery orQueryWithSubqueries:@[challengeQueryOne, challengeQueryTwo]];
  
  // All drawings
  PFQuery *drawingsQuery = [RAAnimal query];
  [drawingsQuery whereKey:kRAAnimalIdKey doesNotMatchKey:kRAAnimalIdKey inQuery:followingQuery];
  [drawingsQuery whereKeyExists:kRAanimalDescription];
  [drawingsQuery whereKey:kRAIsMostRecentKey equalTo:[NSNumber numberWithBool:YES]];
  [drawingsQuery whereKey:kRAAnimalCreatedBy notEqualTo:[PFUser currentUser]];
  [drawingsQuery whereKeyExists:kRAAnimalDrawingFileKey];
  [drawingsQuery whereKey:kRAAnimalDrawnBy notEqualTo:[PFUser currentUser]];
  
  PFQuery *query = [PFQuery orQueryWithSubqueries:@[challengesQuery,drawingsQuery]];
  [query includeKey:kRAAnimalCreatedBy];
  [query includeKey:kRAparentAnimal];
  
  
  return query;
}

#pragma mark - Query Helpers
- (PFQuery *)_appendCurrentUserConstraintToQuery:(PFQuery *)query
{
  [query whereKey:kRAAnimalCurrentlyDrawing equalTo:[PFUser currentUser]];
  return query;
}

- (PFQuery *)_appendNilConstraintToQuery:(PFQuery *)query
{
  [query whereKeyDoesNotExist:kRAAnimalCurrentlyDrawing];
  return query;
}


#pragma mark -

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  // We have to implement this delegate method because the cell height varies too much for a single number to be accurate.
  // So simply setting the estimateRowHeight property is out. Instead, we allow the tableview to automatically calculate the size of cells, and then
  // cache the heights for reuse later on.
  if ([self _cachedCellHeightAtIndexPath:indexPath] != NSNotFound) {
    return [self _cachedCellHeightAtIndexPath:indexPath];
  }
  else {
    return UITableViewAutomaticDimension;
  }
}

 // Override to customize the look of a cell representing an object. The default is to display
 // a UITableViewCellStyleDefault style cell with the label being the textKey in the object,
 // and the imageView being the imageKey in the object.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object
{
  RAAnimal *animalObject = (RAAnimal *)object;
  NSString *identifier;
  if (animalObject.animalDrawingFile) {
    // This is an animal photo cell
    if ([animalObject.drawnBy.objectId isEqualToString:[PFUser currentUser].objectId]) {
      // This is a drawing that the current user did
      identifier = kRACellIdentifierUserPhotoCell;
    }
    else {
      identifier = kRACellIdentifierAnimalPhotoCell;
    }
  }
  else {
    // This is a challenge
    identifier = kRACellIdentifierAnimalDescription;
  }
  
  RAAnimalFeedTableViewCell *cell = (RAAnimalFeedTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
  
  if (cell == nil) {
    cell = [[RAAnimalFeedTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
  }
  if (!cell.delegate) {
    cell.delegate = self;
  }
   
  // Configure the cell
  if (cell) {
    [self _configureCell:cell forRowAtIndexPath:indexPath animalObject:animalObject];
  }
    return cell;
}

- (void)_configureCell:(RAAnimalFeedTableViewCell *)cell
     forRowAtIndexPath:(NSIndexPath *)indexPath
          animalObject:(RAAnimal *)animalObject
{
  // Object
  if (!animalObject) {
    return;
  }
  
  cell.animalObject = animalObject;
  cell.animalDate = animalObject.updatedAt;
  cell.dateLabel.text = [animalObject.updatedAt relativeDateString];
  cell.profilePictureImageView.layer.cornerRadius = 5;
  cell.profilePictureImageView.image = [UIImage imageNamed:@"placeholder-image"];
  
  if ([cell.reuseIdentifier isEqualToString:kRACellIdentifierAnimalDescription]) {
    cell.actionSentenceLabel.attributedText = [self _randomActionSentenceForCell:cell];
    if (_dataType == FromFriends) {
      cell.profilePictureImageView.file = animalObject.createdBy[kRAUserProfilePicture];
      [cell.profilePictureImageView loadInBackground];
  
    }
    else {
      if ([animalObject.createdBy.objectId isEqualToString:[PFUser currentUser].objectId]) {
        // This is an animal challenge the current user created, so the profile picture will be their selected image
        // If the user has signed in with Facebook, show their profile picture
        if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
          cell.profilePictureImageView.file = [PFUser currentUser][kRAUserProfilePicture];
          [cell.profilePictureImageView loadInBackground];
        }
        else {
          // Not linked to Facebook, show the selected image instead
          cell.profilePictureImageView.image = [RAIcon defaultIcons].icons[_userSelectedIndex];
        }
      }
      else {
        // Other people
        cell.profilePictureImageView.image = [self _randomIconForObject:animalObject];
      }
    }
  }
  
  
  // Load the profile picture and animal drawings
  if ([cell.reuseIdentifier isEqualToString:kRACellIdentifierAnimalPhotoCell] ||
      [cell.reuseIdentifier isEqualToString:kRACellIdentifierUserPhotoCell]) {
    // Photo Cell
    [self _setAndLoadFile:animalObject.animalDrawingFile toImageView:cell.childAnimalImageView];
    if ([animalObject.drawnBy.objectId isEqualToString:[PFUser currentUser].objectId]) {
      // This is an animal challenge the current user created, so the profile picture will be their selected image
      if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        cell.profilePictureImageView.file = [PFUser currentUser][kRAUserProfilePicture];
        [cell.profilePictureImageView loadInBackground];
      }
      else {
        // Not linked to Facebook, show the selected image instead
        cell.profilePictureImageView.image = [RAIcon defaultIcons].icons[_userSelectedIndex];
      }
    }
    else {
      cell.profilePictureImageView.image = [self _randomIconForObject:animalObject];
      cell.actionSentenceLabel.attributedText = [self _randomActionSentenceForCell:cell];
    }
  }
}

- (UIImage *)_randomIconForObject:(PFObject *)object
{
  UIImage *randomIcon;
  if (![_otherUserProfileIconDictionary objectForKey:object.objectId]) {
    randomIcon = [[RAIcon defaultIcons] randomIconExcludingIndex:_userSelectedIndex];
    [_otherUserProfileIconDictionary setObject:randomIcon forKey:object.objectId];
  }
  else {
    randomIcon = [_otherUserProfileIconDictionary objectForKey:object.objectId];
  }
  return randomIcon;
}

- (NSAttributedString *)_randomActionSentenceForCell:(RAAnimalFeedTableViewCell *)cell
{
  NSAttributedString *randomSentence;
  RAAnimal *animalObject = cell.animalObject;
  
  // This dictionary key is a combination of the animal's object id and its cell identifier. This way the correct
  // sentence type can be accessed later on. If the cell type changes, a new sentence will be generated for that
  // cell type. Otherwise we will return the stored sentence in the dictionary
  NSString *dictionaryKey = [animalObject.objectId stringByAppendingString:cell.reuseIdentifier];
  
  if (![_randomSentenceDictionary objectForKey:dictionaryKey]) {
    if ([cell.reuseIdentifier isEqualToString:kRACellIdentifierAnimalDescription]) {
      randomSentence = [[RAActionSentenceConstructor sharedConstructor] constructActionSentenceForAnimalFeedCell:cell];
    }
    else {
      randomSentence = [[RAActionSentenceConstructor sharedConstructor] randomDrawingSentence];
    }
    [_randomSentenceDictionary setObject:randomSentence forKey:dictionaryKey];
  }
  else {
    randomSentence = [_randomSentenceDictionary objectForKey:dictionaryKey];
  }
  return randomSentence;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
  [self _cacheCellHeight:cell.bounds.size.height forIndexPath:indexPath];
}

- (void)_setAndLoadFile:(PFFile *)file toImageView:(PFImageView *)imageView
{
  imageView.image = [UIImage imageNamed:@"placeholder-image"];
  imageView.file = file;
  [imageView loadInBackground];
}


- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
  // Have the cell's cardview remain white
  if (indexPath.row == self.objects.count) {
    // This is the last row that shows a "load more" button. We don't need to configure anything here
    return;
  }
  RAAnimalFeedTableViewCell *cell = (RAAnimalFeedTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
  cell.cardView.backgroundColor = [UIColor whiteColor];
}

#pragma mark - Presenting Modal Views
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [super tableView:tableView didSelectRowAtIndexPath:indexPath];
  
  if (indexPath.row == self.objects.count) {
    // This is the last row that shows a "load more" button. We don't need to configure anything here
    return;
  }
  RAAnimalFeedTableViewCell *cell = (RAAnimalFeedTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
  cell.cardView.backgroundColor = [UIColor whiteColor];
  
  if ([cell.reuseIdentifier isEqualToString:kRACellIdentifierAnimalDescription]) {
    if ([cell.animalObject.createdBy.objectId isEqualToString:[PFUser currentUser].objectId]) {
      // This is a challenge you created
      [self _showAlert];
    }
  }
  else if ([cell.reuseIdentifier isEqualToString:kRACellIdentifierAnimalPhotoCell] &&
           ![cell.animalObject.drawnBy.objectId isEqualToString:[PFUser currentUser].objectId]) {
    RAAnimalDescriptionComposer *descriptionComposer = [self.storyboard instantiateViewControllerWithIdentifier:@"DescriptionComposer"];
    descriptionComposer.selectedImage = cell.childAnimalImageView.image;
    descriptionComposer.parentAnimal = cell.animalObject;
    [self presentViewController:[[UINavigationController alloc]
     initWithRootViewController:descriptionComposer]
                       animated:YES completion:nil];

  }
}

- (void)_showAlert
{
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"This is an animal you created!"
                                                                           message:@"You can't draw your own animal"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *okayAction = [UIAlertAction actionWithTitle:@"Okay"
                                                       style:UIAlertActionStyleDefault
                                                     handler:nil];
  [alertController addAction:okayAction];
  
  [self presentViewController:alertController animated:YES completion:nil];
}


#pragma mark - Add/Remove background message

- (void)_addNotFoundMessage
{
  _messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width,
                                                            self.view.bounds.size.height)];
  if (_dataType == FromFriends) {
    _messageLabel.text = @"No new challenges from friends.";
  }
  else {
    _messageLabel.text = @"No new challenges available.";
  }
  
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
//  self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  RAAnimalFeedTableViewCell *animalCell = (RAAnimalFeedTableViewCell *)sender;
  
  if ([segue.identifier isEqualToString:@"PresentCanvas"] ||
      [segue.identifier isEqualToString:@"PresentCanvasFromSecond"]) {
    UINavigationController *navController = (UINavigationController *)segue.destinationViewController;
    RACanvasViewController *canvasVC = (RACanvasViewController *)navController.topViewController;
    canvasVC.animalObject = animalCell.animalObject;
  }  
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
  
  
  if ([sender isKindOfClass:[RAAnimalFeedTableViewCell class]]) {
    RAAnimalFeedTableViewCell *animalCell = (RAAnimalFeedTableViewCell *)sender;
    
    if ([animalCell.reuseIdentifier isEqualToString:kRACellIdentifierAnimalPhotoCell] &&
        animalCell.animalObject.inDrawingSession) {
      
      [[RAAlertManager sharedManager] showAlertWithTitle:@"Someone is already drawing this animal!"
                                                 message:nil];
      
      
      [self loadObjects];
      
      return NO;
    }
    
    if ([animalCell.animalObject.createdBy.objectId isEqualToString:[PFUser currentUser].objectId] &&
        [animalCell.reuseIdentifier isEqualToString:kRACellIdentifierAnimalDescription]) {
      return NO;
    }
    if ([animalCell.animalObject.drawnBy.objectId isEqualToString:[PFUser currentUser].objectId]) {
      return NO;
    }
  }
  return YES;
}

- (IBAction)_galleryButtonPushed:(id)sender
{
  [[NSNotificationCenter defaultCenter] postNotificationName:kRANotificationCenterScrollToGallery object:nil];
}

#pragma mark - Caching Cell Height
- (void)_cacheCellHeight:(CGFloat)cellHeight forIndexPath:(NSIndexPath *)indexPath
{
  if ([_cellHeightCache objectForKey:@(indexPath.row)]) {
    return;
  }
  [_cellHeightCache setObject:[NSNumber numberWithFloat:cellHeight] forKey:@(indexPath.row)];
}

- (CGFloat)_cachedCellHeightAtIndexPath:(NSIndexPath *)indexPath
{
  if ([_cellHeightCache objectForKey:@(indexPath.row)]) {
    return [[_cellHeightCache objectForKey:@(indexPath.row)] floatValue];
  }
  return NSNotFound;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForNextPageAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"LoadMoreCell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }
  
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  
  return cell;
}

#pragma mark - Refresh

- (void)_refreshTableView
{
  // Empty Cache
  [_cellHeightCache removeAllObjects];
  
  // Reload objects
  [self loadObjects];
}

#pragma mark - TableViewCell Delegate
- (void)describeButtonPushedForAnimal:(RAAnimal *)animalObject animalImage:(UIImage *)image
{
  RAAnimalDescriptionComposer *descriptionComposer = [self.storyboard instantiateViewControllerWithIdentifier:@"DescriptionComposer"];
  descriptionComposer.selectedImage = image;
  descriptionComposer.parentAnimal = animalObject;
  [self presentViewController:[[UINavigationController alloc] initWithRootViewController:descriptionComposer] animated:YES completion:nil];
}


#pragma mark - Changing Data Sets
- (void)setDataType:(ChallengeDataType)dataType
{
  _dataType = dataType;
  if (_dataType == AllChallenges) {
    
  }
  else if (_dataType == FromFriends) {
    
  }
  NSLog(@"Changing data type...");
  [self loadObjects];
  

}




@end

























