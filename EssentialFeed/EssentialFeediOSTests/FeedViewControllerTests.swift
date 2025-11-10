//
//  FeedViewControllerTests.swift
//  EssentialFeed
//
//  Created by Murali Nallusamy on 07/11/25.
//

import XCTest
import UIKit
import EssentialFeed

public final class FeedImageCell: UITableViewCell {
    public let locationContainer = UIView()
    public let locationLabel = UILabel()
    public let descriptionLabel = UILabel()
    public let feedImageContainter = UIView()
    public let feedImageView = UIImageView()
    
    private(set) public lazy var feedImageRetryButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
        return button
    }()
    
    var onRetry: (() -> Void)?
    @objc private func retryButtonTapped() {
        onRetry?()
    }
}

protocol FeedImageDataLoaderTask {
    func cancel()
}

protocol FeedImageDataLoader {
    typealias Result = Swift.Result<Data, Error>
    func loadimageData(from url:URL, completion: @escaping (Result) -> Void) -> FeedImageDataLoaderTask
}

public final class FeedRefreshViewController: NSObject {
    private var feedLoader: FeedLoader?
    var onRefresh: (([FeedImage]) -> Void)?
    
    init(feedLoader: FeedLoader? = nil) {
        self.feedLoader = feedLoader
    }

    private(set) lazy var refreshControl: UIRefreshControl? = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return refreshControl
    }()
    
    @objc func refresh() {
        refreshControl?.beginRefreshing()
        load()
    }
    
    @objc func load() {
        feedLoader?.load { [weak self] result in
            if let feeds = try? result.get() {
                self?.onRefresh?(feeds)
            }
            self?.refreshControl?.endRefreshing()
        }
    }
}

final class FeedViewController: UITableViewController, UITableViewDataSourcePrefetching {
    private var refreshViewController: FeedRefreshViewController?
    private var imageLoader: FeedImageDataLoader?
    private var feedLoader: FeedLoader?
    private var tableModel = [FeedImage]() {
        didSet {
            tableView.reloadData()
        }
    }
    private var onViewIsAppearing: ((FeedViewController) -> Void)?
    private var tasks: [IndexPath:FeedImageDataLoaderTask] = [:]

    convenience init(feedLoader:FeedViewControllerTests.LoaderSpy, imageLoader: FeedImageDataLoader) {
        self.init()
        self.refreshViewController = FeedRefreshViewController(feedLoader: feedLoader)
        self.feedLoader = feedLoader
        self.imageLoader = imageLoader
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl = refreshViewController?.refreshControl
        refreshViewController?.onRefresh = { [weak self] feed in
            self?.tableModel = feed
        }
        tableView.prefetchDataSource = self
        onViewIsAppearing = { vc in
            vc.refreshViewController?.refresh()
            vc.refreshControl?.addTarget(vc, action: #selector(vc.refreshViewController?.refresh), for: .valueChanged)
//            vc.refresh()
//            vc.refreshControl?.addTarget(vc, action: #selector(vc.refresh), for: .valueChanged)
            vc.onViewIsAppearing = nil
        }
//        refreshViewController?.refresh()
//        load()
    }
    
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        onViewIsAppearing?(self)
    }
    
//    @objc private func refresh() {
//        refreshControl?.beginRefreshing()
//        load()
//    }
//    
//    @objc private func load() {
//        feedLoader?.load { [weak self] result in
//            if let feeds = try? result.get() {
//                self?.tableModel = feeds
//                self?.tableView.reloadData()
//            }
//            self?.refreshControl?.endRefreshing()
//        }
//    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableModel.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellModel = tableModel[indexPath.row]
        let cell = FeedImageCell()
        cell.locationContainer.isHidden = cellModel.location == nil
        cell.locationLabel.text = cellModel.location
        cell.descriptionLabel.text = cellModel.description
        cell.feedImageView.image = nil
        cell.feedImageRetryButton.isHidden = true
        cell.feedImageContainter.startShimmering()
        
        let loadImage = { [weak self, weak cell] in
            guard let self else { return }
            
            self.tasks[indexPath] = self.imageLoader?.loadimageData(from: cellModel.url) { [weak cell] result in
                let data = try? result.get()
                let image = data.map(UIImage.init) ?? nil
                cell?.feedImageView.image = data.map(UIImage.init) ?? nil
                cell?.feedImageContainter.stopShimmering()
                cell?.feedImageRetryButton.isHidden = (image != nil)
            }
        }
        
