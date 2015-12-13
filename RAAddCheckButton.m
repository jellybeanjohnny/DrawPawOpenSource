//
//  RAAddCheckButton.m
//  RidiculousAnimals
//
//  Created by Matt Amerige on 9/24/14.
//  Copyright (c) 2014 Matt Amerige. All rights reserved.
//

#import "RAAddCheckButton.h"
#import <POP/POP.h>

#pragma mark - Functions

// c^2 * 0.5 = a^2
CGFloat calculateOffset(CGFloat c)
{
    CGFloat aSquared = (powf(c, 2) / 2.0);
    
    return sqrtf(aSquared);
    
}

@interface RAAddCheckButton ()
{
    BOOL _showingCheckmark;
    
    CALayer *_verticalLayer, *_horizontalLayer;
    
    CGFloat _lineThickness;
    
    CGFloat _verticalPlusSignLength, _horiztonalPlusSignLength;
  
  UIColor *_checkmarkColor, *_plusSignColor;
}

@property (nonatomic) CGFloat plusSignLineWidth;
@property (nonatomic) CGFloat checkmarkLineWidth;

@end

@implementation RAAddCheckButton

#pragma mark - Properties

- (CGFloat)checkmarkLineWidth
{
  // Derived from IB ratio
  return self.bounds.size.width / 4.11764704f;
}

- (CGFloat)plusSignLineWidth
{
  return self.bounds.size.width / (3.f + (1.f/3.f));
}

#pragma mark - Init & Setup

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (!(self = [super initWithCoder:aDecoder])) {
        return nil;
    }
    
    [self _setup];
    
    return self;
}

- (void)_setup
{
    self.buttonState = plusSign;
    
    CGFloat cornerRadius = 2.f;
    
    CGColorRef color = [[UIColor colorWithRed:0.000 green:0.502 blue:1.000 alpha:1.000] CGColor];
    
    _lineThickness = self.plusSignLineWidth;
    
    _verticalPlusSignLength = CGRectGetHeight(self.bounds);
    _horiztonalPlusSignLength = CGRectGetWidth(self.bounds);
    
    _verticalLayer = [CALayer layer];
    _verticalLayer.frame = CGRectMake(CGRectGetMidX(self.bounds) - (_lineThickness / 2.0), 0, _lineThickness, _verticalPlusSignLength);
    _verticalLayer.cornerRadius = cornerRadius;
    _verticalLayer.backgroundColor = color;
    
    [self.layer addSublayer:_verticalLayer];
    
    _horizontalLayer = [CALayer layer];
    _horizontalLayer.frame = CGRectMake(0, CGRectGetMidY(self.bounds) - (_lineThickness / 2.0), _horiztonalPlusSignLength, _lineThickness);
    _horizontalLayer.cornerRadius = cornerRadius;
    _horizontalLayer.backgroundColor = color;
    
    [self.layer addSublayer:_horizontalLayer];
    
    [self addTarget:self
             action:@selector(_touchUpInsideHandler)
   forControlEvents:UIControlEventTouchUpInside];
  
  [self addTarget:self action:@selector(_touchDownHandler) forControlEvents:UIControlEventTouchDown];
  [self addTarget:self action:@selector(_touchDownDragExitHandler) forControlEvents:UIControlEventTouchDragExit];

    
}

#pragma mark Touch Event Handlers

- (void)_touchUpInsideHandler
{
  [self _scaleButtonToSize:CGPointMake(1, 1) bounce:20 speed:20];
  if (_showingCheckmark) {
    // animate back to plus sign
    [self _animateToPlusSign];
    self.buttonState = plusSign;
  }
  else {
    // Animate to the check mark
    [self _animateToCheckmark];
    self.buttonState = checkmark;
  }
  _showingCheckmark = !_showingCheckmark;
}

- (void)_touchDownHandler
{
  [self _scaleButtonToSize:CGPointMake(0.8, 0.8) bounce:0 speed:20];
}

- (void)_touchDownDragExitHandler
{
  [self _scaleButtonToSize:CGPointMake(1, 1) bounce:20 speed:20];
}

