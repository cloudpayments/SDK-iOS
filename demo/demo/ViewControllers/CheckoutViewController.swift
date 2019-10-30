//
//  CheckoutViewController.swift
//  demo
//

import UIKit
import PassKit

class CheckoutViewController: UIViewController, D3DSDelegate {
    
    func authorizationCompleted(withMD md: String!, andPares paRes: String!) {
        post3ds(transactionId: md, paRes: paRes)
    }
    
    func authorizationFailed(withHtml html: String!) {
        self.showAlert(title: .errorWord, message: html)
        print("error: \(html)")
    }
    
    @IBOutlet weak var labelTotal: UILabel!
    @IBOutlet weak var textCardNumber: UITextField!
    @IBOutlet weak var textExpDate: UITextField!
    @IBOutlet weak var textCvcCode: UITextField!
    @IBOutlet weak var textCardHolderName: UITextField!
    @IBOutlet weak var buttonApplePay: UIButton!
    
    var d3ds: D3DS = D3DS.init()
        
    var total = 0;

    private let network = NetworkService()
    
    // APPLE PAY
    let paymentNetworks = [PKPaymentNetwork.visa, PKPaymentNetwork.masterCard] // Платежные системы для Apple Pay
    let applePayMerchantID = "merchant.com.YOURDOMAIN" // Ваш ID для Apple Pay!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for product in CartManager.shared.products {
            
            if let price = Int(product.price) {
                total += price
            }
        }
        
        labelTotal.text = "Всего к оплате: \(total) Руб."
        
        buttonApplePay.isHidden = !PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: paymentNetworks) // Проверяем возможно ли использовать Apple Pay
    }
    
    @IBAction func onPayClick(_ sender: Any) {
        
        // Получаем введенные данные банковской карты и проверяем их корректность
        guard let cardNumber = textCardNumber.text, !cardNumber.isEmpty else {
            self.showAlert(title: .errorWord, message: .enterCardNumber)
            return
        }
               
        if !Card.isCardNumberValid(cardNumber) {
            self.showAlert(title: .errorWord, message: .enterCorrectCardNumber)
            return
        }
        
        guard let expDate = textExpDate.text, expDate.count == 5 else {
            self.showAlert(title: .errorWord, message: .enterExpirationDate)
            return
        }
        
        // Срок действия в формате MM/yy
        if !Card.isExpDateValid(expDate) {
            self.showAlert(title: .errorWord, message: .enterExpirationDate)
            return
        }
        
        guard let holderName = textCardHolderName.text, !holderName.isEmpty else {
            self.showAlert(title: .errorWord, message: .enterCardHolder)
            return
        }
        
        guard let cvv = textCvcCode.text, !cvv.isEmpty else {
            self.showAlert(title: .errorWord, message: .enterCVVCode)
            return
        }
        
        // Создаем объект Card
        let card = Card()
        
        // Создаем криптограмму карточных данных
        // Чтобы создать криптограмму необходим PublicID (свой PublicID можно посмотреть в личном кабинете и затем заменить в файле Constants)
        let cardCryptogramPacket = card.makeCryptogramPacket(cardNumber, andExpDate: expDate, andCVV: cvv, andMerchantPublicID: Constants.merchantPulicId)
        
        guard let packet = cardCryptogramPacket else {
            self.showAlert(title: .errorWord, message: .errorCreatingCryptoPacket)
            return
        }
        
        // Используя методы API выполняем оплату по криптограмме
        // (charge (для одностадийного платежа) или auth (для двухстадийного))
 
        //charge(cardCryptogramPacket: packet, cardHolderName: holderName)
        auth(cardCryptogramPacket: packet, cardHolderName: holderName)
    }
    
    @IBAction func onApplePayClick(_ sender: Any) {
    
        // Формируем запрос для Apple Pay
        let request = PKPaymentRequest()
        request.merchantIdentifier = applePayMerchantID
        request.supportedNetworks = paymentNetworks
        request.merchantCapabilities = PKMerchantCapability.capability3DS // Возможно использование 3DS
        request.countryCode = "RU" // Код страны
        request.currencyCode = "RUB" // Код валюты
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "Рубль", amount: NSDecimalNumber(value: total)) // Информация о товаре (название и цена)
        ]
        let applePayController = PKPaymentAuthorizationViewController(paymentRequest: request)
        applePayController?.delegate = self
        self.present(applePayController!, animated: true, completion: nil)
    }
}

