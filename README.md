# Accelera SDK

Библиотека `Accelera` — это модульный SDK для интеграции динамического контента (баннеров, сторис и попапов) и push-уведомлений в ваше iOS-приложение.

## 📦 Установка через Swift Package Manager

1. Откройте Xcode
2. `File → Add Packages...`
3. Введите URL:
   ```
   https://github.com/cubesolutionsgit/accelera-ios-sdk-spm.git
   ```
4. Выберите версию `0.6.4`
5. **Важно:** выберите **только один продукт** из списка:

| Продукт               | Описание                                |
|------------------------|-----------------------------------------|
| `Accelera`             | Всё сразу: контент + уведомления        |
| `AcceleraBanners`      | Баннеры, сторис и попапы                |
| `AcceleraNotifications`| Только пуш-уведомления (Firebase)       |

## ⚙️ Конфигурация

### Стандартная инициализация

```swift
import Accelera

Accelera.shared.configure(
 config: AcceleraConfig(
     url: "https://your-api-endpoint.com",
     systemToken: "your-system-token"
 )
)
```

### Кастомный API (без конфигурации)

Если вы хотите самостоятельно обрабатывать сетевые вызовы, достаточно настроить делегат:

```swift
Accelera.shared.configure(config: AcceleraConfig()) // пустой конфиг

Accelera.shared.delegate = self
```

```swift
extension MyViewController: AcceleraDelegate {
    var customAPI: AcceleraAPIProtocol? { self }
}

extension MyViewController: AcceleraAPIProtocol {
    func logEvent(data: Data?, completion: @escaping (Data?, NetworkError?) -> Void) -> URLSessionDataTask? {
        // вызов вашего backend
    }
    // ... остальные методы
}
```

> ☝️ Все методы взаимодействия с сервером — **POST**.

## 📐 Размещение баннеров и сторис

Баннеры и сторис отображаются в `UIView`-placeholder'ах, которые вы добавляете на экран.

### Программно

```swift
let storiesPlaceholder = UIView()
let bannerPlaceholder = UIView()

view.addSubview(storiesPlaceholder)
view.addSubview(bannerPlaceholder)

storiesPlaceholder.translatesAutoresizingMaskIntoConstraints = false
bannerPlaceholder.translatesAutoresizingMaskIntoConstraints = false

let heightStories = storiesPlaceholder.heightAnchor.constraint(equalToConstant: 0)
heightStories.priority = .defaultHigh
heightStories.isActive = true

let heightBanner = bannerPlaceholder.heightAnchor.constraint(equalToConstant: 0)
heightBanner.priority = .defaultHigh
heightBanner.isActive = true

NSLayoutConstraint.activate([
    storiesPlaceholder.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
    storiesPlaceholder.leadingAnchor.constraint(equalTo: view.leadingAnchor),
    storiesPlaceholder.trailingAnchor.constraint(equalTo: view.trailingAnchor),

    bannerPlaceholder.topAnchor.constraint(equalTo: storiesPlaceholder.bottomAnchor, constant: 20),
    bannerPlaceholder.leadingAnchor.constraint(equalTo: view.leadingAnchor),
    bannerPlaceholder.trailingAnchor.constraint(equalTo: view.trailingAnchor)
])
```

### Через Storyboard

1. Добавьте `UIView` для баннеров и сторис
2. Создайте IBOutlet:

```swift
@IBOutlet weak var storiesPlaceholder: UIView!
@IBOutlet weak var bannerPlaceholder: UIView!
```
> ⚠️ В storyboard выставите height = 0 и priority < 1000

Далее в обоих случаях нужно привязать элементы к библиотеке:

```swift
Accelera.shared.attachContentPlaceholder(
    to: storiesPlaceholder,
    with: ["type": "stories"].asData
)

Accelera.shared.attachContentPlaceholder(
    to: bannerPlaceholder,
    with: ["type": "banner"].asData
)
```

Если удобно хранить ссылку на конкретный placeholder, сохраните handle:

```swift
let bannerHandle = Accelera.shared.attachContentPlaceholder(
    to: bannerPlaceholder,
    with: ["type": "banner"].asData
)

bannerHandle.refresh()
bannerHandle.detach()
```

Если handle хранить не хочется, можно управлять контентом через container:

```swift
Accelera.shared.refreshContentPlaceholder(in: bannerPlaceholder)
Accelera.shared.detachContentPlaceholder(from: bannerPlaceholder)
```

