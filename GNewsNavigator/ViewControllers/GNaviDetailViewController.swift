//
//  GNaviDetailViewController.swift
//  GNewsNavigator
//
//  Created by venus.janne on 12/6/15.
//  Copyright © 2015 venus.janne. All rights reserved.
//

import UIKit

class GNaviDetailViewController: UIViewController {
    @IBOutlet var summaryTextView: UITextView!
    @IBOutlet var detailTextView: UITextView!
    @IBOutlet var imageView: UIImageView!

    var currentItem: BlogRss?

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if self.currentItem != nil {
            self.summaryTextView.text = self.currentItem!.title!
            self.summaryTextView.contentInset = UIEdgeInsets.zero
            
            self.detailTextView.text = self.currentItem!.description!
            self.LoadImageData(self.currentItem?.mediaUrl)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    func LoadImageData(_ imgKey:String?) {
        if imgKey == nil {
            return
        }
        let imgChache:[String:Data]? = UserDefaults.standard.object(forKey: "downloadingImgCache") as? [String:Data]
        let imageData:Data? = imgChache![imgKey!]! as Data
        if imageData != nil {
            self.imageView.performSelector(onMainThread: "setImage:", with: UIImage(data: imageData!), waitUntilDone: false)
        }
   }
}
