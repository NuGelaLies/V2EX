import UIKit

class AppearanceIconsCell: BaseTableViewCell {
    
    @IBAction func tapAction(_ btn: UIButton) {
        
        if #available(iOS 10.3, *) {
            
            var iconName: String?
            
            switch btn.tag {
            case 2:
                iconName = "Cyan"
            case 3:
                iconName = "Dark"
            default:
                break
            }
            
            guard UIApplication.shared.supportsAlternateIcons else {
                return
            }
            UIApplication.shared.setAlternateIconName(iconName) { error in
                if let err = error {
                    HUD.showError("操作失败， \(err.localizedDescription)")
                }
            }
        }
    }
}
