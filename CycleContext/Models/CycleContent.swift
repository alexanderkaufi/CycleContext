import SwiftUI

enum CycleSection: String, CaseIterable, Identifiable, Codable {
    case menstruation
    case building
    case ovulationWindow = "ovulation_window"
    case luteal
    case premenstrual

    var id: String { rawValue }

    var tint: Color {
        switch self {
        case .menstruation: return .red
        case .building: return .green
        case .ovulationWindow: return .blue
        case .luteal: return .orange
        case .premenstrual: return .pink
        }
    }

    var icon: String {
        switch self {
        case .menstruation: return "drop.fill"
        case .building: return "arrow.up.forward.circle.fill"
        case .ovulationWindow: return "circle.hexagongrid.fill"
        case .luteal: return "moon.fill"
        case .premenstrual: return "wind"
        }
    }
}

enum CycleEstimateConfidence {
    case demo
    case confirmedPeriod
    case personalEstimate
    case generalOrientation
    case manualCorrection
    case unclear

    var title: String {
        switch self {
        case .demo: return String(localized: "cycle.confidence.demo")
        case .confirmedPeriod: return String(localized: "cycle.confidence.confirmedPeriod")
        case .personalEstimate: return String(localized: "cycle.confidence.personalEstimate")
        case .generalOrientation: return String(localized: "cycle.confidence.generalOrientation")
        case .manualCorrection: return String(localized: "cycle.confidence.manualCorrection")
        case .unclear: return String(localized: "cycle.confidence.unclear")
        }
    }

    var icon: String {
        switch self {
        case .demo: return "info.circle.fill"
        case .confirmedPeriod: return "checkmark.circle.fill"
        case .personalEstimate: return "chart.line.uptrend.xyaxis"
        case .generalOrientation: return "info.circle.fill"
        case .manualCorrection: return "slider.horizontal.3"
        case .unclear: return "exclamationmark.circle.fill"
        }
    }
}

struct CycleSectionContent: Identifiable {
    var section: CycleSection
    var title: String
    var biologicalPhase: String
    var shortGuide: String
    var energyLabel: String
    var todayText: String
    var bodyText: String
    var possibleExperienceText: String
    var partnerActionText: String
    var avoidText: String
    var medicalNote: String?

    var id: CycleSection { section }
}

enum CycleContentRepository {
    static func content(for section: CycleSection) -> CycleSectionContent {
        let keyPrefix = "cycle.content.\(section.rawValue)"

        func localized(_ field: String) -> String {
            let key = keyPrefix + "." + field
            return String(localized: String.LocalizationValue(key))
        }

        let medicalNote: String?
        switch section {
        case .building, .luteal:
            medicalNote = nil
        case .menstruation, .ovulationWindow, .premenstrual:
            medicalNote = localized("medicalNote")
        }

        return CycleSectionContent(
            section: section,
            title: localized("title"),
            biologicalPhase: localized("biologicalPhase"),
            shortGuide: localized("shortGuide"),
            energyLabel: localized("energyLabel"),
            todayText: localized("todayText"),
            bodyText: localized("bodyText"),
            possibleExperienceText: localized("possibleExperienceText"),
            partnerActionText: localized("partnerActionText"),
            avoidText: localized("avoidText"),
            medicalNote: medicalNote
        )
    }
}
