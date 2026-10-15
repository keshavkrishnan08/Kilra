import Foundation

/// Time-series analysis toolkit for symptom severity data.
/// Provides EMA smoothing, trend decomposition, anomaly detection,
/// and moving statistics for chart visualizations.
struct TimeSeriesAnalyzer {

    // MARK: - Exponential Moving Average (EMA)

    /// Smooths raw severity data using EMA. Lower alpha = smoother, higher = more responsive.
    /// - Parameters:
    ///   - values: Raw data points (ordered chronologically)
    ///   - alpha: Smoothing factor (0..1). Default 0.3 balances responsiveness and noise reduction.
    /// - Returns: Smoothed series of the same length
    static func ema(_ values: [Double], alpha: Double = 0.3) -> [Double] {
        guard !values.isEmpty else { return [] }
        var result = [values[0]]
        for i in 1..<values.count {
            let smoothed = alpha * values[i] + (1 - alpha) * result[i - 1]
            result.append(smoothed)
        }
        return result
    }

    /// Double EMA for even smoother trend extraction (reduces lag vs single EMA).
    static func doubleEMA(_ values: [Double], alpha: Double = 0.3) -> [Double] {
        let single = ema(values, alpha: alpha)
        let double = ema(single, alpha: alpha)
        // DEMA = 2 * EMA - EMA(EMA)
        return zip(single, double).map { 2 * $0 - $1 }
    }

    // MARK: - Simple Moving Average

    static func sma(_ values: [Double], window: Int) -> [Double] {
        guard window > 0, !values.isEmpty else { return values }
        var result: [Double] = []
        for i in 0..<values.count {
            let start = max(0, i - window + 1)
            let slice = values[start...i]
            result.append(slice.reduce(0, +) / Double(slice.count))
        }
        return result
    }

    // MARK: - Trend Decomposition

    struct TrendDecomposition {
        let trend: [Double]       // Long-term direction (SMA-smoothed)
        let seasonal: [Double]    // Repeating pattern (deviations from trend)
        let residual: [Double]    // Noise / anomalies
        let original: [Double]
    }

    /// Decomposes a time series into trend + seasonal + residual components.
    /// Uses additive decomposition: original = trend + seasonal + residual
    /// - Parameters:
    ///   - values: Raw data points
    ///   - period: Expected seasonal period in data points (e.g. 7 for weekly)
    static func decompose(_ values: [Double], period: Int = 7) -> TrendDecomposition {
        guard values.count >= period * 2 else {
            return TrendDecomposition(trend: values, seasonal: Array(repeating: 0, count: values.count),
                                     residual: Array(repeating: 0, count: values.count), original: values)
        }

        // Step 1: Extract trend via centered moving average
        let trend = sma(values, window: period)

        // Step 2: Detrend: subtract trend from original
        let detrended = zip(values, trend).map { $0 - $1 }

        // Step 3: Average seasonal component per position within period
        var seasonalAvg = Array(repeating: 0.0, count: period)
        var counts = Array(repeating: 0, count: period)
        for (i, val) in detrended.enumerated() {
            let pos = i % period
            seasonalAvg[pos] += val
            counts[pos] += 1
        }
        for i in 0..<period {
            seasonalAvg[i] = counts[i] > 0 ? seasonalAvg[i] / Double(counts[i]) : 0
        }

        // Step 4: Build full seasonal signal
        let seasonal = (0..<values.count).map { seasonalAvg[$0 % period] }

        // Step 5: Residual = original - trend - seasonal
        let residual = (0..<values.count).map { values[$0] - trend[$0] - seasonal[$0] }

        return TrendDecomposition(trend: trend, seasonal: seasonal, residual: residual, original: values)
    }

    // MARK: - Anomaly Detection

    struct Anomaly: Identifiable {
        let id = UUID()
        let index: Int
        let value: Double
        let expectedValue: Double
        let zScore: Double
        let type: AnomalyType
    }

    enum AnomalyType: String {
        case spike = "Spike"
        case dip = "Dip"
    }

    /// Detects anomalous data points by comparing each value to a local window baseline.
    /// Points beyond `threshold` standard deviations from the local mean are flagged.
    static func detectAnomalies(_ values: [Double], window: Int = 7, threshold: Double = 2.0) -> [Anomaly] {
        guard values.count > window else { return [] }

        var anomalies: [Anomaly] = []

        for i in window..<values.count {
            let windowSlice = Array(values[(i - window)..<i])
            let mean = windowSlice.reduce(0, +) / Double(windowSlice.count)
            let variance = windowSlice.map { pow($0 - mean, 2) }.reduce(0, +) / Double(windowSlice.count)
            let sd = sqrt(variance)

            guard sd > 0 else { continue }

            let z = (values[i] - mean) / sd
            if abs(z) >= threshold {
                anomalies.append(Anomaly(
                    index: i,
                    value: values[i],
                    expectedValue: mean,
                    zScore: z,
                    type: z > 0 ? .spike : .dip
                ))
            }
        }

        return anomalies
    }

    // MARK: - Moving Statistics

