import Testing
@testable import blockblast

struct PowerUpEarningTests {
    @Test func comboIncrement() {
        var combo = ComboTracker()
        combo.update(linesClearedInMove: 1)
        #expect(combo.currentCombo == 1)
    }

    @Test func comboCarriesOverThreeMisses() {
        var combo = ComboTracker()
        combo.update(linesClearedInMove: 1)
        combo.update(linesClearedInMove: 0)
        combo.update(linesClearedInMove: 0)
        combo.update(linesClearedInMove: 0)
        combo.update(linesClearedInMove: 1)
        #expect(combo.currentCombo == 2)
    }

    @Test func comboResetsAfterFourthMiss() {
        var combo = ComboTracker()
        combo.update(linesClearedInMove: 1)
        combo.update(linesClearedInMove: 0)
        combo.update(linesClearedInMove: 0)
        combo.update(linesClearedInMove: 0)
        combo.update(linesClearedInMove: 0)
        #expect(combo.currentCombo == 0)
    }

    @Test func comboThreeEarnsHammer() {
        let earned = PowerUpEarningService.earnedPowerUps(
            linesClearedInMove: 1,
            comboState: ComboTracker(currentCombo: 3)
        )
        #expect(earned == [.hammer])
    }

    @Test func comboFiveEarnsBomb() {
        let earned = PowerUpEarningService.earnedPowerUps(
            linesClearedInMove: 1,
            comboState: ComboTracker(currentCombo: 5)
        )
        #expect(earned == [.bomb])
    }

    @Test func multiLineMoveEarnsRainbow() {
        let earned = PowerUpEarningService.earnedPowerUps(
            linesClearedInMove: 2,
            comboState: ComboTracker(currentCombo: 0)
        )
        #expect(earned == [.rainbow])
    }

    @Test func rewardsStackWhenMultipleRulesMatch() {
        let earned = PowerUpEarningService.earnedPowerUps(
            linesClearedInMove: 3,
            comboState: ComboTracker(currentCombo: 3)
        )
        #expect(earned == [.hammer, .rainbow])
    }

    @Test func inventoryCapEnforcement() {
        var inventory = PowerUpInventory()
        let firstAdd = inventory.add(type: .hammer)
        let secondAdd = inventory.add(type: .hammer)
        let thirdAdd = inventory.add(type: .hammer)
        let fourthAdd = inventory.add(type: .hammer)

        #expect(firstAdd)
        #expect(secondAdd)
        #expect(thirdAdd)
        #expect(!fourthAdd)
        #expect(inventory.count(for: .hammer) == PowerUpInventory.hammerCap)
        #expect(!inventory.canAdd(type: .hammer))
    }

    @Test func rainbowOnlyOncePerMove() {
        let earned = PowerUpEarningService.earnedPowerUps(
            linesClearedInMove: 4,
            comboState: ComboTracker(currentCombo: 3)
        )
        let rainbowCount = earned.filter { $0 == .rainbow }.count
        #expect(rainbowCount == 1)
    }
}
