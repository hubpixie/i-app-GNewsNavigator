//
//  ViewController.swift
//  GNewsNavigator
//
//  Created by venus.janne on 11/23/15.
//  Copyright © 2015 venus.janne. All rights reserved.
//

import UIKit

let IMAGE_CACHE_FILE_COUNT = 300
//let RIGHT_COLUMN_OFFSET:CGFloat = 240.0
let ROW_HEIGHT: CGFloat = 56
let MAIN_FONT_SIZE = 15.0
let DETAIL_FONT_SIZE = 26.0
let IMAGE_SIDE: CGFloat = 55.0
var TO_PUBDATE_FORMAT: String = "MM/dd HH:mm"
var TOPIC_KIND: [String] = ["Top Stories", "World", "Politics", "Business", "Tech", "Sports", "Social", "Topic"]

class GNaviViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,
UIActionSheetDelegate, BlogRssParserDelegate, UISearchBarDelegate, UIAlertViewDelegate {
    @IBOutlet var rssParser: BlogRssParser!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var toolbar: UIToolbar!
    @IBOutlet var scrollToolbar: UIScrollView!
    @IBOutlet var menuButton:UIBarButtonItem!
    
    fileprivate var _curTopicKindCode:Int = 1
    fileprivate var _appDelegate: GNaviAppDelegate?
    fileprivate var _actionButton: UIBarButtonItem?
    fileprivate var _actionButton2: UIBarButtonItem?
    fileprivate var _topicTitleLabel: UILabel?
    fileprivate var _downloadingImgCache:[String:Data]? = [:]
    fileprivate var __textToSearch:String?
    
    var viewRefreshed: Bool {
        get {
            return self.viewRefreshed
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if revealViewController() != nil {
            //            revealViewController().rearViewRevealWidth = 62
            //            menuButton.target = revealViewController()
            //            menuButton.action = "revealToggle:"
            
            revealViewController().rightViewRevealWidth = 150
            menuButton.target = revealViewController()
            menuButton.action = "rightRevealToggle:"
            
            view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        
        //setup toolbar
        self.setupToolbar()

        
        self.rssParser = BlogRssParser()
        self.rssParser.delegate = self
        self.rssParser.refreshChanges()
        self.rssParser.startProcess()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
        let indexPath = self.tableView.indexPathForSelectedRow
        if indexPath != nil {
            if self.rssParser.rssItems.count > 0 {
                let vc:GNaviDetailViewController? = segue.destination as? GNaviDetailViewController
                if vc != nil {
                    vc!.currentItem = self.rssParser.rssItems[indexPath!.row]
                }
            }
        }
    }
    
    
//MARK: Toolbar
    fileprivate func setupToolbar() {
        let screen = UIScreen.main.bounds.size
        var x:CGFloat = 0.0
        let y0:CGFloat = self.scrollToolbar.frame.origin.y + self.scrollToolbar.frame.size.height - 6
        let button0:UIButton = self.scrollToolbar.viewWithTag(1) as! UIButton
        if UserDefaults.standard.object(forKey: "topic_kind_code") != nil {
            _curTopicKindCode = UserDefaults.standard.integer(forKey: "topic_kind_code")
        }
        
        for ii in 0 ..< TOPIC_KIND.count {
            let button   = UIButton(type:UIButtonType.system)
            button.frame = button0.frame
            button.frame.origin.x = x
            button.frame.origin.y = screen.height - y0
            x += 72.0
            
            if _curTopicKindCode == ii + 1 {
                button.backgroundColor = UIColor(red: 0x40/255, green: 0xE0/255, blue: 0xD0/255, alpha:1.0 )
            }else{
                button.backgroundColor = UIColor.groupTableViewBackground
            }
            button.setTitle(TOPIC_KIND[ii], for: UIControlState())
            button.addTarget(self, action: "toolButtonAction:", for: UIControlEvents.touchUpInside)
            button.titleLabel!.font =  UIFont(name: button.titleLabel!.font!.fontName, size: 12)
            button.tag = ii + 1
            self.scrollToolbar.addSubview(button)
            self.scrollToolbar.contentSize = CGSize(width: CGFloat((ii + 1) * 72), height: 50)
        }
        self.scrollToolbar.showsVerticalScrollIndicator = false
        button0.removeFromSuperview()
        
    }
    
    func toolButtonAction(_ sender:UIButton!) {
        var topicKind: String? = nil
        switch sender.tag - 1 {
        case 0:
            //Top Stories
            topicKind = "h"
        case 1:
            //World
            topicKind = "w"
        case 2:
            //Politics
            topicKind = "p"
        case 3:
            //Buniess
            topicKind = "b"
        case 4:
            //Tech
            topicKind = "t"
        case 5:
            //Sports
            topicKind = "s"
        case 6:
            //Social
            topicKind = "y"
        case 7:
            //Topics
            topicKind = "po"
        default: break
        }
        if topicKind != nil {
            var button:UIButton = self.scrollToolbar.viewWithTag(_curTopicKindCode) as! UIButton
            button.backgroundColor = UIColor.groupTableViewBackground

            button = scrollToolbar.viewWithTag(sender.tag) as! UIButton
            button.backgroundColor = UIColor(red: 0x40/255, green: 0xE0/255, blue: 0xD0/255, alpha:1.0 )
            _curTopicKindCode = sender.tag
            
            UserDefaults.standard.setValue(_curTopicKindCode, forKey: "topic_kind_code")
            UserDefaults.standard.setValue(topicKind, forKey: "topic_key")
            self.reloadRss()
        }
//        }
//        else {
//            let backButton = UIBarButtonItem(title: "< Back", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
//            self.navigationItem.backBarButtonItem = backButton
//            var alert: UIAlertView? = nil
//            var infoDictionary: [String : AnyObject]? = NSBundle.mainBundle().infoDictionary
//            let minorVersion: String = infoDictionary?["CFBundleVersion"] as! String
//            
//            switch buttonIndex {
//            case 0:
//                //Preferences
//                //TODO                _appDelegate.showNaviPrefView()
//                break
//            case 1:
//                //About
//                //[NSString stringWithFormat:@"Version %@ (%@)", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"], kRevisionNumber]
//                alert = UIAlertView(title: "Google News Navigator", message: "Version (\(minorVersion))\n\n Copyright 2013 pixie.", delegate: self, cancelButtonTitle: "OK")
//                alert!.show()
//            default: break
//            }
//        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        self.setupToolbar()
        self.tableView.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //    [self.tableView stopLoading];
        self.tableView.delegate = nil
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
//        if UI_USER_INTERFACE_IDIOM() == .Pad {
//            if _actionSheet!.visible {
//                _actionSheet!.dismissWithClickedButtonIndex(-1, animated: false)
//            }
//        }
        
        //save some data
        let userDeft = UserDefaults.standard
        if _downloadingImgCache != nil {
            userDeft.set(_downloadingImgCache, forKey: "downloadingImgCache")
            userDeft.synchronize()
        }
    }
    
    override var shouldAutorotate : Bool {
        return true
    }
    
    func reloadRss() {
        self.rssParser.refreshChanges()
        self.toggleToolBarButtons(false)
        self.rssParser.startProcess()
    }
    
    func toggleToolBarButtons(_ newState: Bool) {
//        let toolbarItems: [UIBarButtonItem]? = self.toolbar.items
//        for item: UIBarButtonItem in toolbarItems! {
//            item.enabled = newState
//        }
    }

    func resetTitleAreaNavItems(_ sender: AnyObject) {
        let titleLabel:UILabel = UILabel()
        titleLabel.text = "News Selection"
        titleLabel.sizeToFit()
        self.navigationItem.titleView = titleLabel
        //
        //Search Button Item
        //
        let searchButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: "goSearching:")
        //
        //Info Button Item
        //
        let prefButton: UIBarButtonItem = UIBarButtonItem(title: "≡", style: .plain, target: self, action: "showPrefMenu:")
        let normalAttributes:[String : AnyObject]? = [
            NSFontAttributeName : UIFont(name: "Helvetica-Bold", size: 26.0)!
        ]
        
        //Helvetica-Bold
        _actionButton2 = prefButton
        //    [self.navigationItem setRightBarButtonItem:prefButton animated:YES];
        let navItemArray: [UIBarButtonItem]? = [prefButton, searchButton]
        //self.navigationItem.leftBarButtonItem = nil
        self.navigationItem.setRightBarButtonItems(navItemArray, animated: true)
        self.navigationItem.rightBarButtonItem!.setTitleTextAttributes(normalAttributes, for: UIControlState())
    }
    
//@end
}

//-----------------------------------
// MARK: BlogRssParserDelegate
//-----------------------------------
extension GNaviViewController {
    //Delegate method for blog parser will get fired when the process is completed
    func processCompleted() {
        //reload the table view
        self.toggleToolBarButtons(true)
        self.tableView.reloadData()
    }
    
    func processHasErrors() {
        //Might be due to Internet

//        let alert: UIAlertView = UIAlertView(title: "Google News Navigator", message: "Unable to download rss. Please check if you are connected to internet.",
//            delegate: nil, cancelButtonTitle: "OK", otherButtonTitles: "")
//        alert.show()
        AppUtil.showInfoView(self, message: "Unable to download rss. Please check if you are connected to internet.", caption: "Easy News Navigator")
        self.toggleToolBarButtons(true)
    }
}

//-----------------------------------
// MARK: UITableViewDataSource, UITableViewDelegate
//-----------------------------------
extension GNaviViewController {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.rssParser.rssItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell? = nil
        var summaryLabel: UILabel? = nil
        var detailLabel: UILabel? = nil
        var contWidth: CGFloat = 280
        let cellId: String = "cell" //"rssItemCell_\(indexPath.row)_\(indexPath.section)"
        ////   @try {
        //description
        let pubDate: Date = self.rssParser.rssItems[indexPath.row].pubDate!
        let pubDateStr: String = self.getLocalDateFromGMT(pubDate, dateFormat: TO_PUBDATE_FORMAT)
        let imageUrl: String? = self.rssParser.rssItems[indexPath.row].mediaUrl
        let detailValue: String = self.rssParser.rssItems[indexPath.row].description!
        if imageUrl != nil || indexPath.row != 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: cellId)
        }
        if nil == cell {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellId)
            contWidth = cell!.frame.size.width - 2
            summaryLabel = UILabel(frame: CGRect(x: 2, y: 0, width: contWidth, height: ROW_HEIGHT))
            //make Your alignments to this label
            summaryLabel!.tag = 2010
            summaryLabel!.font = UIFont.boldSystemFont(ofSize: 11.0)
            summaryLabel!.numberOfLines = 3
            summaryLabel!.lineBreakMode = NSLineBreakMode.byWordWrapping
            //summaryLabel.attributedText = attributedText;
            //make Your alignments to this detail label
            detailLabel = UILabel(frame: CGRect(x: 2, y: ROW_HEIGHT, width: contWidth, height: ROW_HEIGHT / 2))
            detailLabel!.tag = 2012
            detailLabel!.font = UIFont.systemFont(ofSize: 11.0)
            detailLabel!.numberOfLines = 2
            detailLabel!.lineBreakMode = NSLineBreakMode.byTruncatingTail
            //detailLabel.attributedText = attributedText;
            cell!.contentView.addSubview(summaryLabel!)
            cell!.contentView.addSubview(detailLabel!)
        }
        else {
            summaryLabel = cell!.viewWithTag(2010) as? UILabel
            detailLabel = cell!.viewWithTag(2012)  as? UILabel
        }
        if imageUrl != nil {
            contWidth = self.view.bounds.width - 90
        }
        var textFrame: CGRect = summaryLabel!.frame
        var detaiLabelFrame: CGRect = detailLabel!.frame
        let summaryString: String = self.rssParser.rssItems[indexPath.row].title!
        let detailString: String = "[" + pubDateStr + "] - " + detailValue
        var attrString: NSMutableAttributedString? = nil
        textFrame.size.width = contWidth
        detaiLabelFrame.size.width = contWidth
        summaryLabel!.frame = textFrame
        detailLabel!.frame = detaiLabelFrame
        //~~ summaryLabel.text = [[[[self rssParser]rssItems]objectAtIndex:indexPath.row]title];
        //~~ detailLabel.text = [NSString stringWithFormat:@"[%@] - %@", pubDateStr, detailValue];
        attrString = self.fetchSearchResult(summaryString)
        if attrString != nil {
            summaryLabel!.attributedText = nil
            summaryLabel!.attributedText = attrString
        }
        else {
            summaryLabel!.text = summaryString
        }
        attrString = self.fetchSearchResult(detailString)
        if attrString != nil {
            detailLabel!.attributedText = nil
            detailLabel!.attributedText = attrString
        }
        else {
            detailLabel!.text = detailString
        }
        cell!.accessoryType = .none
        self.loadImageData(indexPath)
        ////    }
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //let backButton = UIBarButtonItem(title: "< Back", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        //self.navigationItem.leftBarButtonItem = backButton
        //self.navigationItem.backBarButtonItem = backButton
    }

    
    func loadImageData(_ indexPath: IndexPath) {
        func cellImgBlock(_ imageData:Data)->Void {
            let image = UIImage(data: imageData)
            let cell: UITableViewCell? = self.tableView.cellForRow(at: indexPath)
            if cell != nil {
                var imageView: UIImageView? = cell!.contentView.viewWithTag(2020) as? UIImageView
                if imageView == nil {
                    imageView = self.setSubImageView()
                    if imageView != nil {
                        imageView!.tag = 2020
                        cell!.contentView.addSubview(imageView!)
                    }
                }
                imageView!.performSelector(onMainThread: "setImage:", with: image, waitUntilDone: false)
            }
        }
        
        let imageUrl: String? = self.rssParser.rssItems[indexPath.row].mediaUrl
        if imageUrl == nil {
            return
        }
        
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async {
            let imgData:Data? = self._downloadingImgCache?[imageUrl!] as Data?
            if imgData != nil {
                DispatchQueue.main.async {
                    cellImgBlock(imgData!)
                }
            }
            else {
                if let url = URL(string: imageUrl!) {
                    URLSession.shared.dataTask(with: url, completionHandler: { data, response, error in
                        guard let data = data, error == nil else {
                            print("\nerror on download \(error)")
                            return
                        }
                        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                            //print("statusCode != 200; \(httpResponse.statusCode)")
                            return
                        }
                        DispatchQueue.main.async {
                            //print("\ndownload completed \(url.lastPathComponent!)")
                            //image = UIImage(data: data)
                            self._downloadingImgCache!.updateValue(data, forKey: imageUrl!)
                            cellImgBlock(data)
                        }
                    }) .resume()
                }
            }
            
        }
    }
    
    func setSubImageView() -> UIImageView {
        var rect: CGRect
        rect = CGRect(x: self.view.bounds.width - 85, y: (ROW_HEIGHT - IMAGE_SIDE) + 15, width: IMAGE_SIDE + 20, height: IMAGE_SIDE)
        let imageView: UIImageView = UIImageView(frame: rect)
        return imageView
    }