#pragma mark - Scale Animations
- (void)_scaleButtonToSize:(CGPoint)scaledPoint bounce:(CGFloat)bounce speed:(CGFloat)speed
{
  POPSpringAnimation *anim = [self pop_animationForKey:@"CompressButton"];
  if (anim) {
    anim.toValue = [NSValue valueWithCGPoint:scaledPoint];
    anim.springBounciness = bounce;
    anim.springSpeed = speed;
  }
  else {
    POPSpringAnimation *compressAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
    compressAnimation.toValue = [NSValue valueWithCGPoint:scaledPoint];
    compressAnimation.springBounciness = bounce;
    compressAnimation.springSpeed = speed;
    [self.layer pop_addAnimation:compressAnimation forKey:@"CompressButton"];
  }
}


#pragma mark - Checkmark/Plus Sign Animations

- (void)_animateToCheckmark
{
    _lineThickness = self.checkmarkLineWidth;
    [self _setLayerColor:[UIColor colorWithRed:0.000 green:0.502 blue:0.000 alpha:1.000]];
    
    /*********************************
    *     Horizontal Animations     *
    *********************************/
    
    // Length of the line
    CGFloat horizontalCheckmarkLength = _horiztonalPlusSignLength / 3.0;

    // offset
    CGFloat horiztonalOffset = calculateOffset(horizontalCheckmarkLength / 2.0);
    
    [self _animateLayer:_horizontalLayer
          WithRotation:M_PI_4
                  Size:CGSizeMake(horizontalCheckmarkLength, _lineThickness)
              Position:CGPointMake(CGRectGetMidX(self.bounds) - horiztonalOffset,
                                   CGRectGetMidY(self.bounds) - (horiztonalOffset  / 2))];
    
    /*********************************************
     *            Vertical Animations            *
     *********************************************/
    
    
    CGFloat verticalCheckmarkLength = _verticalPlusSignLength / 1;
    
    CGFloat verticalOffset = calculateOffset(verticalCheckmarkLength /  2.0);
    
    
    [self _animateLayer:_verticalLayer
          WithRotation:M_PI_4
                  Size:CGSizeMake(_lineThickness, verticalCheckmarkLength)
              Position:CGPointMake(CGRectGetMidX(self.bounds) + (verticalOffset - (_lineThickness / 2.0)),
                                   CGRectGetMidY(self.bounds) - (verticalOffset - (_lineThickness / 2.0)))];
}

- (void)_animateToPlusSign
{
    _lineThickness = self.plusSignLineWidth;
    [self _setLayerColor:[UIColor colorWithRed:0.000 green:0.502 blue:1.000 alpha:1.000]];
      /*********************************
     *     Horizontal Animations     *
     *********************************/
    
    [self _animateLayer:_horizontalLayer
          WithRotation:0
                  Size:CGSizeMake(CGRectGetWidth(self.bounds), _lineThickness)
              Position:CGPointMake(CGRectGetWidth(self.bounds) / 2.0,
                                   CGRectGetMidY(self.bounds))];
    
    
    /*********************************************
     *            Vertical Animations            *
     *********************************************/

    
    [self _animateLayer:_verticalLayer
          WithRotation:0
                  Size:CGSizeMake(_lineThickness, CGRectGetHeight(self.bounds))
              Position:CGPointMake(CGRectGetMidX(self.bounds),
                                   CGRectGetHeight(self.bounds) / 2)];
}

- (void)_animateLayer:(CALayer *)layer
        WithRotation:(CGFloat)rotation
                Size:(CGSize)size
            Position:(CGPoint)position
{
    // Rotation
    POPSpringAnimation *rotationAnimation = [layer pop_animationForKey:@"rotationAnimation"];
    if (rotationAnimation) {
        // Update the toValue
        rotationAnimation.toValue = @(rotation);
    }
    else {
        rotationAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerRotation];
        rotationAnimation.toValue = @(rotation);
        rotationAnimation.springSpeed = 20;
        [layer pop_addAnimation:rotationAnimation forKey:@"rotationAnimation"];
    }
    
    // Size
    POPSpringAnimation *sizeAnimation = [layer pop_animationForKey:@"sizeAnimation"];
    if (sizeAnimation) {
        // Update toValue
        sizeAnimation.toValue = [NSValue valueWithCGSize:size];
    }
    else {
        sizeAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerSize];
        sizeAnimation.toValue = [NSValue valueWithCGSize:size];
        sizeAnimation.springSpeed = 20;
        [layer pop_addAnimation:sizeAnimation forKey:@"sizeAnimation"];
    }
    
    // Position
    POPSpringAnimation *positionAnimation = [layer pop_animationForKey:@"positionAnimation"];
    if (positionAnimation) {
        // Update toValue
        positionAnimation.toValue = [NSValue valueWithCGPoint:position];
    }
    else {
        positionAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPosition];
        positionAnimation.toValue = [NSValue valueWithCGPoint:position];
        positionAnimation.springSpeed = 20;
        [layer pop_addAnimation:positionAnimation forKey:@"positionAnimation"];
    }
}


