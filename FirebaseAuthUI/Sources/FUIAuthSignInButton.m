//
//  Copyright (c) 2016 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "FirebaseAuthUI/Sources/FUIAuthSignInButton.h"

#import "FirebaseAuthUI/Sources/Public/FirebaseAuthUI/FUIAuthProvider.h"
#import "FirebaseAuthUI/Sources/Public/FirebaseAuthUI/FUIAuthUtils.h"

NS_ASSUME_NONNULL_BEGIN

/** @var kCornerRadius
    @brief Corner radius of the button.
 */
static const int kCornerRadius = 2.0f;

/** @var kDropShadowAlpha
    @brief Opacity of the drop shadow of the button.
 */
static const CGFloat kDropShadowAlpha = 0.24f;

/** @var kDropShadowRadius
    @brief Radius of the drop shadow of the button.
 */
static const CGFloat kDropShadowRadius = 2.0f;

/** @var kDropShadowYOffset
    @brief Vertical offset of the drop shadow of the button.
 */
static const CGFloat kDropShadowYOffset = 2.0f;

/** @var kFontSize
    @brief Button text font size.
 */
static const CGFloat kFontSize = 12.0f;

@implementation FUIAuthSignInButton

- (instancetype)initWithFrame:(CGRect)frame
                        image:(UIImage *)image
                         text:(NSString *)text
              backgroundColor:(UIColor *)backgroundColor
                    textColor:(UIColor *)textColor
              buttonAlignment:(FUIButtonAlignment)buttonAlignment {
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }

  self.backgroundColor = backgroundColor;

  UIFont *titleFont = [UIFont boldSystemFontOfSize:kFontSize];
  UIButtonConfiguration *configuration = [UIButtonConfiguration plainButtonConfiguration];
  configuration.image = image;
  configuration.title = text;
  configuration.baseForegroundColor = textColor;
  configuration.imagePadding = 8.0f;
  configuration.contentInsets = NSDirectionalEdgeInsetsMake(0, 8.0f, 0, 8.0f);
  configuration.titleLineBreakMode = NSLineBreakByWordWrapping;
  configuration.titleTextAttributesTransformer =
      ^NSDictionary<NSAttributedStringKey, id> *(NSDictionary<NSAttributedStringKey, id> *attributes) {
    NSMutableDictionary<NSAttributedStringKey, id> *updated = [attributes mutableCopy];
    updated[NSFontAttributeName] = titleFont;
    return updated;
  };
  self.configuration = configuration;

  self.contentHorizontalAlignment = buttonAlignment == FUIButtonAlignmentCenter
      ? UIControlContentHorizontalAlignmentCenter
      : UIControlContentHorizontalAlignmentLeading;

  self.layer.cornerRadius = kCornerRadius;

  // Add a drop shadow.
  self.layer.masksToBounds = NO;
  self.layer.shadowColor = [UIColor blackColor].CGColor;
  self.layer.shadowOpacity = kDropShadowAlpha;
  self.layer.shadowRadius = kDropShadowRadius;
  self.layer.shadowOffset = CGSizeMake(0, kDropShadowYOffset);

  return self;
}

- (instancetype)initWithFrame:(CGRect)frame providerUI:(id<FUIAuthProvider>)providerUI {
  _providerUI = providerUI;
  return [self initWithFrame:frame
                       image:providerUI.icon
                        text:providerUI.signInLabel
             backgroundColor:providerUI.buttonBackgroundColor
                   textColor:providerUI.buttonTextColor
             buttonAlignment:providerUI.buttonAlignment];
}

@end

NS_ASSUME_NONNULL_END

