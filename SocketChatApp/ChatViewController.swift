//
//  ChatViewController.swift
//  SocketChat
//
//  Created by Gabriel Theodoropoulos on 1/31/16.
//  Copyright © 2016 AppCoda. All rights reserved.
//

import UIKit

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UIGestureRecognizerDelegate {
    
    
    @IBOutlet weak var viewContainer: UIView!
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "idCellChat", for: indexPath as IndexPath) as! ChatCell
        cell.layer.cornerRadius = 6
        let currentChatMessage = chatMessages[indexPath.row]
        let senderNickname = currentChatMessage["nickname"]!
        let message = currentChatMessage["message"]!
        let messageDate = currentChatMessage["date"]!
        
        if senderNickname == nickname {
            cell.lblChatMessage.textAlignment = NSTextAlignment.right
            cell.lblMessageDetails.textAlignment = NSTextAlignment.right
            
            cell.lblChatMessage.textColor = lblNewsBanner.backgroundColor
        }
        
        cell.lblChatMessage.text = message
        cell.lblMessageDetails.text = "by \(senderNickname.uppercased()) @ \(messageDate)"
        
        cell.lblChatMessage.textColor = UIColor.darkGray
        
        return cell
    }
    

    @IBOutlet weak var tblChat: UITableView!
    
    @IBOutlet weak var lblOtherUserActivityStatus: UILabel!
    
    @IBOutlet weak var tvMessageEditor: UITextView!
    
    @IBOutlet weak var conBottomEditor: NSLayoutConstraint!
    
    @IBOutlet weak var lblNewsBanner: UILabel!
    
    
    
    var nickname: String!
    
    var chatMessages = [[String: String]]()
    
    var bannerLabelTimer: Timer!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.keyboardDidShow(notification:)),
            name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.keyboardDidHide(notification:)),
            name: UIResponder.keyboardDidHideNotification, object: nil)
        
        NotificationCenter.default.addObserver(self,   selector: #selector(self.handleConnectedUserUpdateNotification(notification:)), name: NSNotification.Name(rawValue: "userWasConnectedNotification"), object: nil)
       
        
        NotificationCenter.default.addObserver(self,  selector: #selector(self.handleDisconnectedUserUpdateNotification(notification:)), name: NSNotification.Name(rawValue: "userWasDisconnectedNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleUserTypingNotification(notification:)), name: NSNotification.Name(rawValue: "userTypingNotification"), object: nil)
        
        
        let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        swipeGestureRecognizer.direction = UISwipeGestureRecognizer.Direction.down
        swipeGestureRecognizer.delegate = self
        view.addGestureRecognizer(swipeGestureRecognizer)
        
        viewContainer.layer.cornerRadius = 6
    }

     @objc func keyboardDidShow(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let keyboardFrame = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
                conBottomEditor.constant = keyboardFrame.size.height
                view.layoutIfNeeded()
            }
        }
    }

    @objc func keyboardDidHide(notification: NSNotification) {
        conBottomEditor.constant = 0
        view.layoutIfNeeded()
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureTableView()
        configureNewsBannerLabel()
        configureOtherUserActivityLabel()
        
        tvMessageEditor.delegate = self
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        SocketIOManagers.sharedInstance.getChatMessage { (messageInfo) -> Void in
            DispatchQueue.main.async {
                self.chatMessages.append(messageInfo)
                self.tblChat.reloadData()
                self.scrollToBottom()
            }
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    
    // MARK: IBAction Methods
    
    @IBAction func sendMessage(sender: AnyObject) {
        if tvMessageEditor.text.count > 0 {
            SocketIOManagers.sharedInstance.sendMessage(message: tvMessageEditor.text!, withNickname: nickname)
            tvMessageEditor.text = ""
            tvMessageEditor.resignFirstResponder()
        }
    }

    
    // MARK: Custom Methods
    
    func configureTableView() {
        tblChat.delegate = self
        tblChat.dataSource = self
        tblChat.register(UINib(nibName: "ChatCell", bundle: nil), forCellReuseIdentifier: "idCellChat")
        tblChat.estimatedRowHeight = 90.0
        tblChat.rowHeight = UITableView.automaticDimension
        tblChat.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    
    @IBAction func backBtnTapped(_ sender: Any) {
        if self.presentingViewController != nil {
            self.dismiss(animated: false, completion: {
               self.navigationController!.popToRootViewController(animated: true)
            })
        }
        else {
            self.navigationController!.popToRootViewController(animated: true)
        }
    }
    func configureNewsBannerLabel() {
        lblNewsBanner.layer.cornerRadius = 15.0
        lblNewsBanner.clipsToBounds = true
        lblNewsBanner.alpha = 0.0
    }
    
    
    func configureOtherUserActivityLabel() {
        lblOtherUserActivityStatus.isHidden = true
        lblOtherUserActivityStatus.text = ""
    }
    
    
    func scrollToBottom() {
        let delay = 0.1 * Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: UInt64(delay))) {
            if self.chatMessages.count > 0 {
                let lastRowIndexPath = NSIndexPath(row: self.chatMessages.count - 1, section: 0)
                self.tblChat.scrollToRow(at: lastRowIndexPath as IndexPath, at: UITableView.ScrollPosition.bottom, animated: true)
            }
        }
    }
    
    
    func showBannerLabelAnimated() {
        UIView.animate(withDuration: 0.75, animations: { () -> Void in
            self.lblNewsBanner.alpha = 1.0
            
            }) { (finished) -> Void in
            self.bannerLabelTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: Selector(("hideBannerLabel")), userInfo: nil, repeats: false)
        }
    }
    
    
    func hideBannerLabel() {
        if bannerLabelTimer != nil {
            bannerLabelTimer.invalidate()
            bannerLabelTimer = nil
        }
        
        UIView.animate(withDuration: 0.75, animations: { () -> Void in
            self.lblNewsBanner.alpha = 0.0
            
            }) { (finished) -> Void in
        }
    }

    
    
    func dismissKeyboard() {
        if tvMessageEditor.isFirstResponder {
            tvMessageEditor.resignFirstResponder()
            
            SocketIOManagers.sharedInstance.sendStopTypingMessage(nickname: nickname)
        }
    }
    
    
    @objc func handleConnectedUserUpdateNotification(notification: NSNotification) {
        let connectedUserInfo = notification.object as! [String: AnyObject]
        let connectedUserNickname = connectedUserInfo["nickname"] as? String
        lblNewsBanner.text = "User \(connectedUserNickname!.uppercased()) was just connected."
        showBannerLabelAnimated()
    }
    
    
    @objc func handleDisconnectedUserUpdateNotification(notification: NSNotification) {
        let disconnectedUserNickname = notification.object as! String
        lblNewsBanner.text = "User \(disconnectedUserNickname.uppercased()) has left."
        showBannerLabelAnimated()
    }
    
    
    @objc func handleUserTypingNotification(notification: NSNotification) {
        if let typingUsersDictionary = notification.object as? [String: AnyObject] {
            var names = ""
            var totalTypingUsers = 0
            for (typingUser, _) in typingUsersDictionary {
                if typingUser != nickname {
                    names = (names == "") ? typingUser : "\(names), \(typingUser)"
                    totalTypingUsers += 1
                }
            }
            
            if totalTypingUsers > 0 {
                let verb = (totalTypingUsers == 1) ? "is" : "are"
                
                lblOtherUserActivityStatus.text = "\(names) \(verb) now typing a message..."
                lblOtherUserActivityStatus.isHidden = false
            }
            else {
                lblOtherUserActivityStatus.isHidden = true
            }
        }
        
    }
    
    
    // MARK: UITableView Delegate and Datasource Methods
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatMessages.count
    }
    
    
   
    
    
    // MARK: UITextViewDelegate Methods
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        SocketIOManagers.sharedInstance.sendStartTypingMessage(nickname: nickname)
        
        return true
    }

    
    // MARK: UIGestureRecognizerDelegate Methods
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}