- (void)_setLayerColor:(UIColor *)color
{
    _verticalLayer.backgroundColor = color.CGColor;
    _horizontalLayer.backgroundColor = color.CGColor;
}


- (void)_instantlyMoveToCheckmarkState
{
    _lineThickness = self.checkmarkLineWidth;
    [self _setLayerColor:[UIColor colorWithRed:0.000 green:0.502 blue:0.000 alpha:1.000]];
    
    
    
    /*********************************
     *     Horizontal Movement       *
     *********************************/
    
    // Length of the line
    CGFloat horizontalCheckmarkLength = _horiztonalPlusSignLength / 3.0;
    
    // offset
    CGFloat horiztonalOffset = calculateOffset(horizontalCheckmarkLength / 2.0);
    
    [self _instantlyMoveLayer:_horizontalLayer
                 withRotation:M_PI_4
                       toSize:CGSizeMake(horizontalCheckmarkLength, _lineThickness)
                   toPosition:CGPointMake(CGRectGetMidX(self.bounds) - horiztonalOffset,
                                          CGRectGetMidY(self.bounds) - (horiztonalOffset  / 2))];
    
    
    /*********************************
     *     Vertical Movement         *
     *********************************/
    
    CGFloat verticalCheckmarkLength = _verticalPlusSignLength / 1;
    
    CGFloat verticalOffset = calculateOffset(verticalCheckmarkLength /  2.0);
    
    [self _instantlyMoveLayer:_verticalLayer
                 withRotation:M_PI_4
                       toSize:CGSizeMake(_lineThickness, verticalCheckmarkLength)
                   toPosition:CGPointMake(CGRectGetMidX(self.bounds) + (verticalOffset - (_lineThickness / 2.0)),
                                          CGRectGetMidY(self.bounds) - (verticalOffset - (_lineThickness / 2.0)))];
}

- (void)_instantlyMoveLayer:(CALayer *)layer
               withRotation:(CGFloat)rotation
                     toSize:(CGSize)size
                 toPosition:(CGPoint)position
{
    // Size
    CGRect newSizedBounds = layer.bounds;
    newSizedBounds.size = size;
    layer.bounds = newSizedBounds;
    
    // Position
    layer.position = position;
    
    // Rotation
    layer.transform = CATransform3DMakeRotation(rotation, 0, 0, 1);
    
    
}

#pragma mark - Public Methods

- (void)setupButtonForState:(ButtonState)buttonState
{
    [CATransaction setDisableActions:YES];
    if (buttonState == checkmark) {
        // Change to checkmark
        [self _instantlyMoveToCheckmarkState];
        _showingCheckmark = YES;
    }
    else if (buttonState == plusSign) {
        _showingCheckmark = NO;
        // Change to plus sign
    }
    [CATransaction setDisableActions:NO];
}

- (void)animateButtonToState:(ButtonState)buttonState
{
  if (buttonState == checkmark) {
    [self _animateToCheckmark];
    self.buttonState = checkmark;
    _showingCheckmark = YES;
  }
  else if (buttonState == plusSign) {
    [self _animateToPlusSign];
    self.buttonState = plusSign;
    _showingCheckmark = NO;
  }
}

- (void)setColor:(UIColor *)color forButtonState:(ButtonState)buttonState
{
  if (buttonState == checkmark) {
    _checkmarkColor = color;
  }
  else if (buttonState == plusSign) {
    _plusSignColor = color;
  }
}

@end


































