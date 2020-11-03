//
//  ViewController.swift
//  Mario-Example
//
//  Created by v on 2020/11/3.
//

import UIKit

extension UIImage {

    func crop(_ rect: CGRect) -> UIImage? {
        guard let cgImage = cgImage else {
            return nil
        }

        let w = rect.width > 0 ? rect.width : size.width
        let h = rect.height > 0 ? rect.height : size.height

        let croppingRect = CGRect(x: rect.minX * scale,
                                  y: rect.minY * scale,
                                  width: w * scale,
                                  height: h * scale)

        guard let croppingImage = cgImage.cropping(to: croppingRect) else {
            return nil
        }

        return UIImage(cgImage: croppingImage)
    }

    class func image(size: CGSize, drawing handler: (CGRect) -> Bool) -> UIImage? {
        var image: UIImage? = nil

        UIGraphicsBeginImageContextWithOptions(size, false, 0)

        defer {
            UIGraphicsEndImageContext()
        }

        guard let ctx = UIGraphicsGetCurrentContext() else {
            return nil
        }

        if !handler(ctx.boundingBoxOfClipPath) {
            return nil
        }

        image = UIGraphicsGetImageFromCurrentImageContext()

        return image
    }
}

class ViewController: UIViewController {

    enum Direct {
        case left
        case right
    }

    var isJumping = false

    var direct: Direct = .right {
        didSet {
            if direct == .right, !marioView.transform.isIdentity {
                marioView.transform = .identity
            } else if direct == .left, marioView.transform.isIdentity {
                marioView.transform = CGAffineTransform(scaleX: -1, y: 1)
            }
        }
    }

