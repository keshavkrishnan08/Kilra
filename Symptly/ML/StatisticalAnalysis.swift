import Foundation

/// Statistical analysis toolkit for rigorous correlation testing.
/// Replaces naive conditional averages with proper hypothesis testing.
struct StatisticalAnalysis {

    // MARK: - Welch's t-test (unequal variance)
    /// Returns (t-statistic, p-value, significant) for two independent samples.
    /// Uses Welch-Satterthwaite approximation for degrees of freedom.
    struct TTestResult {
        let tStatistic: Double
        let degreesOfFreedom: Double
        let pValue: Double
        let isSignificant: Bool      // p < 0.05
        let meanDifference: Double
        let effectSize: Double        // Cohen's d
        let confidenceInterval: (lower: Double, upper: Double) // 95% CI for mean difference
    }

    static func welchTTest(sample1: [Double], sample2: [Double]) -> TTestResult? {
        guard sample1.count >= 2, sample2.count >= 2 else { return nil }

        let n1 = Double(sample1.count)
        let n2 = Double(sample2.count)
        let mean1 = sample1.reduce(0, +) / n1
        let mean2 = sample2.reduce(0, +) / n2

        let var1 = sample1.map { pow($0 - mean1, 2) }.reduce(0, +) / (n1 - 1)
        let var2 = sample2.map { pow($0 - mean2, 2) }.reduce(0, +) / (n2 - 1)

        let se1 = var1 / n1
        let se2 = var2 / n2
        let se = sqrt(se1 + se2)

        guard se > 0 else { return nil }

        let t = (mean1 - mean2) / se

        // Welch-Satterthwaite degrees of freedom
        let num = pow(se1 + se2, 2)
        let denom = pow(se1, 2) / (n1 - 1) + pow(se2, 2) / (n2 - 1)
        let df = denom > 0 ? num / denom : 1

        // Approximate p-value using t-distribution (two-tailed)
        let pValue = tDistributionPValue(t: abs(t), df: df)

        // Cohen's d (pooled)
        let pooledSD = sqrt(((n1 - 1) * var1 + (n2 - 1) * var2) / (n1 + n2 - 2))
        let cohensD = pooledSD > 0 ? abs(mean1 - mean2) / pooledSD : 0

        // 95% confidence interval for mean difference
        let tCritical = tDistributionCritical(df: df, alpha: 0.05)
        let margin = tCritical * se

        return TTestResult(
            tStatistic: t,
            degreesOfFreedom: df,
            pValue: pValue,
            isSignificant: pValue < 0.05,
            meanDifference: mean1 - mean2,
            effectSize: cohensD,
            confidenceInterval: (mean1 - mean2 - margin, mean1 - mean2 + margin)
        )
    }

    // MARK: - Pearson Correlation
    struct CorrelationResult {
        let r: Double                 // Pearson r (-1 to 1)
        let rSquared: Double          // Coefficient of determination
        let pValue: Double
        let isSignificant: Bool
        let strength: CorrelationStrength
    }

    enum CorrelationStrength: String {
        case negligible = "Negligible"
        case weak = "Weak"
        case moderate = "Moderate"
        case strong = "Strong"
        case veryStrong = "Very Strong"
    }

    static func pearsonCorrelation(x: [Double], y: [Double]) -> CorrelationResult? {
        guard x.count == y.count, x.count >= 3 else { return nil }
        let n = Double(x.count)

        let meanX = x.reduce(0, +) / n
        let meanY = y.reduce(0, +) / n

        var sumXY = 0.0, sumX2 = 0.0, sumY2 = 0.0
        for i in 0..<x.count {
            let dx = x[i] - meanX
            let dy = y[i] - meanY
            sumXY += dx * dy
            sumX2 += dx * dx
            sumY2 += dy * dy
        }

        guard sumX2 > 0, sumY2 > 0 else { return nil }

        let r = sumXY / sqrt(sumX2 * sumY2)
        let rSquared = r * r

        // t-test for significance of correlation
        let t = r * sqrt((n - 2) / (1 - rSquared + 1e-10))
        let df = n - 2
        let pValue = tDistributionPValue(t: abs(t), df: df)

        let strength: CorrelationStrength
        let absR = abs(r)
        switch absR {
        case 0..<0.1: strength = .negligible
        case 0.1..<0.3: strength = .weak
        case 0.3..<0.5: strength = .moderate
        case 0.5..<0.7: strength = .strong
        default: strength = .veryStrong
        }

        return CorrelationResult(
            r: r,
            rSquared: rSquared,
            pValue: pValue,
            isSignificant: pValue < 0.05,
            strength: strength
        )
    }

    // MARK: - Descriptive Statistics
    struct DescriptiveStats {
        let count: Int
        let mean: Double
        let median: Double
        let standardDeviation: Double
        let variance: Double
        let min: Double
        let max: Double
        let range: Double
        let q1: Double
        let q3: Double
        let iqr: Double
        let skewness: Double
        let coefficientOfVariation: Double
    }