        cell.onRetry = loadImage
        loadImage()
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        tasks[indexPath]?.cancel()
        tasks[indexPath] = nil
    }
    
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { path in
            let cellModel = tableModel[path.row]
            _ = imageLoader?.loadimageData(from: cellModel.url) {_ in }
        }
    }
}

final class FeedViewControllerTests: XCTestCase {
    
    func test_loadFeedActions_requestFeedFromLoader() {
        let (sut, loader) = makeSUT()
        XCTAssertEqual(loader.loadFeedCallCount, 0, "Expected no loading requests before view is loaded")
        
        sut.simulateAppearance()
        XCTAssertEqual(loader.loadFeedCallCount, 1)
        
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(loader.loadFeedCallCount, 2)
        
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(loader.loadFeedCallCount, 3)
    }
    
    func test_loadingFeedIndicator_isVisibleWhileLoadingFeed() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(at: 0)
        XCTAssertEqual(sut.isShowingLoadingIndicator, false)

        sut.simulateUserInitiatedReload()
        XCTAssertEqual(sut.isShowingLoadingIndicator, true)
        
        loader.completeFeedLoadingWithError(at: 0)
        XCTAssertEqual(sut.isShowingLoadingIndicator, false)
    }
    
    func test_loadFeedCompletion_renderSuccessfullyLoadedFeed() {
        let image0 = makeImage(description: "a desc", location: "location")
        let image1 = makeImage(description: nil, location: "location")
        let image2 = makeImage(description: "a desc", location: nil)
        let image3 = makeImage(description: nil, location: nil)

        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        assertThat(sut, isRendering: [])
        
        loader.completeFeedLoading(feedImages: [image0] ,at: 0)
        assertThat(sut, isRendering: [image0])

        sut.simulateUserInitiatedReload()
        loader.completeFeedLoading(feedImages: [image0,image1,image2,image3], at: 1)
        assertThat(sut, isRendering: [image0,image1,image2,image3])
    }
    
    func test_loadFeedCompletion_doesnotAlterCurrentRenderingStateOnError() {
        let image0 = makeImage(description: "a desc", location: "location")
        let (sut, loader) = makeSUT()

        sut.simulateAppearance()
        loader.completeFeedLoading(feedImages: [image0] ,at: 0)
        assertThat(sut, isRendering: [image0])

        sut.simulateUserInitiatedReload()
        loader.completeFeedLoadingWithError(at: 1)
        assertThat(sut, isRendering: [image0])
    }
    
    func test_feedImageView_loadsImageURLWhenVisible() {
        let image0 = makeImage(url:URL(string: "http://any-url-0.com")!)
        let image1 = makeImage(url:URL(string: "http://any-url-1.com")!)
        let (sut, loader) = makeSUT()
        sut.simulateAppearance()
        loader.completeFeedLoading(feedImages: [image0,image1] ,at: 0)
        XCTAssertEqual(loader.loadedImageURLs, [],"Expected no image url requests until view become visible")
        
        sut.simulateFeedImageViewVisible(at: 0)
        XCTAssertEqual(loader.loadedImageURLs, [image0.url],"Expected first image url requests once first view become visible")
        sut.simulateFeedImageViewVisible(at: 1)
        XCTAssertEqual(loader.loadedImageURLs, [image0.url, image1.url],"Expected second image url requests once first view become visible")
    }
    
    func test_feedImageView_cancelImageLoadingWhenNotVisibleAnymore() {
        let image0 = makeImage(url:URL(string: "http://any-url-0.com")!)
        let image1 = makeImage(url:URL(string: "http://any-url-1.com")!)
        let (sut, loader) = makeSUT()
        sut.simulateAppearance()
        loader.completeFeedLoading(feedImages: [image0,image1] ,at: 0)
        XCTAssertEqual(loader.cancelImageURLs, [],"Expected no cancelled image url requests until image is not visible")
        
        sut.simulateFeedImageViewNotVisible(at: 0)
        XCTAssertEqual(loader.cancelImageURLs, [image0.url],"Expected first image url requests once first view become visible")
        sut.simulateFeedImageViewNotVisible(at: 1)
        XCTAssertEqual(loader.cancelImageURLs, [image0.url, image1.url],"Expected second image url requests once first view become visible")
    }
    
    func test_feedImageViewLoadingIndicator_isVisibleWhileLoading() {
        let (sut, loader) = makeSUT()
        sut.simulateAppearance()
        loader.completeFeedLoading(feedImages: [makeImage(),makeImage()], at: 0)
        let view1 = sut.simulateFeedImageViewVisible(at: 0)
        let view2 = sut.simulateFeedImageViewVisible(at: 1)
        XCTAssertEqual(view1?.isShowingImageLoadingIndicator, true,"Expected loading indicator for first view while loading first image")
        XCTAssertEqual(view2?.isShowingImageLoadingIndicator, true,"Expected loading indicator for second view while loading second image")

        loader.completeImageLoading(at: 0)
        XCTAssertEqual(view1?.isShowingImageLoadingIndicator, false,"Expected no loading indicator for first view once  first image loading is completed successfully")
        XCTAssertEqual(view2?.isShowingImageLoadingIndicator, true,"Expected no loading indicator for second view once second image loading is completed successfully")
        
        loader.completeImageLoadingWithError(at: 1)
        XCTAssertEqual(view1?.isShowingImageLoadingIndicator, false,"Expected no loading indicator for first view once  first image loading is completed with error")
        XCTAssertEqual(view2?.isShowingImageLoadingIndicator, false,"Expected no loading indicator for second view once second image loading is completed with error")
    }
    
    func test_feedImageViewRetryButton_isVisibleOnImageURLLoadError() {
        let (sut, loader) = makeSUT()
        sut.simulateAppearance()
        loader.completeFeedLoading(feedImages: [makeImage(),makeImage()], at: 0)
        let view1 = sut.simulateFeedImageViewVisible(at: 0)
        let view2 = sut.simulateFeedImageViewVisible(at: 1)
        
        XCTAssertEqual(view1?.isShowingRetryAction, false,"Expected no retry action for first view while loading first image")
        XCTAssertEqual(view2?.isShowingRetryAction, false,"Expected no retry action for second view while loading second image")
        
        let imageData0 = UIImage.make(withColor: .red).pngData()!
        loader.completeImageLoading(with: imageData0,at: 0)
        
        XCTAssertEqual(view1?.isShowingRetryAction, false,"Expected no retry action for first view while loading first image")
        XCTAssertEqual(view2?.isShowingRetryAction, false,"Expected no retry action for second view while loading second image")

        loader.completeImageLoadingWithError(at: 1)
        XCTAssertEqual(view1?.isShowingRetryAction, false,"Expected no retry action for first view while loading first image")
        XCTAssertEqual(view2?.isShowingRetryAction, true,"Expected retry action for second view while loading second image")
    }
    
    func test_feedImageView_rendersImageLoadedFromURL() {
        let (sut, loader) = makeSUT()
        sut.simulateAppearance()
        loader.completeFeedLoading(feedImages: [makeImage(),makeImage()], at: 0)
        let view1 = sut.simulateFeedImageViewVisible(at: 0)
        let view2 = sut.simulateFeedImageViewVisible(at: 1)
        
        XCTAssertEqual(view1?.renderedImage, .none,"Expected no image for first view while loading first image")
        XCTAssertEqual(view2?.renderedImage, .none,"Expected no image for second view while loading second image")
        
        let imageData0 = UIImage.make(withColor: .red).pngData()!
        loader.completeImageLoading(with: imageData0,at: 0)
        
        XCTAssertEqual(view1?.renderedImage, imageData0,"Expected image for first view while loading first image")
        XCTAssertEqual(view2?.renderedImage, .none,"Expected no image for second view while loading second image")

        let imageData1 = UIImage.make(withColor: .blue).pngData()!
        loader.completeImageLoading(with: imageData1,at: 1)
        
        XCTAssertEqual(view1?.renderedImage, imageData0,"Expected image for first view while loading first image")
        XCTAssertEqual(view2?.renderedImage, imageData1,"Expected image for second view while loading second image")
    }
    
    func test_feedImageViewRetryButton_isVisibleOnInvalidImageData() {
        let (sut, loader) = makeSUT()
        sut.simulateAppearance()
        loader.completeFeedLoading(feedImages: [makeImage()], at: 0)
        let view1 = sut.simulateFeedImageViewVisible(at: 0)
        
        XCTAssertEqual(view1?.isShowingRetryAction, false,"Expected no retry action while loading image")
        let imageData0 = Data("not an image".utf8)
        loader.completeImageLoading(with: imageData0,at: 0)

        XCTAssertEqual(view1?.isShowingRetryAction, true,"Expected retry action once image loaded with invalid data")
    }
    
    func test_feedImageViewRetryButton_retriesImageLoad() {
        let image0 = makeImage(url:URL(string: "http://any-url-0.com")!)
        let image1 = makeImage(url:URL(string: "http://any-url-1.com")!)
        let (sut, loader) = makeSUT()
        sut.simulateAppearance()
        loader.completeFeedLoading(feedImages: [image0,image1] ,at: 0)
        
        XCTAssertEqual(loader.loadedImageURLs, [], "Expected no image url request until a view is near visible")

        sut.simulateFeedImageViewNearVisible(at: 0)
        XCTAssertEqual(loader.loadedImageURLs, [image0.url], "Expected first image url request for the one near visible views")

        sut.simulateFeedImageViewNearVisible(at: 1)
        
        XCTAssertEqual(loader.loadedImageURLs, [image0.url,image1.url], "Expected two image url request for the two near visible views")
    }
    
    func test_feedImageViewRetryButton_preloadsImageURLWhenNearVisible() {
        let image0 = makeImage(url:URL(string: "http://any-url-0.com")!)
        let image1 = makeImage(url:URL(string: "http://any-url-1.com")!)
        let (sut, loader) = makeSUT()
        sut.simulateAppearance()
        loader.completeFeedLoading(feedImages: [image0,image1] ,at: 0)
    }

    
    private func assertThat(_ sut: FeedViewController, isRendering feed:[FeedImage], file: StaticString = #file, line: UInt = #line) {
        guard sut.numberOfRenderedFeedImageViews() == feed.count else {
            XCTFail("Expected \(feed.count) images, got \(sut.numberOfRenderedFeedImageViews()) instead.",file: file,line: line)
            return
        }
        
        feed.enumerated().forEach { index,image in
            assertThat(sut, hasConfigurationFor: image, at: index)
        }
    }
    
    private func assertThat(_ sut: FeedViewController, hasConfigurationFor image:FeedImage, at index:Int,file: StaticString = #file, line: UInt = #line) {
        let view = sut.feedImageView(at: index)
        guard let cell = view as? FeedImageCell else {
            return XCTFail("Expected \(FeedImageCell.self) instance, but got \(String(describing: view)) instead", file: file,line: line)
        }
        let shouldLocationBeVisible = image.location != nil
        XCTAssertEqual(cell.isShowingLocation, shouldLocationBeVisible, "Expected `isshowinglocation` to be \(shouldLocationBeVisible) for image view at index \(index)",file: file,line: line)
        XCTAssertEqual(cell.locationText, image.location, "Expected `location text` to be \(String(describing: image.location)) for image view at index \(index)",file: file,line: line)
        XCTAssertEqual(cell.descriptionText, image.description, "Expected `description text` to be \(String(describing: image.description)) for image view at index \(index)",file: file,line: line)
    }
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut:FeedViewController,loader:LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedViewController(feedLoader:loader, imageLoader: loader)
        trackForMemortyLeaks(loader, file: file, line: line)
        trackForMemortyLeaks(sut, file: file, line: line)
        return (sut, loader)
    }
    
    private func makeImage(description:String? = nil, location: String? = nil, url: URL = URL(string:"http://any-url.com")!) -> FeedImage {
        FeedImage(
            id: UUID(),
            description: description,
            location: location,
            url: url
        )
    }
    
    class LoaderSpy: FeedLoader, FeedImageDataLoader {
        private struct TaskSpy: FeedImageDataLoaderTask {
            let cancelCallBack: () -> Void
            func cancel() {
                cancelCallBack()
            }
        }
        private var feedRequests = [(FeedLoader.Result)-> Void]()
        private var imageRequests: [(url: URL, completaion: (Result<Data, Error>) -> Void)] = []
        
        var loadFeedCallCount:Int {
            feedRequests.count
        }
        
        var loadedImageURLs: [URL] {
            imageRequests.map{$0.url}
        }
        
        private(set) var cancelImageURLs: [URL] = []

        func load(completion: @escaping (EssentialFeed.FeedLoader.Result) -> Void) {
            feedRequests.append(completion)
        }
        
        func completeFeedLoading(feedImages:[FeedImage] = [],at index:Int) {
            feedRequests[index](.success(feedImages))
        }
        
        func completeFeedLoadingWithError(at index:Int) {
            let error = NSError(domain: "any Error", code: 0)
            feedRequests[index](.failure(error))
        }
        
        func loadimageData(from url: URL, completion: @escaping (Result<Data, Error>) -> Void) -> FeedImageDataLoaderTask {
            imageRequests.append((url,completion))
            return TaskSpy(cancelCallBack: { [weak self] in self?.cancelImageURLs.append(url)})
        }
        
        func completeImageLoading(with imageData:Data = Data(),at index:Int = 0) {
            imageRequests[index].completaion(.success(imageData))
        }
        
        func completeImageLoadingWithError(at index:Int = 0) {
            let error = NSError(domain: "any Error", code: 0)
            imageRequests[index].completaion(.failure(error))
        }
    }
    
    
}

