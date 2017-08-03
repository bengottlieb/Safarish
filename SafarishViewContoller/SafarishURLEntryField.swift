//
//  SafarishURLEntryField.swift
//  Safarish
//
//  Created by Ben Gottlieb on 7/27/17.
//  Copyright © 2017 Stand Alone, Inc. All rights reserved.
//

import UIKit

class SafarishURLEntryField: UIView {
	var fontSize: CGFloat = 15
	var field: UITextField!
	var label: UILabel!
	var labelCenterConstraint: NSLayoutConstraint!
	var labelLeftConstraint: NSLayoutConstraint!
	var backgroundRightConstraint: NSLayoutConstraint!
	var cancelButton: UIButton!
	var shouldShowCancelButton: Bool { return !self.safarishViewController.isIPad }
	var fieldFakeSelectAllEnabled = false
	weak var safarishViewController: SafarishViewController!
	var navigationBarScrollPercentage: CGFloat = 0.0 { didSet { self.updateShrinkage() }}

	var fieldBackground: UIView!
	var backgroundHeight: CGFloat = 30
	var url: URL? { didSet {
			self.field.text = url?.prettyURLString
			self.label.text = url?.prettyName
		}}
	
	let selectionColor = UIColor(red: 0.0, green: 0.33, blue: 0.65, alpha: 0.2)
	
