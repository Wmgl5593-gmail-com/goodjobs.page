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

#import "FIRTwitterAuthUI.h"
#import <FirebaseAuth/FIRTwitterAuthProvider.h>
#import <FirebaseAuthUI/FIRAuthUIErrorUtils.h>
#import <TwitterKit/TwitterKit.h>

/** @var kTableName
 @brief The name of the strings table to search for localized strings.
 */
static NSString *const kTableName = @"FirebaseTwitterAuthUI";

/** @var kSignInWithTwitter
 @brief The string key for localized button text.
 */
static NSString *const kSignInWithTwitter = @"SignInWithTwitter";

@interface FIRTwitterAuthUI()
- (Twitter *)getTwitterManager;
@end


@implementation FIRTwitterAuthUI

/** @fn frameworkBundle
 @brief Returns the auth provider's resource bundle.
 @return Resource bundle for the auth provider.
 */
+ (NSBundle *)frameworkBundle {
  static NSBundle *frameworkBundle = nil;
  static dispatch_once_t predicate;
  dispatch_once(&predicate, ^{
    frameworkBundle = [NSBundle bundleForClass:[self class]];
  });
  return frameworkBundle;
}

/** @fn imageNamed:
 @brief Returns an image from the resource bundle given a resource name.
 @param name The name of the image file.
 @return The image object for the named file.
 */
+ (UIImage *)imageNamed:(NSString *)name {
  NSString *path = [[[self class] frameworkBundle] pathForResource:name ofType:@"png"];
  return [UIImage imageWithContentsOfFile:path];
}

/** @fn localizedStringForKey:
 @brief Returns the localized text associated with a given string key. Will default to english
 text if the string is not available for the current localization.
 @param key A string key which identifies localized text in the .strings files.
 @return Localized value of the string identified by the key.
 */
+ (NSString *)localizedStringForKey:(NSString *)key {
  NSBundle *frameworkBundle = [[self class] frameworkBundle];
  return [frameworkBundle localizedStringForKey:key value:nil table:kTableName];
}

#pragma mark - FIRAuthProviderUI

- (NSString *)providerID {
  return FIRTwitterAuthProviderID;
}

/** @fn accessToken:
 @brief Twitter Auth token is matched by FirebaseUI User Access Token
 */
- (NSString *)accessToken {
  return [self getTwitterManager].sessionStore.session.authToken;
}

/** @fn idToken:
 @brief Twitter Auth Token Secret is matched by FirebaseUI User Id Token
 */
- (NSString *)idToken {
  return [self getTwitterManager].sessionStore.session.authTokenSecret;
}

- (NSString *)shortName {
  return @"Twitter";
}

- (NSString *)signInLabel {
  return [[self class] localizedStringForKey:kSignInWithTwitter];
}

- (UIImage *)icon {
  return [[self class] imageNamed:@"ic_twitter"];
}

- (UIColor *)buttonBackgroundColor {
  return [UIColor colorWithRed:71.0f/255.0f green:154.0f/255.0f blue:234.0f/255.0f alpha:1.0f];
}

- (UIColor *)buttonTextColor {
  return [UIColor whiteColor];
}

- (void)signInWithEmail:(nullable NSString *)email
presentingViewController:(nullable UIViewController *)presentingViewController
            completion:(nullable FIRAuthProviderSignInCompletionBlock)completion {

  [[self getTwitterManager] logInWithViewController:presentingViewController
                                         completion:^(TWTRSession * _Nullable session, NSError * _Nullable error) {
     if (session) {
       FIRAuthCredential *credential =
       [FIRTwitterAuthProvider credentialWithToken:session.authToken
                                            secret:session.authTokenSecret];
       if (completion) {
         completion(credential, nil);
       }
     } else {
       NSError *newError =
       [FIRAuthUIErrorUtils providerErrorWithUnderlyingError:error
                                                  providerID:FIRTwitterAuthProviderID];
       if (completion) {
         completion(nil, newError);
       }
     }
   }];
}

- (void)signOut {
  NSString *twitterUserID = [TWTRAPIClient clientWithCurrentUser].userID;
  if (twitterUserID) {
    [[self getTwitterManager].sessionStore logOutUserID:twitterUserID];
  }
}

- (BOOL)handleOpenURL:(NSURL *)URL sourceApplication:(NSString *)sourceApplication {
  return [[self getTwitterManager] application:[UIApplication sharedApplication]
                                       openURL:URL options:@{}];

}

#pragma mark - Private methods
- (Twitter *)getTwitterManager {
  return [Twitter sharedInstance];
}

@end
