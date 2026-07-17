#if canImport(UIKit)
import UIKit

@MainActor
final class PDFReportGenerator {

    // MARK: - Constants

    private static let pageWidth: CGFloat = 612
    private static let pageHeight: CGFloat = 792
    private static let pageSize = CGSize(width: pageWidth, height: pageHeight)
    private static let margin: CGFloat = 50
    private static let contentWidth: CGFloat = pageWidth - margin * 2

    // Colors
    private static let accentTeal = UIColor(red: 0/255, green: 196/255, blue: 154/255, alpha: 1)
    private static let darkGray = UIColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 1)
    private static let mediumGray = UIColor(red: 0.35, green: 0.38, blue: 0.42, alpha: 1)
    private static let lightGray = UIColor(red: 0.92, green: 0.91, blue: 0.89, alpha: 1)
    private static let rowAltBackground = UIColor(red: 0.96, green: 0.96, blue: 0.95, alpha: 1)

    // Fonts
    private static let titleFont = UIFont.systemFont(ofSize: 26, weight: .bold)
    private static let subtitleFont = UIFont.systemFont(ofSize: 12, weight: .regular)
    private static let sectionHeaderFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
    private static let bodyFont = UIFont.systemFont(ofSize: 11, weight: .regular)
    private static let bodyBoldFont = UIFont.systemFont(ofSize: 11, weight: .semibold)
    private static let smallFont = UIFont.systemFont(ofSize: 9, weight: .regular)
    private static let scoreFont = UIFont.systemFont(ofSize: 42, weight: .bold)
    private static let scoreLabelFont = UIFont.systemFont(ofSize: 14, weight: .medium)
    private static let tableHeaderFont = UIFont.systemFont(ofSize: 10, weight: .bold)
    private static let tableCellFont = UIFont.systemFont(ofSize: 10, weight: .regular)

    // MARK: - Public API

    static func generateReport(dataStore: DataStore, wellnessScore: Double, dateRange: Int = 30) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))

        let cutoffDate = Date().addingTimeInterval(-Double(dateRange * 86400))
        let entries = dataStore.entries.filter { $0.timestamp >= cutoffDate }
        let summaries = dataStore.dailySummaries.filter { $0.date >= cutoffDate }
        let activeMeds = dataStore.medications.filter { $0.isActive }
        let frequencies = dataStore.symptomFrequency(days: dateRange)
        let triggers = dataStore.triggerCorrelations(days: dateRange)

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium

        let endDateStr = dateFormatter.string(from: Date())
        let startDateStr = dateFormatter.string(from: cutoffDate)

        let data = renderer.pdfData { context in
            var yOffset: CGFloat = 0

            // ------- PAGE 1 -------
            context.beginPage()
            yOffset = margin

            // 1. Header
            yOffset = drawHeader(
                context: context,
                yOffset: yOffset,
                startDate: startDateStr,
                endDate: endDateStr,
                generationDate: dateFormatter.string(from: Date())
            )

            // 2. Wellness Score Summary
            yOffset = drawWellnessScore(context: context, yOffset: yOffset, score: wellnessScore)

            // 3. Symptom Summary Table
            yOffset = drawSymptomSummaryTable(
                context: context,
                yOffset: yOffset,
                frequencies: frequencies,
                dataStore: dataStore,
                entries: entries,
                dateRange: dateRange
            )

            // Check if we need a new page before severity distribution
            if yOffset > pageHeight - 200 {
                drawFooter(context: context)
                context.beginPage()
                yOffset = margin
            }

            // 4. Severity Distribution
            yOffset = drawSeverityDistribution(context: context, yOffset: yOffset, entries: entries)

            // Check page break
            if yOffset > pageHeight - 200 {
                drawFooter(context: context)
                context.beginPage()
                yOffset = margin
            }

            // 5. Trigger Analysis
            yOffset = drawTriggerAnalysis(context: context, yOffset: yOffset, triggers: triggers)

            // Check page break
            if yOffset > pageHeight - 200 {
                drawFooter(context: context)
                context.beginPage()
                yOffset = margin
            }

            // 6. Daily Check-in Summary
            yOffset = drawDailyCheckinSummary(context: context, yOffset: yOffset, summaries: summaries)

            // Check page break
            if yOffset > pageHeight - 160 {
                drawFooter(context: context)
                context.beginPage()
                yOffset = margin
            }

            // 7. Health Data (HealthKit)
            let healthSnaps = dataStore.healthSnapshots.filter { $0.date >= cutoffDate }
            if !healthSnaps.isEmpty {
                if yOffset > pageHeight - 200 {
                    drawFooter(context: context)
                    context.beginPage()
                    yOffset = margin
                }
                yOffset = drawHealthData(context: context, yOffset: yOffset, snapshots: healthSnaps)
            }

            // 8. Key Correlations
            let allCorrelations = dataStore.lifestyleCorrelations()
                + (dataStore.waterCorrelation().map { [$0] } ?? [])
                + dataStore.medicationCorrelations()
                + dataStore.healthCorrelations()
            if !allCorrelations.isEmpty {
                if yOffset > pageHeight - 200 {
                    drawFooter(context: context)
                    context.beginPage()
                    yOffset = margin
                }
                yOffset = drawCorrelations(context: context, yOffset: yOffset, correlations: allCorrelations)
            }

            // 9. Medication List
            if yOffset > pageHeight - 160 {
                drawFooter(context: context)
                context.beginPage()
                yOffset = margin
            }
            yOffset = drawMedicationList(context: context, yOffset: yOffset, medications: activeMeds)

            // Footer on last page
            drawFooter(context: context)
        }

        return data
    }

    // MARK: - Section Drawing

    private static func drawHeader(
        context: UIGraphicsPDFRendererContext,
        yOffset: CGFloat,
        startDate: String,
        endDate: String,
        generationDate: String
    ) -> CGFloat {
        var y = yOffset

        // Teal accent bar across the top
        let barRect = CGRect(x: 0, y: 0, width: pageWidth, height: 6)
        accentTeal.setFill()
        context.cgContext.fill(barRect)

        // Title
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: accentTeal
        ]
        let title: NSString = "Symptly Health Report"
        title.draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
        y += titleFont.lineHeight + 6

        // Date range
        let rangeAttrs: [NSAttributedString.Key: Any] = [
            .font: subtitleFont,
            .foregroundColor: mediumGray
        ]
        let rangeStr: NSString = "Report Period: \(startDate) - \(endDate)" as NSString
        rangeStr.draw(at: CGPoint(x: margin, y: y), withAttributes: rangeAttrs)
        y += subtitleFont.lineHeight + 2

        // Generation date
        let genStr: NSString = "Generated: \(generationDate)" as NSString
        genStr.draw(at: CGPoint(x: margin, y: y), withAttributes: rangeAttrs)
        y += subtitleFont.lineHeight + 12

        // Horizontal rule
        y = drawHorizontalRule(y: y)

        return y
    }

    private static func drawWellnessScore(
        context: UIGraphicsPDFRendererContext,
        yOffset: CGFloat,
        score: Double
    ) -> CGFloat {
        var y = yOffset + 8

        // Section header
        y = drawSectionHeader("Wellness Score Summary", y: y)

        let clampedScore = min(max(score, 0), 100)
        let category = scoreCategory(clampedScore)
        let categoryColor = scoreCategoryColor(clampedScore)

        // Score value
        let scoreStr: NSString = "\(Int(clampedScore))" as NSString
        let scoreAttrs: [NSAttributedString.Key: Any] = [
            .font: scoreFont,
            .foregroundColor: categoryColor
        ]
        scoreStr.draw(at: CGPoint(x: margin, y: y), withAttributes: scoreAttrs)

        // "/100" next to the score
        let outOfAttrs: [NSAttributedString.Key: Any] = [
            .font: scoreLabelFont,
            .foregroundColor: mediumGray
        ]
        let scoreWidth = scoreStr.size(withAttributes: scoreAttrs).width
        let outOf: NSString = " / 100"
        outOf.draw(at: CGPoint(x: margin + scoreWidth + 2, y: y + 24), withAttributes: outOfAttrs)

        // Category label
        let catAttrs: [NSAttributedString.Key: Any] = [
            .font: scoreLabelFont,
            .foregroundColor: categoryColor
        ]
        let catStr: NSString = category as NSString
        catStr.draw(at: CGPoint(x: margin + scoreWidth + 60, y: y + 24), withAttributes: catAttrs)

        y += scoreFont.lineHeight + 16

        y = drawHorizontalRule(y: y)
        return y
    }

    private static func drawSymptomSummaryTable(
        context: UIGraphicsPDFRendererContext,
        yOffset: CGFloat,
        frequencies: [(String, Int)],
        dataStore: DataStore,
        entries: [SymptomEntry],
        dateRange: Int
    ) -> CGFloat {
        var y = yOffset + 8

        y = drawSectionHeader("Symptom Summary", y: y)

        guard !frequencies.isEmpty else {
            y = drawBodyText("No symptoms logged during this period.", y: y)
            y = drawHorizontalRule(y: y + 8)
            return y
        }

        // Column widths
        let nameColW: CGFloat = 160
        let freqColW: CGFloat = 80
        let sevColW: CGFloat = 100
        let _: CGFloat = contentWidth - nameColW - freqColW - sevColW
        let rowHeight: CGFloat = 22

        // Table header
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: tableHeaderFont,
            .foregroundColor: UIColor.white
        ]

        let headerRect = CGRect(x: margin, y: y, width: contentWidth, height: rowHeight)
        accentTeal.setFill()
        context.cgContext.fill(headerRect)

        var xPos = margin + 6
        ("Symptom" as NSString).draw(at: CGPoint(x: xPos, y: y + 5), withAttributes: headerAttrs)
        xPos += nameColW
        ("Frequency" as NSString).draw(at: CGPoint(x: xPos, y: y + 5), withAttributes: headerAttrs)
        xPos += freqColW
        ("Avg Severity" as NSString).draw(at: CGPoint(x: xPos, y: y + 5), withAttributes: headerAttrs)
        xPos += sevColW
        ("Trend" as NSString).draw(at: CGPoint(x: xPos, y: y + 5), withAttributes: headerAttrs)

        y += rowHeight

        // Table rows
        let cellAttrs: [NSAttributedString.Key: Any] = [
            .font: tableCellFont,
            .foregroundColor: darkGray
        ]

        for (index, item) in frequencies.prefix(12).enumerated() {
            let symptomName = item.0
            let count = item.1

            // Alternating row background
            if index % 2 == 1 {
                let rowRect = CGRect(x: margin, y: y, width: contentWidth, height: rowHeight)
                rowAltBackground.setFill()
                context.cgContext.fill(rowRect)
            }

            // Check for page overflow mid-table
            if y > pageHeight - 80 {
                drawFooter(context: context)
                context.beginPage()
                y = margin
            }

            xPos = margin + 6
            (symptomName as NSString).draw(at: CGPoint(x: xPos, y: y + 5), withAttributes: cellAttrs)

            xPos += nameColW
            ("\(count) entries" as NSString).draw(at: CGPoint(x: xPos, y: y + 5), withAttributes: cellAttrs)

            xPos += freqColW
            let avgSev = dataStore.averageSeverity(for: symptomName, days: dateRange)
            let sevStr = String(format: "%.1f / 10", avgSev)
            (sevStr as NSString).draw(at: CGPoint(x: xPos, y: y + 5), withAttributes: cellAttrs)

            xPos += sevColW
            let trend = computeTrend(for: symptomName, entries: entries, dateRange: dateRange)
            let trendAttrs: [NSAttributedString.Key: Any] = [
                .font: tableCellFont,
                .foregroundColor: trendColor(trend)
            ]
            (trend as NSString).draw(at: CGPoint(x: xPos, y: y + 5), withAttributes: trendAttrs)

            y += rowHeight
        }

        // Table border
        let tableRect = CGRect(x: margin, y: yOffset + 8 + sectionHeaderFont.lineHeight + 12,
                               width: contentWidth,
                               height: y - (yOffset + 8 + sectionHeaderFont.lineHeight + 12))
        UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1).setStroke()
        context.cgContext.stroke(tableRect, width: 0.5)

        y += 8
        y = drawHorizontalRule(y: y)
        return y
    }

    private static func drawSeverityDistribution(
        context: UIGraphicsPDFRendererContext,
        yOffset: CGFloat,
        entries: [SymptomEntry]
    ) -> CGFloat {
        var y = yOffset + 8

        y = drawSectionHeader("Severity Distribution", y: y)

        guard !entries.isEmpty else {
            y = drawBodyText("No entries to analyze.", y: y)
            y = drawHorizontalRule(y: y + 8)
            return y
        }

        let mild = entries.filter { $0.severity >= 1 && $0.severity <= 3 }.count
        let moderate = entries.filter { $0.severity >= 4 && $0.severity <= 6 }.count
        let severe = entries.filter { $0.severity >= 7 && $0.severity <= 8 }.count
        let critical = entries.filter { $0.severity >= 9 && $0.severity <= 10 }.count
        let total = entries.count

        let categories: [(String, Int, UIColor)] = [
            ("Mild (1-3)", mild, UIColor(red: 0.33, green: 0.77, blue: 0.37, alpha: 1)),
            ("Moderate (4-6)", moderate, UIColor(red: 0.92, green: 0.70, blue: 0.03, alpha: 1)),
            ("Severe (7-8)", severe, UIColor(red: 0.98, green: 0.45, blue: 0.09, alpha: 1)),
            ("Critical (9-10)", critical, UIColor(red: 0.94, green: 0.27, blue: 0.27, alpha: 1))
        ]

        let barMaxWidth: CGFloat = 260
        let barHeight: CGFloat = 16
        let labelWidth: CGFloat = 110
        let _: CGFloat = 80

        for (label, count, color) in categories {
            // Label
            let labelAttrs: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: darkGray
            ]
            (label as NSString).draw(at: CGPoint(x: margin, y: y + 1), withAttributes: labelAttrs)

            // Bar
            let ratio = total > 0 ? CGFloat(count) / CGFloat(total) : 0
            let barWidth = barMaxWidth * ratio
            let barX = margin + labelWidth

            // Background bar
            let bgBarRect = CGRect(x: barX, y: y + 1, width: barMaxWidth, height: barHeight)
            UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1).setFill()
            let bgPath = UIBezierPath(roundedRect: bgBarRect, cornerRadius: 3)
            bgPath.fill()

            // Filled bar
            if barWidth > 0 {
                let fillRect = CGRect(x: barX, y: y + 1, width: barWidth, height: barHeight)
                color.setFill()
                let fillPath = UIBezierPath(roundedRect: fillRect, cornerRadius: 3)
                fillPath.fill()
            }

            // Count
            let pct = total > 0 ? Int(round(Double(count) / Double(total) * 100)) : 0
            let countStr = "\(count) (\(pct)%)" as NSString
            let countAttrs: [NSAttributedString.Key: Any] = [
                .font: bodyBoldFont,
                .foregroundColor: mediumGray
            ]
            countStr.draw(at: CGPoint(x: barX + barMaxWidth + 10, y: y + 2), withAttributes: countAttrs)

            y += barHeight + 8
        }

        // Total
        let totalAttrs: [NSAttributedString.Key: Any] = [
            .font: bodyBoldFont,
            .foregroundColor: darkGray
        ]
        let totalStr = "Total entries: \(total)" as NSString
        totalStr.draw(at: CGPoint(x: margin, y: y), withAttributes: totalAttrs)
        y += bodyBoldFont.lineHeight + 8

        y = drawHorizontalRule(y: y)
        return y
    }

    private static func drawTriggerAnalysis(
        context: UIGraphicsPDFRendererContext,
        yOffset: CGFloat,
        triggers: [(trigger: String, avgWith: Double, avgWithout: Double, count: Int)]
    ) -> CGFloat {
        var y = yOffset + 8

        y = drawSectionHeader("Trigger Analysis", y: y)

        guard !triggers.isEmpty else {
            y = drawBodyText("Not enough data to identify trigger correlations.", y: y)
            y = drawHorizontalRule(y: y + 8)
            return y
        }

        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: bodyBoldFont,
            .foregroundColor: darkGray
        ]
        let detailAttrs: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: mediumGray
        ]

        for item in triggers.prefix(8) {
            if y > pageHeight - 80 {
                drawFooter(context: context)
                context.beginPage()
                y = margin
            }

            let impact = item.avgWith - item.avgWithout
            let arrow = impact > 0 ? "+" : ""
            let triggerLine = "\(item.trigger)  (\(item.count) occurrences)" as NSString
            triggerLine.draw(at: CGPoint(x: margin + 6, y: y), withAttributes: headerAttrs)
            y += bodyBoldFont.lineHeight + 1

            let detailLine = "Avg severity with trigger: \(String(format: "%.1f", item.avgWith))  |  without: \(String(format: "%.1f", item.avgWithout))  |  impact: \(arrow)\(String(format: "%.1f", impact))" as NSString
            detailLine.draw(at: CGPoint(x: margin + 12, y: y), withAttributes: detailAttrs)
            y += bodyFont.lineHeight + 8
        }

        y += 4
        y = drawHorizontalRule(y: y)
        return y
    }

    private static func drawDailyCheckinSummary(
        context: UIGraphicsPDFRendererContext,
        yOffset: CGFloat,
        summaries: [DailySummary]
    ) -> CGFloat {
        var y = yOffset + 8

        y = drawSectionHeader("Daily Check-in Summary", y: y)

        guard !summaries.isEmpty else {
            y = drawBodyText("No daily check-ins recorded during this period.", y: y)
            y = drawHorizontalRule(y: y + 8)
            return y
        }

        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: darkGray
        ]
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: bodyBoldFont,
            .foregroundColor: accentTeal
        ]

        // Average Mood
        let moodSummaries = summaries.filter { $0.overallMood > 0 }
        if !moodSummaries.isEmpty {
            let avgMood = Double(moodSummaries.map(\.overallMood).reduce(0, +)) / Double(moodSummaries.count)
            let moodLabel: NSString = "Average Mood:"
            moodLabel.draw(at: CGPoint(x: margin + 6, y: y), withAttributes: labelAttrs)
            let moodVal = String(format: "%.1f / 5", avgMood) as NSString
            moodVal.draw(at: CGPoint(x: margin + 140, y: y), withAttributes: valueAttrs)
            y += bodyFont.lineHeight + 6
        }

        // Average Energy
        let energySummaries = summaries.filter { $0.overallEnergy > 0 }
        if !energySummaries.isEmpty {
            let avgEnergy = Double(energySummaries.map(\.overallEnergy).reduce(0, +)) / Double(energySummaries.count)
            let energyLabel: NSString = "Average Energy:"
            energyLabel.draw(at: CGPoint(x: margin + 6, y: y), withAttributes: labelAttrs)
            let energyVal = String(format: "%.1f / 5", avgEnergy) as NSString
            energyVal.draw(at: CGPoint(x: margin + 140, y: y), withAttributes: valueAttrs)
            y += bodyFont.lineHeight + 6
        }

        // Average Sleep
        let sleepSummaries = summaries.compactMap { $0.sleepHours != nil ? $0 : nil }
        if !sleepSummaries.isEmpty {
            let avgSleep = sleepSummaries.compactMap(\.sleepHours).reduce(0, +) / Double(sleepSummaries.count)
            let sleepLabel: NSString = "Average Sleep:"
            sleepLabel.draw(at: CGPoint(x: margin + 6, y: y), withAttributes: labelAttrs)
            let sleepVal = String(format: "%.1f hours", avgSleep) as NSString
            sleepVal.draw(at: CGPoint(x: margin + 140, y: y), withAttributes: valueAttrs)
            y += bodyFont.lineHeight + 6
        }

        // Average Stress
        let stressSummaries = summaries.compactMap { $0.stressLevel != nil ? $0 : nil }
        if !stressSummaries.isEmpty {
            let avgStress = Double(stressSummaries.compactMap(\.stressLevel).reduce(0, +)) / Double(stressSummaries.count)
            let stressLabel: NSString = "Average Stress:"
            stressLabel.draw(at: CGPoint(x: margin + 6, y: y), withAttributes: labelAttrs)
            let stressDescriptor = avgStress >= 4 ? "High" : avgStress >= 3 ? "Moderate" : "Low"
            let stressVal = String(format: "%.1f / 5 (%@)", avgStress, stressDescriptor) as NSString
            stressVal.draw(at: CGPoint(x: margin + 140, y: y), withAttributes: valueAttrs)
            y += bodyFont.lineHeight + 6
        }

        // Average Water Intake
        let waterSummaries = summaries.filter { ($0.waterIntake ?? 0) > 0 }
        if !waterSummaries.isEmpty {
            let avgWater = Double(waterSummaries.compactMap(\.waterIntake).reduce(0, +)) / Double(waterSummaries.count)
            let waterLabel: NSString = "Avg Water Intake:"
            waterLabel.draw(at: CGPoint(x: margin + 6, y: y), withAttributes: labelAttrs)
            let waterVal = String(format: "%.1f glasses/day", avgWater) as NSString
            waterVal.draw(at: CGPoint(x: margin + 140, y: y), withAttributes: valueAttrs)
            y += bodyFont.lineHeight + 6
        }

        // Check-in count
        let countAttrs: [NSAttributedString.Key: Any] = [
            .font: smallFont,
            .foregroundColor: mediumGray
        ]
        let countStr = "Based on \(summaries.count) daily check-ins" as NSString
        countStr.draw(at: CGPoint(x: margin + 6, y: y), withAttributes: countAttrs)
        y += smallFont.lineHeight + 10

        y = drawHorizontalRule(y: y)
        return y
    }

    private static func drawMedicationList(
        context: UIGraphicsPDFRendererContext,
        yOffset: CGFloat,
        medications: [Medication]
    ) -> CGFloat {
        var y = yOffset + 8

        y = drawSectionHeader("Active Medications", y: y)

        guard !medications.isEmpty else {
            y = drawBodyText("No active medications recorded.", y: y)
            return y + 8
        }

        let nameAttrs: [NSAttributedString.Key: Any] = [
            .font: bodyBoldFont,
            .foregroundColor: darkGray
        ]
        let detailAttrs: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: mediumGray
        ]

        for (index, med) in medications.enumerated() {
            if y > pageHeight - 80 {
                drawFooter(context: context)
                context.beginPage()
                y = margin
            }

            // Alternating background
            if index % 2 == 0 {
                let rowRect = CGRect(x: margin, y: y - 2, width: contentWidth, height: 32)
                rowAltBackground.setFill()
                context.cgContext.fill(rowRect)
            }

            // Bullet
            let bulletAttrs: [NSAttributedString.Key: Any] = [
                .font: bodyBoldFont,
                .foregroundColor: accentTeal
            ]
            ("\u{2022}" as NSString).draw(at: CGPoint(x: margin + 4, y: y), withAttributes: bulletAttrs)

            // Name
            (med.name as NSString).draw(at: CGPoint(x: margin + 18, y: y), withAttributes: nameAttrs)

            // Dosage and frequency
            let detail = "\(med.dosage) \u{2022} \(med.frequency.rawValue) \u{2022} \(med.timeOfDay.rawValue)" as NSString
            y += bodyBoldFont.lineHeight + 1
            detail.draw(at: CGPoint(x: margin + 18, y: y), withAttributes: detailAttrs)
            y += bodyFont.lineHeight + 8
        }

        return y + 4
    }

    private static func drawHealthData(
        context: UIGraphicsPDFRendererContext,
        yOffset: CGFloat,
        snapshots: [HealthSnapshot]
    ) -> CGFloat {
        var y = yOffset + 8

        y = drawSectionHeader("Health Data (Apple Health)", y: y)

        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: darkGray
        ]
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: bodyBoldFont,
            .foregroundColor: accentTeal
        ]

        let sleepValues = snapshots.compactMap(\.sleepHours).filter { $0 > 0 }
        if !sleepValues.isEmpty {
            let avg = sleepValues.reduce(0, +) / Double(sleepValues.count)
            ("Average Sleep:" as NSString).draw(at: CGPoint(x: margin + 6, y: y), withAttributes: labelAttrs)
            (String(format: "%.1f hours", avg) as NSString).draw(at: CGPoint(x: margin + 140, y: y), withAttributes: valueAttrs)
            y += bodyFont.lineHeight + 6
        }

        let stepValues = snapshots.compactMap(\.stepCount).filter { $0 > 0 }
        if !stepValues.isEmpty {
            let avg = stepValues.reduce(0, +) / stepValues.count
            ("Average Daily Steps:" as NSString).draw(at: CGPoint(x: margin + 6, y: y), withAttributes: labelAttrs)
            ("\(avg)" as NSString).draw(at: CGPoint(x: margin + 140, y: y), withAttributes: valueAttrs)
            y += bodyFont.lineHeight + 6
        }

        let exValues = snapshots.compactMap(\.activeMinutes).filter { $0 > 0 }
        if !exValues.isEmpty {
            let avg = exValues.reduce(0, +) / exValues.count
            ("Average Exercise:" as NSString).draw(at: CGPoint(x: margin + 6, y: y), withAttributes: labelAttrs)
            ("\(avg) min/day" as NSString).draw(at: CGPoint(x: margin + 140, y: y), withAttributes: valueAttrs)
            y += bodyFont.lineHeight + 6
        }

        let hrValues = snapshots.compactMap(\.heartRate).filter { $0 > 0 }
        if !hrValues.isEmpty {
            let avg = Int(hrValues.reduce(0, +) / Double(hrValues.count))
            ("Avg Resting Heart Rate:" as NSString).draw(at: CGPoint(x: margin + 6, y: y), withAttributes: labelAttrs)
            ("\(avg) bpm" as NSString).draw(at: CGPoint(x: margin + 140, y: y), withAttributes: valueAttrs)
            y += bodyFont.lineHeight + 6
        }

        let countStr = "Based on \(snapshots.count) days of Apple Health data" as NSString
        let countAttrs: [NSAttributedString.Key: Any] = [.font: smallFont, .foregroundColor: mediumGray]
        countStr.draw(at: CGPoint(x: margin + 6, y: y), withAttributes: countAttrs)
        y += smallFont.lineHeight + 10

        y = drawHorizontalRule(y: y)
        return y
    }

    private static func drawCorrelations(
        context: UIGraphicsPDFRendererContext,
        yOffset: CGFloat,
        correlations: [(factor: String, finding: String, icon: String, color: String)]
    ) -> CGFloat {
        var y = yOffset + 8

        y = drawSectionHeader("Key Correlations", y: y)

        let bulletAttrs: [NSAttributedString.Key: Any] = [
            .font: bodyBoldFont,
            .foregroundColor: darkGray
        ]

        for corr in correlations.prefix(6) {
            if y > pageHeight - 80 {
                drawFooter(context: context)
                context.beginPage()
                y = margin
            }

            let headerStr = "\(corr.factor):" as NSString
            headerStr.draw(at: CGPoint(x: margin + 6, y: y), withAttributes: bulletAttrs)
            y += bodyBoldFont.lineHeight + 2

            y = drawBodyText(corr.finding, y: y)
            y += 4
        }

        y = drawHorizontalRule(y: y)
        return y
    }

    // MARK: - Drawing Helpers

    private static func drawSectionHeader(_ title: String, y: CGFloat) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: sectionHeaderFont,
            .foregroundColor: accentTeal
        ]
        (title as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: attrs)
        return y + sectionHeaderFont.lineHeight + 8
    }

    private static func drawBodyText(_ text: String, y: CGFloat) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: mediumGray
        ]
        let constraintRect = CGRect(x: margin + 6, y: y, width: contentWidth - 12, height: .greatestFiniteMagnitude)
        let attrStr = NSAttributedString(string: text, attributes: attrs)
        let boundingRect = attrStr.boundingRect(with: constraintRect.size, options: .usesLineFragmentOrigin, context: nil)
        attrStr.draw(in: constraintRect)
        return y + ceil(boundingRect.height) + 4
    }

    private static func drawHorizontalRule(y: CGFloat) -> CGFloat {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: y))
        path.addLine(to: CGPoint(x: pageWidth - margin, y: y))
        UIColor(red: 0.85, green: 0.84, blue: 0.82, alpha: 1).setStroke()
        path.lineWidth = 0.5
        path.stroke()
        return y + 10
    }

    private static func drawFooter(context: UIGraphicsPDFRendererContext) {
        let footerY = pageHeight - margin + 10
        let footerText = "Generated by Symptly \u{2022} Not a medical document \u{2022} Consult your healthcare provider"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: smallFont,
            .foregroundColor: mediumGray
        ]
        let str = NSAttributedString(string: footerText, attributes: attrs)
        let size = str.size()
        let x = (pageWidth - size.width) / 2
        str.draw(at: CGPoint(x: x, y: footerY))
    }

    // MARK: - Utilities

    private static func scoreCategory(_ score: Double) -> String {
        switch score {
        case 0..<25: return "Poor"
        case 25..<50: return "Fair"
        case 50..<75: return "Good"
        default: return "Excellent"
        }
    }

    private static func scoreCategoryColor(_ score: Double) -> UIColor {
        switch score {
        case 0..<25: return UIColor(red: 0.94, green: 0.27, blue: 0.27, alpha: 1)
        case 25..<50: return UIColor(red: 0.98, green: 0.45, blue: 0.09, alpha: 1)
        case 50..<75: return UIColor(red: 0.92, green: 0.70, blue: 0.03, alpha: 1)
        default: return UIColor(red: 0.13, green: 0.77, blue: 0.37, alpha: 1)
        }
    }

    /// Compare the average severity over the first half vs second half of the date range
    /// to determine whether a symptom is trending up, down, or staying stable.
    private static func computeTrend(for symptomName: String, entries: [SymptomEntry], dateRange: Int) -> String {
        let midpoint = Date().addingTimeInterval(-Double(dateRange * 86400) / 2)
        let firstHalf = entries.filter { $0.symptomName == symptomName && $0.timestamp < midpoint }
        let secondHalf = entries.filter { $0.symptomName == symptomName && $0.timestamp >= midpoint }

        guard !firstHalf.isEmpty, !secondHalf.isEmpty else {
            return "\u{2014}" // em dash for insufficient data
        }

        let avgFirst = Double(firstHalf.map(\.severity).reduce(0, +)) / Double(firstHalf.count)
        let avgSecond = Double(secondHalf.map(\.severity).reduce(0, +)) / Double(secondHalf.count)
        let delta = avgSecond - avgFirst

        if delta > 0.5 {
            return "\u{2191} Worsening"
        } else if delta < -0.5 {
            return "\u{2193} Improving"
        } else {
            return "\u{2192} Stable"
        }
    }

    private static func trendColor(_ trend: String) -> UIColor {
        if trend.contains("Worsening") {
            return UIColor(red: 0.94, green: 0.27, blue: 0.27, alpha: 1)
        } else if trend.contains("Improving") {
            return UIColor(red: 0.13, green: 0.77, blue: 0.37, alpha: 1)
        } else {
            return mediumGray
        }
    }
}

#endif