    static func describe(_ data: [Double]) -> DescriptiveStats? {
        guard !data.isEmpty else { return nil }
        let sorted = data.sorted()
        let n = Double(data.count)
        let mean = data.reduce(0, +) / n

        // Median
        let median: Double
        if sorted.count % 2 == 0 {
            median = (sorted[sorted.count / 2 - 1] + sorted[sorted.count / 2]) / 2
        } else {
            median = sorted[sorted.count / 2]
        }

        // Variance and SD
        let variance = data.map { pow($0 - mean, 2) }.reduce(0, +) / max(n - 1, 1)
        let sd = sqrt(variance)

        // Quartiles
        let q1 = percentile(sorted, p: 0.25)
        let q3 = percentile(sorted, p: 0.75)

        // Skewness (Fisher's)
        let skewness: Double
        if sd > 0 && n >= 3 {
            let m3 = data.map { pow(($0 - mean) / sd, 3) }.reduce(0, +)
            skewness = (n / ((n - 1) * (n - 2))) * m3
        } else {
            skewness = 0
        }

        let cv = mean != 0 ? sd / abs(mean) : 0

        return DescriptiveStats(
            count: data.count,
            mean: mean,
            median: median,
            standardDeviation: sd,
            variance: variance,
            min: sorted.first ?? 0,
            max: sorted.last ?? 0,
            range: (sorted.last ?? 0) - (sorted.first ?? 0),
            q1: q1,
            q3: q3,
            iqr: q3 - q1,
            skewness: skewness,
            coefficientOfVariation: cv
        )
    }

    // MARK: - Outlier Detection (IQR method)
    static func detectOutliers(_ data: [Double], multiplier: Double = 1.5) -> [Int] {
        guard let stats = describe(data) else { return [] }
        let lowerBound = stats.q1 - multiplier * stats.iqr
        let upperBound = stats.q3 + multiplier * stats.iqr
        return data.enumerated().compactMap { index, value in
            (value < lowerBound || value > upperBound) ? index : nil
        }
    }

    // MARK: - Z-Score Anomaly Detection
    static func zScores(_ data: [Double]) -> [Double] {
        guard let stats = describe(data), stats.standardDeviation > 0 else {
            return Array(repeating: 0, count: data.count)
        }
        return data.map { ($0 - stats.mean) / stats.standardDeviation }
    }

    // MARK: - Private Helpers

    private static func percentile(_ sorted: [Double], p: Double) -> Double {
        guard !sorted.isEmpty else { return 0 }
        let index = p * Double(sorted.count - 1)
        let lower = Int(floor(index))
        let upper = Int(ceil(index))
        if lower == upper { return sorted[lower] }
        let fraction = index - Double(lower)
        return sorted[lower] * (1 - fraction) + sorted[upper] * fraction
    }

    /// Approximate p-value for two-tailed t-test using rational approximation.
    /// Accurate to ~3 decimal places for most practical df values.
    private static func tDistributionPValue(t: Double, df: Double) -> Double {
        // Use the regularized incomplete beta function approximation
        // For large df, t-distribution ≈ normal
        if df > 100 {
            return 2.0 * normalCDF(-abs(t))
        }

        let x = df / (df + t * t)
        let a = df / 2.0
        let b = 0.5

        // Regularized incomplete beta function approximation
        let betaValue = regularizedBeta(x: x, a: a, b: b)
        return min(1.0, max(0.0, betaValue))
    }

    /// Critical t-value for given df and two-tailed alpha (approximation).
    private static func tDistributionCritical(df: Double, alpha: Double) -> Double {
        // Approximation using normal distribution for large df
        if df > 100 { return 1.96 }
        if df > 30 { return 2.042 }
        if df > 20 { return 2.086 }
        if df > 10 { return 2.228 }
        if df > 5 { return 2.571 }
        return 2.776
    }

    /// Standard normal CDF (Abramowitz & Stegun approximation)
    private static func normalCDF(_ x: Double) -> Double {
        let a1 = 0.254829592
        let a2 = -0.284496736
        let a3 = 1.421413741
        let a4 = -1.453152027
        let a5 = 1.061405429
        let p = 0.3275911

        let sign = x < 0 ? -1.0 : 1.0
        let absX = abs(x) / sqrt(2.0)
        let t = 1.0 / (1.0 + p * absX)
        let y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * exp(-absX * absX)

        return 0.5 * (1.0 + sign * y)
    }

    /// Regularized incomplete beta function (continued fraction approximation)
    private static func regularizedBeta(x: Double, a: Double, b: Double) -> Double {
        guard x > 0, x < 1 else {
            return x <= 0 ? 0 : 1
        }

        // Use the continued fraction (Lentz's method)
        let maxIter = 100
        let epsilon = 1e-8

        let lnBeta = lgamma(a) + lgamma(b) - lgamma(a + b)
        let front = exp(a * log(x) + b * log(1 - x) - lnBeta) / a

        // Modified Lentz's method
        var f = 1.0
        var c = 1.0
        var d = 1.0 - (a + b) * x / (a + 1)
        if abs(d) < 1e-30 { d = 1e-30 }
        d = 1.0 / d
        f = d

        for m in 1...maxIter {
            let mDouble = Double(m)

            // Even step
            var numerator = mDouble * (b - mDouble) * x / ((a + 2 * mDouble - 1) * (a + 2 * mDouble))
            d = 1.0 + numerator * d
            if abs(d) < 1e-30 { d = 1e-30 }
            c = 1.0 + numerator / c
            if abs(c) < 1e-30 { c = 1e-30 }
            d = 1.0 / d
            f *= d * c

            // Odd step
            numerator = -(a + mDouble) * (a + b + mDouble) * x / ((a + 2 * mDouble) * (a + 2 * mDouble + 1))
            d = 1.0 + numerator * d
            if abs(d) < 1e-30 { d = 1e-30 }
            c = 1.0 + numerator / c
            if abs(c) < 1e-30 { c = 1e-30 }
            d = 1.0 / d
            let delta = d * c
            f *= delta

            if abs(delta - 1.0) < epsilon { break }
        }

        return min(1.0, max(0.0, front * f))
    }
}
