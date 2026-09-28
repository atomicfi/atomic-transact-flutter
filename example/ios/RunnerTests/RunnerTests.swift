import AtomicTransact
import Flutter
import UIKit
import XCTest

@testable import atomic_transact_flutter

/// Covers the maps the plugin sends to Dart. Run with `xcodebuild test` on the Runner scheme, after
/// the example app has been built once.
class RunnerTests: XCTestCase {

  private let company = TransactCompany(id: "company-1", name: "Amazon")

  func testAuthStatusUpdateCarriesTheCompanyId() {
    let map = TransactAuthStatusUpdate(company: company, status: .authenticated).toFlutterMap()

    assertIsCompany(map["company"])
  }

  func testTaskStatusUpdateCarriesTheCompanyIds() {
    let map = TransactTaskStatusUpdate(
      taskId: "task-1",
      product: .deposit,
      company: company,
      status: .completed,
      managedBy: .init(company: company)
    ).toFlutterMap()

    assertIsCompany(map["company"])
    let managedBy = map["managedBy"] as? [String: Any?]
    assertIsCompany(managedBy?["company"])
  }

  /// `AtomicTransactCompany.fromJson` reads `id` and `name`.
  private func assertIsCompany(_ value: Any??, file: StaticString = #filePath, line: UInt = #line) {
    let map = value as? [String: Any?]
    XCTAssertEqual(map?["id"] as? String, "company-1", file: file, line: line)
    XCTAssertEqual(map?["name"] as? String, "Amazon", file: file, line: line)
  }
}