private extension UIRefreshControl {
    func simulatePullToRefresh() {
        allTargets.forEach { target in
           actions(forTarget: target, forControlEvent: .valueChanged)?.forEach {
                (target as NSObject).perform(Selector($0))
            }
        }
    }
}

private extension UIButton {
    func simulateTap() {
        allTargets.forEach { target in
           actions(forTarget: target, forControlEvent: .touchUpInside)?.forEach {
                (target as NSObject).perform(Selector($0))
            }
        }
    }
}


private extension FeedViewController {
    var isShowingLoadingIndicator: Bool {
        return refreshControl?.isRefreshing == true
    }
    
    func simulateAppearance() {
        if !isViewLoaded {
            loadViewIfNeeded()
            prepareForFirstAppearance()
        }
        
        beginAppearanceTransition(true, animated: false)
        endAppearanceTransition()
    }
    
    func numberOfRenderedFeedImageViews() -> Int {
        return tableView.numberOfRows(inSection: feedImagesSection)
    }
    
    func simulateUserInitiatedReload() {
        refreshControl?.simulatePullToRefresh()
    }
    
    @discardableResult
    func simulateFeedImageViewVisible(at index: Int) -> FeedImageCell? {
        return feedImageView(at: index) as? FeedImageCell
    }
    
    func simulateFeedImageViewNearVisible(at row: Int) {
        let ds = tableView.prefetchDataSource
        let index = IndexPath(row: row, section: feedImagesSection)
        ds?.tableView(tableView, prefetchRowsAt: [index])
    }
    
