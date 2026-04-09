import Foundation

// MARK: - Unit Type

enum IngredientUnit: String, CaseIterable, Sendable {
    case g, kg, mL, L, cup, tbsp, tsp, whole
}

// MARK: - Ingredient Formatter

enum IngredientFormatter {

    private struct BaseConversion {
        let base: IngredientUnit
        let factor: Double
    }

    private static let toBase: [IngredientUnit: BaseConversion] = [
        .g:     BaseConversion(base: .g, factor: 1),
        .kg:    BaseConversion(base: .g, factor: 1000),
        .mL:    BaseConversion(base: .mL, factor: 1),
        .L:     BaseConversion(base: .mL, factor: 1000),
        .tsp:   BaseConversion(base: .tsp, factor: 1),
        .tbsp:  BaseConversion(base: .tsp, factor: 3),
        .cup:   BaseConversion(base: .tsp, factor: 48),
        .whole: BaseConversion(base: .whole, factor: 1),
    ]

    private static let cookingUnits: Set<IngredientUnit> = [.cup, .tbsp, .tsp]

    private static let fractions: [(value: Double, label: String)] = [
        (0.125,       "1/8"),
        (0.25,        "1/4"),
        (1.0 / 3.0,  "1/3"),
        (0.375,       "3/8"),
        (0.5,         "1/2"),
        (0.625,       "5/8"),
        (2.0 / 3.0,  "2/3"),
        (0.75,        "3/4"),
        (0.875,       "7/8"),
    ]

    // MARK: - Public API

    /// Scale an amount with a multiplier and auto-convert to the best display unit.
    static func scaleAmount(
        amount: Double,
        unit: IngredientUnit,
        multiplier: Double
    ) -> (amount: Double, unit: IngredientUnit) {
        let scaled = amount * multiplier
        guard let conversion = toBase[unit] else { return (scaled, unit) }
        let baseAmount = scaled * conversion.factor
        return bestUnit(baseAmount: baseAmount, baseUnit: conversion.base)
    }

    /// Format an amount for display. Cooking units get fractions, metric gets decimals.
    static func formatAmount(amount: Double, unit: IngredientUnit) -> String {
        if amount == 0 { return "0" }

        if cookingUnits.contains(unit) {
            let whole = Int(amount)
            let remainder = amount - Double(whole)

            if remainder < 0.04 {
                return "\(whole)"
            }

            if let frac = closestFraction(remainder) {
                return whole > 0 ? "\(whole) \(frac)" : frac
            }

            return roundSmart(amount)
        }

        if unit == .whole {
            return isWholeNumber(amount) ? "\(Int(amount))" : roundSmart(amount)
        }

        // Metric units: smart decimal
        return roundSmart(amount)
    }

    /// Format a full ingredient quantity string like "200g" or "1/2 cup".
    static func formatIngredient(amount: Double?, unit: IngredientUnit?) -> String {
        guard let amount, let unit else { return "" }

        let formatted = formatAmount(amount: amount, unit: unit)

        if unit == .whole { return formatted }

        // No space for g, kg, mL, L; space for cup, tbsp, tsp
        switch unit {
        case .g, .kg, .mL, .L:
            return "\(formatted)\(unit.rawValue)"
        default:
            return "\(formatted) \(unit.rawValue)"
        }
    }

    // MARK: - Private Helpers

    private static func bestUnit(
        baseAmount: Double,
        baseUnit: IngredientUnit
    ) -> (amount: Double, unit: IngredientUnit) {
        switch baseUnit {
        case .g:
            if baseAmount >= 1000 { return (baseAmount / 1000, .kg) }
            return (baseAmount, .g)

        case .mL:
            if baseAmount >= 1000 { return (baseAmount / 1000, .L) }
            return (baseAmount, .mL)

        case .tsp:
            if baseAmount >= 48 { return (baseAmount / 48, .cup) }
            if baseAmount >= 3 { return (baseAmount / 3, .tbsp) }
            return (baseAmount, .tsp)

        default:
            return (baseAmount, baseUnit)
        }
    }

    private static func closestFraction(_ decimal: Double) -> String? {
        for (value, label) in fractions {
            if abs(decimal - value) < 0.04 { return label }
        }
        return nil
    }

    private static func isWholeNumber(_ n: Double) -> Bool {
        n.truncatingRemainder(dividingBy: 1) == 0
    }

    private static func roundSmart(_ n: Double) -> String {
        if isWholeNumber(n) {
            return "\(Int(n))"
        }
        if n >= 100 {
            return "\(Int(n.rounded()))"
        }
        if n >= 10 {
            let s = String(format: "%.1f", n)
            return s.hasSuffix(".0") ? String(s.dropLast(2)) : s
        }
        var s = String(format: "%.2f", n)
        // Trim trailing zeros after decimal
        while s.hasSuffix("0") { s = String(s.dropLast()) }
        if s.hasSuffix(".") { s = String(s.dropLast()) }
        return s
    }
}
