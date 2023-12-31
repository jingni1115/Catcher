//
//  ChatViewController.swift
//  Catcher
//
//  Created by 김지은 on 2023/10/18.
//

import UIKit
import FirebaseAuth

/**
 @class ChatViewController.swift
 
 @brief UIViewController
 
 @detail TabBar 채팅 탭 화면 채팅 리스트를 불러온다.
 */
class ChatViewController: UIViewController {
    /// 데이터
    private var conversations = [Conversation]()

    /// Conversation tableview
    private let tbvConversation: UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(ConversationTableViewCell.self,
                       forCellReuseIdentifier: ConversationTableViewCell.identifier)
        return table
    }()

    /// 대화가 없을 때 나오는 label
    private let noConversationsLabel: UILabel = {
        let label = UILabel()
        label.text = "대화를 시작해 보세요."
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        return label
    }()
    
    private let indicator = UIActivityIndicatorView()
    
    private lazy var indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .black.withAlphaComponent(0.5)
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ThemeColor.backGroundColor
        view.addSubview(tbvConversation)
        view.addSubview(noConversationsLabel)
        setupTableView()
        
        // 뷰가 로드될 때 대화를 듣기 시작
        startListeningForCOnversations()
        
        setIndicatorLayout()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tbvConversation.frame = view.bounds
        noConversationsLabel.frame = CGRect(x: 10,
                                            y: (view.height-100)/2,
                                            width: view.width-20,
                                            height: 100)
    }

    private func setupTableView() {
        tbvConversation.delegate = self
        tbvConversation.dataSource = self
    }

    func setIndicatorLayout() {
        indicatorView.addSubview(indicator)
        
        view.addSubview(indicatorView)
        
        indicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        indicatorView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        indicator.hidesWhenStopped = true
        indicator.stopAnimating()
        indicator.style = .large
        indicator.color = .systemOrange
        indicatorView.isHidden = true
    }
    
    func processIndicatorView() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            indicatorView.isHidden.toggle()
            if indicator.isAnimating {
                indicator.stopAnimating()
            } else {
                indicator.startAnimating()
            }
        }
    }
}
//MARK: list 불러옴
extension ChatViewController {
    // 대화를 가져와서 표시하기
    private func startListeningForCOnversations() {
        CommonUtil.print(output:"starting conversation fetch...")
        // 데이터베이스에서 대화 가져오기
        DatabaseManager.shared.getAllConversations(completion: { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let conversations):
                CommonUtil.print(output:"successfully got conversation models")
                guard !conversations.isEmpty else {
                    tbvConversation.isHidden = true
                    noConversationsLabel.isHidden = false
                    return
                }
                noConversationsLabel.isHidden = true
                tbvConversation.isHidden = false
                self.conversations = conversations

                DispatchQueue.main.async {
                    self.tbvConversation.reloadData()
                }
            case .failure(let error):
                tbvConversation.isHidden = true
                noConversationsLabel.isHidden = false
                CommonUtil.print(output:"failed to get convos: \(error)")
            }
        })
    }
}
// MARK: Chatting List TableView 설정
extension ChatViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = conversations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier,
                                                 for: indexPath) as! ConversationTableViewCell
        cell.configure(with: model)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = conversations[indexPath.row]
        openConversation(model)
    }

    func openConversation(_ model: Conversation) {
        let vc = ChattingDetailViewController(otherUid: model.otherUserUid)
        vc.title = model.name
        vc.headerTitle = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}
