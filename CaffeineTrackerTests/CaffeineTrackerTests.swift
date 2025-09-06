//
//  CaffeineTrackerTests.swift
//  CaffeineTrackerTests
//
//  Created by Ethan on 23/8/2025.
//

import Testing
@testable import CaffeineTracker

import XCTest
@testable import CaffeineTracker

final class CaffeineTrackerTests: XCTestCase {
    
    var manager: CaffeineIntakeManager!
    
    override func setUp() {
        super.setUp()
        manager = CaffeineIntakeManager()
        manager.clearAllEntries()
    }
    
    override func tearDown() {
        manager = nil
        super.tearDown()
    }
    
    // MARK: - Model Tests
    
    func testCaffeineEntryCreation() {
        let entry = CaffeineEntry(
            beverageType: .espresso,
            caffeineAmount: 63
        )
        
        XCTAssertNotNil(entry.id)
        XCTAssertEqual(entry.caffeineAmount, 63)
        XCTAssertEqual(entry.beverageType.name, "Espresso")
    }
    
    func testBeverageTypeDefaults() {
        let espresso = BeverageType.espresso
        
        XCTAssertEqual(espresso.defaultCaffeineContent, 63)
        XCTAssertEqual(espresso.servingSize, 30)
        XCTAssertEqual(espresso.category, .coffee)
    }
    
    // MARK: - Manager Tests
    
    func testAddEntry() {
        let entry = CaffeineEntry(
            beverageType: .espresso,
            caffeineAmount: 63
        )
        
        manager.addEntry(entry)
        
        XCTAssertEqual(manager.entriesCount(), 1)
        XCTAssertEqual(manager.todaysTotalCaffeine(), 63)
    }
    
    func testDeleteEntry() {
        let entry1 = CaffeineEntry(
            beverageType: .espresso,
            caffeineAmount: 63
        )
        let entry2 = CaffeineEntry(
            beverageType: .latte,
            caffeineAmount: 63
        )
        
        manager.addEntry(entry1)
        manager.addEntry(entry2)
        XCTAssertEqual(manager.entriesCount(), 2)
        
        manager.deleteEntry(entry1)
        XCTAssertEqual(manager.entriesCount(), 1)
    }
    
    func testTodaysTotalCalculation() {
        manager.addEntry(CaffeineEntry(
            beverageType: .espresso,
            caffeineAmount: 63
        ))
        manager.addEntry(CaffeineEntry(
            beverageType: .latte,
            caffeineAmount: 63
        ))
        
        XCTAssertEqual(manager.todaysTotalCaffeine(), 126)
    }
    
    func testDailyLimitCheck() {
        manager.dailyLimit = 200
        
        manager.addEntry(CaffeineEntry(
            beverageType: .espresso,
            caffeineAmount: 150
        ))
        
        XCTAssertFalse(manager.isOverLimit())
        
        manager.addEntry(CaffeineEntry(
            beverageType: .espresso,
            caffeineAmount: 100
        ))
        
        XCTAssertTrue(manager.isOverLimit())
    }
    
    func testPercentageOfLimit() {
        manager.dailyLimit = 400
        
        manager.addEntry(CaffeineEntry(
            beverageType: .espresso,
            caffeineAmount: 200
        ))
        
        XCTAssertEqual(manager.percentageOfLimit(), 0.5)
    }
    
    // MARK: - Validation Tests
    
    func testValidateEntry() {
        let validEntry = CaffeineEntry(
            beverageType: .espresso,
            caffeineAmount: 63
        )
        
        let result = manager.validateEntry(validEntry)
        
        switch result {
        case .success:
            XCTAssertTrue(true)
        case .failure:
            XCTFail("Valid entry should not fail")
        }
    }
    
    func testValidateInvalidEntry() {
        let invalidEntry = CaffeineEntry(
            beverageType: .espresso,
            caffeineAmount: 0
        )
        
        let result = manager.validateEntry(invalidEntry)
        
        switch result {
        case .success:
            XCTFail("Invalid entry should not succeed")
        case .failure(let error):
            XCTAssertEqual(error, .invalidAmount)
        }
    }
    
    func testValidateExcessiveEntry() {
        let excessiveEntry = CaffeineEntry(
            beverageType: .espresso,
            caffeineAmount: 1500
        )
        
        let result = manager.validateEntry(excessiveEntry)
        
        switch result {
        case .success:
            XCTFail("Excessive entry should not succeed")
        case .failure:
            XCTAssertTrue(true)
        }
    }
    
    // MARK: - Persistence Tests
    
    func testClearAllEntries() {
        manager.addEntry(CaffeineEntry(
            beverageType: .espresso,
            caffeineAmount: 63
        ))
        manager.addEntry(CaffeineEntry(
            beverageType: .latte,
            caffeineAmount: 63
        ))
        
        XCTAssertEqual(manager.entriesCount(), 2)
        
        manager.clearAllEntries()
        
        XCTAssertEqual(manager.entriesCount(), 0)
        XCTAssertEqual(manager.todaysTotalCaffeine(), 0)
    }
    
    func testRemainingCaffeine() {
        manager.dailyLimit = 400
        
        manager.addEntry(CaffeineEntry(
            beverageType: .espresso,
            caffeineAmount: 150
        ))
        
        XCTAssertEqual(manager.remainingCaffeine(), 250)
    }
}
