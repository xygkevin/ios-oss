@testable import KsApi
@testable import Library
import Prelude
import ReactiveExtensions_TestHelpers
import ReactiveSwift
import XCTest

final class ProjectPamphletViewModelTests: TestCase {
  private let releaseBundle = MockBundle(
    bundleIdentifier: KickstarterBundleIdentifier.release.rawValue,
    lang: "en"
  )
  fileprivate var vm: ProjectPamphletViewModelType!

  private let configureChildViewControllersWithProject = TestObserver<Project, Never>()
  private let configureChildViewControllersWithRefTag = TestObserver<RefTag?, Never>()
  private let configurePledgeCTAViewContext = TestObserver<PledgeCTAContainerViewContext, Never>()
  private let configurePledgeCTAViewErrorEnvelope = TestObserver<ErrorEnvelope, Never>()
  private let configurePledgeCTAViewProject = TestObserver<Project, Never>()
  private let configurePledgeCTAViewIsLoading = TestObserver<Bool, Never>()
  private let configurePledgeCTAViewRefTag = TestObserver<RefTag?, Never>()
  private let dismissManagePledgeAndShowMessageBannerWithMessage = TestObserver<String, Never>()
  private let goToManagePledgeProjectParam = TestObserver<Param, Never>()
  private let goToManagePledgeBackingParam = TestObserver<Param?, Never>()
  private let goToRewardsProject = TestObserver<Project, Never>()
  private let goToRewardsRefTag = TestObserver<RefTag?, Never>()
  private let popToRootViewController = TestObserver<(), Never>()
  private let setNavigationBarHidden = TestObserver<Bool, Never>()
  private let setNavigationBarAnimated = TestObserver<Bool, Never>()
  private let setNeedsStatusBarAppearanceUpdate = TestObserver<(), Never>()
  private let topLayoutConstraintConstant = TestObserver<CGFloat, Never>()

  internal override func setUp() {
    super.setUp()

    self.vm = ProjectPamphletViewModel()
    self.vm.outputs.configureChildViewControllersWithProject.map(first)
      .observe(self.configureChildViewControllersWithProject.observer)
    self.vm.outputs.configureChildViewControllersWithProject.map(second)
      .observe(self.configureChildViewControllersWithRefTag.observer)

    self.vm.outputs.configurePledgeCTAView
      .map(first)
      .map(\.left)
      .skipNil()
      .map(first)
      .observe(self.configurePledgeCTAViewProject.observer)

    self.vm.outputs.configurePledgeCTAView
      .map(first)
      .map(\.left)
      .skipNil()
      .map(second)
      .observe(self.configurePledgeCTAViewRefTag.observer)

    self.vm.outputs.configurePledgeCTAView
      .map(first)
      .map(\.right)
      .skipNil()
      .observe(self.configurePledgeCTAViewErrorEnvelope.observer)

    self.vm.outputs.configurePledgeCTAView.map(second).observe(self.configurePledgeCTAViewIsLoading.observer)
    self.vm.outputs.configurePledgeCTAView.map(third).observe(self.configurePledgeCTAViewContext.observer)
    self.vm.outputs.dismissManagePledgeAndShowMessageBannerWithMessage
      .observe(self.dismissManagePledgeAndShowMessageBannerWithMessage.observer)
    self.vm.outputs.goToManagePledge.map(first).observe(self.goToManagePledgeProjectParam.observer)
    self.vm.outputs.goToManagePledge.map(second).observe(self.goToManagePledgeBackingParam.observer)
    self.vm.outputs.goToRewards.map(first).observe(self.goToRewardsProject.observer)
    self.vm.outputs.goToRewards.map(second).observe(self.goToRewardsRefTag.observer)
    self.vm.outputs.popToRootViewController.observe(self.popToRootViewController.observer)
    self.vm.outputs.setNavigationBarHiddenAnimated.map(first)
      .observe(self.setNavigationBarHidden.observer)
    self.vm.outputs.setNavigationBarHiddenAnimated.map(second)
      .observe(self.setNavigationBarAnimated.observer)
    self.vm.outputs.setNeedsStatusBarAppearanceUpdate.observe(self.setNeedsStatusBarAppearanceUpdate.observer)
    self.vm.outputs.topLayoutConstraintConstant.observe(self.topLayoutConstraintConstant.observer)
  }

  func testConfigureChildViewControllersWithProject_WithFriendsNoBacking_ConfiguredWithProject() {
    let project = Project.template
    let friends = [User.template]
    let refTag = RefTag.category
    let projectPamphletData = Project.ProjectPamphletData(project: project, backingId: nil)

    withEnvironment(apiService: MockService(
      fetchManagePledgeViewBackingResult: .success(.template),
      fetchProjectPamphletResult: .success(projectPamphletData),
      fetchProjectFriendsResult: .success(friends),
      fetchProjectRewardsResult: .success([.template])
    )) {
      self.vm.inputs.configureWith(projectOrParam: .left(project), refTag: refTag)
      self.vm.inputs.viewDidLoad()
      self.vm.inputs.viewDidAppear(animated: false)

      self.configureChildViewControllersWithProject.assertValues([project])
      self.configureChildViewControllersWithRefTag.assertValues([refTag])

      self.scheduler.advance()

      self.configureChildViewControllersWithProject.assertValues([project, project])
      self.configureChildViewControllersWithRefTag.assertValues([refTag, refTag])

      self.vm.inputs.didBackProject()

      self.scheduler.advance()

      self.configureChildViewControllersWithProject.assertValues([project, project, project])
      self.configureChildViewControllersWithRefTag.assertValues([refTag, refTag, refTag])

      self.vm.inputs.managePledgeViewControllerFinished(with: nil)

      self.scheduler.advance()

      self.configureChildViewControllersWithProject.assertValues([project, project, project, project])
      self.configureChildViewControllersWithRefTag.assertValues([refTag, refTag, refTag, refTag])
    }
  }

