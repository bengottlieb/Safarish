//
//  SafarishIPhoneTitleBarView.swift
//  Safarish
//
//  Created by Ben Gottlieb on 12/27/16.
//  Copyright © 2016 Stand Alone, Inc. All rights reserved.
//

import Foundation
import UIKit

extension SafarishViewController {
	class TitleBarView: UIView {
		static let maxHeight: CGFloat = 64
		static let minHeight: CGFloat = 40
		
		weak var safarishViewController: SafarishViewController!
		var scrollView: UIScrollView?
		var reloadButton: UIButton!
	
		var originalText: String = ""
		var fieldBackgroundMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
		let fieldBackgroundStatusSpacing: CGFloat = 20
		var effectiveScrollTop: CGFloat!
		var editing = false

		let cancelButtonRight: CGFloat = 60.0
		var cancelButtonRightConstraint: NSLayoutConstraint!
		var doneButtonLeft: CGFloat = 60.0
		var estimatedProgress = 0.0 { didSet { self.setNeedsDisplay() }}
		var currentDoneButtonLeft: CGFloat {
			if !self.isDoneButtonVisible || self.isCancelButtonVisible { return -self.doneButtonLeft }
			
			return 0 - (self.doneButtonLeft * (1.0 - self.displayedHeightFraction) * (1.0 - self.displayedHeightFraction))
		}
		
		var doneButtonLeftConstraint: NSLayoutConstraint!
		var titleHeightConstraint: NSLayoutConstraint!
		
		var urlFieldFont: UIFont {
			return UIFont.systemFont(ofSize: 12 + self.displayedHeightFraction * 4)
		}
		
		var isCancelButtonVisible = false { didSet {
			self.cancelButtonRightConstraint?.constant = self.isCancelButtonVisible ? -(self.fieldBackgroundMargins.right) : self.cancelButtonRight
			self.doneButtonLeftConstraint?.constant = self.currentDoneButtonLeft
		}}
		var isDoneButtonVisible = true { didSet { self.doneButtonLeftConstraint?.constant = self.currentDoneButtonLeft }}
		
		
		var contentHeight: CGFloat { return self.bounds.height - self.fieldBackgroundStatusSpacing }
		var backgroundWidth: CGFloat { return self.bounds.width - (self.fieldBackgroundMargins.left + self.fieldBackgroundMargins.right) }
		var backgroundHeight: CGFloat { return self.contentHeight - (self.fieldBackgroundMargins.top + self.fieldBackgroundMargins.bottom) }

		var currentHeight = TitleBarView.maxHeight
		var displayedHeightFraction: CGFloat = 1.0 { didSet {
			if self.displayedHeightFraction == oldValue { return }
			
			let maxDelta = TitleBarView.maxHeight - TitleBarView.minHeight
			self.currentHeight = TitleBarView.minHeight + maxDelta * self.displayedHeightFraction
			
			self.fieldBackground.alpha = self.displayedHeightFraction * self.displayedHeightFraction
			self.doneButton.alpha = self.displayedHeightFraction * self.displayedHeightFraction
			self.titleHeightConstraint.constant = self.currentHeight
			
			if self.isDoneButtonVisible {
				self.doneButtonLeftConstraint?.constant = self.currentDoneButtonLeft
			}
			
			self.urlField.font = self.urlFieldFont
			if self.displayedHeightFraction != 1.0 {
				self.urlField.isUserInteractionEnabled = false
				self.urlField.textAlignment = .center
			}
		}}
		
		convenience init(frame: CGRect, parent: SafarishViewController) {
			self.init(frame: frame)
			self.safarishViewController = parent
			self.setup(includingCancelButton: true, includingDoneButton: true)
		}
		
		func setup(includingCancelButton: Bool, includingDoneButton: Bool) {
			self.translatesAutoresizingMaskIntoConstraints = false
			self.backgroundColor = UIColor.white
			self.contentMode = .redraw
			self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))
			
