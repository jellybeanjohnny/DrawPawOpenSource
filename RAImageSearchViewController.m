//
//  RAImageSearchViewController.m
//  RidiculousAnimals
//
//  Created by Matt Amerige on 6/8/14.
//  Copyright (c) 2014 Matt Amerige. All rights reserved.
//

#import "RAImageSearchViewController.h"
#import "RAImageSearchCell.h"
#import "Flickr.h"
#import "FlickrPhoto.h"
#import "RAAnimalDescriptionComposer.h"
#import "RAColors.h"
#import <KVNProgress/KVNProgress.h>

@interface RAImageSearchViewController ()
            <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UIGestureRecognizerDelegate>
{
    
  __weak IBOutlet UITableView *_tableView;
  __weak IBOutlet UISearchBar *_searchBar;
  __weak IBOutlet UIActivityIndicatorView *_spinner;
  
  dispatch_queue_t _photoQueue;
  
  NSMutableArray *_searchResults;
  Flickr *_flickr;
  NSMutableDictionary *_cachedPhotos;
    
  CGRect _originalFrame;
  
  id<RAImageSearchDelegate> _delegate;

}

@property (nonatomic, strong) NSMutableArray *imageURLArray, *imageArray;


@end


@implementation RAImageSearchViewController
@synthesize imageURLArray = _imageURLArray;
@synthesize imageArray = _imageArray;
@synthesize delegate = _delegate;

#pragma mark - Initialization & Setup

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (!(self = [super initWithNibName:@"RAImageSearchViewController" bundle:nil])) {
        return nil;
    

    }
    
    return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  _searchResults = [[NSMutableArray alloc] init];
  _searchBar.delegate = self;
  _flickr = [[Flickr alloc] init];
  _cachedPhotos = [[NSMutableDictionary alloc] init];
  _photoQueue = dispatch_queue_create("Photo Queue", NULL);

}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  if (_searchResults.count == 0) {
   [_searchBar becomeFirstResponder];
  }
}

#pragma mark - SearchBar

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    // Start spinner
    [_spinner startAnimating];

    if (_searchResults.count > 0) {
        [_searchResults removeAllObjects];
        [_tableView reloadData];
    }
  

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    // Async stuff
    // Search for JSON here, result needs an array
    [_flickr searchFlickrForTerm:searchBar.text completed:^(NSError *error, NSArray *results) {
      if (error) {
        NSLog(@"Error loading photos");
        dispatch_async(dispatch_get_main_queue(), ^{
          [KVNProgress showErrorWithStatus:@"Error loading photos"];
        });
      }
      else {
        _searchResults = [NSMutableArray arrayWithArray:results];
      }
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
      if (_searchResults.count == 0) {
        [KVNProgress showErrorWithStatus:@"No animals found :["];
      }
      [_tableView reloadData];
      [_spinner stopAnimating];
    });
  });
  
  [searchBar resignFirstResponder];
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _searchResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RAImageSearchCell *cell = (RAImageSearchCell *)[tableView dequeueReusableCellWithIdentifier:@"Animal Image Cell"];
    
    if (!cell) {
        cell = [[RAImageSearchCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Animal Image Cell"];
    }
  
  cell.cellImage = nil;
    
    NSDictionary *photoDic = _searchResults[indexPath.row];
    FlickrPhoto *photo = [[FlickrPhoto alloc] init];
    photo.farm = [photoDic[@"farm"] intValue];
    photo.server = [photoDic[@"server"] intValue];
    photo.secret = photoDic[@"secret"];
    photo.photoID = [photoDic[@"id"] longLongValue];
    
    if (![_cachedPhotos valueForKey:photo.secret]) {
        // no photo, so load from flickr
      
      dispatch_async(_photoQueue, ^{
        // Do asynchronous stuff
        // get the photo
        NSError *error = nil;
        NSString *searchURL = [Flickr flickrPhotoURLForFlickrPhoto:photo size:@"z"];
        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:searchURL]
                                                  options:0
                                                    error:&error];
        if (error) {
          NSLog(@"Error loading photo: %@", error.description);
        }
        else {
          // Update UI
          dispatch_async(dispatch_get_main_queue(), ^{
            UIImage *image = [UIImage imageWithData:imageData];
            // Make sure the cell for this indexpath is still onscreen before setting the photo
            if ([tableView cellForRowAtIndexPath:indexPath]) {
              cell.cellImage = image;
            }
            // cache the image with its secret
            [_cachedPhotos setValue:image forKey:photo.secret];
          });
        }
      });        
    }
    else {
        // already have the photo, so just set the photo from the cache
        cell.cellImage = [_cachedPhotos valueForKey:photo.secret];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  // Get the selected cell
  RAImageSearchCell *cell = (RAImageSearchCell *)[tableView cellForRowAtIndexPath:indexPath];
  if (_delegate && [_delegate respondsToSelector:@selector(imageSearchPhotoWasSelected:)]) {
    [_delegate imageSearchPhotoWasSelected:cell.cellImage];
  }
}


@end



