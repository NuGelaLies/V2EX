import Foundation

protocol OCRService {
    
    func recognize(
        imgBase64: String,
        success: ((String) -> Void)?,
        failure: Failure?)
}

extension OCRService {
    

    func recognize(
        imgBase64: String,
        success: ((String) -> Void)?,
        failure: Failure?) {

        accessToken(success: { oauthResult in
            guard let accessToken = oauthResult.accessToken else {
                failure?("Oauth failed")
                return
            }
            self.recognize(accessToken: accessToken, imgBase64: imgBase64, success: success, failure: failure)
        }, failure: failure)
    }

    
    /// 获取 Access Token
    ///
    /// - Parameters:
    ///   - success: 成功
    ///   - failure: 失败
    private func accessToken(
        success: ((BaiduOauthToken) -> Void)?,
        failure: Failure?) {

        if let model = BaiduOauthToken.get(), model.isValid {
            success?(model)
            return
        }

        var clientId = Constants.BaiduOCR.appKey
        var clientSecret = Constants.BaiduOCR.secretKey
        if let appearence = BaiduAppearence.get() {
            clientId = appearence.appkey
            clientSecret = appearence.secretKey
        }
        
        Network.request(
            target: .baiduAccessToken(
                clientId: clientId,
                clientSecret: clientSecret),
            success: { data in
                if var oauthResult = BaiduOauthToken.oauthResult(data: data) {
                    let currentTimestamp = Int(Date().timeIntervalSince1970)
                    let expiresIn = oauthResult.expiresIn ?? 2592000
                    let expiryTime = currentTimestamp + expiresIn
                    oauthResult.expiryTimestamp = expiryTime

                    log.info("重新获取 Access Token 成功，过期时间:", expiryTime)
                    BaiduOauthToken.save(oauthResult)
                    success?(oauthResult)
                } else {
                    failure?("OAuth Fail")
                }

        }, failure: failure)
    }

    /// OCR 识别
    ///
    /// - Parameters:
    ///   - accessToken: Access Token
    ///   - imgBase64: 图片 Base64
    ///   - success: 成功
    ///   - failure: 失败
    private func recognize(
        accessToken: String,
        imgBase64: String,
        success: ((String) -> Void)?,
        failure: Failure?) {

        Network.request(target: .baiduOCRRecognize(
            accessToken: accessToken,
            imgBase64: imgBase64), success: { data in
                guard let response = BaiduOcrResponse.result(data: data) else {
                    failure?("识别失败")
                    return
                }
                log.info(response.dictionaryRepresentation())
                if let errMsg = response.errorMsg,
                    let errCode = response.errorCode {
                    switch errCode {
                    case 17, 19:
                        failure?("当天免费额度已超限额\n" + errMsg)
                    case 100, 110, 111: // access_token 无效、过期, 重新获取
                        BaiduOauthToken.remove()
                        self.recognize(imgBase64: imgBase64, success: success, failure: failure)
                        return
                    default:
                        failure?(errMsg)
                    }
                    return
                }

                guard let wordsResult = response.wordsResult else {
                    failure?("识别失败"); return
                }

                let wrapperChars: [String] = wordsResult.flatMap({ word in
                    return word.words.deleteOccurrences(target: " ").deleteOccurrences(target: "-").uppercased()
                })

                let chars = wrapperChars.filter { $0.isV2EXCaptcha() }

                guard chars.count.boolValue else {
                    failure?("识别失败"); return
                }

                log.info("filtered recognize values", chars)

                func mostCharIn(_ text: String) -> String {
                    guard let firstCharacter = text.first else { return "" }

                    var dict: [Character: Int] = [:]
                    for i in 0..<text.count {
                        guard let charStr = text[i] else { continue }

                        var preCount = 0
                        if let value = dict[charStr] {
                            preCount = value
                        }
                        dict[charStr] = preCount + 1
                    }
                    let sortDict = dict.sorted(by: { (lhs, rhs) -> Bool in
                        return lhs.value > rhs.value
                    })
                    log.info(sortDict)
                    return String(sortDict.first?.key ?? firstCharacter)
                }

                var list: [String] = []
                for offset in 0..<8 {
                    let col = chars.flatMap { $0[offset] }
                    let char = mostCharIn(String(col))
                    list.append(char)
                }
                let finalCaptcha = list.joined()
                log.info(finalCaptcha)
                success?(finalCaptcha)
        }, failure: failure)
    }
}