`refresh` повторно загружает контент с теми же параметрами, `detach` убирает контент из контейнера.

### SwiftUI

В SwiftUI можно использовать `AcceleraAutoHeightPlaceholderWrapper`, чтобы высота `UIView`-placeholder автоматически синхронизировалась с высотой загруженного контента и уменьшалась до `0`, когда контент исчезает.

```swift
import SwiftUI
import UIKit
import Accelera // Для продукта Accelera
// import AcceleraBanners // Для продукта AcceleraBanners

struct HomeView: View {
    @State private var bannerPlaceholder: UIView?
    @State private var isBannerVisible = false

    var body: some View {
        VStack(spacing: 0) {
            AcceleraAutoHeightPlaceholderWrapper(
                onVisibilityChanged: { isBannerVisible = $0 }
            ) { placeholder in
                bannerPlaceholder = placeholder

                Accelera.shared.attachContentPlaceholder(
                    to: placeholder,
                    with: ["type": "banner"].asData
                )
            }
            .padding(.vertical, isBannerVisible ? 16 : 0)

            MainContentView()
        }
    }

    private func refreshBanner() {
        guard let bannerPlaceholder else { return }
        Accelera.shared.refreshContentPlaceholder(in: bannerPlaceholder)
    }

    private func detachBanner() {
        guard let bannerPlaceholder else { return }
        Accelera.shared.detachContentPlaceholder(from: bannerPlaceholder)
    }
}
```

`refreshContentPlaceholder` повторно загружает баннер с теми же параметрами, `detachContentPlaceholder` убирает его из контейнера.

Необязательный `onVisibilityChanged` позволяет добавлять внешние отступы только тогда, когда высота контента больше `0`. Сам placeholder остаётся в иерархии и доступен для повторной загрузки.

### ℹ️ Параметры метода `attachContentPlaceholder`

| Параметр | Тип    | Описание                                                             |
|----------|--------|----------------------------------------------------------------------|
| `to`     | UIView | View-контейнер для отображения контента                             |
| `with`   | Data   | Конфигурация контента в формате JSON. Может содержать тип и параметры |

#### 🔸 Типы контента:
- `"stories"` — сторис (горизонтальная лента историй, при клике можно открыть на полный экран)
- `"banner"` — баннеры (статичный или карусель)

#### 🔹 Пример

```swift
Accelera.shared.attachContentPlaceholder(
    to: bannerPlaceholder,
    with: [
        "type": "banner",
        "category": "main_screen",
        "user_segment": "premium"
    ].asData
)
```
Конкретный набор параметров зависит от вашей серверной конфигурации и бизнес-логики.

## 🪟 Попапы

Попапы отображают полноэкранный динамический контент поверх текущего экрана.

```swift
Accelera.shared.showPopup(
    data: [
        "type": "popup",
        "slot": "main_popup"
    ].asData
)
```

Если нужно явно указать контроллер, из которого будет показан попап:

```swift
Accelera.shared.showPopup(
    from: self,
    data: [
        "type": "popup",
        "slot": "main_popup"
    ].asData
)
```

Параметры в `data` передаются на сервер так же, как для баннеров и сторис. Конкретные ключи определяются вашей серверной конфигурацией.

## ⚡️ Обработка действий

Если пользователь нажимает на баннер, сторис или попап, или происходит другое действие — оно передаётся в делегат:

```swift
extension MyViewController: AcceleraDelegate {
    func action(action actionName: String, params: [String: String], meta: Any?) {
        print("Действие: \(actionName)")
        print("Параметры: \(params)")
        print("Meta: \(String(describing: meta))")
    }
}
```

Если вам нужен только идентификатор действия без payload, можно по-прежнему реализовать совместимый метод:

```swift
extension MyViewController: AcceleraDelegate {
    func action(action: String) {
        print("Действие: \(action)")
    }
}
```

## 👤 Информация о пользователе

```swift
Accelera.shared.setUserInfo(
    "{\"clientId\": \"123\", \"email\": \"john@example.com\", \"theme\": \"dark\"}"
)
```

Вызывайте:
- после авторизации
- при смене профиля/темы
- при любом событии, которое может поменять вид контента

---

📄 Версия: `0.6.4`
📆 Обновлено: август 2026
📫 Поддержка: [@cubesolutions](https://github.com/cubesolutionsgit)  
📚 Полная документация по методам доступна по [ссылке](https://cubesolutionsgit.github.io/accelera-ios-sdk-spm/documentation/accelera)
