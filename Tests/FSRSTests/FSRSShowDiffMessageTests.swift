//
//  ShowDiffMessageTests.swift
//  FSRS
//
//  Created by nkq on 10/27/24.
//


import XCTest
@testable import FSRS

class ShowDiffMessageTests: XCTestCase {
    
    let timeUnitFormatTest = ["秒", "分", "小时", "天", "个月", "年"]

    func testShowDiffMessageBadType() {
        let t1 = Date.fromString("1970-01-01 00:00:00")!
        let t2 = Date.fromString("1970-01-02 00:00:00")!
        let t3 = Date.fromString("1970-01-01 00:00:00")!
        let t4 = Date.fromString("1970-01-02 00:00:00")!
        
        let t5: Date = .init(timeIntervalSince1970: 0)
        let t6: Date = .init(timeIntervalSince1970: 60 * 60 * 24)
        
        XCTAssertEqual(Date.showDiffMessage(t2, t1, false), "1")
        XCTAssertEqual(Date.showDiffMessage(t2, t1, true), "1day")
        XCTAssertEqual(Date.showDiffMessage(t2, t1, true, timeUnitFormatTest), "1天")
        
        XCTAssertEqual(Date.showDiffMessage(t4, t3), "1")
        XCTAssertEqual(Date.showDiffMessage(t4, t3, true), "1day")
        XCTAssertEqual(Date.showDiffMessage(t4, t3, true, timeUnitFormatTest), "1天")
        
        XCTAssertEqual(Date.showDiffMessage(t6, t5), "1")
        XCTAssertEqual(Date.showDiffMessage(t6, t5, true), "1day")
        XCTAssertEqual(Date.showDiffMessage(t6, t5, true, timeUnitFormatTest), "1天")
    }
    
    func testShowDiffMessageMin() {
        let t1 = Date()
        let t2 = Date(timeIntervalSince1970: t1.timeIntervalSince1970 + 60)
        let t3 = Date(timeIntervalSince1970: t1.timeIntervalSince1970 + 60 * 59)
        
        XCTAssertEqual(Date.showDiffMessage(t2, t1), "1")
        XCTAssertEqual(Date.showDiffMessage(t2, t1, true), "1min")
        XCTAssertEqual(Date.showDiffMessage(t2, t1, true, timeUnitFormatTest), "1分")
        
        XCTAssertEqual(Date.showDiffMessage(t3, t1, true), "59min")
        XCTAssertEqual(Date.showDiffMessage(t3, t1, true, timeUnitFormatTest), "59分")
    }
    
    func testShowDiffMessageHour() {
        let t1 = Date()
        let t2 = Date(timeIntervalSince1970: t1.timeIntervalSince1970 + 60 * 60)
        let t3 = Date(timeIntervalSince1970: t1.timeIntervalSince1970 + 60 * 60 * 59)
        
        XCTAssertEqual(Date.showDiffMessage(t2, t1), "1")
        XCTAssertEqual(Date.showDiffMessage(t2, t1, true), "1hour")
        XCTAssertEqual(Date.showDiffMessage(t2, t1, true, timeUnitFormatTest), "1小时")
        
        XCTAssertNotEqual(Date.showDiffMessage(t3, t1, true), "59hour")
        XCTAssertNotEqual(Date.showDiffMessage(t3, t1, true, timeUnitFormatTest), "59小时")
        
        XCTAssertEqual(Date.showDiffMessage(t3, t1, true), "2day")
        XCTAssertEqual(Date.showDiffMessage(t3, t1, true, timeUnitFormatTest), "2天")
    }
    