	convenience init(in parent: SafarishViewController) {
		self.init(frame: .zero)
		self.backgroundColor = .clear
		
		self.safarishViewController = parent
		self.fieldBackground = UIView(frame: .zero)
		self.fieldBackground.backgroundColor = UIColor(white: 0.85, alpha: 1.0)
		self.fieldBackground.translatesAutoresizingMaskIntoConstraints = false
		self.fieldBackground.layer.cornerRadius = 4
		self.fieldBackground.layer.masksToBounds = true
		self.addSubview(self.fieldBackground)
		self.backgroundRightConstraint = NSLayoutConstraint(item: self.fieldBackground, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0)
		self.addConstraints([
			NSLayoutConstraint(item: self.fieldBackground, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: self.backgroundHeight),
			NSLayoutConstraint(item: self.fieldBackground, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 0),
			NSLayoutConstraint(item: self.fieldBackground, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0),
			self.backgroundRightConstraint,
		])
		
		self.field = UITextField(frame: .zero)
		self.field.translatesAutoresizingMaskIntoConstraints = false
		self.field.autocorrectionType = .no
		self.field.autocapitalizationType = .none
		self.field.spellCheckingType = .no
		self.field.textAlignment = .left
		self.field.adjustsFontSizeToFitWidth = true
		self.field.returnKeyType = .go
		self.field.clipsToBounds = false
		self.field.font = UIFont.systemFont(ofSize: self.fontSize)
		self.field.delegate = self
		self.field.isHidden = true
		self.addSubview(self.field)
		self.field.addTarget(self, action: #selector(urlFieldChanged), for: .editingChanged)
		self.addConstraints([
			NSLayoutConstraint(item: self.field, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: self.backgroundHeight),
			NSLayoutConstraint(item: self.field, attribute: .left, relatedBy: .equal, toItem: self.fieldBackground, attribute: .left, multiplier: 1.0, constant: 5),
			NSLayoutConstraint(item: self.field, attribute: .right, relatedBy: .equal, toItem: self.fieldBackground, attribute: .right, multiplier: 1.0, constant: -5),
			NSLayoutConstraint(item: self.field, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 1),
		])
		
		
		self.label = UILabel(frame: .zero)
		self.label.translatesAutoresizingMaskIntoConstraints = false
		self.label.textAlignment = .center
		self.label.adjustsFontSizeToFitWidth = true
		self.label.font = UIFont.systemFont(ofSize: self.fontSize)
		self.addSubview(self.label)
		self.labelCenterConstraint = NSLayoutConstraint(item: self.label, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 5)
		self.labelLeftConstraint = NSLayoutConstraint(item: self.label, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 10)
		self.addConstraints([
			NSLayoutConstraint(item: self.label, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: self.backgroundHeight),
			NSLayoutConstraint(item: self.label, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0),
			self.labelCenterConstraint,
			self.labelLeftConstraint,
		])
		self.labelLeftConstraint.isActive = false

		let recog = UITapGestureRecognizer(target: self, action: #selector(beginEditing))
		self.isUserInteractionEnabled = true
		self.addGestureRecognizer(recog)

		self.field.addTarget(self, action: #selector(clearSelectAll), for: .touchDown)
	}
	
	func updateShrinkage() {
		let newAlpha = (1.0 - self.navigationBarScrollPercentage) * (1.0 - self.navigationBarScrollPercentage)
		self.fieldBackground.alpha = newAlpha
		self.label.transform = CGAffineTransform(translationX: 0, y: 10 * self.navigationBarScrollPercentage)
		self.fieldBackground.transform = CGAffineTransform(translationX: 0, y: 10 * self.navigationBarScrollPercentage)

		let minFontSize: CGFloat = 10
		self.label.font = UIFont.systemFont(ofSize: minFontSize + (self.fontSize - minFontSize) * (1 - self.navigationBarScrollPercentage))

		self.isUserInteractionEnabled = self.navigationBarScrollPercentage == 0.0
	}
}


extension SafarishURLEntryField: UITextFieldDelegate {
	@objc func beginEditing() {
		guard self.field.isHidden else { return }
		self.makeFieldEditable(true)
	}
	
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		if self.self.fieldFakeSelectAllEnabled {
			self.field.text = string
			self.fieldFakeSelectAllEnabled = false
			return false
		}
		return true
	}
	
	@objc func clearSelectAll() {
		if self.fieldFakeSelectAllEnabled {
			self.urlFieldChanged()
			if let position = self.field.position(from: self.field.endOfDocument, offset: -1) {
				self.field.selectedTextRange = self.field.textRange(from: position, to: position)
			}
		}
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		if let url = URL(fragment: textField.text) {
			self.url = url
			self.safarishViewController?.didEnterURL(url)
		} else {
			self.label.text = url?.prettyName
		}
		self.makeFieldEditable(false)
		return false
	}
	
	@objc func urlFieldChanged() {
		if self.fieldFakeSelectAllEnabled {
			self.fieldFakeSelectAllEnabled = false
			let text = self.field.text
			self.field.attributedText = NSAttributedString(string: text ?? "", attributes: [.font: self.field.font!, .foregroundColor: self.field.textColor!])
		}
	}
	
	func makeFieldEditable(_ editable: Bool) {
		self.field.isHidden = true
		self.label.isHidden = false
		self.labelCenterConstraint.isActive = !editable
		self.labelLeftConstraint.isActive = editable
		
		if self.shouldShowCancelButton {
			if self.cancelButton == nil {
				self.cancelButton = UIButton(type: .system)
				self.cancelButton.frame = CGRect(x: self.bounds.width, y: 0, width: 0, height: 0)
				self.cancelButton.showsTouchWhenHighlighted = true
				self.cancelButton.addTarget(self, action: #selector(cancelEditing), for: .touchUpInside)
				self.cancelButton.translatesAutoresizingMaskIntoConstraints = false
				self.cancelButton.setTitle(NSLocalizedString("Cancel", comment: "Cancel"), for: .normal)
				self.addSubview(self.cancelButton)
				self.cancelButton.alpha = 0.0
				self.addConstraints([
					NSLayoutConstraint(item: self.cancelButton, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0),
					NSLayoutConstraint(item: self.cancelButton, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 5),
				])
			}

			self.cancelButton.sizeToFit()
			self.backgroundRightConstraint.constant = editable ? -(self.cancelButton.bounds.width + 6) : 0
			print("Bounds: \(self.cancelButton.bounds)")
		}
		
		
		if let current = self.label.text, let new = self.field.text, let range = new.range(of: current) {
			let attr: [NSAttributedStringKey: Any] = [ .font: self.label.font ]
			let prefix = String(new[...range.lowerBound])
			self.labelLeftConstraint.constant = 0 + (NSAttributedString(string: prefix, attributes: attr).size().width)
		} else {
			self.labelLeftConstraint.constant = 10
		}

		UIView.animate(withDuration: 0.25, animations: {
			self.cancelButton?.alpha = editable ? 1.0 : 0.0
			self.layoutIfNeeded()
		}) { complete in
			self.fieldFakeSelectAllEnabled = true
			self.field.isHidden = !editable
			self.label.isHidden = editable
			self.field.becomeFirstResponder()
			self.field.attributedText = NSAttributedString(string: self.field.text ?? "", attributes: [.font: self.field.font!, .backgroundColor: self.selectionColor, .foregroundColor: self.field.textColor!])
		}
	}
	
	@objc func cancelEditing() {
		self.field.text = self.url?.prettyURLString
		self.makeFieldEditable(false)
	}
}

extension URL {
	init?(fragment: String?) {
		guard let frag = fragment, !frag.isEmpty else { self.init(string: ""); return nil }
		
		if let components = URLComponents(string: frag), components.scheme != nil {
			self.init(string: frag)
		} else {
			self.init(string: "https://" + frag)
		}
	}
}