/*
    func parseImageDataAsFile(url: String?) -> UIImage? {
        var image: UIImage? = nil
    
        if url == nil {
            return image
        }
        ////    @try {
        let urlObj: NSURL? = NSURL(string: url!)
        if urlObj == nil {
            return image
        }
        var paths: [String] = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let documentsDirectory: String = paths[0]
        let fname: String? = "\(url!.stringByDeletingLastPathComponent.lastPathComponent)\(url!.lastPathComponent)" as String?
        if fname == nil {
            return image
        }
        let localFilePath: String = documentsDirectory.stringByAppendingPathComponent(fname!)
        //If cache images are more than IMAGE_CACHE_FILE_COUNT
        // PG clear them.
        if _downloadedImgList.count > IMAGE_CACHE_FILE_COUNT {
            let fileManager: NSFileManager = NSFileManager.defaultManager()
            var fpath: String? = nil
            for fn: AnyObject in _downloadedImgList {
                fpath = documentsDirectory.stringByAppendingPathComponent(fn as! String)
                try! fileManager.removeItemAtPath(fpath!)
            }
        }
        //
        //Save file name & data.
        //
    
        if !_downloadedImgList.contains(fname!) {
            let request: NSURLRequest = NSURLRequest(URL: urlObj!)
            try! NSURLConnection(request: request, delegate: nil)
            let thedata: NSData = NSData(contentsOfURL:urlObj!)!
            if thedata.writeToFile(localFilePath, atomically: true) {
                _downloadedImgList.append(fname!)
            }
        }
        image = UIImage(contentsOfFile: localFilePath)
        ////    }@catch (NSException * ex) {
        //
        ////   }
        return image
    }
    */
    func getLocalDateFromGMT(_ date: Date, dateFormat formatStr: String) -> String {
        let df: DateFormatter = DateFormatter()
        df.dateFormat = formatStr
        //    [df setTimeZone:[NSTimeZone systemTimeZone]];
        let retDateStr: String = df.string(from: date)
        return retDateStr
    }
    
}