			// set up my constraints
			self.titleHeightConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: TitleBarView.maxHeight)
			self.addConstraint(self.titleHeightConstraint)
			
			if includingCancelButton {		// setup cancel button
				self.addSubview(self.cancelButton)
				self.cancelButton.addTarget(self, action: #selector(cancelEditing), for: .touchUpInside)
				self.cancelButtonRightConstraint = NSLayoutConstraint(item: self.cancelButton, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: self.isCancelButtonVisible ? -(self.fieldBackgroundMargins.right) : self.cancelButtonRight)
				self.addConstraints([
					NSLayoutConstraint(item: self.cancelButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 60),
					NSLayoutConstraint(item: self.cancelButton, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: self.fieldBackgroundStatusSpacing / 2),
					self.cancelButtonRightConstraint,
				])
			}

			if includingDoneButton {	// setup done button
				self.addSubview(self.doneButton)
				self.doneButton.addTarget(self, action: #selector(done), for: .touchUpInside)
				self.doneButtonLeftConstraint = NSLayoutConstraint(item: self.doneButton, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: self.currentDoneButtonLeft)
				self.addConstraints([
					NSLayoutConstraint(item: self.doneButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 60),
					NSLayoutConstraint(item: self.doneButton, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: self.fieldBackgroundStatusSpacing / 2),
					self.doneButtonLeftConstraint,
				])
			}
			
			// set up field background
			self.addSubview(self.fieldBackground)
			self.fieldBackground.frame = CGRect(x: self.fieldBackgroundMargins.left, y: self.fieldBackgroundMargins.top + self.fieldBackgroundStatusSpacing, width: backgroundWidth, height: backgroundHeight)
			self.addConstraints([
				NSLayoutConstraint(item: self.fieldBackground, attribute: .left, relatedBy: .equal, toItem: includingDoneButton ? self.doneButton : self, attribute: includingDoneButton ? .right : .left, multiplier: 1.0, constant: self.fieldBackgroundMargins.left),
				NSLayoutConstraint(item: self.fieldBackground, attribute: .right, relatedBy: .equal, toItem: includingCancelButton ? self.cancelButton : self, attribute: includingCancelButton ? .left : .right, multiplier: 1.0, constant: -(self.fieldBackgroundMargins.right)),
				NSLayoutConstraint(item: self.fieldBackground, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: (self.fieldBackgroundMargins.top + self.fieldBackgroundStatusSpacing)),
				NSLayoutConstraint(item: self.fieldBackground, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: -(self.fieldBackgroundMargins.bottom))
			])
			
			// setup field
			self.addSubview(self.urlField)
			self.addConstraints([
				NSLayoutConstraint(item: self.urlField, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: self.backgroundHeight),
				NSLayoutConstraint(item: self.urlField, attribute: .left, relatedBy: .equal, toItem: self.fieldBackground, attribute: .left, multiplier: 1.0, constant: 0),
				NSLayoutConstraint(item: self.urlField, attribute: .right, relatedBy: .equal, toItem: self.fieldBackground, attribute: .right, multiplier: 1.0, constant: -20),
				NSLayoutConstraint(item: self.urlField, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: (self.fieldBackgroundStatusSpacing + contentHeight / 2) - (self.bounds.height / 2)),
				])
			self.urlField.delegate = self
			self.urlField.font = self.urlFieldFont

			//setup reload button
			let refreshImage = UIImage(named: "safarish-refresh", in: Bundle(for: type(of: self)), compatibleWith: nil)
			self.reloadButton = UIButton(type: .custom)
			self.reloadButton.translatesAutoresizingMaskIntoConstraints = false
			self.reloadButton.setImage(refreshImage, for: .normal)
			self.reloadButton.addTarget(self, action: #selector(reload), for: .touchUpInside)
			self.reloadButton.showsTouchWhenHighlighted = true
			self.addSubview(self.reloadButton)
			self.reloadButton.addConstraints([
				NSLayoutConstraint(item: self.reloadButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 33),
				NSLayoutConstraint(item: self.reloadButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 33),
			])
			self.addConstraints([
				NSLayoutConstraint(item: self.reloadButton, attribute: .right, relatedBy: .equal, toItem: self.fieldBackground, attribute: .right, multiplier: 1.0, constant: 0),
				NSLayoutConstraint(item: self.reloadButton, attribute: .centerY, relatedBy: .equal, toItem: self.fieldBackground, attribute: .centerY, multiplier: 1.0, constant: 0),
			])
			
			self.makeFieldEditable(false)
		}
		
		
		func set(url: URL?) {
			self.urlField.text = url?.prettyName
		}
		
		override func draw(_ rect: CGRect) {
			let lineWidth = 1.0 / UIScreen.main.scale
			let bezier = UIBezierPath()
			let bounds = self.bounds
			UIColor.lightGray.setStroke()
			bezier.move(to: CGPoint(x: 0, y: bounds.height - lineWidth))
			bezier.addLine(to: CGPoint(x: bounds.width, y: bounds.height - lineWidth))
			bezier.lineWidth = lineWidth
			bezier.stroke()
			
			if self.estimatedProgress != 0 && self.estimatedProgress != 1.0 {
				let progressHeight: CGFloat = 3.0
				let barRect = CGRect(x: 0, y: bounds.height - progressHeight, width: bounds.width * CGFloat(self.estimatedProgress), height: progressHeight)
				self.tintColor.setFill()
				UIRectFill(barRect)
			}
		}
		
		//=============================================================================================
		//MARK: Subviews
		
		var cancelButton: UIButton = {
			let button = UIButton(type: .system)
			button.setTitle(NSLocalizedString("Cancel", comment: "Cancel"), for: .normal)
			button.translatesAutoresizingMaskIntoConstraints = false
			
			return button
		}()
		
		var doneButton: UIButton = {
			let button = UIButton(type: .system)
			button.setTitle(NSLocalizedString("Done", comment: "Done"), for: .normal)
			button.translatesAutoresizingMaskIntoConstraints = false
			
			return button
		}()
		
		var fieldBackground: UIView = {
			let view = UIView(frame: CGRect.zero)
			view.translatesAutoresizingMaskIntoConstraints = false
			view.layer.cornerRadius = 5
			view.layer.masksToBounds = true
			view.backgroundColor = UIColor(white: 0.89, alpha: 1.0)
			
			return view
		}()
		
		var urlField: UITextField = {
			let field = UITextField(frame: .zero)
			field.translatesAutoresizingMaskIntoConstraints = false
			field.autocorrectionType = .no
			field.autocapitalizationType = .none
			field.spellCheckingType = .no
			field.textAlignment = .center
			field.adjustsFontSizeToFitWidth = true
			field.returnKeyType = .go
			return field
		}()
		
        
        func beginEditingURL() {
            self.makeFieldEditable(true)
        }
	}
}

