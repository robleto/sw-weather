import Foundation
import Observation

/// Owns the user's Passport (the worlds they've actually landed on) and its
/// persistence. Port of the web app's `src/app/hooks/usePassport.ts`.
///
/// Unlike the web hook there's no hydration race — the first read is
/// synchronous — but the book can change underneath the app when another
/// device earns a stamp, which the remote-change observer merges in.
@Observable
final class PassportViewModel {
    /// How long a world must stay on screen before it's stamped.
    ///
    /// The pager means a fast swipe through five saved locations would
    /// otherwise machine-gun five stamps for worlds nobody looked at. The
    /// dwell is enforced by `.task(id:)` cancellation at the call site rather
    /// than a timer here.
    static let dwellSeconds: Double = 2

    private(set) var passport: Passport

    @ObservationIgnored private var remoteChangeObserver: NSObjectProtocol?

    init() {
        passport = PassportStorage.load()
        PassportStorage.startSync()
        remoteChangeObserver = PassportStorage.observeRemoteChanges { [weak self] merged in
            guard let self else { return }
            // Merge again against what's in memory: a stamp earned in the
            // seconds around a remote change must not be dropped.
            self.passport = PassportStorage.merge(self.passport, merged)
        }

        #if DEBUG
        warnAboutStrandedWorlds()
        #endif
    }

    deinit {
        if let remoteChangeObserver {
            NotificationCenter.default.removeObserver(remoteChangeObserver)
        }
    }

    var progress: PassportProgress { buildProgress(passport) }

    /// Worlds found by any means — the badge on the menu row.
    var foundCount: Int { passport.count }

    /// Award a stamp. Safe to call repeatedly: `recordSighting` returns nil
    /// when there's nothing new, so a duplicate call neither redraws nor
    /// writes to iCloud.
    @MainActor
    func record(_ resolved: ResolvedWorld, city: String, tempF: Double, now: Date = Date()) {
        guard let next = recordSighting(
            into: passport,
            resolved: resolved,
            city: city,
            tempF: tempF,
            now: now
        ) else { return }

        passport = next
        PassportStorage.save(next)

        Analytics.track(
            AnalyticsSignal.passportStampEarned,
            AnalyticsPayload.passportStampEarned(
                slotId: resolved.slotId,
                kind: stampKind(for: resolved),
                totalStamps: next.count
            )
        )
    }
}
