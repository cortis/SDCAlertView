class AlertView: AlertControllerView {

    var actionLayout: ActionLayout = .Automatic
    var textFieldsViewController: TextFieldsViewController? {
        didSet { self.textFieldsViewController?.visualStyle = self.visualStyle }
    }

    var topView: UIView { return self.scrollView }

    override var actionTappedHandler: (AlertAction -> Void)? {
        get { return self.actionsCollectionView.actionTapped }
        set { self.actionsCollectionView.actionTapped = newValue }
    }

    override var visualStyle: VisualStyle! {
        didSet { self.textFieldsViewController?.visualStyle = self.visualStyle }
    }

    private let scrollView = UIScrollView()

    private var elements: [UIView] {
        let possibleElements: [UIView?] = [
            self.titleLabel,
            self.messageLabel,
            self.textFieldsViewController?.view,
            self.contentView.subviews.count > 0 ? self.contentView : nil,
        ]

        return possibleElements.flatMap { $0 }
    }

    private var contentHeight: CGFloat {
        guard let lastElement = self.elements.last else { return 0 }

        lastElement.layoutIfNeeded()
        return lastElement.frame.maxY + self.visualStyle.contentPadding.bottom
    }

    convenience init() {
        self.init(frame: .zero)
        self.titleLabel.font = UIFont.boldSystemFontOfSize(17)
        self.messageLabel.font = UIFont.systemFontOfSize(13)
    }

    override func prepareLayout() {
        super.prepareLayout()

        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.scrollView)

        updateCollectionViewScrollDirection()

        createBackground()
        createUI()
        createContentConstraints()
        updateUI()
    }

    // MARK: - Private methods

    private func createBackground() {
        if let color = self.visualStyle.backgroundColor {
            self.backgroundColor = color
        } else {
            let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .ExtraLight))
            backgroundView.translatesAutoresizingMaskIntoConstraints = false

            self.insertSubview(backgroundView, belowSubview: self.scrollView)
            backgroundView.sdc_alignEdges(.All, withView: self)
        }
    }

    private func createUI() {
        for element in self.elements {
            element.translatesAutoresizingMaskIntoConstraints = false
            self.scrollView.addSubview(element)
        }

        self.actionsCollectionView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(self.actionsCollectionView)
    }

    private func updateCollectionViewScrollDirection() {
        guard let layout = self.actionsCollectionView.collectionViewLayout as? UICollectionViewFlowLayout
            else { return }

        if self.actionLayout == .Horizontal || (self.actions.count == 2 && self.actionLayout == .Automatic) {
            layout.scrollDirection = .Horizontal
        } else {
            layout.scrollDirection = .Vertical
        }
    }

    private func updateUI() {
        self.layer.masksToBounds = true
        self.layer.cornerRadius = self.visualStyle.cornerRadius
        self.textFieldsViewController?.visualStyle = self.visualStyle
    }

    override func intrinsicContentSize() -> CGSize {
        let totalHeight = self.contentHeight + self.actionsCollectionView.displayHeight
        return CGSize(width: UIViewNoIntrinsicMetric, height: totalHeight)
    }

    // MARK: - Constraints

    private func createContentConstraints() {
        createTitleLabelConstraints()
        createMessageLabelConstraints()
        createTextFieldsConstraints()
        createCustomContentViewConstraints()
        createCollectionViewConstraints()
        createScrollViewConstraints()
    }

    private func createTitleLabelConstraints() {
        addConstraint(NSLayoutConstraint(item: self.titleLabel, attribute: .FirstBaseline, relatedBy: .Equal,
            toItem: self, attribute: .Top, multiplier: 1, constant: self.visualStyle.contentPadding.top))
        let contentPadding = self.visualStyle.contentPadding
        let insets = UIEdgeInsets(top: 0, left: contentPadding.left, bottom: 0, right: -contentPadding.right)
        self.titleLabel.sdc_alignEdges([.Left, .Right], withView: self, insets: insets)

        pinBottomOfScrollViewToView(self.titleLabel, withPriority: UILayoutPriorityDefaultLow)
    }

    private func createMessageLabelConstraints() {
        addConstraint(NSLayoutConstraint(item: self.messageLabel, attribute: .FirstBaseline,
            relatedBy: .Equal, toItem: self.titleLabel, attribute: .Baseline , multiplier: 1,
            constant: self.visualStyle.verticalElementSpacing))
        let contentPadding = self.visualStyle.contentPadding
        let insets = UIEdgeInsets(top: 0, left: contentPadding.left, bottom: 0, right: -contentPadding.right)
        self.messageLabel.sdc_alignEdges([.Left, .Right], withView: self, insets: insets)

        pinBottomOfScrollViewToView(self.messageLabel, withPriority: UILayoutPriorityDefaultLow + 1)
    }

    private func createTextFieldsConstraints() {
        guard let textFieldsView = self.textFieldsViewController?.view,
              let height = self.textFieldsViewController?.requiredHeight
        else {
            return
        }

        // The text fields view controller needs the visual style to calculate its height
        self.textFieldsViewController?.visualStyle = self.visualStyle

        let widthOffset = self.visualStyle.contentPadding.left + self.visualStyle.contentPadding.right

        addConstraint(NSLayoutConstraint(item: textFieldsView, attribute: .Top, relatedBy: .Equal,
            toItem: self.messageLabel, attribute: .Baseline, multiplier: 1,
            constant: self.visualStyle.verticalElementSpacing))

        textFieldsView.sdc_pinWidthToWidthOfView(self, offset: -widthOffset)
        textFieldsView.sdc_alignHorizontalCenterWithView(self)
        textFieldsView.sdc_pinHeight(height)

        pinBottomOfScrollViewToView(textFieldsView, withPriority: UILayoutPriorityDefaultLow + 2)
    }

    private func createCustomContentViewConstraints() {
        if !self.elements.contains(self.contentView) { return }

        let aligningView = self.textFieldsViewController?.view ?? self.messageLabel
        let widthOffset = self.visualStyle.contentPadding.left + self.visualStyle.contentPadding.right

        let topSpacing = self.visualStyle.verticalElementSpacing
        self.contentView.sdc_alignEdge(.Top, withEdge: .Bottom, ofView: aligningView, inset: topSpacing)
        self.contentView.sdc_alignHorizontalCenterWithView(self)
        self.contentView.sdc_pinWidthToWidthOfView(self, offset: -widthOffset)

        pinBottomOfScrollViewToView(self.contentView, withPriority: UILayoutPriorityDefaultLow + 3)
    }

    private func createCollectionViewConstraints() {
        let height = self.actionsCollectionView.displayHeight
        let heightConstraint = NSLayoutConstraint(item: self.actionsCollectionView, attribute: .Height,
            relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: height)
        heightConstraint.priority = UILayoutPriorityDefaultHigh
        self.actionsCollectionView.addConstraint(heightConstraint)
        self.actionsCollectionView.sdc_pinWidthToWidthOfView(self)
        self.actionsCollectionView.sdc_alignEdge(.Top, withEdge: .Bottom, ofView: self.scrollView)
        self.actionsCollectionView.sdc_alignHorizontalCenterWithView(self)
        self.actionsCollectionView.sdc_alignEdges(.Bottom, withView: self)
    }

    private func createScrollViewConstraints() {
        self.scrollView.sdc_alignEdges([.Left, .Right, .Top], withView: self)
        self.scrollView.layoutIfNeeded()
        self.scrollView.sdc_pinHeight(self.scrollView.contentSize.height)
    }

    private func pinBottomOfScrollViewToView(view: UIView, withPriority priority: UILayoutPriority) {
        let bottomAnchor = NSLayoutConstraint(item: view, attribute: .Bottom, relatedBy: .Equal,
            toItem: self.scrollView, attribute: .Bottom, multiplier: 1,
            constant: -self.visualStyle.contentPadding.bottom)
        bottomAnchor.priority = priority
        addConstraint(bottomAnchor)
    }

    func addParallax() {
        let parallax = self.visualStyle.parallax

        let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .TiltAlongHorizontalAxis)
        horizontal.minimumRelativeValue = NSNumber(float: Float(-parallax.horizontal))
        horizontal.maximumRelativeValue = NSNumber(float: Float(parallax.horizontal))

        let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .TiltAlongVerticalAxis)
        vertical.minimumRelativeValue = NSNumber(float: Float(-parallax.vertical))
        vertical.maximumRelativeValue = NSNumber(float: Float(parallax.vertical))

        let group = UIMotionEffectGroup()
        group.motionEffects = [horizontal, vertical]

        self.addMotionEffect(group)
    }
}
