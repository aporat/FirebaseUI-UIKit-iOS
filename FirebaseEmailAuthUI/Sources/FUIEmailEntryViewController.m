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

#import "FirebaseEmailAuthUI/Sources/Public/FirebaseEmailAuthUI/FUIEmailEntryViewController.h"

@import FirebaseAuth;

#import <FirebaseAuthUI/FirebaseAuthUI.h>

#import "FirebaseEmailAuthUI/Sources/Public/FirebaseEmailAuthUI/FUIEmailAuth.h"
#import "FirebaseEmailAuthUI/Sources/FUIEmailAuth_Internal.h"
#import "FirebaseEmailAuthUI/Sources/FUIEmailAuthStrings.h"
#import "FirebaseEmailAuthUI/Sources/Public/FirebaseEmailAuthUI/FUIPasswordSignInViewController.h"
#import "FirebaseEmailAuthUI/Sources/Public/FirebaseEmailAuthUI/FUIPasswordSignUpViewController.h"

/** @var kCellReuseIdentifier
    @brief The reuse identifier for table view cell.
 */
static NSString *const kCellReuseIdentifier = @"cellReuseIdentifier";

/** @var kAppIDCodingKey
    @brief The key used to encode the app ID for NSCoding.
 */
static NSString *const kAppIDCodingKey = @"appID";

/** @var kAuthUICodingKey
    @brief The key used to encode @c FUIAuth instance for NSCoding.
 */
static NSString *const kAuthUICodingKey = @"authUI";

/** @var kEmailCellAccessibilityID
    @brief The Accessibility Identifier for the @c email sign in cell.
 */
static NSString *const kEmailCellAccessibilityID = @"EmailCellAccessibilityID";

/** @var kNextButtonAccessibilityID
    @brief The Accessibility Identifier for the @c next button.
 */
static NSString *const kNextButtonAccessibilityID = @"NextButtonAccessibilityID";

@interface FUIEmailEntryViewController () <UITableViewDataSource, UITextFieldDelegate>
@end

@implementation FUIEmailEntryViewController {
  /** @var _emailField
      @brief The @c UITextField that user enters email address into.
   */
  UITextField *_emailField;
  
  /** @var _tableView
      @brief The @c UITableView used to store all UI elements.
   */
  __weak IBOutlet UITableView *_tableView;

  /** @var _termsOfServiceView
   @brief The @c Text view which displays Terms of Service.
   */
  __weak IBOutlet FUIPrivacyAndTermsOfServiceView *_termsOfServiceView;

}

- (instancetype)initWithAuthUI:(FUIAuth *)authUI {
  return [self initWithNibName:NSStringFromClass([self class])
                        bundle:[FUIEmailAuth bundle]
                        authUI:authUI];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil
                         bundle:(NSBundle *)nibBundleOrNil
                         authUI:(FUIAuth *)authUI {

  self = [super initWithNibName:nibNameOrNil
                         bundle:nibBundleOrNil
                         authUI:authUI];
  if (self) {
    self.title = FUILocalizedString(kStr_EnterYourEmail);
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  UIBarButtonItem *nextButtonItem =
      [FUIAuthBaseViewController barItemWithTitle:FUILocalizedString(kStr_Next)
                                           target:self
                                           action:@selector(next)];
  nextButtonItem.accessibilityIdentifier = kNextButtonAccessibilityID;
  self.navigationItem.rightBarButtonItem = nextButtonItem;
  _termsOfServiceView.authUI = self.authUI;
  [_termsOfServiceView useFullMessage];

  [self enableDynamicCellHeightForTableView:_tableView];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  if (self.navigationController.viewControllers.firstObject == self) {
    if (!self.authUI.shouldHideCancelButton) {
      UIBarButtonItem *cancelBarButton =
          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                        target:self
                                                        action:@selector(cancelAuthorization)];
      self.navigationItem.leftBarButtonItem = cancelBarButton;
    }
    self.navigationItem.backBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:FUILocalizedString(kStr_Back)
                                         style:UIBarButtonItemStylePlain
                                        target:nil
                                        action:nil];

    if (!self.authUI.isInteractiveDismissEnabled) {
      self.modalInPresentation = YES;
    }
  }
}

#pragma mark - Actions

- (void)next {
  [self onNext:_emailField.text];
}

