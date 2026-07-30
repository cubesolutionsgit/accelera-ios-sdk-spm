//
//  FullscreenViewController.swift
//  Accelera
//
//  Created by Evgeny on 20.10.2025.
//

#if ACCELERA_BANNERS_ENABLED

import UIKit
import DivKit
import Lottie
import AVFoundation

final class AcceleraFullscreenViewController: UIViewController {

    private let jsonData: Data
    private weak var originContext: AcceleraAttachedContentContext?
    private let sourceCardId: DivCardID?

    private var divView: DivView!
    private var divKitComponents: DivKitComponents?
    private var closeButton: UIButton?

    private var entryIds: [String] = []
    
    private var currentEntryIndex: Int = 0
    private var currentEntryId: String?
    private var currentCards: [[String: Any]] = []
    private var currentCardIndex: Int = 0

    private var progressStack: UIStackView?
    private var progressBars: [StoryProgressBar] = []
    private var displayLink: CADisplayLink?
    private var stateStartTime: CFTimeInterval = 0
    private var stateDuration: CFTimeInterval = 0
    private var isPaused: Bool = false
    private var pauseTime: CFTimeInterval = 0
    private var isTransitioning: Bool = false
    private lazy var plainCard: [String: Any]? = {
        let root = (try? JSONSerialization.jsonObject(with: jsonData)) as? [String: Any]
        return root?["card"] as? [String: Any]
    }()

    init(jsonData: Data, entryId: String? = nil, originContext: AcceleraAttachedContentContext? = nil, sourceCardId: DivCardID? = nil) {
        self.jsonData = jsonData
        self.currentEntryId = entryId
        self.originContext = originContext
        self.sourceCardId = sourceCardId
        super.init(nibName: nil, bundle: nil)
        modalTransitionStyle = entryId == nil ? .crossDissolve : .coverVertical
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = currentEntryId == nil ? .clear : .black
        view.isOpaque = currentEntryId != nil
        
        setupDivView()

        if let currentEntryId {
            loadEntryIds()
            loadEntry(id: currentEntryId)
            setupTapZones(multipleEntries: entryIds.count > 1 || currentCards.count > 1)
        } else {
            updateCloseButtonVisibility()
            showPlainCard()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateSafeAreaInsets()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateSafeAreaInsets()
    }

    private func setupDivView() {
        let context = DivKitSetup.makeView(
            from: jsonData,
            presentingViewController: self,
            originContext: originContext,
            variablesStorage: originContext?.sharedVariablesStorage()
        )
        divView = context.view
        divKitComponents = context.components
        divView.backgroundColor = .clear
        divView.isOpaque = false
        view.addSubview(divView)
        divView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            divView.topAnchor.constraint(equalTo: view.topAnchor),
            divView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            divView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            divView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func updateSafeAreaInsets() {
        divKitComponents?.safeAreaManager.setEdgeInsets(view.safeAreaInsets)
    }

    private var currentCard: [String: Any]? {
        if currentCards.indices.contains(currentCardIndex) {
            return currentCards[currentCardIndex]["card"] as? [String: Any]
        }
        return plainCard
    }

    func currentMeta() -> Any? {
        currentCard?["meta"]
    }

    private func divKitCardId(for index: Int) -> DivCardID {
        sourceCardId ?? DivCardID(rawValue: "\(currentEntryId ?? "plain")_\(index)")
    }

    private var shouldShowCloseButton: Bool {
        (currentCard?["closable"] as? Bool) != false
    }

    private func setupCloseButton() {
        let button = CloseButtonView(target: self, action: #selector(closeTapped))
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 28),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        self.closeButton = button
    }

    private func updateCloseButtonVisibility() {
        if shouldShowCloseButton {
            if closeButton == nil {
                setupCloseButton()
            }
            closeButton?.isHidden = false
        } else {
            closeButton?.isHidden = true
        }
    }

    private func setupTapZones(multipleEntries: Bool = false) {
        if multipleEntries {
            let left = PassthroughZoneView()
            left.divView = divView
            left.translatesAutoresizingMaskIntoConstraints = false
            left.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(prevCardTapped)))
            
            let right = PassthroughZoneView()
            right.divView = divView
            right.translatesAutoresizingMaskIntoConstraints = false
            right.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(nextCardTapped)))
            