  func testConfigureChildViewControllersWithProject_FailedProjectFriendsNoBacking_ConfiguredWithProject() {
    let project = Project.template
    let refTag = RefTag.category
    let projectPamphletData = Project.ProjectPamphletData(project: project, backingId: nil)

    withEnvironment(apiService: MockService(
      fetchManagePledgeViewBackingResult: .success(.template),
      fetchProjectPamphletResult: .success(projectPamphletData),
      fetchProjectFriendsResult: .failure(.couldNotParseJSON),
      fetchProjectRewardsResult: .success([.template])
    )) {
      self.vm.inputs.configureWith(projectOrParam: .left(project), refTag: refTag)
      self.vm.inputs.viewDidLoad()
      self.vm.inputs.viewDidAppear(animated: false)

      self.configureChildViewControllersWithProject.assertValues([project])
      self.configureChildViewControllersWithRefTag.assertValues([refTag])

      self.scheduler.advance()

      self.configureChildViewControllersWithProject.assertValues([project, project])
      self.configureChildViewControllersWithRefTag.assertValues([refTag, refTag])

      self.vm.inputs.didBackProject()

      self.scheduler.advance()

      self.configureChildViewControllersWithProject.assertValues([project, project, project])
      self.configureChildViewControllersWithRefTag.assertValues([refTag, refTag, refTag])

      self.vm.inputs.managePledgeViewControllerFinished(with: nil)

      self.scheduler.advance()

      self.configureChildViewControllersWithProject.assertValues([project, project, project, project])
      self.configureChildViewControllersWithRefTag.assertValues([refTag, refTag, refTag, refTag])
    }
  }

  func testConfigureChildViewControllersWithProject_WithFriendsNoBacking_ConfiguredWithParam() {
    let project = .template |> Project.lens.id .~ 42
    let projectPamphletData = Project.ProjectPamphletData(project: project, backingId: nil)
    let friends = [User.template]

    withEnvironment(apiService: MockService(
      fetchManagePledgeViewBackingResult: .success(.template),
      fetchProjectPamphletResult: .success(projectPamphletData),
      fetchProjectFriendsResult: .success(friends),
      fetchProjectRewardsResult: .success([.template])
    )) {
      self.vm.inputs.configureWith(projectOrParam: .right(.id(project.id)), refTag: nil)
      self.vm.inputs.viewDidLoad()
      self.vm.inputs.viewWillAppear(animated: false)
      self.vm.inputs.viewDidAppear(animated: false)

      self.configureChildViewControllersWithProject.assertValues([])
      self.configureChildViewControllersWithRefTag.assertValues([])

      self.scheduler.advance()

      self.configureChildViewControllersWithProject.assertValues([project])
      self.configureChildViewControllersWithRefTag.assertValues([nil])

      self.vm.inputs.didBackProject()

      self.scheduler.advance()

      self.configureChildViewControllersWithProject.assertValues([project, project])
      self.configureChildViewControllersWithRefTag.assertValues([nil, nil])

      self.vm.inputs.managePledgeViewControllerFinished(with: nil)

      self.scheduler.advance()

      self.configureChildViewControllersWithProject.assertValues([project, project, project])
      self.configureChildViewControllersWithRefTag.assertValues([nil, nil, nil])
    }
  }

  func testConfiguredProject_WithFriendsNoBacking_Succcessfully() {
    let project = Project.template
    let friends = [User.template, User.brando]
    let projectPamphletData = Project.ProjectPamphletData(project: project, backingId: nil)
    let refTag = RefTag.category

    withEnvironment(apiService: MockService(
      fetchManagePledgeViewBackingResult: .success(.template),
      fetchProjectPamphletResult: .success(projectPamphletData),
      fetchProjectFriendsResult: .success(friends),
      fetchProjectRewardsResult: .success([.template])
    )) {
      self.vm.inputs.configureWith(projectOrParam: .left(project), refTag: refTag)
      self.vm.inputs.viewDidLoad()
      self.vm.inputs.viewDidAppear(animated: false)

      let projectWithFriends = project |> \.personalization.friends .~ friends

      self.scheduler.advance()

      XCTAssertEqual(
        self.configureChildViewControllersWithProject.values.last!.personalization.friends,
        friends
      )
      self.configureChildViewControllersWithProject.assertValues([projectWithFriends, projectWithFriends])
    }
  }

  func testConfiguredProject_WithNoFriendsNoBacking_Unsucccessfully() {
    let project = Project.template
    let refTag = RefTag.category
    let projectPamphletData = Project.ProjectPamphletData(project: project, backingId: nil)

    withEnvironment(apiService: MockService(
      fetchManagePledgeViewBackingResult: .success(.template),
      fetchProjectPamphletResult: .success(projectPamphletData),
      fetchProjectFriendsResult: .failure(.couldNotParseJSON),
      fetchProjectRewardsResult: .success([.template])
    )) {
      self.vm.inputs.configureWith(projectOrParam: .left(project), refTag: refTag)
      self.vm.inputs.viewDidLoad()
      self.vm.inputs.viewDidAppear(animated: false)

      self.scheduler.advance()

      XCTAssertTrue(self.configureChildViewControllersWithProject.values.last!.personalization.friends!
        .isEmpty)
      self.configureChildViewControllersWithProject.assertValues([project, project])
    }
  }