    func simulateFeedImageViewNotVisible(at row: Int) {
        let view = simulateFeedImageViewVisible(at: row)
        let delegate = tableView.delegate
        let index = IndexPath(row: row, section: feedImagesSection)
        delegate?.tableView?(tableView, didEndDisplaying: view!, forRowAt: index)
    }
    
    private func prepareForFirstAppearance() {
        setSmallFrameToPreventRenderingCells()
        replaceRefreshControlWithFakeForiOS17PlusSupport()
    }
    
    private func setSmallFrameToPreventRenderingCells() {
        tableView.frame = CGRect(x: 0, y: 0, width: 390, height: 1)
    }
    
    private func replaceRefreshControlWithFakeForiOS17PlusSupport() {
        let fakeRefreshControl = FakeUIRefreshControl()
        
        refreshControl?.allTargets.forEach { target in
            refreshControl?.actions(forTarget: target, forControlEvent: .valueChanged)?.forEach { action in
                fakeRefreshControl.addTarget(target, action: Selector(action), for: .valueChanged)
            }
        }
        
        refreshControl = fakeRefreshControl
    }
    
    private var feedImagesSection: Int {
        return 0
    }
    
    func feedImageView(at row: Int) -> UITableViewCell? {
        let ds = tableView.dataSource
        let index = IndexPath(row: row, section: feedImagesSection)
        return ds?.tableView(tableView, cellForRowAt: index)
    }
}

private class FakeUIRefreshControl: UIRefreshControl {
    private var _isRefreshing = false
    
    override var isRefreshing: Bool { _isRefreshing }
    
    override func beginRefreshing() {
        _isRefreshing = true
    }
    
    override func endRefreshing() {
        _isRefreshing = false
    }
}

private extension FeedImageCell {
    var isShowingLocation: Bool {
        return !locationContainer.isHidden
    }
    
    var isShowingImageLoadingIndicator: Bool {
        return feedImageContainter.isShimmering
    }
    
    var locationText: String? {
        return locationLabel.text
    }
    
    var descriptionText: String? {
        return descriptionLabel.text
    }
    
    var renderedImage: Data? {
        return feedImageView.image?.pngData()
    }
    
    var isShowingRetryAction: Bool {
        return !feedImageRetryButton.isHidden
    }
    
    func simulateRetryAction() {
        feedImageRetryButton.simulateTap()
    }
}


extension UIImage {
    static func make(withColor color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        return UIGraphicsImageRenderer(size: rect.size, format: format).image { rendererContext in
            color.setFill()
            rendererContext.fill(rect)
        }
    }
}