// Обработка результата для Apple Pay
// ВНИМАНИЕ! Нельзя тестировать Apple Pay в симуляторе, так как в симуляторе payment.token.paymentData всегда nil
extension CheckoutViewController: PKPaymentAuthorizationViewControllerDelegate {
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: @escaping ((PKPaymentAuthorizationStatus) -> Void)) {
        completion(PKPaymentAuthorizationStatus.success)
        
        // Конвертируем объект PKPayment в строку криптограммы
        guard let cryptogram = PKPaymentConverter.convert(toString: payment) else {
            return
        }
               
        // Используя методы API выполняем оплату по криптограмме
        // (charge (для одностадийного платежа) или auth (для двухстадийного))
        //charge(cardCryptogramPacket: cryptogram, cardHolderName: "")
        auth(cardCryptogramPacket: cryptogram, cardHolderName: "")
      
    }
    
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Private methods
private extension CheckoutViewController {

    func charge(cardCryptogramPacket: String, cardHolderName: String) {
        
        network.charge(cardCryptogramPacket: cardCryptogramPacket, cardHolderName: cardHolderName, amount: total) { [weak self] result in
            
            switch result {
            case .success(let transactionResponse):
                print("success")
                self?.checkTransactionResponse(transactionResponse: transactionResponse)
            case .failure(let error):
                print("error: \(error.localizedDescription)")
                self?.showAlert(title: .errorWord, message: error.localizedDescription)
            }
        }
    }
    
    func auth(cardCryptogramPacket: String, cardHolderName: String) {
        
        network.auth(cardCryptogramPacket: cardCryptogramPacket, cardHolderName: cardHolderName, amount: total) { [weak self] result in
            
            switch result {
            case .success(let transactionResponse):
                print("success")
                self?.checkTransactionResponse(transactionResponse: transactionResponse)
            case .failure(let error):
                print("error: \(error.localizedDescription)")
                self?.showAlert(title: .errorWord, message: error.localizedDescription)
            }
        }
    }
    
    // Проверяем необходимо ли подтверждение с использованием 3DS
    func checkTransactionResponse(transactionResponse: TransactionResponse) {
        if (transactionResponse.success) {
            
            // Показываем результат
            self.showAlert(title: .informationWord, message: transactionResponse.transaction?.cardHolderMessage)
        } else {
            
            if (!transactionResponse.message.isEmpty) {
                self.showAlert(title: .errorWord, message: transactionResponse.message)
                return
            }
            if (transactionResponse.transaction?.paReq != nil && transactionResponse.transaction?.acsUrl != nil) {
                
                let transactionId = String(describing: transactionResponse.transaction?.transactionId ?? 0)
                
                let paReq = transactionResponse.transaction!.paReq
                let acsUrl = transactionResponse.transaction!.acsUrl
                               
                // Показываем 3DS форму
                
                d3ds.make3DSPayment(with: self, andAcsURLString: acsUrl, andPaReqString: paReq, andTransactionIdString: transactionId)
            } else {
                self.showAlert(title: .informationWord, message: transactionResponse.transaction?.cardHolderMessage)
            }
        }
    }
    
    func post3ds(transactionId: String, paRes: String) {
        
        network.post3ds(transactionId: transactionId, paRes: paRes) { [weak self] result in
            
            switch result {
            case .success(let transactionResponse):
                print("success")
                self?.checkTransactionResponse(transactionResponse: transactionResponse)
            case .failure(let error):
                print("error: \(error.localizedDescription)")
                self?.showAlert(title: .errorWord, message: error.localizedDescription)
            }
        }
    }
    
    // MARK: - Utilities
    
    func parse(response: String?) -> [AnyHashable: Any]? {
        guard let response = response else {
            return nil
        }
        
        let pairs = response.components(separatedBy: "&")
        let elements = pairs.map { $0.components(separatedBy: "=") }
        let dict = elements.reduce(into: [String: String]()) {
            $0[$1[0].removingPercentEncoding!] = $1[1].removingPercentEncoding
        }
        
        return dict
    }
}