  func testConfiguredProject_WithFriendsWithBacking_Succcessfully() {
    let project = Project.template
    let refTag = RefTag.category
    let friends = [User.template, User.brando]
    let projectPamphletData = Project.ProjectPamphletData(project: project, backingId: 1)

    withEnvironment(apiService: MockService(
      fetchManagePledgeViewBackingResult: .success(.template),
      fetchProjectPamphletResult: .success(projectPamphletData),
      fetchProjectFriendsResult: .success(friends),
      fetchProjectRewardsResult: .success([.template])
    )) {
      self.vm.inputs.configureWith(projectOrParam: .left(project), refTag: refTag)
      self.vm.inputs.viewDidLoad()
      self.vm.inputs.viewDidAppear(animated: false)

      let projectWithBacking = project |> \.personalization.backing .~ .template
        |> \.personalization.isBacking .~ true

      self.scheduler.advance()

      XCTAssertEqual(
        self.configureChildViewControllersWithProject.values.last!.personalization.backing,
        .template
      )
      XCTAssertTrue(
        self.configureChildViewControllersWithProject.values.last!.personalization.isBacking!)
      self.configureChildViewControllersWithProject.assertValues([projectWithBacking, projectWithBacking])
    }
  }

  func testNavigationBar() {
    self.vm.inputs.configureWith(projectOrParam: .left(.template), refTag: nil)
    self.vm.inputs.viewDidLoad()

    self.setNavigationBarHidden.assertValues([true])
    self.setNavigationBarAnimated.assertValues([false])

    self.vm.inputs.viewWillAppear(animated: false)
    self.vm.inputs.viewDidAppear(animated: false)

    self.setNavigationBarHidden.assertValues([true])
    self.setNavigationBarAnimated.assertValues([false])

    self.vm.inputs.viewWillAppear(animated: true)
    self.vm.inputs.viewDidAppear(animated: true)

    self.setNavigationBarHidden.assertValues([true, true])
    self.setNavigationBarAnimated.assertValues([false, true])

    self.vm.inputs.viewWillAppear(animated: false)
    self.vm.inputs.viewDidAppear(animated: true)

    self.setNavigationBarHidden.assertValues([true, true, true])
    self.setNavigationBarAnimated.assertValues([false, true, false])
  }

  // Tests that ref tags and referral credit cookies are tracked and saved like we expect.
  func testTracksRefTag() {
    let project = Project.template
    let projectPamphletData = Project.ProjectPamphletData(project: .template, backingId: nil)

    withEnvironment(apiService: MockService(
      fetchProjectPamphletResult: .success(projectPamphletData),
      fetchProjectRewardsResult: .success([
        Reward.noReward,
        Reward.template
      ])
    )) {
      self.vm.inputs.configureWith(projectOrParam: .left(project), refTag: .category)
      self.vm.inputs.viewDidLoad()
      self.vm.inputs.viewWillAppear(animated: false)
      self.vm.inputs.viewDidAppear(animated: false)

      self.scheduler.advance()

      XCTAssertEqual(
        ["Page Viewed"],
        self.segmentTrackingClient.events, "A project page event is tracked."
      )

      XCTAssertEqual(
        [RefTag.category.stringTag],
        self.segmentTrackingClient.properties.compactMap { $0["session_ref_tag"] as? String },
        "The ref tag is tracked in the event."
      )
      XCTAssertEqual(
        1, self.cookieStorage.cookies?.count,
        "A single cookie is set"
      )
      XCTAssertEqual(
        "ref_\(project.id)", self.cookieStorage.cookies?.last?.name,
        "A referral cookie is set for the project."
      )
      XCTAssertEqual(
        "category?",
        (self.cookieStorage.cookies?.last?.value.prefix(9)).map(String.init),
        "A referral cookie is set for the category ref tag."
      )

      // Start up another view model with the same project
      let newVm: ProjectPamphletViewModelType = ProjectPamphletViewModel()
      newVm.inputs.configureWith(projectOrParam: .left(project), refTag: .recommended)
      newVm.inputs.viewDidLoad()
      newVm.inputs.viewWillAppear(animated: true)
      newVm.inputs.viewDidAppear(animated: true)

      self.scheduler.advance()

      XCTAssertEqual(
        [
          "Page Viewed", "Page Viewed"
        ],
        self.segmentTrackingClient.events, "A project page event is tracked."
      )

      XCTAssertEqual(
        [
          RefTag.category.stringTag,
          RefTag.recommended.stringTag
        ],
        self.segmentTrackingClient.properties.compactMap { $0["session_ref_tag"] as? String },
        "The new ref tag is tracked in an event."
      )
      XCTAssertEqual(
        1, self.cookieStorage.cookies?.count,
        "A single cookie has been set."
      )
    }
  }

  func testProjectPageViewed_Tracking_OnError() {
    let service = MockService(fetchProjectPamphletResult: .failure(.couldNotParseJSON))

    withEnvironment(apiService: service) {
      self.configureInitialState(.init(left: .template))

      self.scheduler.advance()

      XCTAssertEqual(
        [],
        self.segmentTrackingClient.events,
        "Project Page Viewed doesnt track if the request fails"
      )
    }
  }

  func testProjectPageViewed_OnViewDidAppear() {
    let projectPamphletData = Project.ProjectPamphletData(project: .template, backingId: nil)

    withEnvironment(apiService: MockService(
      fetchProjectPamphletResult: .success(projectPamphletData),
      fetchProjectRewardsResult: .success([Reward.noReward, Reward.template])
    )) {
      XCTAssertEqual([], self.segmentTrackingClient.events)

      self.configureInitialState(.init(left: .template))

      self.scheduler.advance()

      XCTAssertEqual(["Page Viewed"], self.segmentTrackingClient.events)

      XCTAssertEqual(["project"], self.segmentTrackingClient.properties(forKey: "context_page"))
      XCTAssertEqual(["overview"], self.segmentTrackingClient.properties(forKey: "context_section"))
      XCTAssertEqual(["discovery"], self.segmentTrackingClient.properties(forKey: "session_ref_tag"))
    }
  }