            if let closeButton = self.closeButton {
                view.insertSubview(left, belowSubview: closeButton)
                view.insertSubview(right, belowSubview: closeButton)
            } else {
                view.addSubview(left)
                view.addSubview(right)
            }
            
            NSLayoutConstraint.activate([
                left.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                left.topAnchor.constraint(equalTo: view.topAnchor),
                left.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                left.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.3),
                
                right.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                right.topAnchor.constraint(equalTo: view.topAnchor),
                right.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                right.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.3)
            ])
        }
        
        let press = UILongPressGestureRecognizer(target: self, action: #selector(handlePress(_:)))
        press.minimumPressDuration = 0.15
        press.cancelsTouchesInView = false
        view.addGestureRecognizer(press)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeDown(_:)))
        swipeDown.direction = .down
        swipeDown.cancelsTouchesInView = false
        view.addGestureRecognizer(swipeDown)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleHorizontalSwipe(_:)))
        swipeLeft.direction = .left
        swipeLeft.cancelsTouchesInView = false
        view.addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleHorizontalSwipe(_:)))
        swipeRight.direction = .right
        swipeRight.cancelsTouchesInView = false
        view.addGestureRecognizer(swipeRight)
    }

    private func loadEntryIds() {
        let root = (try? JSONSerialization.jsonObject(with: jsonData)) as? [String: Any]
        let fullscreens = root?["fullscreens"] as? [String: Any]
        self.entryIds = fullscreens?.keys.sorted() ?? []
        self.currentEntryIndex = entryIds.firstIndex(of: currentEntryId ?? "") ?? 0
    }

    private func loadEntry(id: String, lastCard: Bool = false) {
        displayLink?.invalidate()
                
        guard let root = (try? JSONSerialization.jsonObject(with: jsonData)) as? [String: Any],
              let fullscreens = root["fullscreens"] as? [String: Any],
              let entry = fullscreens[id] as? [String: Any],
              let cards = entry["cards"] as? [[String: Any]] else {
            dismiss(animated: true); return
        }

        currentEntryId = id
        currentEntryIndex = entryIds.firstIndex(of: id) ?? 0
        self.currentCards = cards
        
        currentCardIndex = lastCard ? cards.count - 1 : 0
        updateCloseButtonVisibility()
        
        setupProgressBars()
        showCard(at: currentCardIndex)
    }

    private func setupProgressBars() {
        progressStack?.removeFromSuperview()
        progressStack = nil

        progressBars.forEach { $0.removeFromSuperview() }
        progressBars = []

        let needProgress = currentCards.contains { hasDuration($0) }
        guard needProgress else { return }

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            stack.heightAnchor.constraint(equalToConstant: 2)
        ])

        for _ in currentCards {
            let bar = StoryProgressBar()
            stack.addArrangedSubview(bar)
            progressBars.append(bar)
        }

        progressStack = stack
    }

    private func hasDuration(_ object: [String: Any]) -> Bool {
        guard let card = object["card"] as? [String: Any] else { return false }
        
        if let duration = card["duration"] as? Int, duration > 0 {
            return true
        }
        return false
    }
    
    private func showCard(at index: Int) {
        if index < 0 {
            if currentEntryIndex - 1 >= 0 {
                moveToPrevEntry(fromTap: true)
            } else {
                guard !currentCards.isEmpty else { return }

                displayLink?.invalidate()
                displayLink = nil

                let restartIndex = 0
                currentCardIndex = restartIndex
                updateCloseButtonVisibility()

                progressStack?.layoutIfNeeded()
                for bar in progressBars {
                    bar.setProgress(0)
                }

                guard let data = try? JSONSerialization.data(withJSONObject: currentCards[restartIndex]) else { return }

                let cardId = divKitCardId(for: restartIndex)
                let source = DivViewSource(kind: .data(data), cardId: cardId)

                guard
                    let card = currentCard
                else {
                    return
                }

                Task {
                    await divView.setSource(source)
                    Accelera.shared.logEvent(event: ["event": "view", "meta": card["meta"] ?? [:]].asData)
                }

                if let duration = card["duration"] as? Int {
                    stateDuration = CFTimeInterval(duration) / 1000.0
                } else if let div = card["div"] as? [String: Any],
                          let duration = div["duration"] as? Int {
                    stateDuration = CFTimeInterval(duration) / 1000.0
                } else if !progressBars.isEmpty {
                    stateDuration = 5.0
                } else {
                    return
                }

                stateStartTime = CACurrentMediaTime()
                displayLink = CADisplayLink(target: self, selector: #selector(updateProgress))
                displayLink?.add(to: .main, forMode: .common)
            }
            return
        }

        if index >= currentCards.count {
            moveToNextEntry()
            return
        }

        displayLink?.invalidate()
        displayLink = nil

        currentCardIndex = index
        updateCloseButtonVisibility()

        progressStack?.layoutIfNeeded()
        
        for (i, bar) in progressBars.enumerated() {
            bar.setProgress(i < index ? 1 : 0)
        }

        guard let data = try? JSONSerialization.data(withJSONObject: currentCards[index]) else { return }

        let cardId = divKitCardId(for: index)
        let source = DivViewSource(kind: .data(data), cardId: cardId)

        guard let card = currentCard else {
            return
        }

        Task {
            await divView.setSource(source)
            Accelera.shared.logEvent(event: ["event": "view", "meta": card["meta"] ?? [:]].asData)
        }

        if let duration = card["duration"] as? Int {
            stateDuration = CFTimeInterval(duration) / 1000.0
        } else if let div = card["div"] as? [String: Any],
                  let duration = div["duration"] as? Int {
            stateDuration = CFTimeInterval(duration) / 1000.0
        } else if !progressBars.isEmpty {
            stateDuration = 5.0
        } else {
            return
        }

        stateStartTime = CACurrentMediaTime()
        displayLink = CADisplayLink(target: self, selector: #selector(updateProgress))
        displayLink?.add(to: .main, forMode: .common)
    }

    private func showPlainCard() {
        let source = DivViewSource(
            kind: .data(jsonData),
            cardId: DivCardID(rawValue: "popup_\(UUID().uuidString)")
        )

        Task {
            await divView.setSource(source)
            Accelera.shared.logEvent(event: ["event": "view", "meta": currentCard?["meta"] ?? [:]].asData)
        }
    }

    @objc private func updateProgress() {
        let elapsed = CACurrentMediaTime() - stateStartTime
        let progress = CGFloat(min(max(elapsed / stateDuration, 0), 1))
        if currentCardIndex < progressBars.count {
            progressBars[currentCardIndex].setProgress(progress)
        }
        if progress >= 1 {
            displayLink?.invalidate()
            nextCard()
        }
    }

    @objc private func nextCard() {
        displayLink?.invalidate()
        showCard(at: currentCardIndex + 1)
    }

    @objc private func nextCardTapped() {
        logCurrentCardDismissByUser()
        nextCard()
    }

    @objc private func prevCard() {
        displayLink?.invalidate()
        showCard(at: currentCardIndex - 1)
    }

    @objc private func prevCardTapped() {
        prevCard()
    }

    private func transitionToEntry(id: String, direction: CGFloat, lastCard: Bool) {
        guard !isTransitioning else { return }
        isTransitioning = true
        
        displayLink?.invalidate()
        displayLink = nil
        
        guard let snapshot = divView.snapshotView(afterScreenUpdates: false) else {
            loadEntry(id: id, lastCard: lastCard)
            isTransitioning = false
            return
        }
        
        snapshot.frame = divView.frame
        view.addSubview(snapshot)
        
        let width = view.bounds.width
        let initialTransform = CGAffineTransform(translationX: direction * width, y: 0)
        
        loadEntry(id: id, lastCard: lastCard)
        
        view.layoutIfNeeded()
        divView.transform = initialTransform
        divView.alpha = 0
        
        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: [.curveEaseInOut]
        ) {
            snapshot.transform = CGAffineTransform(translationX: -direction * width, y: 0)
            snapshot.alpha = 0
            self.divView.transform = .identity
            self.divView.alpha = 1
        } completion: { _ in
            snapshot.removeFromSuperview()
            self.isTransitioning = false
        }
    }

    private func moveToNextEntry() {
        guard currentEntryIndex + 1 < entryIds.count else {
            closeFullscreen()
            return
        }
        let nextId = entryIds[currentEntryIndex + 1]
        transitionToEntry(id: nextId, direction: 1, lastCard: false)
    }

    private func moveToPrevEntry(fromTap: Bool) {
        let isFirstEntry = currentEntryIndex - 1 < 0

        if isFirstEntry {
            if fromTap {
                return
            } else {
                closeFullscreen()
                return
            }
        }

        let prevId = entryIds[currentEntryIndex - 1]
        let lastCard = fromTap
        transitionToEntry(id: prevId, direction: -1, lastCard: lastCard)
    }
    
    func pauseLottieAnimations(in view: UIView) {
        for subview in view.subviews {
            if let lottieView = subview as? LottieAnimationView {
                lottieView.pause()
            }
            pauseLottieAnimations(in: subview)
        }
    }
    
    func pauseVideos(in view: UIView) {
        for subview in view.subviews {
            if let playerLayer = subview.layer.sublayers?.compactMap({ $0 as? AVPlayerLayer }).first,
               let player = playerLayer.player {
                player.pause()
            }
            pauseVideos(in: subview)
        }
    }
    
    func playLottieAnimations(in view: UIView) {
        for subview in view.subviews {
            if let lottieView = subview as? LottieAnimationView {
                lottieView.play()
            }
            playLottieAnimations(in: subview)
        }
    }
    
    func playVideos(in view: UIView) {
        for subview in view.subviews {
            if let playerLayer = subview.layer.sublayers?.compactMap({ $0 as? AVPlayerLayer }).first,
               let player = playerLayer.player {
                player.play()
            }
            playVideos(in: subview)
        }
    }
    
    @objc private func handlePress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            if !isPaused {
                displayLink?.isPaused = true
                pauseVideos(in: divView)
                pauseLottieAnimations(in: divView)
                pauseTime = CACurrentMediaTime()
                isPaused = true
            }

        case .ended, .cancelled, .failed:
            if isPaused {
                let pausedDuration = CACurrentMediaTime() - pauseTime
                stateStartTime += pausedDuration
                displayLink?.isPaused = false
                playVideos(in: divView)
                playLottieAnimations(in: divView)
                isPaused = false
            }

        default:
            break
        }
    }
    
    @objc private func handleSwipeDown(_ gesture: UISwipeGestureRecognizer) {
        if gesture.state == .ended {
            closeTapped()
        }
    }
    
    @objc private func handleHorizontalSwipe(_ gesture: UISwipeGestureRecognizer) {
        switch gesture.direction {
        case .left:
            logCurrentCardDismissByUser()
            moveToNextEntry()
        case .right:
            moveToPrevEntry(fromTap: false)
        default:
            break
        }
    }

    @objc private func closeTapped() {
        logCurrentCardDismissByUser()
        closeFullscreen()
    }

    func closeFullscreen() {
        displayLink?.invalidate()
        displayLink = nil
        dismiss(animated: true)
    }

    private func logCurrentCardDismissByUser() {
        guard let card = currentCard else {
            return
        }
        Accelera.shared.logEvent(event: ["event": "close", "meta": card["meta"] ?? [:]].asData)
    }
}

#endif
