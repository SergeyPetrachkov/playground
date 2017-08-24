//
//  ViewController.swift
//  carthage_test
//
//  Created by Sergey Petrachkov on 8/23/17.
//  Copyright © 2017 Sergey Petrachkov. All rights reserved.
//

import UIKit
import ReactiveSwift
import ReactiveCocoa
import Result
import MagicalRecord


class ViewController: UIViewController {
  class ViewModel {
    var email : String?
    var accepted : Bool = false
  }
  var viewModel = ViewModel()
  
  public let emailField = UITextField()
  public let emailConfirmationField = UITextField()
  public let termsSwitch = UISwitch()
  public let submitButton = UIButton(type: .system)
  public let reasonLabel = UILabel()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    //MARK: - appearance
    self.view.backgroundColor = .white
    
    self.view.addSubview(emailField)
    self.view.addSubview(emailConfirmationField)
    self.view.addSubview(termsSwitch)
    self.view.addSubview(submitButton)
    self.view.addSubview(reasonLabel)
    
    let labelFont = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
    
    // Email Field.
    let emailLabel = UILabel(frame: CGRect(x: 20, y: 20, width: 260, height: 20))
    emailLabel.font = labelFont
    emailLabel.text = "E-mail"
    self.view.addSubview(emailLabel)
    
    emailField.borderStyle = .roundedRect
    emailField.frame.origin = CGPoint(x: 20, y: 40)
    emailField.frame.size = CGSize(width: 260, height: 30)
    emailField.autocapitalizationType = .none
    
    // Email Confirmation Field.
    let emailConfirmationLabel = UILabel(frame: CGRect(x: 20, y: 80, width: 260, height: 20))
    emailConfirmationLabel.font = labelFont
    emailConfirmationLabel.text = "Confirm E-mail"
    self.view.addSubview(emailConfirmationLabel)
    
    emailConfirmationField.borderStyle = .roundedRect
    emailConfirmationField.frame.origin = CGPoint(x: 20, y: 100)
    emailConfirmationField.frame.size = CGSize(width: 260, height: 30)
    emailConfirmationField.autocapitalizationType = .none
    
    // Accept Terms Switch
    let termsSwitchLabel = UILabel(frame: CGRect(x: 80, y: 155, width: 200, height: 20))
    termsSwitchLabel.font = labelFont
    termsSwitchLabel.text = "Accept Terms and Conditions"
    self.view.addSubview(termsSwitchLabel)
    
    termsSwitch.frame.origin = CGPoint(x: 20, y: 150)
    
    // Submit Button
    submitButton.titleLabel!.font = labelFont
    submitButton.setBackgroundColor(submitButton.tintColor, for: .normal)
    submitButton.setBackgroundColor(UIColor(white: 0.85, alpha: 1.0), for: .disabled)
    submitButton.setTitleColor(.white, for: .normal)
    submitButton.setTitle("Submit", for: .normal)
    submitButton.frame.origin = CGPoint(x: 20, y: 200)
    submitButton.frame.size = CGSize(width: 260, height: 30)
    
    
    
    // Reason Label
    reasonLabel.frame.origin = CGPoint(x: 20, y: 250)
    reasonLabel.frame.size = CGSize(width: 260, height: 80)
    reasonLabel.numberOfLines = 0
    reasonLabel.font = labelFont
    
    
    
    //MARK: Reactive stuff here
    let textFieldEmailSourceSignal = self.emailField.reactive.continuousTextValues
    let textFieldEmailConfirmationSignal = self.emailConfirmationField.reactive.continuousTextValues
    let acceptedSignal = self.termsSwitch.reactive.isOnValues
    let validator = Signal.combineLatest(textFieldEmailSourceSignal, textFieldEmailConfirmationSignal, acceptedSignal)
      .map { sourceEmail, emailConfirmation, acceptance in
        return sourceEmail == emailConfirmation && sourceEmail != "" && acceptance
    }
    
    let enabledIf = Property(initial: false, then: validator)
    
    
    let action = Action<(String?, String?), Void, NoError>(enabledIf: enabledIf) { sourceEmail, emailConfirmation in
      return SignalProducer<Void, NoError> { observer, disposable in
        observer.send(value: {
          MagicalRecord.save({
            localContext in
            // update existing
            if let user = User.mr_findFirst() as? User {
              user.mr_deleteEntity()

            }
              let user = User.mr_createEntity(in: localContext)
              user?.email = self.viewModel.email
          }, completion: {completion in })
          
        }())
        observer.sendCompleted()
      }
    }
    
    
    let characters = MutableProperty("")
    
    emailConfirmationField.reactive.text <~ characters
    emailConfirmationField.reactive.continuousTextValues.observeValues { [weak characters = characters] (text) in
      if let text = text {
        characters?.value = text
        self.viewModel.email = text
      }
    }
    
    self.submitButton.reactive.pressed = CocoaAction(action, input: (self.emailField.text, self.emailConfirmationField.text))
    
    if let users = User.mr_findAll(),
      let user = users.last as? User {
      self.emailField.text = user.email
      self.emailConfirmationField.text = user.email
      self.termsSwitch.isOn = true
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

extension UIButton {
  func setBackgroundColor(_ color: UIColor, for state: UIControlState) {
    UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
    let context = UIGraphicsGetCurrentContext()!
    context.setFillColor(color.cgColor)
    context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
    let colorImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    self.setBackgroundImage(colorImage, for: state)
  }
}

