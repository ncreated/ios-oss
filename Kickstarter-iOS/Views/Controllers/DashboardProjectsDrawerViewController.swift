import KsApi
import Library
import Prelude
import Prelude_UIKit
import UIKit

internal protocol DashboardProjectsDrawerViewControllerDelegate: class {
  /// Call when a project cell is tapped with the project.
  func dashboardProjectsDrawerCellDidTapProject(project: Project)

  /// Call when drawer view has completed animating out.
  func dashboardProjectsDrawerDidAnimateOut()

  /// Call when background view is tapped to close.
  func dashboardProjectsDrawerHideDrawer()
}

internal final class DashboardProjectsDrawerViewController: UITableViewController {

  internal weak var delegate: DashboardProjectsDrawerViewControllerDelegate?

  private let viewModel: DashboardProjectsDrawerViewModelType = DashboardProjectsDrawerViewModel()
  private let dataSource = DashboardProjectsDrawerDataSource()

  internal func configureWith(data data: [ProjectsDrawerData]) {
    self.viewModel.inputs.configureWith(data: data)
  }

  internal override func viewDidLoad() {
    super.viewDidLoad()

    self.tableView.dataSource = self.dataSource

    self.viewModel.inputs.viewDidLoad()
  }

  override func viewWillDisappear(animated: Bool) {
    if let tapGesture = self.tableView.backgroundView?.gestureRecognizers?.first {
      self.tableView.backgroundView?.removeGestureRecognizer(tapGesture)
    }
  }

  internal override func bindViewModel() {
    super.bindViewModel()

    self.viewModel.outputs.projectsDrawerData
      .observeForUI()
      .observeNext { [weak self] data in
        self?.dataSource.load(data: data)
        self?.tableView.reloadData()
        self?.animateIn()
    }

    self.viewModel.outputs.notifyDelegateToCloseDrawer
      .observeForUI()
      .observeNext { [weak self] in
        self?.delegate?.dashboardProjectsDrawerHideDrawer()
    }

    self.viewModel.outputs.notifyDelegateDidAnimateOut
      .observeForUI()
      .observeNext { [weak self] in
        self?.delegate?.dashboardProjectsDrawerDidAnimateOut()
    }

    self.viewModel.outputs.notifyDelegateProjectCellTapped
      .observeForUI()
      .observeNext { [weak self] project in
        self?.delegate?.dashboardProjectsDrawerCellDidTapProject(project)
    }
  }

  override func bindStyles() {
    self
      |> baseTableControllerStyle(estimatedRowHeight: 44.0)
      |> UITableViewController.lens.view.backgroundColor .~ .clearColor()

    self.tableView |> UITableView.lens.backgroundView .~ (
      UIView()
        |> UIView.lens.backgroundColor .~ .blackColor()
        |> UIView.lens.alpha .~ 0.0
    )

    self.animateIn()
  }

  internal override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    guard let project = self.dataSource.projectAtIndexPath(indexPath) else { return }

    self.viewModel.inputs.projectCellTapped(project)
  }

  internal func animateOut() {
    self.tableView.backgroundView?.userInteractionEnabled = false

    UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut, animations: {
      self.tableView.backgroundView?.alpha = 0.0
      self.tableView.contentOffset = CGPoint(x: 0.0, y: self.tableView.frame.size.height / 2)
      }, completion: { _ in
        self.viewModel.inputs.animateOutCompleted()
    })
  }

  private func animateIn() {
    self.tableView.contentOffset = CGPoint(x: 0.0, y: self.tableView.frame.size.height)

    UIView.animateWithDuration(0.3, delay: 0.0, options: .CurveEaseOut, animations: {
      self.tableView.backgroundView?.alpha = 0.4
      }, completion: { _ in
        self.tableView.backgroundView?.addGestureRecognizer(
          UITapGestureRecognizer(target: self, action: #selector(self.backgroundTapped))
        )
    })

    UIView.animateWithDuration(0.3,
                               delay: 0.0,
                               usingSpringWithDamping: 0.95,
                               initialSpringVelocity: 0.9,
                               options: .CurveEaseOut,
                               animations: {
      self.tableView.contentOffset = CGPoint(x: 0.0, y: 0.0)
      }, completion: nil
    )
  }

  @objc private func backgroundTapped() {
    self.viewModel.inputs.backgroundTapped()
  }
}
