//
//  ViewController.swift
//  fintechTinkoffLab
//
//  Created by Jack Sp@rroW on 25/01/2019.
//  Copyright © 2019 Jack Sp@rroW. All rights reserved.
//  stepanet

import UIKit

struct Company: Decodable {
    let symbol: String
    let companyName: String
}




class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    
    var company = [Company]()
    var companyNameBtn: String?
    
    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var companySymbolLabel: UILabel!
    @IBOutlet weak var companyLogo: UIImageView!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var priceChangeLabel: UILabel!
    @IBOutlet weak var companyPickerView: UIPickerView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var changePriceLogo: UIImageView!
    @IBOutlet weak var threeLineView: UIView!
    
    //btn
    @IBOutlet weak var buyBtn: UIButton!
    @IBOutlet weak var sellBtn: UIButton!
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        companyNameLabel.text = "Tinkoff"
        self.companyLogo.layer.cornerRadius = companyLogo.bounds.height / 2
        self.companyPickerView.dataSource = self
        self.companyPickerView.delegate = self
        self.companyPickerView.tintColor = UIColor.yellow
        self.changePriceLogo.image = UIImage(named: "")
        self.activityIndicator.hidesWhenStopped = true
        
        self.buyBtn.isHidden = true
        self.sellBtn.isHidden = true
        self.buyBtn.layer.cornerRadius = 15 //buyBtn.bounds.height / 2
        self.sellBtn.layer.cornerRadius = 15 //sellBtn.bounds.height / 2
        self.companyLoadJson()

        
    }
    
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.company[row].companyName
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.company.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        requestQouteUpdate()
    }
    
    //MARK: change color picker
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let titleData =  self.company[row].companyName
        let myTitle = NSAttributedString(string: titleData, attributes: [NSAttributedString.Key.foregroundColor: UIColor.yellow])
        return myTitle
    }
    
    
    
    //MARK: load company name from infolist
    public func companyLoadJson() {

            let url = URL(string: "https://api.iextrading.com/1.0/stock/market/list/infocus")
        
            //let url = URL(string: "https://api.iextrading.com/1.0/stock/market/list/mostactive")
            URLSession.shared.dataTask(with: url!) { (data, response, error) in
                if error == nil {
                    
                    do {
                        self.company = try JSONDecoder().decode([Company].self, from: data!)
                        self.company = self.company.sorted(by: { $0.companyName < $1.companyName })
                    } catch {
                        print("load Json company error")
                    }
                }

                DispatchQueue.main.async {
                    self.requestQouteUpdate()
                }
         
                }.resume()
    }
    

    //MARK: requestQouteUpdate
    private func requestQouteUpdate() {
        
        
        self.changePriceLogo.image = UIImage(named: "")
        self.companyNameLabel.text = "-"
        self.companySymbolLabel.text = "-"
        self.priceLabel.text = "-"
        self.priceChangeLabel.text = "-"
        self.buyBtn.isHidden = true
        self.sellBtn.isHidden = true
        self.threeLineView.isHidden = true
        
        //проверим соединение с интернетом
        if Reachability.isConnectedToNetwork() {
            print("соединение с интернетом есть")
        
            
        //проверим загруден список компаний или нет
        if self.company.count == 0 {
            self.showAlertMessage(title: "ошибка", message: "невозможно загрузить список компаний", buttonTitle: "повторить", reloadData: true)
        } else {
            self.companyPickerView.reloadAllComponents()
            self.activityIndicator.startAnimating()
            let selectedRow = self.companyPickerView.selectedRow(inComponent: 0)
            let selectedSymbol = self.company[selectedRow].symbol
            self.requestQuote(for: selectedSymbol)
            self.requestLogo(for: selectedSymbol)
        }
        } else {
           
            print("!!!! внимание отсутствует соединение с интернетом")
            self.showAlertMessage(title: "Ошибка!", message: "Оплатите интернет :) Можно оформить кредит в Тинькофф.", buttonTitle: "повторить", reloadData: true)
      
        }
        
    }
    
    
    //MARK: requestQuote
    private func requestQuote(for symbol: String) {
        let url = URL(string: "https://api.iextrading.com/1.0/stock/\(symbol)/quote")!
        let dataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
           
            guard
                error == nil,
                (response as? HTTPURLResponse)?.statusCode == 200,
                let data = data
            
                else {
                    
                    print("! Network error quote")
                    self.showAlertMessage(title: "Ошибка", message: "Оплатите интернет :) Можно оформить кредит в Тинькофф.", buttonTitle: "повторить", reloadData: true)
                    return
            }
            self.parseQuote(data: data)
        }
        dataTask.resume()
    }
    
    
    //MARK: requestLogo
    private func requestLogo(for symbol: String) {
        let url = URL(string: "https://api.iextrading.com/1.0/stock/\(symbol)/logo")!
        let dataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
            
            guard
                error == nil,
                (response as? HTTPURLResponse)?.statusCode == 200,
                let data = data
                
                else {
                    
                    print("! Network error logo. ошибка не критичная пользователя не стоит уведомлять")
                    return
            }
            self.parseLogo(data: data)
        }
        dataTask.resume()
    }
    
    
    //MARK: parseLogo
    private func parseLogo(data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [String: Any],
                let companyLogoUrl = json["url"] as? String
  
                
                else {
                    print("! invalid json format url")
                    return
            }
            
            DispatchQueue.main.async {
                self.displayStockLogo(companyLogo: companyLogoUrl)
            }
            
        } catch {
            print("json parsing error" + error.localizedDescription)
        }
    }
    

    //MARK: parseQuote
    private func parseQuote(data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [String: Any],
                let companyName = json["companyName"] as? String,
                let companySymbol = json["symbol"] as? String,
                let price = json["latestPrice"] as? Double,
                let priceChange = json["change"] as? Double

            else {
                print("! invalid json format parseQuote")
                return
            }
            
                DispatchQueue.main.async {
                    self.displayStockInfo(companyName: companyName,
                                          symbol: companySymbol,
                                          price: price,
                                          priceChange: priceChange)
                }
       
        } catch {
            print("json parsing error" + error.localizedDescription)
        }
    }
    
    
    //MARK: displayStockLogo
    private func displayStockLogo(companyLogo: String) {
        self.companyLogo.image = UIImage(named: "")
        let url = URL(string: companyLogo)
        self.companyLogo.downloadedFrom(url: url!, contentMode: .scaleAspectFit)

    }
    
    
    //MARK: displayStockInfo
    private func displayStockInfo(companyName: String, symbol: String,
                                  price: Double,
                                  priceChange: Double) {
        self.activityIndicator.stopAnimating()
        self.threeLineView.isHidden = false
        self.companyNameLabel.text = companyName
        self.companyNameBtn = companyName
        self.companySymbolLabel.text = symbol
        self.priceLabel.text = "\(price)"
        
        self.buyBtn.isHidden = false
        self.sellBtn.isHidden = false
        
        if priceChange < 0 {
            self.priceChangeLabel.textColor = UIColor.red
            self.changePriceLogo.image = UIImage(named: "pricedown")
        } else  if priceChange > 0 {
            self.priceChangeLabel.textColor = UIColor.green
            self.changePriceLogo.image = UIImage(named: "priceup")
        } else {
            self.priceChangeLabel.textColor = UIColor.black
            self.changePriceLogo.image = UIImage(named: "")
        }
        self.priceChangeLabel.text = "\(priceChange)"
    }
    
    
    
    private func showAlertMessage(title: String, message: String, buttonTitle: String, reloadData: Bool) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: buttonTitle, style: .default) { (action) in
            if reloadData {
            self.companyLoadJson()
            }
        }
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    @IBAction func sellBtnAction(_ sender: UIButton) {
        self.showAlertMessage(title: "Deals done", message: "you sell \(companyNameBtn ?? "")", buttonTitle: "OK", reloadData: false)
    }
    
    @IBAction func buyBtnAction(_ sender: UIButton) {
                self.showAlertMessage(title: "Deals done", message: "you buy \(companyNameBtn ?? "")", buttonTitle: "OK", reloadData: false)
    }
    
    
}

extension UIImageView {
    func downloadedFrom(url: URL, contentMode mode: UIView.ContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() {
                self.image = image
            }
            }.resume()
    }
}
