//
//  GNaviPrefViewController.swift
//  GNewsNavigator
//
//  Created by venus.janne on 12/21/15.
//  Copyright © 2015 venus.janne. All rights reserved.
//

import UIKit

class GNaviPrefViewController: UIViewController, UITableViewDataSource, UITableViewDelegate{

    @IBOutlet var prefTableView: UITableView!
    
    fileprivate var _cellSecTitleArr:[String] = ["Category", "Language", "Detail View", "History"]
    fileprivate let _cellIdArr:[String] = ["kategorioĈelo", "lingvoĈelo", "detaloOpcionĈelo", "historioĈelo"]
    fileprivate let _lingvoKlavoj = ["en", "en-UK", "ja", "zh-CN", "zh-TW"]
    fileprivate let _lingvoVortaro = ["en":"English (US)", "en-UK":"English (UK)", "ja":"日本語 (Japanese)",
        "zh-CN":"簡体中文 (Simplified)", "zh-TW":"繁体中文 (Tradictional)"]
    fileprivate let _detaloKordoj = ["Quick view", "Full view"]
    fileprivate var _kontrolataĈeloA:UITableViewCell?
    fileprivate var _kontrolataĈeloB:UITableViewCell?
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func malbariHistorionAction(_ sender: UIButton) {
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - Private functions
    
    fileprivate func prepareDataSource() {
        
    }
    
    fileprivate func akiriLingvoŜlosiloKodo() -> String {
        var ling: String? = UserDefaults.standard.string(forKey: "language_key")
        if ling == nil {
            ling = (Locale.current as NSLocale).object(forKey: NSLocale.Key.languageCode) as? String
        }
        return ling!
    }
    fileprivate func akiriDetaloVidio() -> String {
        var detalo: String? = UserDefaults.standard.string(forKey: "detalo_vido")
        if detalo == nil {
            detalo = "Quick view"
        }
        return detalo!
    }
}

extension GNaviPrefViewController {
    //MARK: Table View DataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return _cellSecTitleArr[section]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var num = 0
        switch section {
            case 0:
                num = 1
            case 1:
                num = _lingvoVortaro.count
            case 2:
                num = _detaloKordoj.count
            case 3:
                num = 1
            default:
                break
        }
        return num
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellId:String = _cellIdArr[indexPath.section]
        var cell:UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: cellId)
        var label1:UILabel?
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellId)
        }
        
        switch indexPath.section {
        case 1:
            label1 = cell!.contentView.viewWithTag(1) as? UILabel
            label1?.text = _lingvoVortaro[_lingvoKlavoj[indexPath.row]]
            
            if _lingvoKlavoj[indexPath.row] == self.akiriLingvoŜlosiloKodo() {
                cell!.accessoryType = .checkmark
                _kontrolataĈeloA = cell
            }else{
                cell!.accessoryType = .none
            }
        case 2:
            label1 = cell!.contentView.viewWithTag(1) as? UILabel
            label1?.text = _detaloKordoj[indexPath.row]
            
            if _detaloKordoj[indexPath.row] == self.akiriDetaloVidio() {
                cell!.accessoryType = .checkmark
                _kontrolataĈeloB = cell
            }else{
                cell!.accessoryType = .none
            }
        default:
            break
        }
        return cell!
    }

    //MARK: Table View Delegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 3 {
            return 115
        }else {
            return 47
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        if indexPath.section == 1 {
            if _kontrolataĈeloA != nil {
                _kontrolataĈeloA!.accessoryType = .none
                cell!.accessoryType = .checkmark
            }
            
            //teni la kontrolita preferoj.
            UserDefaults.standard.setValue(_lingvoKlavoj[indexPath.row], forKey: "language_key")
            UserDefaults.standard.synchronize()
            _kontrolataĈeloA = cell
            
        }
        if indexPath.section == 2 {
            if _kontrolataĈeloB != nil {
                _kontrolataĈeloB!.accessoryType = .none
                cell!.accessoryType = .checkmark
            }
            
            //teni la kontrolita preferoj.
            UserDefaults.standard.setValue(_detaloKordoj[indexPath.row], forKey: "detalo_vido")
            UserDefaults.standard.synchronize()
            _kontrolataĈeloB = cell
        }
    }
    
}
