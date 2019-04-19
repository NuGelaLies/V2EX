//
//  TodayViewController.swift
//  HotTopic
//
//  Created by Joe on 2019/3/30.
//  Copyright © 2019 Joe. All rights reserved.
//

import UIKit
import NotificationCenter

public struct Topic: Codable {
    public let title: String
    //    public let url: String
    public let id: Int
    
    enum CodingKeys: String, CodingKey {
        case title = "title"
        //        case url = "url"
        case id = "id"
    }
    
    public init(title: String, id: Int) {
        self.title = title
        //        self.url = url
        self.id = id
    }
}

class TodayViewController: UIViewController, NCWidgetProviding {
    
    @IBOutlet var tableView: UITableView!
    
    private lazy var activityView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView.init(style: .white)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.hidesWhenStopped = true
        return view
    }()
    
    private var topics: [Topic] = []
    
    
    private let hotAPI = "https://www.v2ex.com/api/topics/hot.json"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOSApplicationExtension 10.0, *) {
            extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        }
        
        activityView.startAnimating()
        view.addSubview(activityView)
        
        NSLayoutConstraint.activate([
            activityView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
    }
    
    private func fetchTopics() {
        URLSession.shared.dataTask(with: URL(string: hotAPI
            )!) { [weak self] (data, respose, error) in
                guard let topicsData = data else { return }
                let topics = try? JSONDecoder().decode([Topic].self, from: topicsData)
                self?.topics = topics ?? []
                
                DispatchQueue.main.async {
                    self?.activityView.stopAnimating()
                    self?.tableView.reloadData()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                        self?.preferredContentSize = self?.tableView.contentSize ?? .zero
                    })
                }
            }.resume()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchTopics()
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        completionHandler(NCUpdateResult.newData)
    }
    
    @available(iOSApplicationExtension 10.0, *)
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize){
        tableView.reloadData()
        if (activeDisplayMode == .compact) {
            preferredContentSize = maxSize
        } else {
            preferredContentSize = tableView.contentSize
        }
    }
}


extension TodayViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if #available(iOSApplicationExtension 10.0, *) {
            let isCompact = extensionContext?.widgetActiveDisplayMode == .compact
            
            tableView.rowHeight = isCompact ? (extensionContext?.widgetMaximumSize(for: .compact) ?? preferredContentSize).height / 3 : 44;
        } else {
            tableView.rowHeight = preferredContentSize.height / 4
        }
        return topics.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TopicCell")!
        let topic = topics[indexPath.row]
        cell.textLabel?.text = topic.title
        cell.textLabel?.numberOfLines = 2
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let topic = topics[indexPath.row]
        guard let url = URL(string: "v2er://topic?id=\(topic.id)") else {
            return
        }
        extensionContext?.open(url, completionHandler: nil)
    }
}
