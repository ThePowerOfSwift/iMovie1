//
//  ActionButton.swift
//  MoviewsStorage
//
//  Created by Oleksandr O. Dudash on 8/30/17.
//  Copyright © 2017 Oleksandr O. Dudash. All rights reserved.
//

import UIKit

public typealias ActionButtonAction = (ActionButton) -> Void

open class ActionButton: NSObject {
    
    /// The action the button should perform when tapped
    open var action: ActionButtonAction?
    
    /// The button's background color : set default color and selected color
    open var backgroundColor: UIColor = UIColor(red: 238.0/255.0, green: 130.0/255.0, blue: 34.0/255.0, alpha:1.0) {
        willSet {
            floatButton.backgroundColor = newValue
            backgroundColorSelected = newValue
        }
    }
    
    /// The button's background color : set default color
    open var backgroundColorSelected: UIColor = UIColor(red: 238.0/255.0, green: 130.0/255.0, blue: 34.0/255.0, alpha:1.0)
    
    /// Indicates if the buttons is active (showing its items)
    fileprivate(set) open var active: Bool = false
    
    /// An array of items that the button will present
    internal var items: [ActionButtonItem]? {
        willSet {
            for abi in self.items! {
                abi.view.removeFromSuperview()
            }
        }
        didSet {
            placeButtonItems()
            showActive(true)
        }
    }
    
    /// The button that will be presented to the user
    fileprivate var floatButton: UIButton!
    
    /// View that will hold the placement of the button's actions
    fileprivate var contentView: UIView!
    
    /// View where the *floatButton* will be displayed
    fileprivate var parentView: UIView!
    
    /// Blur effect that will be presented when the button is active
    fileprivate var blurVisualEffect: UIVisualEffectView!
    
    // Distance between each item action
    fileprivate let itemOffset = -55
    
    /// the float button's radius
    fileprivate let floatButtonRadius = 50
    
    public init(attachedToView view: UIView, items: [ActionButtonItem]?) {
        super.init()
        
        self.parentView = view
        self.items = items
        let bounds = self.parentView.bounds
        let image = #imageLiteral(resourceName: "sort")
        
        self.floatButton = UIButton(type: .custom)
        self.floatButton.layer.cornerRadius = CGFloat(floatButtonRadius / 2)
        self.floatButton.layer.shadowOpacity = 1
        self.floatButton.layer.shadowRadius = 2
        self.floatButton.layer.shadowOffset = CGSize(width: 1, height: 1)
        self.floatButton.layer.shadowColor = UIColor.gray.cgColor
        self.floatButton.setTitle(nil, for: UIControlState())
        self.floatButton.setImage(image, for: UIControlState())
        self.floatButton.backgroundColor = self.backgroundColor
        self.floatButton.titleLabel!.font = UIFont(name: "HelveticaNeue-Light", size: 35)
        self.floatButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)
        self.floatButton.isUserInteractionEnabled = true
        self.floatButton.translatesAutoresizingMaskIntoConstraints = false
        
        self.floatButton.addTarget(self, action: #selector(ActionButton.buttonTapped(_:)), for: .touchUpInside)
        self.floatButton.addTarget(self, action: #selector(ActionButton.buttonTouchDown(_:)), for: .touchDown)
        self.parentView.addSubview(self.floatButton)
        
        self.contentView = UIView(frame: bounds)
        self.blurVisualEffect = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
        self.blurVisualEffect.frame = self.contentView.frame
        self.contentView.addSubview(self.blurVisualEffect)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(ActionButton.backgroundTapped(_:)))
        self.contentView.addGestureRecognizer(tap)
        
        self.installConstraints()
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Set Methods
    open func setTitle(_ title: String?, forState state: UIControlState) {
        floatButton.setImage(nil, for: state)
        floatButton.setTitle(title, for: state)
        floatButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)
    }
    
    open func setImage(_ image: UIImage?, forState state: UIControlState) {
        setTitle(nil, forState: state)
        floatButton.setImage(image, for: state)
        floatButton.adjustsImageWhenHighlighted = false
        floatButton.contentEdgeInsets = UIEdgeInsets.zero
    }
    
