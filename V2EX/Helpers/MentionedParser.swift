import UIKit
import YYText

class MentionedParser: NSObject, YYTextParser{

    func parseText(_ text: NSMutableAttributedString?, selectedRange: NSRangePointer?) -> Bool {
        guard let text = text, let regex = TextParser.linkAndAt else {
            return false
        }

        regex.enumerateMatches(
            in: text.string,
            options: [.withoutAnchoringBounds],
            range: text.yy_rangeOfAll()) { (result, flags, stop) in
                guard let result = result else { return }
                let range = result.range
                if range.location == NSNotFound || range.length < 1 { return }
                if (text.attribute(NSAttributedString.Key(rawValue: YYTextBindingAttributeName), at: range.location, effectiveRange: nil) != nil) { return }
                let bindlingRange = NSMakeRange(range.location, range.length-1)
                let binding = YYTextBinding()
                binding.deleteConfirm = true
                text.yy_setTextBinding(binding, range: bindlingRange)
                text.yy_setColor(ThemeStyle.style.value.linkColor, range: bindlingRange)
        }
        
        return false;
    }
    
}