    lazy var walkingTimer = CADisplayLink(target: self, selector: #selector(onWalking(_:)))
    lazy var jumpingTimer = CADisplayLink(target: self, selector: #selector(onJumping(_:)))

    lazy var mario: [UIImage] = [
        UIImage(named: "mario")!.crop(CGRect(x: 0, y: 0, width: 32.5, height: 0))!,
        UIImage(named: "mario")!.crop(CGRect(x: 32.5, y: 0, width: 32.5, height: 0))!,
        UIImage(named: "mario")!.crop(CGRect(x: 65, y: 0, width: 32.5, height: 0))!
    ]

    lazy var marioView = UIImageView(image: mario[0])
    var floorView = UIImageView(image: UIImage(named: "floor")?.resizableImage(withCapInsets: .zero, resizingMode: .tile))
    var backgroundView = UIImageView(image: UIImage(named: "background"))
    var backgroundView2 = UIImageView(image: UIImage(named: "background"))
    var scrollView = UIScrollView()

    lazy var buttonNormalBackground = UIImage.image(size: CGSize(width: 48, height: 48)) { (bounds) -> Bool in
        UIColor.white.setFill()

        let path = UIBezierPath(roundedRect: bounds, cornerRadius: 24)
        path.fill()
        path.addClip()

        return true
    }

    lazy var buttonHighlightedBackground = UIImage.image(size: CGSize(width: 48, height: 48)) { (bounds) -> Bool in
        UIColor.white.withAlphaComponent(0.5).setFill()

        let path = UIBezierPath(roundedRect: bounds, cornerRadius: 24)
        path.fill()
        path.addClip()

        return true
    }

    lazy var leftButton = UIButton(type: .custom)
    lazy var rightButton = UIButton(type: .custom)
    lazy var jumpButton = UIButton(type: .custom)

    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.frame = view.bounds;
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.addSubview(backgroundView)
        scrollView.addSubview(backgroundView2)
        scrollView.addSubview(floorView)
        view.addSubview(scrollView)

        marioView.frame = CGRect(x: 0, y: 0, width: 32.5, height: 64.5)
        view.addSubview(marioView)

        leftButton.frame = CGRect(x: 0, y: 0, width: 48, height: 48)
        leftButton.setTitle("←", for: .normal)
        leftButton.setTitleColor(.black, for: .normal)
        leftButton.setBackgroundImage(buttonNormalBackground, for: .normal)
        leftButton.setBackgroundImage(buttonHighlightedBackground, for: .highlighted)
        leftButton.addTarget(self, action: #selector(moveAction(_:)), for: .touchDown)
        leftButton.addTarget(self, action: #selector(stopMoveAction(_:)), for: [.touchUpInside, .touchUpOutside])
        view.addSubview(leftButton)

        rightButton.frame = CGRect(x: 0, y: 0, width: 48, height: 48)
        rightButton.setTitle("→", for: .normal)
        rightButton.setTitleColor(.black, for: .normal)
        rightButton.setBackgroundImage(buttonNormalBackground, for: .normal)
        rightButton.setBackgroundImage(buttonHighlightedBackground, for: .highlighted)
        rightButton.addTarget(self, action: #selector(moveAction(_:)), for: .touchDown)
        rightButton.addTarget(self, action: #selector(stopMoveAction(_:)), for: [.touchUpInside, .touchUpOutside])
        view.addSubview(rightButton)

        jumpButton.frame = CGRect(x: 0, y: 0, width: 48, height: 48)
        jumpButton.setTitle("↑", for: .normal)
        jumpButton.setTitleColor(.black, for: .normal)
        jumpButton.setBackgroundImage(buttonNormalBackground, for: .normal)
        jumpButton.setBackgroundImage(buttonHighlightedBackground, for: .highlighted)
        jumpButton.addTarget(self, action: #selector(jumpAction(_:)), for: .touchDown)
        view.addSubview(jumpButton)

        direct = .right
        walkingTimer.add(to: .main, forMode: .common)
        walkingTimer.isPaused = true

        jumpingTimer.add(to: .main, forMode: .common)
        jumpingTimer.isPaused = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let bounds = view.bounds
        scrollView.frame = bounds;

        let imageSize = backgroundView.image!.size
        let h = imageSize.height, w = imageSize.width, floorHeight: CGFloat = 53
        let h1 = bounds.height - floorHeight, w1 = h1 / h * w

        scrollView.contentSize = CGSize(width: w1 * 2, height: 0)
        backgroundView.frame = CGRect(x: 0, y: 0, width: w1, height: h1)
        backgroundView2.frame = CGRect(x: w1, y: 0, width: w1, height: h1)

        floorView.frame = CGRect(x: 0, y: h1, width: w1 * 2, height: floorHeight)

        let marioWidth: CGFloat = 32.5, marioHeight: CGFloat = 64.5
        var x = (bounds.width - marioWidth) * 0.5, y = bounds.height - floorHeight - marioHeight
        marioView.frame = CGRect(x: x, y: y, width: marioWidth, height: marioHeight)

        x = 36
        y = bounds.height - 36 - 48

        if #available(iOS 11.0, *) {
            x += view.safeAreaInsets.left
        }

        leftButton.frame = CGRect(x: x, y: y, width: 48, height: 48)
        rightButton.frame = CGRect(x: x + 36 + 48, y: y, width: 48, height: 48)

        x = bounds.width - 36 - 48

        if #available(iOS 11.0, *) {
            x -= view.safeAreaInsets.right
        }

        jumpButton.frame = CGRect(x: x, y: y, width: 48, height: 48)
    }

    var i: Int = 0, total: CFTimeInterval = 0
    @objc func onWalking(_ sender: CADisplayLink) {
        total += sender.duration * Double(sender.frameInterval)
        if total < 0.125 {
            return
        }

        total = 0

        i += 1
        if i > 2 {
            i = 0
        }

        marioView.image = mario[i]

        let d: CGFloat = 32.5 * (isJumping ? 1.25 : 1 ) * 0.25
        var offset = scrollView.contentOffset

        if direct == .right, offset.x + scrollView.bounds.width + d > backgroundView2.frame.maxX {
            offset.x = offset.x - backgroundView2.frame.minX
        } else if direct == .left, offset.x - d < 0 {
            offset.x = backgroundView2.frame.minX
        }

        if direct == .right {
            offset.x += d
        } else {
            offset.x -= d
        }

        scrollView.contentOffset = offset
    }

    var total2: CFTimeInterval = 0
    @objc func onJumping(_ sender: CADisplayLink) {
        total2 += sender.duration * Double(sender.frameInterval)

        var frame = marioView.frame
        var y = frame.minY

        if total2 <= 1 {
            y -= 2
        } else if total2 <= 2 {
            y += 2
        } else {
            jumpingTimer.isPaused = true
            jumpButton.isUserInteractionEnabled = true
            isJumping = false
            y = view.bounds.height - 53 - 64.5
            total2 = 0
        }

        frame.origin.y = y
        marioView.frame = frame
    }

    @objc func moveAction(_ sender: UIButton) {
        if sender == leftButton {
            direct = .left
        } else {
            direct = .right
        }

        walkingTimer.isPaused = false
    }

    @objc func stopMoveAction(_ sender: UIButton) {
        walkingTimer.isPaused = true
    }

    @objc func jumpAction(_ sender: UIButton) {
        isJumping = true
        jumpButton.isUserInteractionEnabled = false
        jumpingTimer.isPaused = false
    }
}

