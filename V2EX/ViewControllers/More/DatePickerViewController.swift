import UIKit

final class DatePickerViewController: BaseViewController {

    @IBOutlet weak var fromBtn: UIButton!
    @IBOutlet weak var toBtn: UIButton!
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    private var fromTime: Date = defaults[.fromTime]
    private var toTime: Date = defaults[.toTime]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configBtn(fromBtn)
        configBtn(toBtn)
        
        fromBtn.isSelected = true
        datePicker.date = fromTime
        
//        UILabel.appearance(whenContainedInInstancesOf: [UIDatePicker.self]).textColor = ThemeStyle.style.value == .day ? .black : .white

        datePicker.setValue(ThemeStyle.style.value == .day ? UIColor.black : UIColor.white, forKey: "textColor")
        updateTime()
        
        title = "夜间模式时段"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "保存", style: .plain, action: { [unowned self] in
            defaults[.fromTime] = self.fromTime
            defaults[.toTime] = self.toTime
            self.navigationController?.popViewController(animated: true)
        })
        navigationItem.rightBarButtonItem?.tintColor = ThemeStyle.style.value.tintColor
    }
    
    private func configBtn(_ btn: UIButton) {
        let theme = ThemeStyle.style.value
        let isDay = theme == .day
        
        btn.setTitleColor(isDay ? .black : .white, for: .normal)
        btn.setTitleColor(.white, for: .selected)
        btn.setBackgroundImage(theme.cellBackgroundColor.toImage(), for: .normal)
        btn.setBackgroundImage(UIColor.darkGray.toImage(), for: .selected)
    }

    init() {
        super.init(nibName: "DatePickerViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateTime() {
        fromBtn.setTitle("从 \(fromTime.timeString)", for: .normal)
        toBtn.setTitle("到 \(toTime.timeString)", for: .normal)
    }
    
    @IBAction func didChangeDateAction(_ sender: Any) {
        if fromBtn.isSelected {
            fromTime = datePicker.date
        } else {
            toTime = datePicker.date
        }
        updateTime()
    }
    
    @IBAction func btnTapAction(_ sender: UIButton) {
        [toBtn, fromBtn].forEach { $0?.isSelected = false }
        sender.isSelected = true
        
        let time = sender == fromBtn ? fromTime : toTime
        datePicker.date = time
    }
    
//    func setDatePickerTextColor(){
//        var count:UInt32 = 0
//        let propertys = class_copyPropertyList(UIDatePicker.self, &count)
//        for index in 0..<count {
//            let i = Int(index)
//            let property = propertys![i]
//            let propertyName = property_getName(property)
//
//            if let strName = String(cString: propertyName, encoding: .utf8), strName == "textColor" {
//                datePicker?.setValue(ThemeStyle.style.value == .day ? UIColor.black : UIColor.white, forKey: strName)
//            }
//        }
//    }
    
}

extension UIColor {
    /// Color to Image
    func toImage(size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        let rect:CGRect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, true, 0)
        self.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image! // was image
    }
    
}