//-----------------------------------
// MARK: UIActionSheetDelegate
//-----------------------------------
/*
extension GNaviViewController {
    func showTopicMenu(sender: AnyObject) {
        if actionSheet().visible {
            _actionSheet!.dismissWithClickedButtonIndex(-1, animated: false)
        }
        else {
            if UI_USER_INTERFACE_IDIOM() == .Pad {
                _actionSheet!.showFromBarButtonItem(_actionButton!, animated: false)
            }
            else {
                _actionSheet!.showInView(self.view)
            }
        }
    }
    
    func showPrefMenu(sender: AnyObject) {
        if actionSheet().visible {
            _actionSheet2!.dismissWithClickedButtonIndex(-1, animated: false)
        }
        else {
            if UI_USER_INTERFACE_IDIOM() == .Pad {
                _actionSheet2!.showFromBarButtonItem(_actionButton2!, animated: false)
            }
            else {
                //[self.actionSheet2 showInView:[[self navigationController] navigationBar ]];
                _actionSheet2!.showFromBarButtonItem(_actionButton2!, animated: false)
            }
        }
    }
    
    
    func actionSheet() -> UIActionSheet {
        if _actionSheet == nil {
            var cancelButtonTitle: String? = "Cancel"
            if UI_USER_INTERFACE_IDIOM() == .Pad {
                cancelButtonTitle = nil
            }
            _actionSheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: cancelButtonTitle, destructiveButtonTitle: nil, otherButtonTitles: TOPIC_KIND[0], TOPIC_KIND[1], TOPIC_KIND[2], TOPIC_KIND[3], TOPIC_KIND[4], TOPIC_KIND[5], TOPIC_KIND[6], TOPIC_KIND[7])
            _actionSheet!.actionSheetStyle = .BlackTranslucent
            _actionSheet!.clipsToBounds = true
        }
        return _actionSheet!
    }
    
    func actionSheet2() -> UIActionSheet {
        if _actionSheet2 == nil {
            var cancelButtonTitle: String? = "Cancel"
            if UI_USER_INTERFACE_IDIOM() == .Pad {
                cancelButtonTitle = nil
            }
            _actionSheet2 = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: cancelButtonTitle, destructiveButtonTitle: nil, otherButtonTitles: "Settings", "About")
            _actionSheet2!.actionSheetStyle = .BlackTranslucent
            _actionSheet2!.clipsToBounds = true
        }
        return _actionSheet2!
    }
    
}
*/

