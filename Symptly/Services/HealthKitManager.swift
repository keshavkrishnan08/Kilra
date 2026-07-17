import SwiftUI
#if canImport(HealthKit)
import HealthKit
#endif

@MainActor
final class HealthKitManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var sleepHours: Double?
    @Published var heartRate: Double?
    @Published var stepCount: Int?
    @Published var activeMinutes: Int?

    #if canImport(HealthKit)
    private let healthStore = HKHealthStore()
    #endif

    #if canImport(HealthKit)
    private let readTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepType)
        }
        if let heartType = HKObjectType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartType)
        }
        if let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) {
            types.insert(stepType)
        }
        if let exerciseType = HKObjectType.quantityType(forIdentifier: .appleExerciseTime) {
            types.insert(exerciseType)
        }
        return types
    }()
    #endif

    func requestAuthorization() async {
        #if canImport(HealthKit)
        guard HKHealthStore.isHealthDataAvailable() else { return }

        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            await fetchTodayData()
        } catch {
            print("HealthKit auth failed: \(error)")
        }
        #endif
    }

    func fetchTodayData() async {
        #if canImport(HealthKit)
        await fetchSleepData()
        await fetchHeartRate()
        await fetchStepCount()
        await fetchActiveMinutes()
        #endif
    }

    #if canImport(HealthKit)
    private func fetchSleepData() async {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay.addingTimeInterval(-86400),
            end: now,
            options: .strictEndDate
        )

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: sleepType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)]
        )

        do {
            let samples = try await descriptor.result(for: healthStore)
            let asleepSamples = samples.filter { $0.value != HKCategoryValueSleepAnalysis.inBed.rawValue }
            let totalSleep = asleepSamples.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
            sleepHours = totalSleep / 3600.0
        } catch {
            print("Sleep fetch error: \(error)")
        }
    }

    private func fetchHeartRate() async {
        guard let heartType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)

        let descriptor = HKStatisticsQueryDescriptor(
            predicate: .quantitySample(type: heartType, predicate: predicate),
            options: .discreteAverage
        )

        do {
            let result = try await descriptor.result(for: healthStore)
            heartRate = result?.averageQuantity()?.doubleValue(for: HKUnit(from: "count/min"))
        } catch {
            print("Heart rate fetch error: \(error)")
        }
    }

    private func fetchStepCount() async {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)

        let descriptor = HKStatisticsQueryDescriptor(
            predicate: .quantitySample(type: stepType, predicate: predicate),
            options: .cumulativeSum
        )

        do {
            let result = try await descriptor.result(for: healthStore)
            stepCount = Int(result?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
        } catch {
            print("Step count fetch error: \(error)")
        }
    }

    private func fetchActiveMinutes() async {
        guard let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else { return }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)

        let descriptor = HKStatisticsQueryDescriptor(
            predicate: .quantitySample(type: exerciseType, predicate: predicate),
            options: .cumulativeSum
        )

        do {
            let result = try await descriptor.result(for: healthStore)
            activeMinutes = Int(result?.sumQuantity()?.doubleValue(for: .minute()) ?? 0)
        } catch {
            print("Active minutes fetch error: \(error)")
        }
    }
    #endif
}