    //MARK: - Auto Layout Methods
    /**
     Install all the necessary constraints for the button. By the default the button will be placed at 15pts from the bottom and the 15pts from the right of its *parentView*
     */
    fileprivate func installConstraints() {
        let views: [String: UIView] = ["floatButton":self.floatButton, "parentView":self.parentView]
        let width = NSLayoutConstraint.constraints(withVisualFormat: "H:[floatButton(\(floatButtonRadius))]", options: NSLayoutFormatOptions.alignAllCenterX, metrics: nil, views: views)
        let height = NSLayoutConstraint.constraints(withVisualFormat: "V:[floatButton(\(floatButtonRadius))]", options: NSLayoutFormatOptions.alignAllCenterX, metrics: nil, views: views)
        self.floatButton.addConstraints(width)
        self.floatButton.addConstraints(height)
        
        let trailingSpacing = NSLayoutConstraint.constraints(withVisualFormat: "V:[floatButton]-70-|", options: NSLayoutFormatOptions.alignAllCenterX, metrics: nil, views: views)
        let bottomSpacing = NSLayoutConstraint.constraints(withVisualFormat: "H:[floatButton]-16-|", options: NSLayoutFormatOptions.alignAllCenterX, metrics: nil, views: views)
        self.parentView.addConstraints(trailingSpacing)
        self.parentView.addConstraints(bottomSpacing)
    }
    
    //MARK: - Button Actions Methods
    func buttonTapped(_ sender: UIControl) {
        animatePressingWithScale(1.0)
        
        if let unwrappedAction = self.action {
            unwrappedAction(self)
        }
    }
    
    func buttonTouchDown(_ sender: UIButton) {
        animatePressingWithScale(0.9)
    }
    
    //MARK: - Gesture Recognizer Methods
    func backgroundTapped(_ gesture: UIGestureRecognizer) {
        if self.active {
            self.toggle()
        }
    }
    
    //MARK: - Custom Methods
    /**
     Presents or hides all the ActionButton's actions
     */
    open func toggleMenu() {
        self.placeButtonItems()
        self.toggle()
    }
    
    //MARK: - Action Button Items Placement
    /**
     Defines the position of all the ActionButton's actions
     */
    fileprivate func placeButtonItems() {
        if let optionalItems = self.items {
            for item in optionalItems {
                item.view.center = CGPoint(x: self.floatButton.center.x - 83, y: self.floatButton.center.y)
                item.view.removeFromSuperview()
                
                self.contentView.addSubview(item.view)
            }
        }
    }
    
    //MARK - Float Menu Methods
    /**
     Presents or hides all the ActionButton's actions and changes the *active* state
     */
    fileprivate func toggle() {
        self.animateMenu()
        self.showBlur()
        
        self.active = !self.active
        self.floatButton.backgroundColor = self.active ? backgroundColorSelected : backgroundColor
        self.floatButton.isSelected = self.active
    }
    
    fileprivate func animateMenu() {
        let rotation = self.active ? 0 : CGFloat(Double.pi/4)
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.1, options: UIViewAnimationOptions.allowAnimatedContent, animations: {
            
            if self.floatButton.imageView?.image == nil {
                self.floatButton.transform = CGAffineTransform(rotationAngle: rotation)
            }
            
            self.showActive(false)
        }, completion: {completed in
            if self.active == false {
                self.hideBlur()
            }
        })
    }
    
    fileprivate func showActive(_ active: Bool) {
        if self.active == active {
            self.contentView.alpha = 1.0
            
            if let optionalItems = self.items {
                for (index, item) in optionalItems.enumerated() {
                    let offset = index + 1
                    let translation = self.itemOffset * offset
                    item.view.transform = CGAffineTransform(translationX: 0, y: CGFloat(translation))
                    item.view.alpha = 1
                }
            }
        } else {
            self.contentView.alpha = 0.0
            
            if let optionalItems = self.items {
                for item in optionalItems {
                    item.view.transform = CGAffineTransform(translationX: 0, y: 0)
                    item.view.alpha = 0
                }
            }
        }
    }
    
    fileprivate func showBlur() {
        self.parentView.insertSubview(self.contentView, belowSubview: self.floatButton)
    }
    
    fileprivate func hideBlur() {
        self.contentView.removeFromSuperview()
    }
    
    /**
     Animates the button pressing, by the default this method just scales the button down when it's pressed and returns to its normal size when the button is no longer pressed
     
     - parameter scale: how much the button should be scaled
     */
    fileprivate func animatePressingWithScale(_ scale: CGFloat) {
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.1, options: UIViewAnimationOptions.allowAnimatedContent, animations: {
            self.floatButton.transform = CGAffineTransform(scaleX: scale, y: scale)
        }, completion: nil)
    }
}