  func testMockCookieStorageSet_SeparateSchedulers() {
    let project = Project.template
    let scheduler1 = TestScheduler(startDate: MockDate().date)
    let scheduler2 = TestScheduler(startDate: scheduler1.currentDate.addingTimeInterval(1))
    let projectPamphletData = Project.ProjectPamphletData(project: .template, backingId: nil)

    withEnvironment(
      apiService: MockService(
        fetchProjectPamphletResult: .success(projectPamphletData),
        fetchProjectRewardsResult: .success([.template])
      ),
      scheduler: scheduler1
    ) {
      let newVm: ProjectPamphletViewModelType = ProjectPamphletViewModel()
      newVm.inputs.configureWith(projectOrParam: .left(project), refTag: .category)
      newVm.inputs.viewDidLoad()
      newVm.inputs.viewWillAppear(animated: true)
      newVm.inputs.viewDidAppear(animated: true)

      scheduler1.advance()

      XCTAssertEqual(1, self.cookieStorage.cookies?.count, "A single cookie has been set.")
    }

    withEnvironment(
      apiService: MockService(
        fetchProjectPamphletResult: .success(projectPamphletData),
        fetchProjectRewardsResult: .success([.template])
      ),
      scheduler: scheduler2
    ) {
      let newVm: ProjectPamphletViewModelType = ProjectPamphletViewModel()
      newVm.inputs.configureWith(projectOrParam: .left(project), refTag: .recommended)
      newVm.inputs.viewDidLoad()
      newVm.inputs.viewWillAppear(animated: true)
      newVm.inputs.viewDidAppear(animated: true)

      scheduler2.advance()

      XCTAssertEqual(2, self.cookieStorage.cookies?.count, "Two cookies are set on separate schedulers.")
    }
  }

  func testMockCookieStorageSet_SameScheduler() {
    let project = Project.template
    let scheduler1 = TestScheduler(startDate: MockDate().date)

    withEnvironment(scheduler: scheduler1) {
      let newVm: ProjectPamphletViewModelType = ProjectPamphletViewModel()
      newVm.inputs.configureWith(projectOrParam: .left(project), refTag: .category)
      newVm.inputs.viewDidLoad()
      newVm.inputs.viewWillAppear(animated: true)
      newVm.inputs.viewDidAppear(animated: true)

      scheduler1.advance()

      XCTAssertEqual(1, self.cookieStorage.cookies?.count, "A single cookie has been set.")
    }

    withEnvironment(scheduler: scheduler1) {
      let newVm: ProjectPamphletViewModelType = ProjectPamphletViewModel()
      newVm.inputs.configureWith(projectOrParam: .left(project), refTag: .recommended)
      newVm.inputs.viewDidLoad()
      newVm.inputs.viewWillAppear(animated: true)
      newVm.inputs.viewDidAppear(animated: true)

      scheduler1.advance()

      XCTAssertEqual(
        1, self.cookieStorage.cookies?.count,
        "A single cookie has been set on the same scheduler."
      )
    }
  }

  func testTopLayoutConstraints_AfterRotation() {
    self.vm.inputs.initial(topConstraint: 30.0)
    XCTAssertNil(self.topLayoutConstraintConstant.lastValue)

    self.vm.inputs.willTransition(toNewCollection: UITraitCollection(horizontalSizeClass: .compact))
    XCTAssertEqual(30.0, self.topLayoutConstraintConstant.lastValue)
  }

  func testTracksRefTag_WithBadData() {
    let project = Project.template
    let projectPamphletData = Project.ProjectPamphletData(project: .template, backingId: nil)

    withEnvironment(apiService: MockService(
      fetchProjectPamphletResult: .success(projectPamphletData),
      fetchProjectFriendsResult: .success([.template]),
      fetchProjectRewardsResult: .success([.template])
    )) {
      self.vm.inputs.configureWith(
        projectOrParam: .left(project), refTag: RefTag.unrecognized("category%3F1232")
      )
      self.vm.inputs.viewDidLoad()
      self.vm.inputs.viewWillAppear(animated: false)
      self.vm.inputs.viewDidAppear(animated: false)

      self.scheduler.advance()

      XCTAssertEqual(
        ["Page Viewed"],
        self.segmentTrackingClient.events, "A project page event is tracked."
      )

      XCTAssertEqual(
        [RefTag.category.stringTag],
        self.segmentTrackingClient.properties.compactMap { $0["session_ref_tag"] as? String },
        "The ref tag is tracked in the event."
      )
      XCTAssertEqual(
        1, self.cookieStorage.cookies?.count,
        "A single cookie is set"
      )
      XCTAssertEqual(
        "ref_\(project.id)", self.cookieStorage.cookies?.last?.name,
        "A referral cookie is set for the project."
      )
      XCTAssertEqual(
        "category?",
        (self.cookieStorage.cookies?.last?.value.prefix(9)).map(String.init),
        "A referral cookie is set for the category ref tag."
      )

      // Start up another view model with the same project
      let newVm: ProjectPamphletViewModelType = ProjectPamphletViewModel()
      newVm.inputs.configureWith(projectOrParam: .left(project), refTag: .recommended)
      newVm.inputs.viewDidLoad()
      newVm.inputs.viewWillAppear(animated: true)
      newVm.inputs.viewDidAppear(animated: true)

      self.scheduler.advance()

      XCTAssertEqual(
        [
          "Page Viewed", "Page Viewed"
        ],
        self.segmentTrackingClient.events, "A project page event is tracked."
      )

      XCTAssertEqual(
        [
          RefTag.category.stringTag,
          RefTag.recommended.stringTag
        ],
        self.segmentTrackingClient.properties.compactMap { $0["session_ref_tag"] as? String },
        "The new ref tag is tracked in an event."
      )
      XCTAssertEqual(
        1, self.cookieStorage.cookies?.count,
        "A single cookie has been set."
      )
    }
  }

