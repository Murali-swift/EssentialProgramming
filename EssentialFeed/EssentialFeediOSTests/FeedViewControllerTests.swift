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
}

protocol FeedImageDataLoader {
    func loadimageData(from url:URL)
    func cancelImageDataLoad(from url:URL)
}

final class FeedViewController: UITableViewController {
    private var feedLoader: FeedLoader?
    private var imageLoader: FeedImageDataLoader?
    private var tableModel = [FeedImage]()
    private var onViewIsAppearing: ((FeedViewController) -> Void)?

    convenience init(feedLoader:FeedViewControllerTests.LoaderSpy, imageLoader: FeedImageDataLoader) {
        self.init()
        self.feedLoader = feedLoader
        self.imageLoader = imageLoader
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
        onViewIsAppearing = { vc in
            vc.refresh()
            vc.refreshControl?.addTarget(vc, action: #selector(vc.refresh), for: .valueChanged)
            vc.onViewIsAppearing = nil
        }
        load()
    }
    
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        onViewIsAppearing?(self)
    }
    
    @objc private func refresh() {
        refreshControl?.beginRefreshing()
    }
    
    @objc private func load() {
        feedLoader?.load { [weak self] result in
            if let feeds = try? result.get() {
                self?.tableModel = feeds
                self?.tableView.reloadData()
            }
            self?.refreshControl?.endRefreshing()
        }
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableModel.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellModel = tableModel[indexPath.row]
        let cell = FeedImageCell()
        cell.locationContainer.isHidden = cellModel.location == nil
        cell.locationLabel.text = cellModel.location
        cell.descriptionLabel.text = cellModel.description
        imageLoader?.loadimageData(from: cellModel.url)
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        let cellModel = tableModel[indexPath?.row ?? 0]
        imageLoader?.cancelImageDataLoad(from: cellModel.url)
    }
}

final class FeedViewControllerTests: XCTestCase {
    
    func test_loadFeedActions_requestFeedFromLoader() {
        let (sut, loader) = makeSUT()
        XCTAssertEqual(loader.loadFeedCallCount, 0, "Expected no loading requests before view is loaded")
        
        sut.loadViewIfNeeded()
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
        
        loader.completeFeedLoadingWithError(at: 1)
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
        private var feedRequests = [(FeedLoader.Result)-> Void]()
        
        var loadFeedCallCount:Int {
            feedRequests.count
        }
        
        private(set) var loadedImageURLs: [URL] = []
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
        
        func loadimageData(from url: URL) {
            loadedImageURLs.append(url)
        }
        
        func cancelImageDataLoad(from url: URL) {
            cancelImageURLs.append(url)
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
    
    var locationText: String? {
        return locationLabel.text
    }
    
    var descriptionText: String? {
        return descriptionLabel.text
    }
}