    func testShowDiffMessageDay() {
        let t1 = Date()
        let t2 = Date(timeIntervalSince1970: t1.timeIntervalSince1970 + 60 * 60 * 24)
        let t3 = Date(timeIntervalSince1970: t1.timeIntervalSince1970 + 60 * 60 * 24 * 30)
        let t4 = Date(timeIntervalSince1970: t1.timeIntervalSince1970 + 60 * 60 * 24 * 31)
        
        XCTAssertEqual(Date.showDiffMessage(t2, t1), "1")
        XCTAssertEqual(Date.showDiffMessage(t2, t1, true), "1day")
        XCTAssertEqual(Date.showDiffMessage(t2, t1, true, timeUnitFormatTest), "1天")
        
        XCTAssertEqual(Date.showDiffMessage(t3, t1), "30")
        XCTAssertEqual(Date.showDiffMessage(t3, t1, true), "30day")
        XCTAssertEqual(Date.showDiffMessage(t3, t1, true, timeUnitFormatTest), "30天")
        
        XCTAssertNotEqual(Date.showDiffMessage(t4, t1), "31")
        XCTAssertEqual(Date.showDiffMessage(t4, t1, true), "1month")
        XCTAssertEqual(Date.showDiffMessage(t4, t1, true, timeUnitFormatTest), "1个月")
    }

    func testShowDiffMessageMonth() {
           let t1 = Date()
           let t2 = Date(timeIntervalSince1970: t1.timeIntervalSince1970 + 60 * 60 * 24 * 31)
           let t3 = Date(timeIntervalSince1970: t1.timeIntervalSince1970 + 60 * 60 * 24 * 31 * 12)
           let t4 = Date(timeIntervalSince1970: t1.timeIntervalSince1970 + 60 * 60 * 24 * 31 * 13)
           
           XCTAssertEqual(Date.showDiffMessage(t2, t1), "1")
           XCTAssertEqual(Date.showDiffMessage(t2, t1, true), "1month")
           XCTAssertEqual(Date.showDiffMessage(t2, t1, true, timeUnitFormatTest), "1个月")
           
           XCTAssertNotEqual(Date.showDiffMessage(t3, t1), "12")
           XCTAssertNotEqual(Date.showDiffMessage(t3, t1, true), "12month")
           XCTAssertNotEqual(Date.showDiffMessage(t3, t1, true, timeUnitFormatTest), "12个月")
           
           XCTAssertNotEqual(Date.showDiffMessage(t4, t1), "13")
           XCTAssertEqual(Date.showDiffMessage(t4, t1, true), "1year")
           XCTAssertEqual(Date.showDiffMessage(t4, t1, true, timeUnitFormatTest), "1年")
       }
       
       func testShowDiffMessageYear() {
           let t1 = Date()
           let t2 = Date(timeIntervalSince1970: t1.timeIntervalSince1970 + 60 * 60 * 24 * 31 * 13)
           let t3 = Date(timeIntervalSince1970: t1.timeIntervalSince1970 + 60 * 60 * 24 * 31 * 13 + 60 * 60 * 24)
           let t4 = Date(timeIntervalSince1970: t1.timeIntervalSince1970 + 60 * 60 * 24 * 31 * 24 + 60 * 60 * 24)
           
           XCTAssertEqual(Date.showDiffMessage(t2, t1), "1")
           XCTAssertEqual(Date.showDiffMessage(t2, t1, true), "1year")
           XCTAssertEqual(Date.showDiffMessage(t2, t1, true, timeUnitFormatTest), "1年")
           
           XCTAssertEqual(Date.showDiffMessage(t3, t1), "1")
           XCTAssertEqual(Date.showDiffMessage(t3, t1, true), "1year")
           XCTAssertEqual(Date.showDiffMessage(t3, t1, true, timeUnitFormatTest), "1年")
           
           XCTAssertEqual(Date.showDiffMessage(t4, t1), "2")
           XCTAssertEqual(Date.showDiffMessage(t4, t1, true), "2year")
           XCTAssertEqual(Date.showDiffMessage(t4, t1, true, timeUnitFormatTest), "2年")
       }
       
       func testWrongTimeUnitLength() {
           let timeUnitFormatTestShort = ["年"]
           let t1 = Date()
           let t2 = Date(timeIntervalSince1970: t1.timeIntervalSince1970 + 60 * 60 * 24 * 31 * 13)
           
           XCTAssertEqual(Date.showDiffMessage(t2, t1), "1")
           XCTAssertEqual(Date.showDiffMessage(t2, t1, true), "1year")
           XCTAssertNotEqual(Date.showDiffMessage(t2, t1, true, timeUnitFormatTestShort), "1年")
           XCTAssertEqual(Date.showDiffMessage(t2, t1, true, timeUnitFormatTestShort), "1year")
       }
}