  func testTrackingDoesNotOccurOnLoad() {
    let project = Project.template

    self.vm.inputs.configureWith(
      projectOrParam: .left(project), refTag: RefTag.unrecognized("category%3F1232")
    )
    self.vm.inputs.viewDidLoad()

    self.scheduler.advance()

    XCTAssertEqual([], self.segmentTrackingClient.events)
  }

  func testGoToRewards() {
    withEnvironment(config: .template, mainBundle: self.releaseBundle) {
      let project = Project.template

      self.configureInitialState(.left(project))

      self.goToRewardsProject.assertDidNotEmitValue()
      self.goToRewardsRefTag.assertDidNotEmitValue()

      self.vm.inputs.pledgeCTAButtonTapped(with: .pledge)

      self.goToRewardsProject.assertValues([project], "Tapping 'Back this project' emits the project")
      self.goToRewardsRefTag.assertValues([.discovery], "Tapping 'Back this project' emits the refTag")

      self.vm.inputs.pledgeCTAButtonTapped(with: .viewRewards)

      self.goToRewardsProject.assertValues(
        [project, project],
        "Tapping 'View rewards' emits the project"
      )
      self.goToRewardsRefTag.assertValues(
        [.discovery, .discovery],
        "Tapping 'View rewards' emits the refTag"
      )

      self.vm.inputs.pledgeCTAButtonTapped(with: .viewYourRewards)

      self.goToRewardsProject.assertValues(
        [project, project, project],
        "Tapping 'View your rewards' emits the project"
      )
      self.goToRewardsRefTag.assertValues(
        [.discovery, .discovery, .discovery],
        "Tapping 'View your rewards' emits the refTag"
      )
    }
  }

  func testGoToManageViewPledge_ManagingPledge() {
    withEnvironment(config: .template) {
      let reward = Project.cosmicSurgery.rewards.first!
      let backing = Backing.template
        |> Backing.lens.reward .~ reward
        |> Backing.lens.rewardId .~ reward.id

      let project = Project.cosmicSurgery
        |> Project.lens.personalization.backing .~ backing
        |> Project.lens.personalization.isBacking .~ true

      self.configureInitialState(.left(project))

      self.goToManagePledgeProjectParam.assertDidNotEmitValue()
      self.goToManagePledgeBackingParam.assertDidNotEmitValue()

      self.vm.inputs.pledgeCTAButtonTapped(with: .manage)

      self.goToManagePledgeProjectParam.assertValues([.slug(project.slug)])
      self.goToManagePledgeBackingParam.assertValues([.id(backing.id)])
    }
  }

  func testGoToManageViewPledge_ViewingPledge() {
    withEnvironment(config: .template, currentUser: .template) {
      let reward = Project.cosmicSurgery.rewards.first!
      let backing = Backing.template
        |> Backing.lens.reward .~ reward
        |> Backing.lens.rewardId .~ reward.id

      let project = Project.cosmicSurgery
        |> Project.lens.state .~ .successful
        |> Project.lens.personalization.backing .~ backing
        |> Project.lens.personalization.isBacking .~ true

      self.configureInitialState(.left(project))

      self.goToManagePledgeProjectParam.assertDidNotEmitValue()
      self.goToManagePledgeBackingParam.assertDidNotEmitValue()

      self.vm.inputs.pledgeCTAButtonTapped(with: .viewBacking)

      self.goToManagePledgeProjectParam.assertValues([.slug(project.slug)])
      self.goToManagePledgeBackingParam.assertValues([.id(backing.id)])
    }
  }

  func testConfigurePledgeCTAView_FetchProjectSuccess() {
    let project = Project.template
    let projectFull = Project.template
      |> \.id .~ 2
      |> Project.lens.personalization.isBacking .~ true

    let projectPamphletData = Project.ProjectPamphletData(project: projectFull, backingId: nil)

    let mockService = MockService(
      fetchProjectPamphletResult: .success(projectPamphletData),
      fetchProjectRewardsResult: .success([Reward.noReward, Reward.template])
    )

    withEnvironment(
      apiService: mockService,
      apiDelayInterval: .seconds(1),
      config: .template,
      mainBundle: self.releaseBundle
    ) {
      self.configurePledgeCTAViewProject.assertDidNotEmitValue()
      self.configurePledgeCTAViewIsLoading.assertDidNotEmitValue()
      self.configurePledgeCTAViewRefTag.assertValues([])
      self.configurePledgeCTAViewContext.assertValues([])

      self.configureInitialState(.left(project))

      self.configurePledgeCTAViewProject.assertValues([project])
      self.configurePledgeCTAViewIsLoading.assertValues([true])
      self.configurePledgeCTAViewRefTag.assertValues([.discovery])
      self.configurePledgeCTAViewContext.assertValues([.projectPamphlet])

      self.scheduler.run()

      self.configurePledgeCTAViewProject.assertValues([project, projectFull, projectFull])
      self.configurePledgeCTAViewIsLoading.assertValues([true, true, false])
      self.configurePledgeCTAViewRefTag.assertValues([.discovery, .discovery, .discovery])
      self.configurePledgeCTAViewContext.assertValues([.projectPamphlet, .projectPamphlet, .projectPamphlet])
    }
  }

