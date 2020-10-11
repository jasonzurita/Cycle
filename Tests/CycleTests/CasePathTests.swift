import XCTest
@testable import Cycle

final class CasePathTests: XCTestCase {
    func testSimpleEnum() {
        enum Color: Equatable {
            case hex(String)
        }

        let hexString = "FFF"

        let color: Color = .hex(hexString)
        let casePath = /Color.hex

        let value = casePath.extract(color)
        let newColor = casePath.embed(hexString)

        XCTAssertEqual(value, hexString)
        XCTAssertEqual(color, newColor)

    }

    func testEnumWithDifferrentAssociatedValueTypes() {
        enum Percentage: Equatable {
            case value(Double)
            case display(String)
        }

        let valuePath = /Percentage.value
        let displayPath = /Percentage.display

        let value: Percentage = .value(10)
        let display: Percentage = .display("10%")

        XCTAssertEqual(10, valuePath.extract(value))
        XCTAssertEqual(value, valuePath.embed(10))
        XCTAssertNil(valuePath.extract(display))

        XCTAssertEqual("10%", displayPath.extract(display))
        XCTAssertEqual(display, displayPath.embed("10%"))
        XCTAssertNil(displayPath.extract(value))
    }

    func testEnumWithSameAssociatedValueTypes() {
        enum Font: Equatable {
            case sans(String)
            case serif(String)
        }

        let sansPath = /Font.sans
        let serifPath = /Font.serif

        let sans: Font = .sans("sans")
        let serif: Font = .serif("serif")

        XCTAssertEqual("sans", sansPath.extract(sans))
        XCTAssertEqual(sans, sansPath.embed("sans"))
        XCTAssertNil(sansPath.extract(serif))

        XCTAssertEqual("serif", serifPath.extract(serif))
        XCTAssertEqual(serif, serifPath.embed("serif"))
        XCTAssertNil(serifPath.extract(sans))

    }

    static var allTests = [
        ("testSimpleEnum", testSimpleEnum),
        ("testEnumWithTwoDifferrentAssociatedTypes", testEnumWithDifferrentAssociatedValueTypes),
        ("testEnumWithSameAssociatedTypes", testEnumWithSameAssociatedValueTypes)
    ]
}
