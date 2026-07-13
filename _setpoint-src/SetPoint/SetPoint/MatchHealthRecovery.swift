import Foundation
import HealthKit
import SwiftData

/// Recupera metriche salute da Apple Salute per partite passate
/// (allenamenti registrati dall'Apple Watch senza sync a SetPoint).
@MainActor
enum MatchHealthRecovery {
    private static let store = HKHealthStore()
    private static var didAuthorize = false

    private static let readTypes: Set<HKObjectType> = [
        HKQuantityType(.heartRate),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.stepCount),
        HKQuantityType(.distanceWalkingRunning),
        HKObjectType.workoutType()
    ]

    /// Recupero singolo al dettaglio partita.
    static func recoverIfNeeded(for match: MatchRecord, context: ModelContext) async {
        guard !match.hasHealthData else { return }
        guard HKHealthStore.isHealthDataAvailable() else { return }
        await authorize()

        let workouts = await fetchWorkouts(around: match)
        guard let workout = bestWorkout(for: match, among: workouts) else { return }
        let snapshot = await snapshot(from: workout)
        guard snapshot.hasData else { return }

        match.applyHealth(snapshot, recoveredFromSalute: true)
        try? context.save()
    }

    /// Scan in background di tutte le partite senza dati (tab Storico).
    static func recoverAllIfNeeded(in matches: [MatchRecord], context: ModelContext) async {
        let needy = matches.filter { !$0.hasHealthData }
        guard !needy.isEmpty else { return }
        guard HKHealthStore.isHealthDataAvailable() else { return }
        await authorize()

        let buffer: TimeInterval = 120
        guard let minDate = needy.map(\.date).min(),
              let maxDate = needy.map({ matchEnd($0) }).max() else { return }

        let workouts = await fetchWorkouts(
            from: minDate.addingTimeInterval(-buffer),
            to: maxDate.addingTimeInterval(buffer)
        )
        guard !workouts.isEmpty else { return }

        var usedWorkoutIDs = Set<UUID>()
        var updated = false

        for match in needy.sorted(by: { $0.date < $1.date }) {
            let candidates = workouts.filter { !usedWorkoutIDs.contains($0.uuid) }
            guard let workout = bestWorkout(for: match, among: candidates) else { continue }
            let snapshot = await snapshot(from: workout)
            guard snapshot.hasData else { continue }

            match.applyHealth(snapshot, recoveredFromSalute: true)
            usedWorkoutIDs.insert(workout.uuid)
            updated = true
        }

        if updated { try? context.save() }
    }

    // MARK: - HealthKit

    private static func authorize() async {
        guard HKHealthStore.isHealthDataAvailable(), !didAuthorize else { return }

        await withCheckedContinuation { continuation in
            store.requestAuthorization(toShare: [], read: readTypes) { _, _ in
                continuation.resume()
            }
        }
        didAuthorize = true
    }

    private static func fetchWorkouts(around match: MatchRecord) async -> [HKWorkout] {
        let buffer: TimeInterval = 300
        return await fetchWorkouts(
            from: match.date.addingTimeInterval(-buffer),
            to: matchEnd(match).addingTimeInterval(buffer)
        )
    }

    private static func fetchWorkouts(from start: Date, to end: Date) async -> [HKWorkout] {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                continuation.resume(returning: (samples as? [HKWorkout]) ?? [])
            }
            store.execute(query)
        }
    }

    private static func snapshot(from workout: HKWorkout) async -> MatchHealthSnapshot {
        var snap = MatchHealthSnapshot()
        let interval = DateInterval(start: workout.startDate, end: workout.endDate)
        let bpm = HKUnit.count().unitDivided(by: .minute())

        if let calories = workout.statistics(for: HKQuantityType(.activeEnergyBurned))?
            .sumQuantity()?.doubleValue(for: .kilocalorie()), calories > 0 {
            snap.activeCalories = calories
        } else if let calories = await sum(.activeEnergyBurned, in: interval, unit: .kilocalorie()) {
            snap.activeCalories = calories
        }

        if let avg = workout.statistics(for: HKQuantityType(.heartRate))?
            .averageQuantity()?.doubleValue(for: bpm), avg > 0 {
            snap.avgHeartRate = avg
        } else if let avg = await average(.heartRate, in: interval, unit: bpm) {
            snap.avgHeartRate = avg
        }

        if let max = workout.statistics(for: HKQuantityType(.heartRate))?
            .maximumQuantity()?.doubleValue(for: bpm), max > 0 {
            snap.maxHeartRate = max
        } else if let max = await maximum(.heartRate, in: interval, unit: bpm) {
            snap.maxHeartRate = max
        }

        if let steps = workout.statistics(for: HKQuantityType(.stepCount))?
            .sumQuantity()?.doubleValue(for: .count()), steps > 0 {
            snap.steps = Int(steps.rounded())
        } else if let steps = await sum(.stepCount, in: interval, unit: .count()) {
            snap.steps = Int(steps.rounded())
        }

        if let distance = workout.statistics(for: HKQuantityType(.distanceWalkingRunning))?
            .sumQuantity()?.doubleValue(for: .meter()), distance > 0 {
            snap.distanceMeters = distance
        } else if let distance = await sum(.distanceWalkingRunning, in: interval, unit: .meter()) {
            snap.distanceMeters = distance
        }

        return snap
    }

    private static func sum(_ identifier: HKQuantityTypeIdentifier,
                            in interval: DateInterval,
                            unit: HKUnit) async -> Double? {
        await quantityStats(
            identifier,
            in: interval,
            options: .cumulativeSum
        )?.sumQuantity()?.doubleValue(for: unit)
    }

    private static func average(_ identifier: HKQuantityTypeIdentifier,
                                in interval: DateInterval,
                                unit: HKUnit) async -> Double? {
        await quantityStats(
            identifier,
            in: interval,
            options: .discreteAverage
        )?.averageQuantity()?.doubleValue(for: unit)
    }

    private static func maximum(_ identifier: HKQuantityTypeIdentifier,
                                in interval: DateInterval,
                                unit: HKUnit) async -> Double? {
        await quantityStats(
            identifier,
            in: interval,
            options: .discreteMax
        )?.maximumQuantity()?.doubleValue(for: unit)
    }

    private static func quantityStats(
        _ identifier: HKQuantityTypeIdentifier,
        in interval: DateInterval,
        options: HKStatisticsOptions
    ) async -> HKStatistics? {
        let type = HKQuantityType(identifier)
        let predicate = HKQuery.predicateForSamples(
            withStart: interval.start,
            end: interval.end,
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: options
            ) { _, stats, _ in
                continuation.resume(returning: stats)
            }
            store.execute(query)
        }
    }

    // MARK: - Matching

    private static func matchEnd(_ match: MatchRecord) -> Date {
        let estimated = match.date.addingTimeInterval(max(match.duration, 300))
        if !match.setDurations.isEmpty {
            let fromSets = match.date.addingTimeInterval(match.setDurations.reduce(0, +))
            return max(estimated, fromSets)
        }
        return estimated
    }

    /// Sceglie l'allenamento con migliore sovrapposizione temporale.
    private static func bestWorkout(for match: MatchRecord, among workouts: [HKWorkout]) -> HKWorkout? {
        let matchStart = match.date
        let matchEnd = matchEnd(match)

        return workouts
            .compactMap { workout -> (HKWorkout, Double)? in
                let score = matchScore(
                    workout: workout,
                    matchStart: matchStart,
                    matchEnd: matchEnd
                )
                guard score < 1200 else { return nil }
                return (workout, score)
            }
            .min(by: { $0.1 < $1.1 })?
            .0
    }

    private static func matchScore(workout: HKWorkout,
                                   matchStart: Date,
                                   matchEnd: Date) -> Double {
        let overlapStart = max(workout.startDate, matchStart)
        let overlapEnd = min(workout.endDate, matchEnd)
        let overlap = max(0, overlapEnd.timeIntervalSince(overlapStart))
        let matchSpan = max(matchEnd.timeIntervalSince(matchStart), 60)
        let overlapRatio = overlap / matchSpan

        let startDelta = abs(workout.startDate.timeIntervalSince(matchStart))
        let endDelta = abs(workout.endDate.timeIntervalSince(matchEnd))
        let tennisBonus = workout.workoutActivityType == .tennis ? 0.0 : 45.0
        let overlapPenalty = overlapRatio < 0.1 ? 180.0 : 0.0

        return startDelta + endDelta * 0.3 + tennisBonus + overlapPenalty
    }
}