  func testConfigurePledgeCTAView_FetchProjectFailure() {
    let config = Config.template
    let project = Project.template
    let mockService = MockService(fetchProjectPamphletResult: .failure(.couldNotParseJSON))

    withEnvironment(
      apiService: mockService,
      apiDelayInterval: .seconds(1),
      config: config,
      mainBundle: releaseBundle
    ) {
      self.configurePledgeCTAViewProject.assertDidNotEmitValue()
      self.configurePledgeCTAViewIsLoading.assertDidNotEmitValue()
      self.configurePledgeCTAViewRefTag.assertDidNotEmitValue()
      self.configurePledgeCTAViewContext.assertValues([])

      self.configureInitialState(.left(project))

      self.configurePledgeCTAViewProject.assertValues([project])
      self.configurePledgeCTAViewIsLoading.assertValues([true])
      self.configurePledgeCTAViewRefTag.assertValues([.discovery])
      self.configurePledgeCTAViewContext.assertValues([.projectPamphlet])

      self.scheduler.run()

      self.configurePledgeCTAViewProject.assertValues([project, project])
      self.configurePledgeCTAViewErrorEnvelope.assertValueCount(1)
      self.configurePledgeCTAViewIsLoading.assertValues([true, false, false])
      self.configurePledgeCTAViewRefTag.assertValues([.discovery, .discovery])
      self.configurePledgeCTAViewContext.assertValues([.projectPamphlet, .projectPamphlet, .projectPamphlet])
    }
  }

  func testConfigurePledgeCTAView_ReloadsUponBackProject() {
    let config = Config.template
    let project = Project.template
    let friends = [User.template]
    let projectFull = Project.template
      |> Project.lens.rewardData.rewards .~ []

    let projectAndEnvelope = ProjectAndBackingEnvelope(project: projectFull, backing: Backing.template)
    let projectPamphletData = Project.ProjectPamphletData(project: projectFull, backingId: 1)
    let mockService = MockService(
      fetchManagePledgeViewBackingResult: .success(projectAndEnvelope),
      fetchProjectPamphletResult: .success(projectPamphletData),
      fetchProjectFriendsResult: .success(friends),
      fetchProjectRewardsResult: .success([Reward.noReward, Reward.template])
    )

    withEnvironment(apiService: mockService, config: config, mainBundle: self.releaseBundle) {
      self.configurePledgeCTAViewProject.assertDidNotEmitValue()
      self.configurePledgeCTAViewIsLoading.assertDidNotEmitValue()
      self.configurePledgeCTAViewRefTag.assertDidNotEmitValue()
      self.configurePledgeCTAViewContext.assertDidNotEmitValue()

      self.vm.inputs.configureWith(projectOrParam: .left(project), refTag: .discovery)
      self.vm.inputs.viewDidLoad()
      self.vm.inputs.viewDidAppear(animated: true)

      self.configurePledgeCTAViewProject.assertValues([project])
      self.configurePledgeCTAViewIsLoading.assertValues([true])
      self.configurePledgeCTAViewRefTag.assertValues([.discovery])
      self.configurePledgeCTAViewContext.assertValues([.projectPamphlet])

      self.scheduler.advance()

      self.configurePledgeCTAViewProject.assertValues([project, project, projectFull])
      self.configurePledgeCTAViewIsLoading.assertValues([true, true, false])
      self.configurePledgeCTAViewRefTag.assertValues([.discovery, .discovery, .discovery])
      self.configurePledgeCTAViewContext.assertValues([.projectPamphlet, .projectPamphlet, .projectPamphlet])
    }

    withEnvironment(
      apiService: MockService(
        fetchManagePledgeViewBackingResult: .success(projectAndEnvelope),
        fetchProjectPamphletResult: .success(projectPamphletData),
        fetchProjectFriendsResult: .success(friends),
        fetchProjectRewardsResult: .success([Reward.noReward, Reward.template])
      ),
      config: config,
      mainBundle: self.releaseBundle
    ) {
      self.vm.inputs.didBackProject()

      self.configurePledgeCTAViewProject.assertValues([project, project, projectFull, projectFull])
      self.configurePledgeCTAViewIsLoading.assertValues([true, true, false, true])
      self.configurePledgeCTAViewRefTag.assertValues([.discovery, .discovery, .discovery, .discovery])
      self.configurePledgeCTAViewContext.assertValues([
        .projectPamphlet, .projectPamphlet, .projectPamphlet, .projectPamphlet
      ])

      self.scheduler.advance()

      let projectWithBacking = project |> \.personalization.backing .~ .template
        |> \.personalization.isBacking .~ true

      self.configurePledgeCTAViewProject.assertValues([
        project,
        project,
        projectFull,
        projectFull,
        projectFull,
        projectWithBacking
      ])
      self.configurePledgeCTAViewIsLoading.assertValues([true, true, false, true, true, false])
      self.configurePledgeCTAViewRefTag.assertValues([
        .discovery,
        .discovery,
        .discovery,
        .discovery,
        .discovery,
        .discovery
      ])
      self.configurePledgeCTAViewContext.assertValues([
        .projectPamphlet,
        .projectPamphlet,
        .projectPamphlet,
        .projectPamphlet,
        .projectPamphlet,
        .projectPamphlet
      ])
    }
  }

