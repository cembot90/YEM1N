import Foundation
import Testing
@testable import YEM1N

// Der Sparmodus gilt, wenn er eingeschaltet ist oder iOS Strom spart.

@MainActor
struct SparmodusTests {

    @Test func schalterUndStromsparmodus() {
        let d = UserDefaults.standard
        let vorher = d.object(forKey: Sparmodus.key)
        defer { d.set(vorher, forKey: Sparmodus.key) }
        d.set(true, forKey: Sparmodus.key)
        #expect(Sparmodus.an)
        d.set(false, forKey: Sparmodus.key)
        #expect(Sparmodus.an == Sparmodus.stromsparen)
    }

    @Test func dieStimmeRuhtImSparmodusFrueher() {
        let d = UserDefaults.standard
        let vorher = d.object(forKey: Sparmodus.key)
        defer { d.set(vorher, forKey: Sparmodus.key) }
        d.set(true, forKey: Sparmodus.key)
        #expect(GeraeteStimmeMotor.ruhezeitJetzt == 30)
        d.set(false, forKey: Sparmodus.key)
        if !Sparmodus.stromsparen { #expect(GeraeteStimmeMotor.ruhezeitJetzt == GeraeteStimmeMotor.ruhezeit) }
    }
}