    struct MovingStats {
        let means: [Double]
        let stdDevs: [Double]
        let upperBand: [Double]  // mean + 2*SD (Bollinger-style)
        let lowerBand: [Double]  // mean - 2*SD
    }

    /// Computes rolling mean and standard deviation, producing Bollinger-style bands.
    static func movingStatistics(_ values: [Double], window: Int = 7) -> MovingStats {
        guard !values.isEmpty else {
            return MovingStats(means: [], stdDevs: [], upperBand: [], lowerBand: [])
        }

        var means: [Double] = []
        var stdDevs: [Double] = []
        var upper: [Double] = []
        var lower: [Double] = []

        for i in 0..<values.count {
            let start = max(0, i - window + 1)
            let slice = Array(values[start...i])
            let mean = slice.reduce(0, +) / Double(slice.count)
            let variance = slice.map { pow($0 - mean, 2) }.reduce(0, +) / Double(slice.count)
            let sd = sqrt(variance)

            means.append(mean)
            stdDevs.append(sd)
            upper.append(mean + 2 * sd)
            lower.append(max(0, mean - 2 * sd))
        }

        return MovingStats(means: means, stdDevs: stdDevs, upperBand: upper, lowerBand: lower)
    }

    // MARK: - Rate of Change

    /// Computes the rate of change (first derivative) of a time series.
    /// Positive = increasing, negative = decreasing.
    static func rateOfChange(_ values: [Double]) -> [Double] {
        guard values.count >= 2 else { return Array(repeating: 0, count: values.count) }
        var roc: [Double] = [0]  // First point has no prior
        for i in 1..<values.count {
            roc.append(values[i] - values[i - 1])
        }
        return roc
    }

    // MARK: - Trend Strength

    struct TrendMetrics {
        let slope: Double         // Linear regression slope (severity per day)
        let rSquared: Double      // How well linear model fits (0-1)
        let direction: TrendDirection
        let changePerWeek: Double // Projected severity change per week
    }

    enum TrendDirection: String {
        case improving = "Improving"
        case stable = "Stable"
        case worsening = "Worsening"
    }

    /// Measures the strength and direction of the overall trend in the data.
    static func trendStrength(_ values: [Double]) -> TrendMetrics {
        guard values.count >= 3 else {
            return TrendMetrics(slope: 0, rSquared: 0, direction: .stable, changePerWeek: 0)
        }

        let n = Double(values.count)
        let xValues = (0..<values.count).map { Double($0) }

        var sumX = 0.0, sumY = 0.0, sumXY = 0.0, sumX2 = 0.0, sumY2 = 0.0
        for i in 0..<values.count {
            sumX += xValues[i]
            sumY += values[i]
            sumXY += xValues[i] * values[i]
            sumX2 += xValues[i] * xValues[i]
            sumY2 += values[i] * values[i]
        }

        let denomX = n * sumX2 - sumX * sumX
        guard denomX != 0 else {
            return TrendMetrics(slope: 0, rSquared: 0, direction: .stable, changePerWeek: 0)
        }

        let slope = (n * sumXY - sumX * sumY) / denomX

        // R-squared
        let denomR = (n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY)
        let rSquared: Double
        if denomR > 0 {
            let r = (n * sumXY - sumX * sumY) / sqrt(denomR)
            rSquared = r * r
        } else {
            rSquared = 0
        }

        let direction: TrendDirection
        if slope < -0.02 { direction = .improving }
        else if slope > 0.02 { direction = .worsening }
        else { direction = .stable }

        return TrendMetrics(
            slope: slope,
            rSquared: rSquared,
            direction: direction,
            changePerWeek: slope * 7
        )
    }

    // MARK: - Forecast (simple linear extrapolation)

    /// Projects the next `count` values based on linear regression of the input series.
    static func forecast(_ values: [Double], count: Int = 7) -> [Double] {
        guard values.count >= 3 else {
            let last = values.last ?? 5.0
            return Array(repeating: last, count: count)
        }

        let metrics = trendStrength(values)
        let n = Double(values.count)
        let mean = values.reduce(0, +) / n

        // y-intercept: b = mean_y - slope * mean_x
        let meanX = (n - 1) / 2.0
        let intercept = mean - metrics.slope * meanX

        return (0..<count).map { i in
            let x = n + Double(i)
            let predicted = intercept + metrics.slope * x
            return max(0, min(10, predicted))  // Clamp to valid severity range
        }
    }

    // MARK: - Seasonal Average

    /// Computes the average value for each position within a cycle (e.g. day-of-week).
    /// Returns an array of length `period` representing the average at each cycle position.
    static func seasonalAverage(_ values: [Double], period: Int = 7) -> [Double] {
        guard period > 0, !values.isEmpty else { return [] }
        var sums = Array(repeating: 0.0, count: period)
        var counts = Array(repeating: 0, count: period)
        for (i, val) in values.enumerated() {
            let pos = i % period
            sums[pos] += val
            counts[pos] += 1
        }
        return (0..<period).map { counts[$0] > 0 ? sums[$0] / Double(counts[$0]) : 0 }
    }
}