  func testConfigurePledgeCTAView_ReloadsUponUpdatePledge() {
    let config = Config.template
    let project = Project.template
    let friends = [User.template]
    let backingFull = Backing.template |> Backing.lens.amount .~ 10.0
    let updatedBacking = Backing.template |> Backing.lens.amount .~ 15.0
    let projectFull = Project.template
      |> Project.lens.personalization.backing .~ backingFull
      |> Project.lens.personalization.isBacking .~ true
    let updatedProject = Project.template
      |> Project.lens.personalization.backing .~ updatedBacking
      |> Project.lens.personalization.isBacking .~ true

    let projectFullAndEnvelope = ProjectAndBackingEnvelope(project: projectFull, backing: backingFull)
    let projectUpdatedAndEnvelope = ProjectAndBackingEnvelope(
      project: updatedProject,
      backing: updatedBacking
    )
    let projectFullPamphletData = Project.ProjectPamphletData(project: projectFull, backingId: 1)
    let projectUpdatedPamphletData = Project.ProjectPamphletData(project: updatedProject, backingId: 1)

    let mockService = MockService(
      fetchManagePledgeViewBackingResult: .success(projectFullAndEnvelope),
      fetchProjectPamphletResult: .success(projectFullPamphletData),
      fetchProjectFriendsResult: .success(friends),
      fetchProjectRewardsResult: .success([Reward.noReward, Reward.template])
    )

    withEnvironment(apiService: mockService, config: config, mainBundle: self.releaseBundle) {
      self.configurePledgeCTAViewProject.assertDidNotEmitValue()
      self.configurePledgeCTAViewIsLoading.assertDidNotEmitValue()
      self.configurePledgeCTAViewRefTag.assertDidNotEmitValue()
      self.configurePledgeCTAViewContext.assertDidNotEmitValue()

      self.vm.inputs.configureWith(projectOrParam: .left(project), refTag: .discovery)
      self.vm.inputs.viewDidLoad()

      self.configurePledgeCTAViewProject.assertValues([project])
      self.configurePledgeCTAViewIsLoading.assertValues([true])
      self.configurePledgeCTAViewRefTag.assertValues([.discovery])
      self.configurePledgeCTAViewContext.assertValues([.projectPamphlet])

      self.scheduler.advance()

      self.configurePledgeCTAViewProject.assertValues([project, project, projectFull])
      self.configurePledgeCTAViewIsLoading.assertValues([true, true, false])
      self.configurePledgeCTAViewRefTag.assertValues([.discovery, .discovery, .discovery])
      self.configurePledgeCTAViewContext.assertValues([.projectPamphlet, .projectPamphlet, .projectPamphlet])
    }

    withEnvironment(
      apiService: MockService(
        fetchManagePledgeViewBackingResult: .success(projectUpdatedAndEnvelope),
        fetchProjectPamphletResult: .success(projectUpdatedPamphletData),
        fetchProjectFriendsResult: .success(friends),
        fetchProjectRewardsResult: .success([Reward.noReward, Reward.template])
      ),
      config: config,
      mainBundle: self.releaseBundle
    ) {
      self.vm.inputs.managePledgeViewControllerFinished(with: nil)

      self.configurePledgeCTAViewProject.assertValues([project, project, projectFull, projectFull])
      self.configurePledgeCTAViewIsLoading.assertValues([true, true, false, true])
      self.configurePledgeCTAViewRefTag.assertValues([.discovery, .discovery, .discovery, .discovery])
      self.configurePledgeCTAViewContext.assertValues([
        .projectPamphlet, .projectPamphlet, .projectPamphlet, .projectPamphlet
      ])

      self.scheduler.advance()

      self.configurePledgeCTAViewProject.assertValues([
        project,
        project,
        projectFull,
        projectFull,
        projectFull,
        updatedProject
      ])
      self.configurePledgeCTAViewIsLoading.assertValues([true, true, false, true, true, false])
      self.configurePledgeCTAViewRefTag.assertValues([
        .discovery,
        .discovery,
        .discovery,
        .discovery,
        .discovery,
        .discovery
      ])
      self.configurePledgeCTAViewContext.assertValues([
        .projectPamphlet,
        .projectPamphlet,
        .projectPamphlet,
        .projectPamphlet,
        .projectPamphlet,
        .projectPamphlet
      ])
    }
  }

  func testConfigurePledgeCTAView_ReloadsUponRetryButtonTappedEvent() {
    let config = Config.template
    let project = Project.template
    let friends = [User.template]
    let projectFull = Project.template
      |> \.id .~ 2
      |> Project.lens.personalization.isBacking .~ true
    let projectFull2 = Project.template
      |> \.id .~ 3

    let projectFullAndEnvelope = ProjectAndBackingEnvelope(project: projectFull, backing: .template)
    let projectFull2AndEnvelope = ProjectAndBackingEnvelope(project: projectFull2, backing: .template)
    let projectFullPamphletData = Project.ProjectPamphletData(project: projectFull, backingId: nil)
    let projectFull2PamphletData = Project.ProjectPamphletData(project: projectFull2, backingId: nil)

    let mockService = MockService(
      fetchManagePledgeViewBackingResult: .success(projectFullAndEnvelope),
      fetchProjectPamphletResult: .success(projectFullPamphletData),
      fetchProjectFriendsResult: .success(friends),
      fetchProjectRewardsResult: .success([Reward.noReward, Reward.template])
    )

    withEnvironment(apiService: mockService, config: config) {
      self.configurePledgeCTAViewProject.assertDidNotEmitValue()
      self.configurePledgeCTAViewIsLoading.assertDidNotEmitValue()
      self.configurePledgeCTAViewRefTag.assertDidNotEmitValue()
      self.configurePledgeCTAViewContext.assertDidNotEmitValue()

      self.vm.inputs.configureWith(projectOrParam: .left(project), refTag: .discovery)
      self.vm.inputs.viewDidLoad()

      self.configurePledgeCTAViewProject.assertValues([project])
      self.configurePledgeCTAViewIsLoading.assertValues([true])
      self.configurePledgeCTAViewRefTag.assertValues([.discovery])
      self.configurePledgeCTAViewContext.assertValues([.projectPamphlet])

      self.scheduler.advance()

      self.configurePledgeCTAViewProject.assertValues([project, projectFull, projectFull])
      self.configurePledgeCTAViewIsLoading.assertValues([true, true, false])
      self.configurePledgeCTAViewRefTag.assertValues([.discovery, .discovery, .discovery])
      self.configurePledgeCTAViewContext.assertValues([.projectPamphlet, .projectPamphlet, .projectPamphlet])
    }

    withEnvironment(
      apiService: MockService(
        fetchManagePledgeViewBackingResult: .success(projectFull2AndEnvelope),
        fetchProjectPamphletResult: .success(projectFull2PamphletData),
        fetchProjectFriendsResult: .success(friends),
        fetchProjectRewardsResult: .success([Reward.noReward, Reward.template])
      ),
      config: config
    ) {
      self.vm.inputs.pledgeRetryButtonTapped()

      self.configurePledgeCTAViewProject.assertValues([project, projectFull, projectFull, projectFull])
      self.configurePledgeCTAViewIsLoading.assertValues([true, true, false, true])
      self.configurePledgeCTAViewContext.assertValues([
        .projectPamphlet, .projectPamphlet, .projectPamphlet, .projectPamphlet
      ])

      self.scheduler.advance()

      self.configurePledgeCTAViewProject.assertValues([
        project,
        projectFull,
        projectFull,
        projectFull,
        projectFull2,
        projectFull2
      ])
      self.configurePledgeCTAViewIsLoading.assertValues([true, true, false, true, true, false])
      self.configurePledgeCTAViewRefTag.assertValues([
        .discovery,
        .discovery,
        .discovery,
        .discovery,
        .discovery,
        .discovery
      ])
      self.configurePledgeCTAViewContext.assertValues([
        .projectPamphlet,
        .projectPamphlet,
        .projectPamphlet,
        .projectPamphlet,
        .projectPamphlet,
        .projectPamphlet
      ])
    }
  }