extension SafarishViewController.TitleBarView: UIScrollViewDelegate, UITextFieldDelegate {
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		if self.effectiveScrollTop == nil { self.effectiveScrollTop = -scrollView.contentInset.top }
		let maxDelta = SafarishViewController.TitleBarView.maxHeight - SafarishViewController.TitleBarView.minHeight
		let scrollAmount = scrollView.contentOffset.y - self.effectiveScrollTop
		self.scrollView = scrollView
		
		if scrollAmount < 0 {
			self.displayedHeightFraction = 1.0
		} else if scrollAmount < maxDelta {
			self.makeFieldEditable(false)
			self.displayedHeightFraction = 1.0 - scrollAmount / maxDelta
		} else {
			self.makeFieldEditable(false)
			self.displayedHeightFraction = 0.0
		}
		scrollView.scrollIndicatorInsets = UIEdgeInsets(top: self.currentHeight, left: 0, bottom: 0, right: 0)
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		guard let text = self.urlField.text, let url = URL(string: text) else {
			self.makeFieldEditable(false)
			return false
		}
		self.makeFieldEditable(false)
		guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return false }
		
		if components.scheme == nil { components.scheme = self.safarishViewController.forceHTTP ? "http" : "https" }
		if components.host == nil {
			components.host = components.path
			components.path = ""
		}
		
		self.safarishViewController?.didEnterURL(components.url)

		return false
	}
	
	public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		if decelerate {
			self.makeFullyVisible(animated: true)
		}
		
		self.effectiveScrollTop = scrollView.contentOffset.y
	}
}

