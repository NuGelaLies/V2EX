import Foundation
import Kanna

protocol NodeService: HTMLParseService {

    /// 获取首页节点
    func homeNodes() -> [NodeModel]

    /// 更新首页节点
    func updateHomeNodes(nodes: [NodeModel]) -> Error?
    
    /// 重置首页显示的节点
    func resetHomeNodes()

    /// 获取节点导航
    ///
    /// - Parameters:
    ///   - success: 成功
    ///   - failure: 失败
    func nodeNavigation(
        success: ((_ nodeCategorys: [NodeCategoryModel]) -> Void)?,
        failure: Failure?)
    
    
    /// 获取指定节点的详情和主题
    ///
    /// - Parameters:
    ///   - node: node
    ///   - success: 成功
    ///   - failure: 失败
    func nodeDetail(
        page: Int,
        node: NodeModel,
        success: ((_ node: NodeModel, _ topics: [TopicModel], _ maxPage: Int) -> Void)?,
        failure: Failure?)
    
    
    /// 获取我收藏的节点
    ///
    /// - Parameters:
    ///   - success: 成功
    ///   - failure: 失败
    func myNodes(
        success: ((_ nodes: [NodeModel]) -> Void)?,
        failure: Failure?)
    
    /// 所有节点
    ///
    /// - Parameters:
    ///   - success: 成功
    ///   - failure: 失败
    func nodes(
        success: @escaping ((_ groups: [NodeCategoryModel]) -> Void),
        failure: Failure?)
}

extension NodeService {

