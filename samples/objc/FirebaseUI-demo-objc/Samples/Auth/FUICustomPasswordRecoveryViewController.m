//
//  FUICustomPasswordRecoveryViewController.m
//  FirebaseUI-demo-objc
//
//  Created by Yury Ramanchuk on 10/14/16.
//  Copyright © 2016 Firebase, Inc. All rights reserved.
//

#import "FUICustomPasswordRecoveryViewController.h"

@interface FUICustomPasswordRecoveryViewController ()
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *recoverButton;

@end

@implementation FUICustomPasswordRecoveryViewController

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil
                         authUI:(FUIAuth *)authUI
                          email:(NSString *_Nullable)email {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil authUI:authUI email:email];

  if (self) {
    _emailTextField.text = email;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  //override action of default 'Next' button to use custom layout elements
  self.navigationItem.rightBarButtonItem.target = self;
  self.navigationItem.rightBarButtonItem.action = @selector(onRecoverButton:);
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  //update state of all UI elements (e g disable 'Next' buttons)
  [self updateEmailValue:_emailTextField];
}

- (IBAction)onBackButton:(id)sender {
  [self onBack];
}
- (IBAction)onRecoverButton:(id)sender {
  [self recoverEmail:_emailTextField.text];
}
- (IBAction)onCancel:(id)sender {
  [self cancelAuthorization];
}
- (IBAction)updateEmailValue:(UITextField *)sender {
  BOOL enableActionButton = sender.text.length > 0;
  self.recoverButton.enabled = enableActionButton;

  [self didChangeEmail:sender.text];
}

- (IBAction)onViewSelected:(id)sender {
  [_emailTextField resignFirstResponder];
}

#pragma mark - UITextFieldDelegate methods
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [self recoverEmail:textField.text];

  return NO;
}
@end
