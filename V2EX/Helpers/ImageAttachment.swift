import UIKit
import Foundation
import Kingfisher

class ImageAttachment: AnimatedImageView {

    public var url: URL?

    init(url: URL?) {
        self.url = url
        super.init(frame: CGRect(x: 0, y: 0, width: 80, height: 80))

        contentMode = .scaleAspectFill
        isUserInteractionEnabled = true
        layer.masksToBounds = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)

        guard image == nil else { return }

        setImage(with: url, placeholder: #imageLiteral(resourceName: "placeholder"), progress: nil) { imageResult in
            guard let imageSize = imageResult.image?.size else { return }
            if imageSize.width < self.width && imageSize.height < self.height {
                self.contentMode = .bottomLeft
            }
        }

//        setImage(url: url, placeholder: #imageLiteral(resourceName: "placeholder"))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let tapCount = touch?.tapCount
        if let tapCount = tapCount {
            if tapCount == 1 {
                handleSingleTap()
            }
        }
        //取消后续的事件响应
        next?.touchesCancelled(touches, with: event)
    }

    private func handleSingleTap(){
        guard let img = image else { return }
        showImageBrowser(imageType: .image(img))
    }
}