  func testManagePledgeViewControllerFinished() {
    self.vm.inputs.configureWith(projectOrParam: .left(Project.template), refTag: .discovery)
    self.vm.inputs.viewDidLoad()

    self.dismissManagePledgeAndShowMessageBannerWithMessage.assertDidNotEmitValue()

    self.vm.inputs.managePledgeViewControllerFinished(with: "Your changes have been saved")

    self.dismissManagePledgeAndShowMessageBannerWithMessage.assertValues(["Your changes have been saved"])
  }

  func testTrackingProjectPageViewed_LoggedIn() {
    let segmentClient = MockTrackingClient()
    let ksrAnalytics = KSRAnalytics(
      config: .template,
      loggedInUser: User.template,
      segmentClient: segmentClient
    )

    let projectPamphletData = Project.ProjectPamphletData(project: .template, backingId: nil)

    withEnvironment(
      apiService: MockService(
        fetchProjectPamphletResult: .success(projectPamphletData),
        fetchProjectRewardsResult: .success([Reward.noReward, Reward.template])
      ),
      currentUser: User.template,
      ksrAnalytics: ksrAnalytics
    ) {
      self.vm.inputs.configureWith(projectOrParam: .left(.template), refTag: .discovery)
      self.vm.inputs.viewDidLoad()
      self.vm.inputs.viewDidAppear(animated: false)

      self.scheduler.advance()

      XCTAssertEqual(segmentClient.events, ["Page Viewed"])

      XCTAssertEqual(segmentClient.properties(forKey: "session_user_is_logged_in", as: Bool.self), [true])
      XCTAssertEqual(segmentClient.properties(forKey: "user_uid", as: String.self), ["1"])
      XCTAssertEqual(segmentClient.properties(forKey: "session_ref_tag"), ["discovery"])
      XCTAssertEqual(segmentClient.properties(forKey: "project_subcategory"), ["Ceramics"])
      XCTAssertEqual(segmentClient.properties(forKey: "project_category"), ["Art"])
      XCTAssertEqual(segmentClient.properties(forKey: "project_country"), ["US"])
      XCTAssertEqual(segmentClient.properties(forKey: "project_user_has_watched", as: Bool.self), [nil])
    }
  }

  func testTrackingProjectPageViewed_LoggedOut() {
    let config = Config.template
      |> \.countryCode .~ "GB"

    let segmentClient = MockTrackingClient()
    let ksrAnalytics = KSRAnalytics(
      config: config,
      loggedInUser: nil,
      segmentClient: segmentClient
    )

    let projectPamphletData = Project.ProjectPamphletData(project: .template, backingId: nil)

    withEnvironment(
      apiService: MockService(
        fetchProjectPamphletResult: .success(projectPamphletData),
        fetchProjectRewardsResult: .success([Reward.noReward, Reward.template])
      ),
      currentUser: nil,
      ksrAnalytics: ksrAnalytics
    ) {
      self.vm.inputs.configureWith(projectOrParam: .left(.template), refTag: .discovery)
      self.vm.inputs.viewDidLoad()
      self.vm.inputs.viewDidAppear(animated: false)

      self.scheduler.advance()

      XCTAssertEqual(segmentClient.events, ["Page Viewed"])

      XCTAssertEqual(segmentClient.properties(forKey: "session_ref_tag"), ["discovery"])

      XCTAssertEqual(segmentClient.properties(forKey: "session_user_is_logged_in", as: Bool.self), [false])
      XCTAssertEqual(segmentClient.properties(forKey: "user_uid", as: Int.self), [nil])
      XCTAssertEqual(segmentClient.properties(forKey: "project_subcategory"), ["Ceramics"])
      XCTAssertEqual(segmentClient.properties(forKey: "project_category"), ["Art"])
      XCTAssertEqual(segmentClient.properties(forKey: "project_country"), ["US"])
      XCTAssertEqual(segmentClient.properties(forKey: "project_user_has_watched", as: Bool.self), [nil])
    }
  }

  func testPopToRootViewController() {
    self.vm.inputs.configureWith(projectOrParam: .left(.template), refTag: nil)
    self.vm.inputs.viewDidLoad()

    self.popToRootViewController.assertDidNotEmitValue()

    self.vm.inputs.didBackProject()

    self.popToRootViewController.assertValueCount(1)
  }

  // MARK: - Functions

  private func configureInitialState(_ projectOrParam: Either<Project, Param>) {
    self.vm.inputs.configureWith(projectOrParam: projectOrParam, refTag: .discovery)
    self.vm.inputs.viewDidLoad()
    self.vm.inputs.viewWillAppear(animated: false)
    self.vm.inputs.viewDidAppear(animated: false)
  }
}