    /// 首页节点
    func homeNodes() -> [NodeModel] {
        var nodes: [NodeModel] = [
            NodeModel(title: "全部", href: "/?tab=all"),
            NodeModel(title: "最热", href: "/?tab=hot"),
            NodeModel(title: "技术", href: "/?tab=tech"),
            NodeModel(title: "创意", href: "/?tab=creative"),
            NodeModel(title: "好玩", href: "/?tab=play"),
            NodeModel(title: "Apple", href: "/?tab=apple"),
            NodeModel(title: "城市", href: "/?tab=city"),
            NodeModel(title: "问与答", href: "/?tab=qna"),
            NodeModel(title: "节点", href: "/?tab=nodes"),
            NodeModel(title: "R2", href: "/?tab=r2"),
            NodeModel(title: "交易", href: "/?tab=deals"),
            NodeModel(title: "酷工作", href: "/?tab=jobs")
        ]

        if FileManager.default.fileExists(atPath: Constants.Keys.homeNodes) {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: Constants.Keys.homeNodes))
                nodes = try JSONDecoder().decode([NodeModel].self, from: data)
            } catch {
                HUD.showTest(error)
                log.error(error)
            }
        }

        if AccountModel.isLogin {
            nodes.append(NodeModel(title: "关注", href: "/?tab=members"))
        }
        return nodes
    }

    func updateHomeNodes(nodes: [NodeModel]) -> Error? {
        do {
            let enc = try JSONEncoder().encode(nodes)
            let error = FileManager.save(enc, savePath: Constants.Keys.homeNodes)
            return error
        } catch {
            HUD.showTest(error)
            log.error(error)
            return error
        }
    }
    
    func resetHomeNodes() {
        guard let error = FileManager.delete(at: Constants.Keys.createTopicNodenameDraft) else { return }
        HUD.showError(error)
        log.info(error)
    }
    
    func nodeNavigation(
        success: ((_ nodeCategorys: [NodeCategoryModel]) -> Void)?,
        failure: Failure?) {
        Network.htmlRequest(target: .topics(href: nil), success: { html in
            let cates = self.parseNodeNavigation(html: html)
            success?(cates)
        }, failure: failure)
    }
    
    
    func nodeDetail(
        page: Int,
        node: NodeModel,
        success: ((_ node: NodeModel, _ topics: [TopicModel], _ maxPage: Int) -> Void)?,
        failure: Failure?) {
        Network.htmlRequest(target: .nodeDetail(href: node.path, page: page), success: { html in
            
            //            let nodeIcon = html.xpath("//*[@id='Main']//div[@class='header']/div/img").first?["src"]
            //            let nodeIntro = html.xpath("//*[@id='Main']//div[@class='header']/span[last()]").first?.content
            //            let topicNumber = html.xpath("//*[@id='Main']//div[@class='header']/div[2]/strong").first?.content
            //            var `node` = node
            //            node.icon = nodeIcon
            //            node.intro = nodeIntro
            //            node.topicNumber = topicNumber

            // 需要验证
            if let error = html.xpath("//*[@id='Main']/div/div//span[@class='negative'][text()]").first?.content {
                failure?("为了节约大家的时间，维护 V2EX 有建设性的技术讨论氛围，在访问部分被移动至限制节点的内容之前，你的账号需要完成以下验证： \n\(error)")
                return
            }

            var `node` = node
            if let title = html.xpath("//*[@id='Wrapper']//div[@class='header']/text()[2]").first?.text?.trimmed {
                node.title = title
            }
            node.favoriteHref = html.xpath("//*[@id='Wrapper']//div[@class='header']/div/a").first?["href"]
            node.isFavorite = node.favoriteHref?.hasPrefix("/unfavorite") ?? false
            let topics = self.parseTopic(html: html, type: .nodeDetail)
            let page = self.parsePage(html: html).max

            // 如果主题数量 == 0， 并且 title == 登录， 代表该节点需要登录才能查看
            if !topics.count.boolValue, node.title == "登录" {
                failure?("查看该节点需要先登录")
                return
            }

            success?(node, topics, page)
        }, failure: failure)
    }
    
    func myNodes(
        success: ((_ nodes: [NodeModel]) -> Void)?,
        failure: Failure?) {
        Network.htmlRequest(target: .myNodes, success: { html in
            let nodes = html.xpath("//*[@id='MyNodes']/a/div").compactMap({ (ele) -> NodeModel? in
                guard let imageSrc = ele.xpath("./img").first?["src"],
                    let comment = ele.xpath("./span").first?.content,
                    let title = ele.parent?.xpath("./div/text()").first?.content,
                    let href = ele.parent?["href"] else {
                        return nil
                }
                return NodeModel(title: title, href: href, icon: imageSrc, comments: comment)
            })
            success?(nodes)
        }, failure: failure)
    }
    
    func nodes(
        success: @escaping ((_ groups: [NodeCategoryModel]) -> Void),
        failure: Failure?) {

        if let groups = NodeCategoryModel.get() {
            success(groups)
            return
        }

        Network.request(target: .nodes, success: { data in
            guard let nodes = NodeModel.nodes(data: data) else {
                failure?("数据解析失败")
                return
            }
            self.nodeSort(nodes, complete: success)
        }, failure: failure)
//        Network.htmlRequest(target: .nodes, success: { html in
//            let nodesPath = html.xpath("//*[@id='Wrapper']/div/div[@class='box']/div[@class='inner']/a")
//            let nodes = nodesPath.flatMap({ ele -> NodeModel? in
//                guard let nodename = ele.content,
//                    let nodeHref = ele["href"] else {
//                        return nil
//                }
//                return NodeModel(name: nodename, href: nodeHref)
//            })
//            success?(nodes)
//        }, failure: failure)
    }
    
    
    /// 将所有 node 排序成组
    ///
    /// - Parameters:
    ///   - nodes: nodes
    ///   - complete: 完成
    private func nodeSort(_ nodes: [NodeModel], complete: @escaping ((_ nodeGroup: [NodeCategoryModel]) -> Void )) {
        guard nodes.count > 0 else { return }

        GCD.runOnBackgroundThread {

            var `nodes` = nodes

            let tempInitial = nodes[0].title.pinYingString.firstLetter
            let currentGroup = NodeCategoryModel(id: 0, name: tempInitial, nodes: [])
            var group: [NodeCategoryModel] = [currentGroup]

            var otherGroup = NodeCategoryModel(id: 0, name: "#", nodes: [])

            for node in nodes {
                let initial = node.title.pinYingString.firstLetter

                //  不放在其他组, 单独一组
                if initial != "", !initial.isLetter() {
                    otherGroup.nodes.append(node)
                    continue
                }

                if let index = group.firstIndex(where: { $0.name == initial }) {
                    group[index].nodes.append(node)
                    continue
                }

                group.append(NodeCategoryModel(id: 0, name: initial, nodes: [node]))
            }

            if otherGroup.nodes.count.boolValue {
                group.append(otherGroup)
            }

            group.sort { (lhs, rhs) -> Bool in
                return lhs.name < rhs.name
            }

            // 缓存排序后的数据
            NodeCategoryModel.save(group)

            GCD.runOnMainThread {
                complete(group)
            }
        }
    }
    

}
