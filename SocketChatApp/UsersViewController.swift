//
//  UsersViewController.swift
//  SocketChat
//
//  Created by Gabriel Theodoropoulos on 1/31/16.
//  Copyright © 2016 AppCoda. All rights reserved.
//

import UIKit

class UsersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "idCellUser", for: indexPath) as! UserCell
        
        cell.textLabel?.text = users[indexPath.row]["nickname"] as? String
        cell.detailTextLabel?.text = (users[indexPath.row]["isConnected"] as! Bool) ? "Online" : "Offline"
        cell.detailTextLabel?.textColor = (users[indexPath.row]["isConnected"] as! Bool) ? UIColor.green : UIColor.red
        
        return cell
    }
    

    @IBOutlet weak var tblUserList: UITableView!
    
    
    var users = [[String: AnyObject]]()
    
    var nickname: String!
    
    var configurationOK = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SocketIOManagers.sharedInstance.establishConnection()
        self.navigationController?.isNavigationBarHidden = true

        // Do any additional setup after loading the view.
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !configurationOK {
            configureNavigationBar()
            configureTableView()
            configurationOK = true
        }
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if nickname == nil {
            askForNickname()
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
          if let identifier = segue.identifier {
                  if identifier == "idSegueJoinChat" {
                      let chatViewController = segue.destination as! ChatViewController
                      chatViewController.nickname = nickname
                  }
              }
    }

    
    // MARK: IBAction Methods
    
    @IBAction func exitChat(sender: AnyObject) {
        SocketIOManagers.sharedInstance.exitChatWithNickname(nickname: nickname) { () -> Void in
           DispatchQueue.main.async {
                self.nickname = nil
                self.users.removeAll()
            self.tblUserList.isHidden = true
                self.askForNickname()
            }
        }
    }

    
    
    // MARK: Custom Methods
    
    func configureNavigationBar() {
        navigationItem.title = "SocketChat"
    }
    
    
    func configureTableView() {
        tblUserList.delegate = self
        tblUserList.dataSource = self
        tblUserList.register(UINib(nibName: "UserCell", bundle: nil), forCellReuseIdentifier: "idCellUser")
        tblUserList.isHidden = true
        tblUserList.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    
    func askForNickname() {
        let appearance = SCLAlertView.SCLAppearance(
            kTitleFont: UIFont(name: "HelveticaNeue", size: 20)!,
            kTextFont: UIFont(name: "HelveticaNeue", size: 14)!,
            kButtonFont: UIFont(name: "HelveticaNeue-Bold", size: 14)!,
            showCloseButton: false,
            dynamicAnimatorActive: true
        )
        
        // Initialize SCLAlertView using custom Appearance
        let alert = SCLAlertView(appearance: appearance)
        
        // Creat the subview
        let subview = UIView(frame: CGRect(x: 0,y: 0,width: 216,height: 70))
        let x = (subview.frame.width - 180) / 2
        
        // Add textfield 1
        let textfield = UITextField(frame: CGRect(x: x,y: 10,width: 180,height: 35))
        textfield.layer.borderColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        textfield.layer.borderWidth = 1.5
        textfield.layer.cornerRadius = 5
        textfield.placeholder = "Enter your Name"
        textfield.textAlignment = NSTextAlignment.center
        subview.addSubview(textfield)
        
        // Add the subview to the alert's UI property
        alert.customSubview = subview
        _ = alert.addButton("Enter") {
            if textfield.text?.count == 0 {
                self.askForNickname()
            }
            else {
                self.nickname = textfield.text
                
                SocketIOManagers.sharedInstance.connectToServerWithNickname(nickname: self.nickname, completionHandler: { (userList) -> Void in
                    DispatchQueue.main.async {
                        if userList != nil {
                            self.users = userList!
                            self.tblUserList.reloadData()
                            self.tblUserList.isHidden = false
                        }
                    }
                })
            }
        }
    
        
        _ = alert.showInfo("ChatRoom", subTitle: "Enter Your Username ")
        }
    
    
    // MARK: UITableView Delegate and Datasource methods
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    
    
    
    
    private func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44.0
    }
    
}
