//
//  RAAddCheckButton.h
//  RidiculousAnimals
//
//  Created by Matt Amerige on 9/24/14.
//  Copyright (c) 2014 Matt Amerige. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum ButtonState
{
    checkmark,
    plusSign
    
} ButtonState;

@interface RAAddCheckButton : UIControl

/**
 @abstract The state of the button.
 @discussion Either checkmark or plusSign
 */
@property (nonatomic) ButtonState buttonState;

/**
 @abstract Sets the button to the specified state without animation
 */
- (void)setupButtonForState:(ButtonState)buttonState;

/**
 @abstract Sets the color of the button for the specified state
 */
- (void)setColor:(UIColor *)color forButtonState:(ButtonState)buttonState;

/**
 @abstract Sets the button to the specified state with animations
 */
- (void)animateButtonToState:(ButtonState)buttonState;
@end