- (void)onNext:(NSString *)emailText {
  FUIEmailAuth *emailAuth = [self.authUI providerWithID:@"password"];
  id<FUIAuthDelegate> delegate = self.authUI.delegate;

  if (![[self class] isValidEmail:emailText]) {
    [self showAlertWithMessage:FUILocalizedString(kStr_InvalidEmailError)];
    return;
  }

  // Email enumeration protection means the backend no longer reveals whether an account exists
  // or which provider it uses, so route on configuration alone. An existing account that lands on
  // the sign-up screen is redirected to sign-in when the backend reports the email as in use.
  if ([emailAuth.signInMethod isEqualToString:@"emailLink"]) {
    [self sendSignInLinkToEmail:emailText];
    return;
  }

  UIViewController *controller;
  if (emailAuth.allowNewEmailAccounts) {
    if ([delegate respondsToSelector:@selector(passwordSignUpViewControllerForAuthUI:email:requireDisplayName:)]) {
      controller = [delegate passwordSignUpViewControllerForAuthUI:self.authUI
                                                             email:emailText
                                                requireDisplayName:emailAuth.requireDisplayName];
    } else {
      controller = [[FUIPasswordSignUpViewController alloc] initWithAuthUI:self.authUI
                                                                     email:emailText
                                                        requireDisplayName:emailAuth.requireDisplayName];
    }
  } else {
    if ([delegate respondsToSelector:@selector(passwordSignInViewControllerForAuthUI:email:)]) {
      controller = [delegate passwordSignInViewControllerForAuthUI:self.authUI
                                                             email:emailText];
    } else {
      controller = [[FUIPasswordSignInViewController alloc] initWithAuthUI:self.authUI
                                                                     email:emailText];
    }
  }
  [self pushViewController:controller];
}

- (void)sendSignInLinkToEmail:(NSString*)email {
  if (![[self class] isValidEmail:email]) {
    [self showAlertWithMessage:FUILocalizedString(kStr_InvalidEmailError)];
    return;
  }

  [self incrementActivity];
  FUIEmailAuth *emailAuth = [self.authUI providerWithID:@"password"];
  [emailAuth generateURLParametersAndLocalCache:email linkingProvider:nil];
  [self.auth sendSignInLinkToEmail:email
                actionCodeSettings:emailAuth.actionCodeSettings
                        completion:^(NSError * _Nullable error) {
    [self decrementActivity];

    if (error) {
      [FUIAuthBaseViewController showAlertWithTitle:FUILocalizedString(kStr_Error)
                                            message:error.description
                           presentingViewController:self];
    } else {
      NSString *successMessage =
          [NSString stringWithFormat: FUILocalizedString(kStr_EmailSentConfirmationMessage), email];
      [FUIAuthBaseViewController showAlertWithTitle:FUILocalizedString(kStr_SignInEmailSent)
                                            message:successMessage
                                        actionTitle:FUILocalizedString(kStr_TroubleGettingEmailTitle)
                                      actionHandler:^{
                                        [FUIAuthBaseViewController
                                           showAlertWithTitle:FUILocalizedString(kStr_TroubleGettingEmailTitle)
                                                      message:FUILocalizedString(kStr_TroubleGettingEmailMessage)
                                                  actionTitle:FUILocalizedString(kStr_Resend)
                                                actionHandler:^{
                                                  [self sendSignInLinkToEmail:email];
                                                } dismissTitle:FUILocalizedString(kStr_Back)
                                               dismissHandler:^{
                                                 [self.navigationController popToRootViewControllerAnimated:YES];
                                               }
                                     presentingViewController:self];
                                      }
                                       dismissTitle:FUILocalizedString(kStr_Back)
                                     dismissHandler:^{
                                       [self.navigationController dismissViewControllerAnimated:YES
                                                                                     completion:nil];
                                     }
                           presentingViewController:self];
    }
  }];
}

- (void)textFieldDidChange {
  [self didChangeEmail:_emailField.text];
}

- (void)didChangeEmail:(NSString *)emailText {
  self.navigationItem.rightBarButtonItem.enabled = (emailText.length > 0);
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  FUIAuthTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellReuseIdentifier];
  if (!cell) {
    UINib *cellNib = [UINib nibWithNibName:NSStringFromClass([FUIAuthTableViewCell class])
                                    bundle:[FUIAuthUtils authUIBundle]];
    [tableView registerNib:cellNib forCellReuseIdentifier:kCellReuseIdentifier];
    cell = [tableView dequeueReusableCellWithIdentifier:kCellReuseIdentifier];
  }
  cell.label.text = FUILocalizedString(kStr_Email);
  cell.textField.placeholder = FUILocalizedString(kStr_EnterYourEmail);
  cell.textField.delegate = self;
  cell.accessibilityIdentifier = kEmailCellAccessibilityID;
  _emailField = cell.textField;
  cell.textField.secureTextEntry = NO;
  cell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
  cell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
  cell.textField.returnKeyType = UIReturnKeyNext;
  cell.textField.keyboardType = UIKeyboardTypeEmailAddress;
  cell.textField.textContentType = UITextContentTypeUsername;
  [cell.textField addTarget:self
                     action:@selector(textFieldDidChange)
           forControlEvents:UIControlEventEditingChanged];
  [self didChangeEmail:_emailField.text];
  return cell;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  if (textField == _emailField) {
    [self onNext:_emailField.text];
  }
  return NO;
}

@end