//-----------------------------------
// MARK: UISearchBarDelegate
//-----------------------------------
extension GNaviViewController {
    func goSearching(_ sender: AnyObject) {
        let searchBar: UISearchBar = UISearchBar(frame: CGRect(x: -5.0, y: 0.0, width: 320.0, height: 36.0))
        searchBar.autoresizingMask = .flexibleWidth
        searchBar.showsCancelButton = true
        for searBarView: UIView in searchBar.subviews {
            for subView: UIView in searBarView.subviews {
                if subView.isKind(of: UIButton.self) {
                    let cancleButton: UIButton = subView as! UIButton
                    cancleButton.setTitle("Done", for: UIControlState())
                }
            }
        }
        let searchBarView: UIView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 310.0, height: 36.0))
        searchBarView.autoresizingMask = UIViewAutoresizing()
        searchBar.delegate = self
        searchBarView.addSubview(searchBar)
        self.navigationItem.rightBarButtonItems = nil
        self.navigationItem.titleView = searchBarView
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.resetTitleAreaNavItems(searchBar)
        __textToSearch = nil
        self.tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        __textToSearch = searchBar.text
        if __textToSearch != nil {
            self.tableView.reloadData()
        }
    }
    
    func fetchSearchResult(_ textToSearch: String) -> NSMutableAttributedString? {
        var retAttrText: NSMutableAttributedString? = nil
        let nsText:NSString = textToSearch as NSString
        
        if __textToSearch == nil {
            return retAttrText
        }
        var rangeSearched: NSRange = nsText.range(of: __textToSearch!, options: NSString.CompareOptions.caseInsensitive)
        if rangeSearched.location == NSNotFound {
            return retAttrText
        }
        retAttrText = NSMutableAttributedString(string: textToSearch)
        rangeSearched = NSMakeRange(0, nsText.length)
        var keepGoing: Bool = true
        let searchLen: Int = __textToSearch!.characters.count
        // Find all ssid
        while keepGoing {
            let subRangeSearched: NSRange = nsText.range(of: __textToSearch!, options: NSString.CompareOptions.caseInsensitive, range: rangeSearched)
            if subRangeSearched.location != NSNotFound {
                // since we have found the access key, we can assume somethings
                let pos: Int = subRangeSearched.location + searchLen + 1
                //NSString *ssid = [textToSearch substringWithRange:NSMakeRange(pos, pos + searchLen)];
                retAttrText!.addAttribute(NSFontAttributeName, value: UIFont(name: "Helvetica-Bold", size: 13)!, range: subRangeSearched)
                retAttrText!.addAttribute(NSBackgroundColorAttributeName, value: UIColor.orange, range: subRangeSearched)
                // reset our search up a little for our next loop around
                rangeSearched = NSMakeRange(pos, nsText.length - pos)
            }
            else {
                keepGoing = false
            }
        }
        //    [attrText addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"Helvetica-Bold" size:13] range:rangeSearched];
        //    [attrText addAttribute:NSBackgroundColorAttributeName value:[UIColor orangeColor] range:rangeSearched];

        return retAttrText
    }
    
    
}

