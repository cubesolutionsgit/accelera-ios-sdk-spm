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

    private var divView: DivView!
    private var closeButton: UIButton?

    private var entryIds: [String] = []
    
    private var currentEntryIndex: Int = 0
    private var currentEntryId: String
    private var currentCards: [[String: Any]] = []
    private var currentCardIndex: Int = 0

    private var progressStack: UIStackView?
    private var progressBars: [StoryProgressBar] = []
    private var displayLink: CADisplayLink?
    private var stateStartTime: CFTimeInterval = 0
    private var stateDuration: CFTimeInterval = 0
    private var isPaused: Bool = false
    private var pauseTime: CFTimeInterval = 0

    init(jsonData: Data, entryId: String) {
        self.jsonData = jsonData
        self.currentEntryId = entryId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        setupDivView()
        setupCloseButton()
        loadEntryIds()
        
        loadEntry(id: currentEntryId)
        
        if entryIds.count > 1 || currentCards.count > 1 {
            setupTapZones()
        }
    }

    private func setupDivView() {
        divView = DivKitSetup.makeView(from: jsonData, presentingViewController: self)
        view.addSubview(divView)
        divView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            divView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            divView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            divView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            divView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupCloseButton() {
        let button = CloseButtonView(target: self, action: #selector(closeTapped))
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        self.closeButton = button
    }

    private func setupTapZones() {
        let left = PassthroughZoneView()
        left.divView = divView
        left.translatesAutoresizingMaskIntoConstraints = false
        left.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(prevCard)))

        let right = PassthroughZoneView()
        right.divView = divView
        right.translatesAutoresizingMaskIntoConstraints = false
        right.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(nextCard)))

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
        
        let press = UILongPressGestureRecognizer(target: self, action: #selector(handlePress(_:)))
        press.minimumPressDuration = 0.15
        press.cancelsTouchesInView = false
        view.addGestureRecognizer(press)
    }

    private func loadEntryIds() {
        let root = (try? JSONSerialization.jsonObject(with: jsonData)) as? [String: Any]
        let fullscreens = root?["fullscreens"] as? [String: Any]
        self.entryIds = fullscreens?.keys.sorted() ?? []
        self.currentEntryIndex = entryIds.firstIndex(of: currentEntryId) ?? 0
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
        guard index >= 0 && index < currentCards.count else {
            index < 0 ? moveToPrevEntry() : moveToNextEntry()
            return
        }

        displayLink?.invalidate()
        displayLink = nil

        currentCardIndex = index

        progressStack?.layoutIfNeeded()
        
        for (i, bar) in progressBars.enumerated() {
            bar.setProgress(i < index ? 1 : 0)
        }

        guard let data = try? JSONSerialization.data(withJSONObject: currentCards[index]) else { return }

        let source = DivViewSource(
            kind: .data(data),
            cardId: DivCardID(rawValue: "card_\(currentEntryId)_\(index)")
        )

        Task {
            await divView.setSource(source)
            Accelera.shared.logEvent(event: ["event": "view", "meta": jsonData.meta].asData)
        }

        guard let card = currentCards[index]["card"] as? [String: Any] else {
            return
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

    @objc private func prevCard() {
        displayLink?.invalidate()
        showCard(at: currentCardIndex - 1)
    }

    private func moveToNextEntry() {
        guard currentEntryIndex + 1 < entryIds.count else {
            closeTapped()
            return
        }
        loadEntry(id: entryIds[currentEntryIndex + 1])
    }

    private func moveToPrevEntry() {
        guard currentEntryIndex - 1 >= 0 else {
            return
        }
        loadEntry(id: entryIds[currentEntryIndex - 1], lastCard: true)
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

    @objc private func closeTapped() {
        displayLink?.invalidate()
        displayLink = nil
        dismiss(animated: true)
    }
}

#endif
