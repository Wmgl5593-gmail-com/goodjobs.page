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

import UIKit
import FirebaseAuthUI
import FirebaseAuth

class FIRCustomAuthUIDelegate: NSObject, FIRAuthUIDelegate {

  func authUI(_ authUI: FIRAuthUI, didSignInWith user: FIRUser?, error: Error?) {
    guard let authError = error else { return }

    let errorCode = UInt((authError as NSError).code)

    switch errorCode {
    case FIRAuthUIErrorCode.userCancelledSignIn.rawValue:
      print("User cancelled sign-in");
      break
    default:
      let detailedError = (authError as NSError).userInfo[NSUnderlyingErrorKey] ?? authError
      print("Login error: \((detailedError as! NSError).localizedDescription)");
    }
  }

  func authPickerViewController(for authUI: FIRAuthUI) -> FIRAuthPickerViewController {
    return FIRCustomAuthPickerViewController(authUI: authUI)
  }

  func emailEntryViewController(for authUI: FIRAuthUI) -> FIREmailEntryViewController {
    return FIRCustomEmailEntryViewController(authUI: authUI)
  }

  func passwordRecoveryViewController(for authUI: FIRAuthUI, email: String) -> FIRPasswordRecoveryViewController {
    return FIRCustomPasswordRecoveryViewController(authUI: authUI, email: email)
  }

  func passwordSignInViewController(for authUI: FIRAuthUI, email: String) -> FIRPasswordSignInViewController {
    return FIRCustomPasswordSignInViewController(authUI: authUI, email: email)
  }

  func passwordSignUpViewController(for authUI: FIRAuthUI, email: String) -> FIRPasswordSignUpViewController {
    return FIRCustomPasswordSignUpViewController(authUI: authUI, email: email)
  }

  func passwordVerificationViewController(for authUI: FIRAuthUI, email: String, newCredential: FIRAuthCredential) -> FIRPasswordVerificationViewController {
    return FIRCustomPasswordVerificationViewController(authUI: authUI, email: email, newCredential: newCredential)
  }
}
