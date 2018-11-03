import UIKit

class AppearanceIconsCell: BaseTableViewCell {
    
    @IBAction func tapAction(_ btn: UIButton) {
        
        if #available(iOS 10.3, *) {
            
            var iconName: String?
            
            switch btn.tag {
            case 2:
                iconName = "cyan"
            case 3:
                iconName = "dark"
            default:
                break
            }
            
            UIApplication.shared.setAlternateIconName(iconName) { error in
                if let err = error {
                    HUD.showTest(err)
                }
            }
        }
    }
}