extension SafarishViewController.TitleBarView {
	func tapped() {
		if self.displayedHeightFraction != 1.0 {
			self.makeFullyVisible(animated: true)
		} else {
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { self.beginEditingURL() }
		}
	}
	
	func makeFullyVisible(animated: Bool) {
		guard let scrollView = self.scrollView else { return }
		
		if self.displayedHeightFraction != 1.0 {
			let delta = (SafarishViewController.TitleBarView.maxHeight - SafarishViewController.TitleBarView.minHeight)
			self.effectiveScrollTop = scrollView.contentOffset.y - delta
			
			scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: self.effectiveScrollTop), animated: animated)
		}
	}
	
	func makeFieldEditable(_ editable: Bool) {
		let str = NSAttributedString(string: self.urlField.text ?? "", attributes: [NSFontAttributeName: self.urlField.font!])
		let size = str.size()
		let offset = ((self.urlField.bounds.width - size.width) / 2) - 2
		let duration: TimeInterval = 0.2
		
		if editable {
			if self.editing { return }
			self.editing = true
			self.isCancelButtonVisible = true
			self.originalText = self.urlField.text ?? ""
			UIView.animate(withDuration: duration, animations: {
				self.updateConstraintsIfNeeded()
				self.urlField.transform = CGAffineTransform(translationX: -(offset - self.cancelButtonRight / 2), y: 0)
			}) { complete in
				self.urlField.isUserInteractionEnabled = true
				self.cancelButton.isUserInteractionEnabled = true
				self.urlField.transform = CGAffineTransform.identity
				self.urlField.textAlignment = .left
				self.urlField.selectAll(nil)
				self.urlField.clearButtonMode = .whileEditing
				UIView.animate(withDuration: 0.4) {
					self.urlField.text = self.safarishViewController.url?.prettyURLString
				}
			}
		} else {
			self.isCancelButtonVisible = false
			self.urlField.clearButtonMode = .never
			self.urlField.isUserInteractionEnabled = false
			self.cancelButton.isUserInteractionEnabled = false
			self.urlField.text = self.safarishViewController.url?.prettyName
			if !self.editing { return }
			
			UIView.animate(withDuration: duration, animations: {
				self.updateConstraintsIfNeeded()
				self.urlField.transform = CGAffineTransform(translationX: offset + self.cancelButtonRight / 2, y: 0)
			}) { complete in
				self.urlField.transform = CGAffineTransform.identity
				self.urlField.textAlignment = .center
				self.editing = false
			}
		}
	}
	
	func reload() {
		self.safarishViewController.webView.reload()
	}
	
	func cancelEditing() {
		self.urlField.text = self.originalText
		self.makeFieldEditable(false)
	}

	func done() {
		self.safarishViewController?.done()
	}
}


extension URL {
	var prettyName: String? {
		let components = URLComponents(url: self, resolvingAgainstBaseURL: false)
		var name = components?.host ?? ""
		if name.hasPrefix("www.") { name = name.substring(from: name.index(name.startIndex, offsetBy: 4)) }
		return name
	}
	
	var prettyURLString: String? {
		let string = self.absoluteString
		if string == "about:blank" { return "" }
		return string
	}
}