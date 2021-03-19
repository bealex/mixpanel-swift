//
//  MixpanelPeopleTests.swift
//  MixpanelDemo
//
//  Created by Yarden Eitan on 6/28/16.
//  Copyright © 2016 Mixpanel. All rights reserved.
//

import XCTest
import Nocilla

@testable import Mixpanel
@testable import MixpanelDemo

class MixpanelPeopleTests: MixpanelBaseTests {

    func testPeopleSet() {
        mixpanel.identify(distinctId: "d1")
        let p: Properties = ["p1": "a"]
        mixpanel.people.set(properties: p)
        waitForTrackingQueue()
        let q = mixpanel.people.peopleQueue.last!["$set"] as! InternalProperties
        XCTAssertEqual(q["p1"] as? String, "a", "custom people property not queued")
        assertDefaultPeopleProperties(q)
    }

    func testPeopleSetOnce() {
        mixpanel.identify(distinctId: "d1")
        let p: Properties = ["p1": "a"]
        mixpanel.people.setOnce(properties: p)
        waitForTrackingQueue()
        let q = mixpanel.people.peopleQueue.last!["$set_once"] as! InternalProperties
        XCTAssertEqual(q["p1"] as? String, "a", "custom people property not queued")
        assertDefaultPeopleProperties(q)
    }

    func testPeopleSetReservedProperty() {
        mixpanel.identify(distinctId: "d1")
        let p: Properties = ["$ios_app_version": "override"]
        mixpanel.people.set(properties: p)
        waitForTrackingQueue()
        let q = mixpanel.people.peopleQueue.last!["$set"] as! InternalProperties
        XCTAssertEqual(q["$ios_app_version"] as? String,
                       "override",
                       "reserved property override failed")
        assertDefaultPeopleProperties(q)
    }

    func testPeopleSetTo() {
        mixpanel.identify(distinctId: "d1")
        mixpanel.people.set(property: "p1", to: "a")
        waitForTrackingQueue()
        let p: InternalProperties = mixpanel.people.peopleQueue.last!["$set"] as! InternalProperties
        XCTAssertEqual(p["p1"] as? String, "a", "custom people property not queued")
        assertDefaultPeopleProperties(p)
    }

    func testDropUnidentifiedPeopleRecords() {
        QueueConstants.queueSize = 500
        for i in 0..<505 {
            mixpanel.people.set(property: "i", to: i)
        }
        waitForTrackingQueue()
        XCTAssertTrue(mixpanel.people.unidentifiedQueue.count == 500)
        var r: InternalProperties = mixpanel.people.unidentifiedQueue.first!
        XCTAssertEqual((r["$set"] as? InternalProperties)?["i"] as? Int, 5)
        r = mixpanel.people.unidentifiedQueue.last!
        XCTAssertEqual((r["$set"] as? InternalProperties)?["i"] as? Int, 504)
    }

    func testDropPeopleRecords() {
        QueueConstants.queueSize = 500
        mixpanel.identify(distinctId: "d1")
        for i in 0..<505 {
            mixpanel.people.set(property: "i", to: i)
        }
        waitForTrackingQueue()
        XCTAssertTrue(mixpanel.people.peopleQueue.count == 500)
        var r: InternalProperties = mixpanel.people.peopleQueue.first!
        XCTAssertEqual((r["$set"] as? InternalProperties)?["i"] as? Int, 5)
        r = mixpanel.people.peopleQueue.last!
        XCTAssertEqual((r["$set"] as? InternalProperties)?["i"] as? Int, 504)
    }

    func testPeopleAssertPropertyTypes() {
        var p: Properties = ["URL": [Data()]]
        XCTExpectAssert("unsupported property type was allowed") {
            mixpanel.people.set(properties: p)
        }
        XCTExpectAssert("unsupported property type was allowed") {
            mixpanel.people.set(property: "p1", to: [Data()])
        }
        p = ["p1": "a"]
        // increment should require a number
        XCTExpectAssert("unsupported property type was allowed") {
            mixpanel.people.increment(properties: p)
        }
    }

    func testPeopleIncrement() {
        mixpanel.identify(distinctId: "d1")
        let p: Properties = ["p1": 3]
        mixpanel.people.increment(properties: p)
        waitForTrackingQueue()
        let q = mixpanel.people.peopleQueue.last!["$add"] as! InternalProperties
        XCTAssertTrue(q.count == 1, "incorrect people properties: \(p)")
        XCTAssertEqual(q["p1"] as? Int, 3, "custom people property not queued")
    }

