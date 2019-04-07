//
//  TodayViewController.swift
//  HotTopic
//
//  Created by Joe on 2019/3/30.
//  Copyright © 2019 Joe. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
        
    @IBOutlet var tableView: UITableView!
    
    private lazy var activityView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView.init(style: .white)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.hidesWhenStopped = true
        return view
    }()
    
    private var topics: [Topic] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        activityView.startAnimating()
        view.addSubview(activityView)

        NSLayoutConstraint.activate([
            activityView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        
        if #available(iOSApplicationExtension 10.0, *) {
            extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        }

        let hotAPI = "https://www.v2ex.com/api/topics/hot.json"
        
        URLSession.shared.dataTask(with: URL(string: hotAPI
            )!) { [weak self] (data, respose, error) in
                guard let topicsData = data else { return }
                let topics = try? JSONDecoder().decode([Topic].self, from: topicsData)
                self?.topics = topics ?? []
                self?.tableView.reloadData()
                self?.preferredContentSize = self?.tableView.contentSize ?? .zero
                DispatchQueue.main.async {
                    self?.activityView.stopAnimating()
                }
        }.resume()
    }
        
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.newData)
    }
    
    @available(iOSApplicationExtension 10.0, *)
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize){
        if (activeDisplayMode == .compact) {
            preferredContentSize = maxSize
        } else {
            preferredContentSize = tableView.contentSize
        }
    }
}


extension TodayViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
