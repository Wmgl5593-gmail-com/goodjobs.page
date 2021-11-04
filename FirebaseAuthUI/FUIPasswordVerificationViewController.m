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

#import "FUIPasswordVerificationViewController.h"

#import <FirebaseAuth/FirebaseAuth.h>
#import "FUIAuthStrings.h"
#import "FUIAuthTableHeaderView.h"
#import "FUIAuthTableViewCell.h"
#import "FUIAuthUtils.h"
#import "FUIAuth_Internal.h"
#import "FUIPasswordRecoveryViewController.h"

/** @var kCellReuseIdentifier
    @brief The reuse identifier for table view cell.
 */
static NSString *const kCellReuseIdentifier = @"cellReuseIdentifier";

@interface FUIPasswordVerificationViewController () <UITableViewDataSource, UITextFieldDelegate>
@end

@implementation FUIPasswordVerificationViewController {
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

- (instancetype)initWithAuthUI:(FUIAuth *)authUI
                         email:(NSString *_Nullable)email
                 newCredential:(FIRAuthCredential *)newCredential {
  return [self initWithNibName:NSStringFromClass([self class])
                        bundle:[FUIAuthUtils frameworkBundle]
                        authUI:authUI
                         email:email
                 newCredential:newCredential];
}

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil
                         authUI:(FUIAuth *)authUI
                          email:(NSString *_Nullable)email
                  newCredential:(FIRAuthCredential *)newCredential {
  self = [super initWithNibName:nibNameOrNil
                         bundle:nibBundleOrNil
                         authUI:authUI];
  if (self) {
    _email = [email copy];
    _newCredential = newCredential;
    self.title = [FUIAuthStrings signInTitle];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  UIBarButtonItem *nextButtonItem =
      [[UIBarButtonItem alloc] initWithTitle:[FUIAuthStrings next]
                                       style:UIBarButtonItemStylePlain
                                      target:self
                                      action:@selector(next)];
  self.navigationItem.rightBarButtonItem = nextButtonItem;

  // The initial frame doesn't matter as long as it's not CGRectZero, otherwise a default empty
  // header is added by UITableView.
  FUIAuthTableHeaderView *tableHeaderView =
      [[FUIAuthTableHeaderView alloc] initWithFrame:_tableView.bounds];
  _tableView.tableHeaderView = tableHeaderView;
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];

  FUIAuthTableHeaderView *tableHeaderView =
      (FUIAuthTableHeaderView *)_tableView.tableHeaderView;
  tableHeaderView.titleLabel.text = [FUIAuthStrings existingAccountTitle];
  tableHeaderView.detailLabel.text =
      [NSString stringWithFormat:[FUIAuthStrings passwordVerificationMessage], _email];

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
    [self showAlertWithMessage:[FUIAuthStrings invalidEmailError]];
    return;
  }
  if (password.length <= 0) {
    [self showAlertWithMessage:[FUIAuthStrings invalidPasswordError]];
    return;
  }

  [self incrementActivity];

  [self.auth signInWithEmail:_email
                    password:password
                  completion:^(FIRUser *_Nullable user, NSError *_Nullable error) {
                    if (error) {
                      [self decrementActivity];

                      [self showAlertWithMessage:[FUIAuthStrings wrongPasswordError]];
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
    viewController = [[FUIPasswordRecoveryViewController alloc] initWithAuthUI:self.authUI
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
  FUIAuthTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellReuseIdentifier];
  if (!cell) {
    UINib *cellNib = [UINib nibWithNibName:NSStringFromClass([FUIAuthTableViewCell class])
                                    bundle:[FUIAuthUtils frameworkBundle]];
    [tableView registerNib:cellNib forCellReuseIdentifier:kCellReuseIdentifier];
    cell = [tableView dequeueReusableCellWithIdentifier:kCellReuseIdentifier];
  }
  cell.textField.delegate = self;
  cell.label.text = [FUIAuthStrings password];
  _passwordField = cell.textField;
  _passwordField.placeholder = [FUIAuthStrings enterYourPassword];
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
