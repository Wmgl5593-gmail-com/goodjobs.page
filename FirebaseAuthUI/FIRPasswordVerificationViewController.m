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

#import "FIRPasswordVerificationViewController.h"

#import <FirebaseAuth/FirebaseAuth.h>
#import "FIRAuthUIStrings.h"
#import "FIRAuthUITableHeaderView.h"
#import "FIRAuthUITableViewCell.h"
#import "FIRAuthUIUtils.h"
#import "FIRAuthUI_Internal.h"
#import "FIRPasswordRecoveryViewController.h"

/** @var kCellReuseIdentifier
    @brief The reuse identifier for table view cell.
 */
static NSString *const kCellReuseIdentifier = @"cellReuseIdentifier";

@interface FIRPasswordVerificationViewController () <UITableViewDataSource, UITextFieldDelegate>
@end

@implementation FIRPasswordVerificationViewController {
  /** @var _email
      @brief The @c The email address of the user collected previously.
   */
  NSString *_email;

  /** @var _newCredential
      @brief The new @c FIRAuthCredential that the user had never used before.
   */
  FIRAuthCredential *_newCredential;

  /** @var _passwordField
      @brief The @c UITextField that user enters password into.
   */
  UITextField *_passwordField;

  __unsafe_unretained IBOutlet UITableView *_tableView;
}

- (instancetype)initWithAuthUI:(FIRAuthUI *)authUI
                         email:(NSString *_Nullable)email
                 newCredential:(FIRAuthCredential *)newCredential {
  return [self initWithNibName:NSStringFromClass([self class])
                        bundle:[FIRAuthUIUtils frameworkBundle]
                        authUI:authUI
                         email:email
                 newCredential:newCredential];
}

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil
                         authUI:(FIRAuthUI *)authUI
                          email:(NSString *_Nullable)email
                  newCredential:(FIRAuthCredential *)newCredential {
  self = [super initWithNibName:nibNameOrNil
                         bundle:nibBundleOrNil
                         authUI:authUI];
  if (self) {
    _email = [email copy];
    _newCredential = newCredential;
    self.title = [FIRAuthUIStrings signInTitle];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  UIBarButtonItem *nextButtonItem =
      [[UIBarButtonItem alloc] initWithTitle:[FIRAuthUIStrings next]
                                       style:UIBarButtonItemStylePlain
                                      target:self
                                      action:@selector(next)];
  self.navigationItem.rightBarButtonItem = nextButtonItem;

  // The initial frame doesn't matter as long as it's not CGRectZero, otherwise a default empty
  // header is added by UITableView.
  FIRAuthUITableHeaderView *tableHeaderView =
      [[FIRAuthUITableHeaderView alloc] initWithFrame:_tableView.bounds];
  _tableView.tableHeaderView = tableHeaderView;
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];

  FIRAuthUITableHeaderView *tableHeaderView =
      (FIRAuthUITableHeaderView *)_tableView.tableHeaderView;
  tableHeaderView.titleLabel.text = [FIRAuthUIStrings existingAccountTitle];
  tableHeaderView.detailLabel.text =
      [NSString stringWithFormat:[FIRAuthUIStrings passwordVerificationMessage], _email];

  CGSize previousSize = tableHeaderView.frame.size;
  [tableHeaderView sizeToFit];
  if (!CGSizeEqualToSize(tableHeaderView.frame.size, previousSize)) {
    // Update the height of table header view by setting the view again.
    _tableView.tableHeaderView = tableHeaderView;
  }
}

#pragma mark - Actions

- (void)next {
  [self verifyPassword:_passwordField.text];
}

- (void)verifyPassword:(NSString *)password {
  if (![[self class] isValidEmail:_email]) {
    [self showAlertWithMessage:[FIRAuthUIStrings invalidEmailError]];
    return;
  }
  if (password.length <= 0) {
    [self showAlertWithMessage:[FIRAuthUIStrings invalidPasswordError]];
    return;
  }

  [self incrementActivity];

  [self.auth signInWithEmail:_email
                    password:password
                  completion:^(FIRUser *_Nullable user, NSError *_Nullable error) {
                    if (error) {
                      [self decrementActivity];

                      [self showAlertWithMessage:[FIRAuthUIStrings wrongPasswordError]];
                      return;
                    }

                    [user linkWithCredential:_newCredential completion:^(FIRUser * _Nullable user,
                                                                         NSError * _Nullable error) {
                      [self decrementActivity];

                      // Ignore any error (shouldn't happen) and treat the user as successfully signed in.
                      [self.navigationController dismissViewControllerAnimated:YES completion:^{
                        [self.authUI invokeResultCallbackWithUser:user error:nil];
                      }];
                    }];
                  }];
}

- (IBAction)forgotPassword {
  UIViewController *viewController;
  if ([self.authUI.delegate respondsToSelector:@selector(passwordRecoveryViewControllerForAuthUI:email:)]) {
    viewController = [self.authUI.delegate passwordRecoveryViewControllerForAuthUI:self.authUI
                                                                             email:_email];
  } else {
    viewController = [[FIRPasswordRecoveryViewController alloc] initWithAuthUI:self.authUI
                                                                         email:_email];
  }
  [self pushViewController:viewController];
}

- (void)textFieldDidChange {
  [self didChangePassword:_passwordField.text];
}

- (void)didChangePassword:(NSString *)password {
  BOOL enableActionButton = (password.length > 0);
  self.navigationItem.rightBarButtonItem.enabled = enableActionButton;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  FIRAuthUITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellReuseIdentifier];
  if (!cell) {
    UINib *cellNib = [UINib nibWithNibName:NSStringFromClass([FIRAuthUITableViewCell class])
                                    bundle:[FIRAuthUIUtils frameworkBundle]];
    [tableView registerNib:cellNib forCellReuseIdentifier:kCellReuseIdentifier];
    cell = [tableView dequeueReusableCellWithIdentifier:kCellReuseIdentifier];
  }
  cell.textField.delegate = self;
  cell.label.text = [FIRAuthUIStrings password];
  _passwordField = cell.textField;
  _passwordField.placeholder = [FIRAuthUIStrings enterYourPassword];
  _passwordField.secureTextEntry = YES;
  _passwordField.returnKeyType = UIReturnKeyNext;
  _passwordField.keyboardType = UIKeyboardTypeDefault;
  [cell.textField addTarget:self
                     action:@selector(textFieldDidChange)
           forControlEvents:UIControlEventEditingChanged];
  [self didChangePassword:_passwordField.text];
  return cell;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  if (textField == _passwordField) {
    [self next];
  }
  return NO;
}

@end
