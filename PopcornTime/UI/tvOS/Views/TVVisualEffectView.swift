import UIKit

@IBDesignable class TVVisualEffectView: UIVisualEffectView {
    
    var _blurRadius: CGFloat = 90
    var _style: UIBlurEffect.Style = .dark
    @IBInspectable var blurRadius: CGFloat {
        get {
            return _blurRadius
        } set (radius) {
            if(_blurRadius != radius)
            {
            _blurRadius = radius
                if #available(iOS 14.0, *)
                {
                    let neweffect = CustomBlurEffect.effect(with: _style)
                    neweffect.blurRadius = blurRadius
                    effect = neweffect
                    blurEffect = neweffect}
                 }
            else
            {
                blurEffect.setValue(radius, forKey: "blurRadius")
            }
        }
    }
    
    /// Blur effect for IOS >= 14
      private lazy var customBlurEffect_ios14: CustomBlurEffect = {
          let effect = CustomBlurEffect.effect(with: .dark)
          effect.blurRadius = blurRadius
          return effect
      }()
      
      /// Blur effect for IOS < 14
      private lazy var customBlurEffect: UIBlurEffect = {
          return (NSClassFromString("_UICustomBlurEffect") as! UIBlurEffect.Type).init()
      }()
    
    private var blurEffect: UIBlurEffect!
    
    override init(effect: UIVisualEffect?) {
        guard let effect = effect as? UIBlurEffect else {
            fatalError("Effect must be of class: UIBlurEffect")
        }
        super.init(effect: effect)
        
        sharedSetup(effect: effect)
        
        self.effect = blurEffect
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        //guard let effect = effect as? UIBlurEffect else {
        //    fatalError("Effect must be of class: UIBlurEffect")
            var effect: UIBlurEffect
            if #available(iOS 14.0, *){
              effect = customBlurEffect_ios14
            }
            else{
              effect = customBlurEffect
            }
        
        sharedSetup(effect: effect)
        
        self.effect = blurEffect
    }
    
    private func sharedSetup(effect: UIBlurEffect, radius: CGFloat = 90) {
     
        let raw = effect.value(forKey: "_style") as! Int
        let style = UIBlurEffect.Style(rawValue: raw)!
        if #available(iOS 14.0, *)
        {
            let newEffect = CustomBlurEffect.effect(with: style)
            newEffect.blurRadius = blurRadius
            let subviewClass = NSClassFromString("_UIVisualEffectSubview") as? UIView.Type
            let visualEffectSubview: UIView? = self.subviews.filter({ type(of: $0) == subviewClass }).first
            visualEffectSubview?.backgroundColor = UIColor.clear
            self.blurEffect = newEffect

        }
            else
        {
            let UICustomBlurEffect = NSClassFromString("_UICustomBlurEffect") as! UIBlurEffect.Type
            let newEffect = UICustomBlurEffect.init(style: style)
            newEffect.setValue(1.0, forKey: "Scale")
            newEffect.setValue(radius, forKey: "blurRadius")
            newEffect.setValue(UIColor.clear, forKey: "colorTint")
            self.blurEffect = newEffect
        }
            
    }
    
}
