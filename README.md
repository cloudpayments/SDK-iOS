# CloudPayments SDK for iOS 

CloudPayments SDK позволяет интегрировать прием платежей в мобильные приложение для платформы iOS.

### Схема работы мобильного приложения:
![Схема проведения платежа](https://cloudpayments.ru/storage/SNbUKmXtE1XgZoL7ypOSJBTFKvRpfMaWtWiNI51U.png)
1. В приложении необходимо получить данные карты: номер, срок действия, имя держателя и CVV;
2. Создать криптограмму карточных данных при помощи SDK;
3. Отправить криптограмму и все данные для платежа с мобильного устройства на ваш сервер;
4. С сервера выполнить оплату через платежное API CloudPayments. 

### Требования
Для работы CloudPayments SDK необходим iOS версии 8.0 и выше.

### Подключение
Для подключения SDK мы рекомендуем использовать Cocoa Pods. Добавьте в файл Podfile зависимость:

```
pod 'SDK-iOS', :git =>  "https://github.com/cloudpayments/SDK-iOS", :branch => "master"
```

Если ваш проект написан на языке Swift, вам так же необходимо создать файл моста {PROJECT_NAME}-Bridging-Header.h для использования классов из Objective-C и импортировать в нем классы которые вы планируете использовать:

```
#import <SDK-iOS/sdk/sdk/Card/Card.h> // Создание критограммы 
#import <SDK-iOS/sdk/sdk/Card/Api/CPCardApi.h> // Получение информации о банке по номеру карты
#import <SDK-iOS/sdk/sdk/3DS/D3DS.h> // Обработка 3DS формы
#import <SDK-iOS/sdk/sdk/Utils/PKPaymentConverter.h> // Работа c Apple Pay
```
#### ЗАМЕЧАНИЕ 
Чтобы использовать относительные пути к файлам в настройках проекта в переменную Header-Search Path добавьте следующее значение: "$(SOURCE_ROOT)/Pods"

### Структура проекта:

* **api** - Пример файлов для проведения платежа через ваш сервер
* **demo** - Пример реализации приложения с использованием SDK
* **sdk** - Исходный код SDK


### Подготовка к работе

Для начала приема платежей через мобильные приложения вам понадобятся:

* Public ID;
* Пароль для API (**Важно:** Не храните пароль для API в приложении, выполняйте запросы через сервер согласно Схемы работы мобильного приложения).

Эти данные можно получить в личном кабинете: [https://merchant.cloudpayments.ru/](https://merchant.cloudpayments.ru/) после подключения к [CloudPayments](https://cloudpayments.ru/).

### Возможности CloudPayments SDK:

* Проверка карточного номера на корректность

```
Card.isCardNumberValid(cardNumber)

```

* Проверка срока действия карты

```
Card.isExpDateValid(expDate) // expDate в формате MM/yy

```

* Определение типа платежной системы

```
Card.cardType(toString: Card.cardType(fromCardNumber: textField.text))

```

* Определение банка эмитента

```
let api : CPCardApi = CPCardApi.init()
        api.delegate = self
        api.getBinInfo(cardNumber)

	// Результат можно получить в методах делигата CPCardApiDelegate
	func didFinish(_ info: BinInfo!) {
        
        if let bankName = info.bankName {
            print("BankName: \(bankName)")
        } else {
            print("BankName is empty")
        }
        
        if let logoUrl = info.logoUrl {
            print("LogoUrl: \(logoUrl)")
        } else {
            print("LogoUrl is empty")
        }
     }
    
    func didFailWithError(_ message: String!) {
        
        if let error = message {
            print("error: \(error)")
        } else {
            print("Error")
        }
    }
```

* Шифрование карточных данных и создание криптограммы для отправки на сервер

```
let card = Card()
let cardCryptogramPacket = card.makeCryptogramPacket(cardNumber, andExpDate: expDate, andCVV: cvv, andMerchantPublicID: Constants.merchantPulicId)

```

* Отображение 3DS формы и получении результата 3DS аутентификации

```
var d3ds: D3DS = D3DS.init()
d3ds.make3DSPayment(with: self, andAcsURLString: acsUrl, andPaReqString: paReq, andTransactionIdString: transactionId)
```
#### ЗАМЕЧАНИЕ 
Переменную var d3ds: D3DS лучше объявить как член класса который будет реализовывать делегата D3DSDelegate, в противном случае методы делегата могуть быть не вызванны, так как к моменту их вызова ссылка на экземпляр D3DS может быть автоматически удалена.

### Пример проведения платежа:

#### 1) Создание криптограммы

```
// Обязательно проверяйте входящие данные карты (номер, срок действия и cvc код) на корректность, иначе при попытке создания объекта CPCard мы получим исключение.
let card = Card()
let cardCryptogramPacket = card.makeCryptogramPacket(cardNumber, andExpDate: expDate, andCVV: cvv, andMerchantPublicID: Constants.merchantPulicId)

```

#### 2) Выполнение запроса на проведения платежа через  API CloudPayments

Платёж - [оплата по криптограмме](https://developers.cloudpayments.ru/#oplata-po-kriptogramme).

Для привязки карты (платёж "в один клик")  используйте метод
[оплату по токену](https://developers.cloudpayments.ru/#oplata-po-tokenu-rekarring).  

Токен можно получить при совершении оплаты по криптограмме, либо при получении  [уведомлений](https://developers.cloudpayments.ru/#uvedomleniya).


#### 3) Если необходимо, показать 3DS форму для подтверждения платежа

```
var d3ds: D3DS = D3DS.init()
d3ds.make3DSPayment(with: self, andAcsURLString: acsUrl, andPaReqString: paReq, andTransactionIdString: transactionId)
```

Для получения результатов прохождения 3DS аутентификации реализуйте делигат D3DSDelegate в ViewController из которого происходит создание и отображение 3DS формы.

```
class CheckoutViewController: UIViewController, D3DSDelegate {
...
	func authorizationCompleted(withMD md: String!, andPares paRes: String!) {
        post3ds(transactionId: md, paRes: paRes)
    }
    
    func authorizationFailed(withHtml html: String!) {
        self.showAlert(title: .errorWord, message: html)
        print("error: \(html)")
    }
```

#### 4) Для завершения оплаты выполнить метод Post3ds

Смотрите документацию по API: Платёж - [обработка 3-D Secure](https://developers.cloudpayments.ru/#obrabotka-3-d-secure).

### Подключение Apple Pay для клиентов CloudPayments

[О Apple Pay](https://cloudpayments.ru/docs/applepay)

[https://www.raywenderlich.com/87300/apple-pay-tutorial](https://www.raywenderlich.com/87300/apple-pay-tutorial) \- туториал, по подключению Apple Pay в приложение.

#### ВАЖНО:

При обработке успешного ответа от Apple Pay, необходимо выполнить переобразование объекта PKPayment в криптограмму для передачи в платежное API CloudPayments

```
let cryptogram = PKPaymentConverter.convert(toString: payment) 
```
После успешного преобразования криптограмму можно использовать для проведения оплаты.

### Поддержка

По возникающим вопросам техничечкого характера обращайтесь на support@cloudpayments.ru