    func testPeopleIncrementBy() {
        mixpanel.identify(distinctId: "d1")
        mixpanel.people.increment(property: "p1", by: 3)
        waitForTrackingQueue()
        let p: InternalProperties = mixpanel.people.peopleQueue.last!["$add"] as! InternalProperties
        XCTAssertTrue(p.count == 1, "incorrect people properties: \(p)")
        XCTAssertEqual(p["p1"] as? Double, 3, "custom people property not queued")
    }

    func testPeopleDeleteUser() {
        mixpanel.identify(distinctId: "d1")
        mixpanel.people.deleteUser()
        waitForTrackingQueue()
        let p: InternalProperties = mixpanel.people.peopleQueue.last!["$delete"] as! InternalProperties
        XCTAssertTrue(p.isEmpty, "incorrect people properties: \(p)")
    }


    func testPeopleTrackChargeDecimal() {
        mixpanel.identify(distinctId: "d1")
        mixpanel.people.trackCharge(amount: 25.34)
        waitForTrackingQueue()
        let r: InternalProperties = mixpanel.people.peopleQueue.last!
        let prop = ((r["$append"] as? InternalProperties)?["$transactions"] as? InternalProperties)?["$amount"] as? Double
        let prop2 = ((r["$append"] as? InternalProperties)?["$transactions"] as? InternalProperties)?["$time"]
        XCTAssertEqual(prop, 25.34)
        XCTAssertNotNil(prop2)
    }

    func testPeopleTrackChargeZero() {
        mixpanel.identify(distinctId: "d1")
        mixpanel.people.trackCharge(amount: 0)
        waitForTrackingQueue()
        let r: InternalProperties = mixpanel.people.peopleQueue.last!
        let prop = ((r["$append"] as? InternalProperties)?["$transactions"] as? InternalProperties)?["$amount"] as? Double
        let prop2 = ((r["$append"] as? InternalProperties)?["$transactions"] as? InternalProperties)?["$time"]
        XCTAssertEqual(prop, 0)
        XCTAssertNotNil(prop2)
    }
    func testPeopleTrackChargeWithTime() {
        mixpanel.identify(distinctId: "d1")
        let p: Properties = allPropertyTypes()
        mixpanel.people.trackCharge(amount: 25, properties: ["$time": p["date"]!])
        waitForTrackingQueue()
        let r: InternalProperties = mixpanel.people.peopleQueue.last!
        let prop = ((r["$append"] as? InternalProperties)?["$transactions"] as? InternalProperties)?["$amount"] as? Double
        let prop2 = ((r["$append"] as? InternalProperties)?["$transactions"] as? InternalProperties)?["$time"]
        XCTAssertEqual(prop, 25)
        XCTAssertEqual(prop2 as? Date, p["date"] as? Date)
    }

    func testPeopleTrackChargeWithProperties() {
        mixpanel.identify(distinctId: "d1")
        mixpanel.people.trackCharge(amount: 25, properties: ["p1": "a"])
        waitForTrackingQueue()
        let r: InternalProperties = mixpanel.people.peopleQueue.last!
        let prop = ((r["$append"] as? InternalProperties)?["$transactions"] as? InternalProperties)?["$amount"] as? Double
        let prop2 = ((r["$append"] as? InternalProperties)?["$transactions"] as? InternalProperties)?["p1"]
        XCTAssertEqual(prop, 25)
        XCTAssertEqual(prop2 as? String, "a")
    }

    func testPeopleTrackCharge() {
        mixpanel.identify(distinctId: "d1")
        mixpanel.people.trackCharge(amount: 25)
        waitForTrackingQueue()
        let r: InternalProperties = mixpanel.people.peopleQueue.last!
        let prop = ((r["$append"] as? InternalProperties)?["$transactions"] as? InternalProperties)?["$amount"] as? Double
        let prop2 = ((r["$append"] as? InternalProperties)?["$transactions"] as? InternalProperties)?["$time"]
        XCTAssertEqual(prop, 25)
        XCTAssertNotNil(prop2)
    }

    func testPeopleClearCharges() {
        mixpanel.identify(distinctId: "d1")
        mixpanel.people.clearCharges()
        waitForTrackingQueue()
        let r: InternalProperties = mixpanel.people.peopleQueue.last!
        let transactions = (r["$set"] as? InternalProperties)?["$transactions"] as? [MixpanelType]
        XCTAssertEqual(transactions?.count, 0)
    }
}
